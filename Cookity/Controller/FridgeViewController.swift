//
//  FridgeViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 24/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift
import SwipeCellKit

class FridgeViewController: UIViewController, PopUpDelegate {


    let realm = try! Realm()
    let config = Configuration()
    var products: Results<Product>?
    var selectedIndexPath: IndexPath? //variable is used to store the IndexPath selected by LongTap Gesture
    var chosenIndexPaths = [Int : IndexPath]() // dictionary is used to store the indexPaths of chosen cells, Key value is the number of cell is used to find the cell in the dictionary
    @IBOutlet weak var fridgeTableView: UITableView!
    @IBOutlet weak var addButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addButton.isEnabled = false
        addButton.isHidden = true
        
        fridgeTableView.delegate = self
        fridgeTableView.dataSource = self
        loadProducts()
        
        //add long gesture recognizer
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressed))
        self.view.addGestureRecognizer(longPressRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateView()
    }
   
    
    func loadProducts(){
        products = realm.objects(Product.self).filter("inFridge == YES")
    }
    
    
    //PopUpDelegate method used to reload data while dismissing popup View Controller
    func updateView() {
        fridgeTableView.reloadData()
    }
    
    func deleteProduct(at indexPath: IndexPath){
        if let product = self.products?[indexPath.row] {
            do{
                try self.realm.write {
                    self.realm.delete(product)
                }
            }catch
            {
                print("Error while deleting items \(error)")
            }
            updateView()
        }
    }
    
    
    // Methods for buttons
    @objc func longPressed(longPressRecognizer: UILongPressGestureRecognizer) {

        // find the IndexPath of the cell which was "longtouched"
        let touchPoint = longPressRecognizer.location(in: self.fridgeTableView)
        selectedIndexPath = fridgeTableView.indexPathForRow(at: touchPoint)
        guard selectedIndexPath != nil else { return }
        if self.presentedViewController == nil {
            performSegue(withIdentifier: "popupEditFridge", sender: self)
        }
    }
    
    
    @IBAction func addButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "goToCookingAreaFromFridge", sender: self)
        chosenIndexPaths.removeAll()
        addButton.isEnabled = false
        addButton.isHidden = true
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "popupEditFridge"{
            let destinationVC = segue.destination as! PopupEditViewController
            if let indexPath = selectedIndexPath, let product = products?[indexPath.row] {
                destinationVC.selectedProduct = product
                destinationVC.delegate = self
            }
        }
        else if segue.identifier == "goToCookingAreaFromFridge" {
            let destinationVC = segue.destination as! CookViewController
            
            for (_, indexPath) in chosenIndexPaths {
                
                if let product = products?[indexPath.row] {
                    
                    //creates the separate product in the Realm which can be used and edited in the recipe, not touching the existing product in the fridge
                    let copiedProduct = Product()
                    copiedProduct.name = product.name
                    copiedProduct.quantity = product.quantity
                    copiedProduct.measure = product.measure
                    
                    destinationVC.products.append(copiedProduct)
                }
                fridgeTableView.cellForRow(at: indexPath)?.textLabel?.textColor = UIColor.black
            }
        }

        
    }
}




//MARK: - Extension for TableView Methods
extension FridgeViewController: UITableViewDelegate, UITableViewDataSource, SwipeTableViewCellDelegate {
    
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            self.deleteProduct(at: indexPath)
        }
        return [deleteAction]
    }
    
    
    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FridgeCell", for: indexPath) as! SwipeTableViewCell
        cell.delegate = self as SwipeTableViewCellDelegate
        cell.selectionStyle = .none
        
        if let products = products?[indexPath.row]{
            let (presentedQuantity, presentedMeasure) = config.presentNumbers(quantity: products.quantity, measure: products.measure)
            cell.textLabel?.text = "\(presentedQuantity) \(presentedMeasure) of \(products.name)"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let product = products?[indexPath.row]{
            do{
                try realm.write {
                    product.checkForRecipe = !product.checkForRecipe
                }
            }catch{
                print("Error while updating items \(error)")
            }
            
            if  product.checkForRecipe == true{
                fridgeTableView.cellForRow(at: indexPath)?.textLabel?.textColor = UIColor.green
                //adds the chosen cell indexPath to the dictionary to reach the selected products while pressing Cook Button
                chosenIndexPaths[indexPath.row] = indexPath
            } else {
                //deletes the chosen cell indexPath from the dictionary if the user unchecks the product
                fridgeTableView.cellForRow(at: indexPath)?.textLabel?.textColor = UIColor.black
                chosenIndexPaths.removeValue(forKey: indexPath.row)
            }
        }
        fridgeTableView.deselectRow(at: indexPath, animated: true)
       
        if chosenIndexPaths.count > 0 {
            addButton.isEnabled = true
            addButton.isHidden = false
        }
        else {
            addButton.isEnabled = false
            addButton.isHidden = true
        }
    }
}




