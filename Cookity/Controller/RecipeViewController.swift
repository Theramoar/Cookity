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
    
    private let config = Configuration()
    private let dataManager = RealmDataManager()
    
    var productsForRecipe: Results<Product>?
    var productsInFridge: Results<Product>?
    var recipeSteps: Results<RecipeStep>?
    var chosenProducts = [String : Product]() // The variable is used to store the products chosen from the Fridge list. The Key - name of the Recipe Product
    @IBOutlet weak var productTable: UITableView!
    let sections = ["Ingridients:", "Cooking steps:"]
    
    var selectedRecipe: Recipe?{
        didSet{
            dataManager.loadFromRealm(vc: self, parentObject: selectedRecipe)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        productTable.delegate = self
        productTable.dataSource = self
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
    
    
    
    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "EditCookingArea", sender: self)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! CookViewController
        if selectedRecipe != nil {
            destinationVC.editedRecipe = selectedRecipe
            destinationVC.recipeVC = self
        }
    }
        
    
    
    
    //Creates a new shopping list the adds the products from recipe to it
    @IBAction func createButtonPressed(_ sender: UIButton) {
        
        //Добавить возможность добавить только те продукты которых нет в холодильнике
        
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
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return productsForRecipe?.count ?? 0
        }
        else {
            return recipeSteps?.count ?? 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recipeProductCell", for: indexPath)
        
        if let product = productsForRecipe?[indexPath.row] {
            
            let (presentedQuantity, presentedMeasure) = config.presentNumbers(quantity: product.quantity, measure: product.measure)
            
            var description = "(You don't have any)"
            if compareFridgeToRecipe(selectedProduct: product) == true {
                if let selectedProduct = chosenProducts[product.name]{
                    
                    let (selectedQuantity, selectedMeasure) = config.presentNumbers(quantity: selectedProduct.quantity, measure: selectedProduct.measure)
                    description = "(You have \(selectedQuantity) \(selectedMeasure))"
                }
            }
            cell.textLabel?.text = "\(product.name) - \(presentedQuantity) \(presentedMeasure) \(description)"
        }
        
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "recipeProductCell", for: indexPath)
            if let recipeStep = recipeSteps?[indexPath.row] {
                cell.textLabel?.text = recipeStep.name
            }
            cell.selectionStyle = .none
            return cell
        }
    }
    
    
}
