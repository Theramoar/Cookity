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
    
    @IBOutlet weak var productTable: UITableView!
    @IBOutlet weak var cookButton: UIButton!
    @IBOutlet var recipeDataManager: RecipeDataManager!
    
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
        if recipeDataManager.selectedRecipe?.isInvalidated ?? true {
            navigationController?.popViewController(animated: true)
        }
        else {
            if let imageFileName = recipeDataManager.selectedRecipe?.imageFileName,
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
    

    
    
    @IBAction func shareButtonPressed(_ sender: UIBarButtonItem) {
        guard let recipe = recipeDataManager.selectedRecipe,
            let activity = recipeDataManager.shareObject(recipe) else { return }
        activity.popoverPresentationController?.barButtonItem = sender
        present(activity, animated: true, completion: nil)
    }
    
    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "EditCookingArea", sender: self)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "EditCookingArea" {
            let destinationVC = segue.destination as! CookViewController
            if let recipe = recipeDataManager.selectedRecipe {
                destinationVC.cookDataManager.selectedRecipe = recipe
                destinationVC.updateVCDelegate = self
            }
        }
        else if segue.identifier == "goToCookProcess" {
            let destinationVC = segue.destination as! CookProcessViewController
            if let selectedRecipe = recipeDataManager.selectedRecipe {
                destinationVC.recipeSteps = Array(selectedRecipe.recipeSteps)
            }
        }
    }
        
    
    //Creates a new shopping list the adds the products from recipe to it
    @IBAction func createButtonPressed(_ sender: UIButton) {
        let checkmark = CheckmarkView(frame: self.view.frame, message: "Done!")
        self.view.addSubview(checkmark)
        checkmark.animate()
        recipeDataManager.createCartFromRecipe()
    }
    
    
    @IBAction func cookButtonPressed(_ sender: UIButton) {
        if recipeDataManager.selectedRecipe?.recipeSteps.count != 0 {
            performSegue(withIdentifier: "goToCookProcess", sender: self)
        }
        else {
            let checkmark = CheckmarkView(frame: self.view.frame, message: "Fridge was edited")
            self.view.addSubview(checkmark)
            checkmark.animate()
        }
        recipeDataManager.editFridgeProducts()
        productTable.reloadData()
    }
}


//MARK:- UITableView Methods
extension RecipeViewController: UITableViewDelegate, UITableViewDataSource{
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if recipeDataManager.recipeSteps.count == 0 { return 2 }
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0,
              let name = recipeDataManager.selectedRecipe?.name else { return nil }
        let backgroundView = RecipeSectionView()
        backgroundView.configureView(.Header, with: name)
        return backgroundView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section != 2 else { return nil }
        if section == 1, recipeDataManager.recipeSteps.count == 0 { return nil }
        
        let backgroundView = RecipeSectionView()
        backgroundView.configureView(.Footer, with: sections[section + 1])
        return backgroundView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard section != 2 else { return 0 }
        if section == 1, recipeDataManager.recipeSteps.count == 0 { return 0 }
        return 30
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section == 0 else { return 0 }
        return 38
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return recipeDataManager.products.count.advanced(by: 1)
        }
        else if section == 2 {
            return recipeDataManager.recipeSteps.count
        }
        else {
            return 0
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            if indexPath.row < recipeDataManager.products.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeProductCell", for: indexPath) as! RecipeProductCell
                let product = recipeDataManager.products[indexPath.row]
                cell.productsInFridge = Array(recipeDataManager.productsInFridge)
                cell.product = product
                
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "createShoppingListCell", for: indexPath) as! CreateListCell
                return cell
            }
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RVRecipeStepCell", for: indexPath) as! RVRecipeStepCell
            let recipeStep = recipeDataManager.recipeSteps[indexPath.row]
            cell.position = indexPath.row + 1
            cell.recipeStep = recipeStep
            
            cell.selectionStyle = .none
            return cell
        }
    }
}
