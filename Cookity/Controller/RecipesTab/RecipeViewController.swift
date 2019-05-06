//
//  RecipeViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 25/11/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift

class RecipeViewController: UIViewController {
    
    private let dataManager = RealmDataManager()
    
    var productsForRecipe: Results<Product>?
    var productsInFridge: Results<Product>?
    var recipeSteps: Results<RecipeStep>?
    var chosenProducts = [String : Product]() // The variable is used to store the products chosen from the Fridge list. The Key - name of the Recipe Product
    @IBOutlet weak var productTable: UITableView!
    let sections = ["Name", "Ingridients:", "Cooking steps:"]
    
    var selectedRecipe: Recipe?{
        didSet{
            dataManager.loadFromRealm(vc: self, parentObject: selectedRecipe)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        productTable.delegate = self
        productTable.dataSource = self
        productTable.separatorStyle = .none
        
        productTable.rowHeight = UITableView.automaticDimension
        productTable.estimatedRowHeight = 300
    }
    
    override func viewWillAppear(_ animated: Bool) {
        productTable.reloadData()
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
            activityItems: ["Check out this recipe! I like using Cookity.", url],
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
                destinationVC.recipeVC = self
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
        let checkmark = CheckmarkView()
        self.view.addSubview(checkmark)
        checkmark.animate()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            checkmark.removeFromSuperview()
        }
        
        let newCart = ShoppingCart()
        newCart.name = selectedRecipe?.name ?? "Selected Recipe"
        
        if productsForRecipe != nil{
            for product in productsForRecipe! {
                let coppiedProduct = Product(value: product)
                newCart.products.append(coppiedProduct)
            }
        }
        dataManager.saveToRealm(parentObject: nil, object: newCart)
    }
    
    
    @IBAction func cookButtonPressed(_ sender: UIButton) {
        
        if selectedRecipe?.recipeSteps.count != 0 {
            performSegue(withIdentifier: "goToCookProcess", sender: self)
        }
        
        // The loop compares if there is a similar product in the fridge. If Yes - edits this product in the fridge
        guard productsForRecipe != nil else { return }
        for recipeProduct in productsForRecipe! {
            if compareFridgeToRecipe(selectedProduct: recipeProduct) == true {
                if let selectedProduct = chosenProducts[recipeProduct.name] {
                    //If the quantity of the product in Recipe is less than in the Fridge substracts it, else deletes it from the fridge
                    if recipeProduct.quantity >= selectedProduct.quantity {
                        dataManager.deleteFromRealm(object: selectedProduct)
                    }
                    else{
                        let newQuantity = selectedProduct.quantity - recipeProduct.quantity
                        dataManager.changeElementIn(object: selectedProduct, keyValue: "quantity", objectParameter: selectedProduct.quantity, newParameter: newQuantity)
                    }
                }
            }
        }
        productTable.reloadData()
    }
}


extension RecipeViewController: UITableViewDelegate, UITableViewDataSource{
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if recipeSteps?.count == 0 { return 2 }
        return sections.count
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section != 0 else { return nil }
        
        let view = UIView()
        view.backgroundColor = .white
        
        let label = UILabel()
        label.frame = CGRect(x: 5, y: 0, width: 200, height: 35)
        label.textColor = darkGreen
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.text = sections[section]
        view.addSubview(label)
        
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section != 0 else { return 0 }
        return 35
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        else if section == 1 {
            return productsForRecipe?.count.advanced(by: 1) ?? 0
        }
        else {
            return recipeSteps?.count ?? 0
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
        else if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RVRecipeStepCell", for: indexPath) as! RVRecipeStepCell
            if let recipeStep = recipeSteps?[indexPath.row] {
                cell.position = indexPath.row + 1
                cell.recipeStep = recipeStep
            }
            cell.selectionStyle = .none
            return cell
        }
        
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "recipeImageViewCell", for: indexPath) as! RecipeImageViewCell
            cell.recipe = selectedRecipe
            return cell
        }
    }
}
