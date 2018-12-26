//
//  CookViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 30/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift

class CookViewController: UIViewController {

    let realm = try! Realm()
    let config = Configuration()
    
    @IBOutlet weak var productsTable: UITableView!
    
    @IBOutlet weak var recipeName: UITextField!
    
    
    var recipeSteps: [String]?
    var products: Results<Product>?
    var chosenIndexPaths = [Int : IndexPath]()
    let sections = ["Choose ingridients for the recipe:", "Describe cooking process:"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recipeName.delegate = self
        productsTable.delegate = self
        productsTable.dataSource = self
        productsTable.keyboardDismissMode = .interactive
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
        
        loadProducts()
    }
    
    
    func loadProducts(){
        products = realm.objects(Product.self).filter("inFridge == YES")
    }
    
    
    func deleteRecipe(recipe: Recipe) {
        do{
            try realm.write {
                self.realm.delete(recipe)
            }
        }catch{
            print("Error while cooking items \(error)")
        }
    }
    
    
    @objc func viewTapped(tapGesture: UITapGestureRecognizer) {
        self.view.endEditing(true)
        productsTable.allowsSelection = true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        productsTable.allowsSelection = false
        
    }
    
    
    func saveStep(step: String) {
        if recipeSteps?.append(step) == nil {
            recipeSteps = [step]
        }
        productsTable.reloadData()
    }
    
    
    @IBAction func cookButtonPressed(_ sender: UIButton) {
        
        let recipe = Recipe()
        let alert = UIAlertController(title: "Amount is not entered!", message: "Enter the amount used for for the recipe", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { (_) in
            return
        }
        alert.addAction(action)
        
        //Check for the entered recipe name correctness
        if recipeName?.text != ""{
            do{
                try realm.write {
                    realm.add(recipe)
                    recipe.name = (recipeName?.text)!
                }
            }catch{
                print("Error saving context in Product \(error)")
            }
        }
        else {
            alert.title = "Recipe name is not entered!"
            alert.message = "Enter the recipe name"
            present(alert, animated: true, completion: nil)
            return
        }
        
        //1st circle is used to iterate over the array and check if all entered quantities are correct
        for (_, indexPath) in chosenIndexPaths{
            let cell = productsTable.cellForRow(at: indexPath) as! CookTableViewCell
            //throws the alert if entered quantity is empty and breaks the cooking and deletes the recipe from database
            
            guard Float(cell.quantityForRecipe.text!) != nil  else {
                deleteRecipe(recipe: recipe)
                alert.title = "Amount is not entered!"
                alert.message = "Enter the amount used for for the recipe"
                present(alert, animated: true, completion: nil)
                return
            }
            
            if let product = products?[indexPath.row]{
                let (quantity, measure) = config.configNumbers(quantity: cell.quantityForRecipe.text!, measure: product.measure)
                //throws the alert if entered quantity suprass the amount in the fridge and breaks the cooking and deletes the recipe from database
                guard product.quantity >= quantity else{
                    deleteRecipe(recipe: recipe)
                    alert.title = "Not enough products"
                    alert.message = "You don't have enough \(product.name) in your fridge"
                    present(alert, animated: true, completion: nil)
                    return
                }
            }
        }
        
        //2nd circle is used for the Data manipulation
        for (_, indexPath) in chosenIndexPaths{
            let cell = productsTable.cellForRow(at: indexPath) as! CookTableViewCell
            
            if let product = products?[indexPath.row]{
                let (quantity, measure) = config.configNumbers(quantity: cell.quantityForRecipe.text!, measure: product.measure)
                
            // 1 - Saves Data for the new Recipe
                    let productForRecipe = Product()
                    do{
                        try realm.write {
                            productForRecipe.name = product.name
                            productForRecipe.quantity = quantity
                            productForRecipe.measure = measure
                            recipe.products.append(productForRecipe)
                        }
                    }catch{
                        print("Error saving context in Product \(error)")
                    }
            
            // 2 - Manages the products in the Fridge
            // if the entered amount equals to the amount in the fridge - deletes the product from database, otherwise substract the quantity
                if product.quantity == quantity {
                    do{
                        try realm.write {
                            self.realm.delete(product)
                        }
                    }catch{
                        print("Error while cooking items \(error)")
                    }
                } else{
                    do{
                        try realm.write {
                            product.quantity -= quantity
                            product.checkForRecipe = false
                        }
                    }catch{
                        print("Error while cooking items \(error)")
                        }
                }
            }
        }
        chosenIndexPaths.removeAll()
        
        if let recipeArray = recipeSteps {
            for recipeStep in recipeArray {
                do{
                    try realm.write {
                        recipe.recipeSteps.append(recipeStep)
                    }
                }catch{
                    print("Error saving context in recipe \(error)")
                }
            }
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        
        // Unchecks all checked products and dismisses VC
        if let loadedProducts = products{
            for product in loadedProducts{
                do{
                    try realm.write {
                        product.checkForRecipe = false
                    }
                }catch{
                    print("Error while cooking items \(error)")
                }
            }
        }
        self.dismiss(animated: true, completion: nil)
    }
}





extension CookViewController: UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, RecipeStepDelegate {
    

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            tableView.rowHeight = 60
            return products?.count ?? 1
        }
        else {
            
            return (recipeSteps?.count ?? 0) + 1
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CookCell", for: indexPath) as! CookTableViewCell
            cell.quantityForRecipe.delegate = self
            cell.selectionStyle = .none
        
            if let product = products?[indexPath.row]{
                cell.textLabel?.text = "\(product.name) - (you have \(product.quantity) \(product.measure))"

            }
            return cell
        }
        else {
            
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddRecipeCell", for: indexPath) as! RecipeStepTableViewCell
                cell.delegate = self
                cell.recipeStep.delegate = self
                cell.selectionStyle = .none
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeCell", for: indexPath)
                if let recipeStep = recipeSteps?[indexPath.row - 1] {
                    cell.textLabel?.text = recipeStep
                }
                cell.selectionStyle = .none
                return cell
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            if let product = products?[indexPath.row]{
                do{
                    try realm.write {
                        product.checkForRecipe = !product.checkForRecipe
                    }
                }catch{
                    print("Error while updating items \(error)")
                }
                
                if  product.checkForRecipe == true{
                    productsTable.cellForRow(at: indexPath)?.textLabel?.textColor = UIColor.orange
                    //adds the chosen cell indexPath to the dictionary to reach the selected products while pressing Cook Button
                    chosenIndexPaths[indexPath.row] = indexPath
                } else {
                    //deletes the chosen cell indexPath from the dictionary if the user unchecks the product
                    productsTable.cellForRow(at: indexPath)?.textLabel?.textColor = UIColor.black
                    chosenIndexPaths.removeValue(forKey: indexPath.row)
                }
            }
            productsTable.deselectRow(at: indexPath, animated: true)
        }
    }
    
}
