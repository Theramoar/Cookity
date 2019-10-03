//
//  RecipeViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 25/11/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift

enum ParentViewForLabel {
    case image
    case view
}

class RecipeViewController: UIViewController, UpdateVCDelegate {
    
    private let dataManager = RealmDataManager()
    
    var productsForRecipe: List<Product>?
    var productsInFridge: List<Product>?
    var recipeSteps: List<RecipeStep>?
    var chosenProducts = [String : Product]() // The variable is used to store the products chosen from the Fridge list. The Key - name of the Recipe Product
    @IBOutlet weak var productTable: UITableView!
    @IBOutlet weak var cookButton: UIButton!
    
    let imageView = UIImageView()
    let labelRightView = UIView()
    let recipeNameLabel = UILabel()
    
    var navBarHeight: CGFloat {
        guard let navBarHeight = self.navigationController?.navigationBar.frame.height,
            let statBarHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height
        else { return 0 }
        return statBarHeight + navBarHeight
    }

    let sections = ["Name", "Ingridients:", "Cooking steps:"]
    
    var selectedRecipe: Recipe?{
        didSet{
            productsForRecipe = selectedRecipe?.products
            recipeSteps = selectedRecipe?.recipeSteps
            productsInFridge = Fridge.shared.products
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        productTable.delegate = self
        productTable.dataSource = self
        productTable.separatorStyle = .none
        productTable.rowHeight = UITableView.automaticDimension
        productTable.estimatedRowHeight = 100
        
        cookButton.layer.shadowOffset = CGSize(width: 0, height: 3.0)
        cookButton.layer.shadowOpacity = 0.7
        cookButton.layer.shadowRadius = 5.0
    }

    override func viewWillAppear(_ animated: Bool) {
        updateVC()
    }
    
    func updateVC() {
        if selectedRecipe?.isInvalidated ?? true {
            navigationController?.popViewController(animated: true)
        }
        else {
            if let imageFileName = selectedRecipe?.imageFileName,
            let image = Configuration.getImageFromFileManager(with: imageFileName) {
                addImageView(image: image)
                productTable.reloadData()
            }
            else {
                setStandardNavBar()
            }
        }
    }
    
    private func addImageView(image: UIImage) {

        productTable.contentInset = UIEdgeInsets(top: 300, left: 0, bottom: 0, right: 0)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = .clear
        self.navigationController?.navigationBar.backgroundColor = .clear
        self.navigationController?.navigationBar.tintColor = .white
        
        imageView.image = image
        let imageHeight = 300 + navBarHeight
        imageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: imageHeight)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        view.addSubview(imageView)
    }
    