//{
//    //
//    var recipe = Recipe()
//    if editedRecipe != nil {
//        recipe = editedRecipe!
//    }
//
//    let alert = UIAlertController(title: "Amount is not entered!", message: "Enter the amount used for for the recipe", preferredStyle: .alert)
//    let action = UIAlertAction(title: "OK", style: .default) { (_) in
//        return
//    }
//    alert.addAction(action)
//    
//    //Check for the entered recipe name correctness
//    if recipeName?.text != ""{
//        do{
//            try realm.write {
//                realm.add(recipe)
//                recipe.name = (recipeName?.text)!
//            }
//        }catch{
//            print("Error saving context in Product \(error)")
//        }
//    }
//    else {
//        alert.title = "Recipe name is not entered!"
//        alert.message = "Enter the recipe name"
//        present(alert, animated: true, completion: nil)
//        return
//    }
//    //
//    //1st circle is used to iterate over the array and check if all entered quantities are correct
//    let cells = productsTable.visibleCells as! Array<UITableViewCell>
//
//    for (_, indexPath) in chosenIndexPaths{
//        let cell = productsTable.cellForRow(at: indexPath) as! CookTableViewCell
//
//        //throws the alert if entered quantity is empty and breaks the cooking and deletes the recipe from database
//
//        guard Float(cell.quantityForRecipe.text!) != nil  else {
//            deleteRecipe(recipe: recipe)
//            alert.title = "Amount is not entered!"
//            alert.message = "Enter the amount used for for the recipe"
//            present(alert, animated: true, completion: nil)
//            return
//        }
//
//        if let product = products?[indexPath.row]{
//            let (quantity, _) = config.configNumbers(quantity: cell.quantityForRecipe.text!, measure: product.measure)
//            //throws the alert if entered quantity suprass the amount in the fridge and breaks the cooking and deletes the recipe from database
//            guard product.quantity >= quantity else{
//                deleteRecipe(recipe: recipe)
//                alert.title = "Not enough products"
//                alert.message = "You don't have enough \(product.name) in your fridge"
//                present(alert, animated: true, completion: nil)
//                return
//            }
//        }
//    }
//    //
//    //        //2nd circle is used for the Data manipulation
//    //        for (_, indexPath) in chosenIndexPaths{
//    //            let cell = productsTable.cellForRow(at: indexPath) as! CookTableViewCell
//    //
//    //            if let product = products?[indexPath.row]{
//    //                let (quantity, measure) = config.configNumbers(quantity: cell.quantityForRecipe.text!, measure: product.measure)
//    //
//    //            // 1 - Saves Data for the new Recipe
//    //                    let productForRecipe = Product()
//    //                    do{
//    //                        try realm.write {
//    //                            productForRecipe.name = product.name
//    //                            productForRecipe.quantity = quantity
//    //                            productForRecipe.measure = measure
//    //                            recipe.products.append(productForRecipe)
//    //                        }
//    //                    }catch{
//    //                        print("Error saving context in Product \(error)")
//    //                    }
//    //
//    //            // 2 - Manages the products in the Fridge
//    //            // if the entered amount equals to the amount in the fridge - deletes the product from database, otherwise substract the quantity
//    ////                if product.quantity == quantity {
//    ////                    do{
//    ////                        try realm.write {
//    ////                            self.realm.delete(product)
//    ////                        }
//    ////                    }catch{
//    ////                        print("Error while cooking items \(error)")
//    ////                    }
//    ////                } else{
//    ////                    do{
//    ////                        try realm.write {
//    ////                            product.quantity -= quantity
//    ////                            product.checkForRecipe = false
//    ////                        }
//    ////                    }catch{
//    ////                        print("Error while cooking items \(error)")
//    ////                        }
//    ////                }
//    //            }
//    //        }
//    //        chosenIndexPaths.removeAll()
//    //
//    //        if let recipeArray = recipeSteps {
//    //            for recipeStep in recipeArray {
//    //                do{
//    //                    try realm.write {
//    //                        recipe.recipeSteps.append(recipeStep)
//    //                    }
//    //                }catch{
//    //                    print("Error saving context in recipe \(error)")
//    //                }
//    //            }
//    //        }
//    self.dismiss(animated: true, completion: nil)
//}
