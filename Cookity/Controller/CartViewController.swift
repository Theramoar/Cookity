//
//  ListViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 03/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift
import SwipeCellKit

class CartViewController: UITableViewController, PopUpDelegate {
    
    let realm = try! Realm()
    let config = Configuration()
    var products: Results<Product>?
    var selectedIndexPath: IndexPath? //variable is used to store the IndexPath selected by LongTap Gesture
    var selectedCart: ShoppingCart?{
        // didSet wil trigger once the selectedCart get set with a value
        didSet{
          loadProducts()
        }
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        title = selectedCart?.name
        
        //add long gesture recognizer
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressed))
        self.view.addGestureRecognizer(longPressRecognizer)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
    }
    
    func deleteProduct(at indexPath: IndexPath){
        if let product = self.products?[indexPath.row - 1] {
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

    // Loadsproducts from the Database to the Array
    func loadProducts(){
        products = selectedCart?.products.filter("inFridge == NO")
    }
    
    //PopUpDelegate method used to reload data while dismissing popup View Controller
    func updateView() {
        tableView.reloadData()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    @objc func viewTapped() {
        self.view.endEditing(true)
    }

    
    @objc func longPressed(longPressRecognizer: UILongPressGestureRecognizer) {
        
        // find the IndexPath of the cell which was "longtouched"
        let touchPoint = longPressRecognizer.location(in: self.view)
        selectedIndexPath = tableView.indexPathForRow(at: touchPoint)
        if selectedIndexPath != nil {
            performSegue(withIdentifier: "popupEdit", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! PopupEditViewController
        destinationVC.delegate = self
        if let indexPath = selectedIndexPath, let product = products?[indexPath.row - 1] {
            destinationVC.selectedProduct = product
        }
        
    }
    
}





//MARK: - Extension for TableView Methods
extension CartViewController: SwipeTableViewCellDelegate, UITextFieldDelegate {
    
    //MARK: - TableView DataSource Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let numberOfProducts = products?.count{
            return numberOfProducts + 1
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let textCell = tableView.dequeueReusableCell(withIdentifier: "TextCell") as! TextFieldCell
            textCell.delegate = self
            textCell.insertMeasure.delegate = self
            textCell.insertProduct.delegate = self
            textCell.insertQuantity.delegate = self
            return textCell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath) as! SwipeTableViewCell
            cell.delegate = self as SwipeTableViewCellDelegate
            if let item = products?[indexPath.row - 1] {
                var measure = item.measure
                
                let (presentedQuantity, presentedMeasure) = config.presentNumbers(quantity: item.quantity, measure: measure)
                
                if measure == "pcs"{
                    if item.quantity == 1 {
                        measure = "piece of"
                    }
                    else {
                        measure = "pieces of"
                    }
                }
                
                cell.textLabel?.text = "\(presentedQuantity) \(presentedMeasure) \(item.name)"
                cell.accessoryType = item.checked ? .checkmark : .none
            }
            return cell
        }
    }
    
    //MARK: - SwipeTableViewCellDelegate Method
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            // handle action by updating model with deletion
            self.deleteProduct(at: indexPath)
        }
        return [deleteAction]
    }
    
    //MARK: - TableView Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let product = products?[indexPath.row - 1]{
            do{
                try realm.write {
                    product.checked = !product.checked
                }
            }catch{
                print("Error while updating items \(error)")
            }
        }
        updateView()
        
        //If all products are checked, App offers to add them to the Fridge
        var checkForFridge: Bool = true
        for product in products! {
            guard product.checked == true else{ return checkForFridge = false }
        }
        if checkForFridge == true {
            let alert = UIAlertController(title: "Add products to the fridge?", message: "", preferredStyle: .actionSheet)
            let yesAction = UIAlertAction(title: "Yes", style: .default) { (_) in
                for product in self.products! {
                    
                    //Checks if the similar product is already in the fridge
                    var productsInFridge: Results<Product>?
                    productsInFridge = self.realm.objects(Product.self).filter("inFridge == YES")
                    for fridgeProduct in productsInFridge!{
                        // if products name and measure coincide, adds quantity and deletes product from the shopping list
                        if product.name == fridgeProduct.name && product.measure == fridgeProduct.measure{
                           do{
                            try self.realm.write {
                                fridgeProduct.quantity += product.quantity
                                self.realm.delete(product)
                                }
                           }
                           catch{
                                print("Error while  adding to fridge \(error)")
                            }
                            break
                        }
                    }
                    if product.isInvalidated == false{
                    do{
                        try self.realm.write {
                            product.inFridge = true
                        }
                    }
                    catch{
                        print("Error while  adding to fridge \(error)")
                        }
                    }
                    self.tableView.reloadData()
                }
            }
            let noAction = UIAlertAction(title: "No", style: .default) { (_) in
                return
            }
            alert.addAction(yesAction)
            alert.addAction(noAction)
            present(alert, animated: true, completion: nil)
            
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    
}





//MARK: - extension for the first TextField cell of the table
extension CartViewController: TextFieldDelegate{
    
    
    
    //MARK: - TextFieldDelegate Method
    func saveProduct(productName: String, productQuantity: String, productMeasure: String)
    {
        let newProduct = Product()
        
        //выделить алерт в отдельную функцию => bool и обратится к ней в popupedit
        let alert = UIAlertController(title: "title", message: "message", preferredStyle: .alert)
        let action = UIAlertAction(title: "Okay", style: .cancel) { (_) in
            return
        }
        alert.addAction(action)
        
        guard productName != "" else {
            alert.title = "No Name"
            alert.message = "Please enter product name"
            present(alert, animated: true, completion: nil)
            return
        }
        
        guard productQuantity != "" else {
            alert.title = "No Quantity"
            alert.message = "Please enter product quantity"
            present(alert, animated: true, completion: nil)
            return
        }
        
        guard Float(productQuantity) != nil else {
            alert.title = "Incorrect Quantity"
            alert.message = "Please enter the quantity in numbers"
            present(alert, animated: true, completion: nil)
            return
        }
        
        let measure = config.configMeasure(measure: productMeasure)
        let (savedQuantity, savedMeasure) = config.configNumbers(quantity: productQuantity, measure: measure)
        
        if let currentCart = selectedCart {
            do{
                try realm.write {
                    newProduct.name = productName
                    newProduct.quantity = savedQuantity
                    newProduct.measure = savedMeasure
                    currentCart.products.append(newProduct)
                }
            }catch{
                print("Error saving context in Product \(error)")
            }
        }
        updateView()
    }
}