    private func setStandardNavBar() {
        imageView.removeFromSuperview()
//        self.preferredStatusBarStyle = UIStatusBarStyle.default
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.view.backgroundColor = Colors.appColor
        self.navigationController?.navigationBar.tintColor = Colors.textColor
        productTable.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let labelY = max(navBarHeight, imageView.frame.height - 38)
        recipeNameLabel.frame.origin.y = labelY
        labelRightView.frame.origin.y = labelY
        let y = 300 - (scrollView.contentOffset.y + 300)
        let height = min(max(y, navBarHeight + recipeNameLabel.frame.height), 600)
        imageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: height)
    }
    
    func compareFridgeToRecipe(selectedProduct: Product) -> Bool{
        if productsInFridge != nil{
            for product in productsInFridge!{
                if selectedProduct.name == product.name{
                    chosenProducts[selectedProduct.name] = product
                    return true
                }
            }
        }
            return false
    }
    
    
    @IBAction func shareButtonPressed(_ sender: UIBarButtonItem) {
        
        let shareManager = ShareDataManager()
        guard
        let recipe = selectedRecipe,
        let url = shareManager.exportToURL(object: recipe)
        else { return }
        
        let activity = UIActivityViewController(
            activityItems: ["Check out this recipe! You can use Cookity app to read it.", url],
            applicationActivities: nil
        )
        activity.popoverPresentationController?.barButtonItem = sender
        
        present(activity, animated: true, completion: nil)
    }
    
    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "EditCookingArea", sender: self)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "EditCookingArea" {
            let destinationVC = segue.destination as! CookViewController
            if selectedRecipe != nil {
                destinationVC.editedRecipe = selectedRecipe
                destinationVC.updateVCDelegate = self
//                destinationVC.recipeVC = self
            }
        }
        else if segue.identifier == "goToCookProcess" {
            let destinationVC = segue.destination as! CookProcessViewController
            if let selectedRecipe = selectedRecipe {
                destinationVC.recipeSteps = Array(selectedRecipe.recipeSteps)
            }
        }
    }
        
    
    //Creates a new shopping list the adds the products from recipe to it
    @IBAction func createButtonPressed(_ sender: UIButton) {
        let checkmark = CheckmarkView(frame: self.view.frame, message: "Done!")
        self.view.addSubview(checkmark)
        checkmark.animate()
        
        let newCart = ShoppingCart()
        newCart.name = selectedRecipe?.name ?? "Selected Recipe"
        
        if productsForRecipe != nil{
            for product in productsForRecipe! {
                let coppiedProduct = Product(value: product)
                newCart.products.append(coppiedProduct)
            }
        }
        RealmDataManager.saveToRealm(parentObject: nil, object: newCart)
        CloudManager.saveDataToCloud(ofType: .Cart, object: newCart) { (recordID) in
            DispatchQueue.main.async {
                RealmDataManager.changeElementIn(object: newCart,
                                                 keyValue: "cloudID",
                                                 objectParameter: newCart.cloudID,
                                                 newParameter: recordID)
            }
        }
    }
    
    
    @IBAction func cookButtonPressed(_ sender: UIButton) {
        
        if selectedRecipe?.recipeSteps.count != 0 {
            performSegue(withIdentifier: "goToCookProcess", sender: self)
        }
        else {
            let checkmark = CheckmarkView(frame: self.view.frame, message: "Fridge was edited")
            self.view.addSubview(checkmark)
            checkmark.animate()
        }
        // The loop compares if there is a similar product in the fridge. If Yes - edits this product in the fridge
        guard productsForRecipe != nil else { return }
        for recipeProduct in productsForRecipe! {
            if compareFridgeToRecipe(selectedProduct: recipeProduct) == true {
                if let selectedProduct = chosenProducts[recipeProduct.name] {
                    //If the quantity of the product in Recipe is less than in the Fridge substracts it, else deletes it from the fridge
                    if recipeProduct.quantity >= selectedProduct.quantity {
                        RealmDataManager.deleteFromRealm(object: selectedProduct)
                    }
                    else{
                        let newQuantity = selectedProduct.quantity - recipeProduct.quantity
                        RealmDataManager.changeElementIn(object: selectedProduct, keyValue: "quantity", objectParameter: selectedProduct.quantity, newParameter: newQuantity)
                    }
                }
            }
        }
        productTable.reloadData()
    }
}


//MARK:- UITableView Methods
extension RecipeViewController: UITableViewDelegate, UITableViewDataSource{
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if recipeSteps?.count == 0 { return 2 }
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0 else { return nil }
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = Colors.viewColor
        let nameLabel = UILabel()
        nameLabel.font = UIFont.systemFont(ofSize: 30, weight: .black)
        nameLabel.text = selectedRecipe?.name
        nameLabel.numberOfLines = 2
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 1/3
        nameLabel.textColor = Colors.textColor
        nameLabel.backgroundColor = Colors.viewColor
        let labelWidth = (UIScreen.main.bounds.size.width / 4) * 3
        nameLabel.frame = CGRect(x: 8, y: 0, width: Int(labelWidth), height: 38)
        backgroundView.addSubview(nameLabel)
        return backgroundView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section != 2 else { return nil }
        if section == 1, recipeSteps?.count == 0 { return nil }
        let backgroundView = UIView()
        backgroundView.backgroundColor = Colors.viewColor
        let nameLabel = UILabel()
        nameLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        nameLabel.text = sections[section + 1]
        nameLabel.textColor = Colors.textColor
        nameLabel.frame = CGRect(x: 8, y: 0, width: UIScreen.main.bounds.size.width, height: 30)
        backgroundView.addSubview(nameLabel)
        return backgroundView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard section != 2 else { return 0 }
        if section == 1, recipeSteps?.count == 0 { return 0 }
        return 30
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section == 0 else { return 0 }
        return 38
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return productsForRecipe?.count.advanced(by: 1) ?? 0
        }
        else if section == 2 {
            return recipeSteps?.count ?? 0
        }
        else {
            return 0
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            if indexPath.row < (productsForRecipe?.count)! {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeProductCell", for: indexPath) as! RecipeProductCell
                
                if let product = productsForRecipe?[indexPath.row] {
                    
                    if let productsInFridge = productsInFridge {
                        cell.productsInFridge = Array(productsInFridge)
                    }
                    
                    cell.product = product
                }
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "createShoppingListCell", for: indexPath) as! CreateListCell
                return cell
            }
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RVRecipeStepCell", for: indexPath) as! RVRecipeStepCell
            if let recipeStep = recipeSteps?[indexPath.row] {
                cell.position = indexPath.row + 1
                cell.recipeStep = recipeStep
            }
            cell.selectionStyle = .none
            return cell
        }
    }
}
