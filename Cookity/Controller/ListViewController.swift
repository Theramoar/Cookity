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

class ListViewController: UITableViewController, SwipeTableViewCellDelegate {
    
    
    

    let realm = try! Realm()
    var products: Results<Product>?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadProducts()
    }
    
    
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
            return textCell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath) as! SwipeTableViewCell
            cell.delegate = self as SwipeTableViewCellDelegate
            if let item = products?[indexPath.row - 1]{
                cell.textLabel?.text = item.name
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
            self.updateModel(at: indexPath)
        }
        return [deleteAction]
    }
        
    func updateModel(at indexPath: IndexPath){
        if let product = self.products?[indexPath.row - 1] {
            do{
                try self.realm.write {
                    self.realm.delete(product)
                }
            }catch
            {
                print("Error while deleting items \(error)")
            }
            tableView.reloadData()
        }
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
        tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    // Loadsproducts from the Database to the Array
    func loadProducts(){
        products = realm.objects(Product.self)
    }
}


//MARK: - extension for the first TextField cell of the table
extension ListViewController: TextFieldDelegate {
    
    //MARK: - TextFieldDelegate Method
    func saveProduct(productName: String, productQuantity: String)
    {
        let newProduct = Product()
        
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
        
        guard Int(productQuantity) != nil else {
            alert.title = "Incorrect Quantity"
            alert.message = "Please enter the quantity in numbers"
            present(alert, animated: true, completion: nil)
            return
        }
        newProduct.name = productName
        newProduct.quantity = Int(productQuantity)!
        
        do{
            try realm.write {
                realm.add(newProduct)
            }
        }catch{
            print("Error saving context in Product \(error)")
        }
        tableView.reloadData()
    }
}


