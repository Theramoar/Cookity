//
//  CartCollectionViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 21/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift
import SwipeCellKit

class CartCollectionViewController: SwipeTableViewController {
    

    @IBOutlet weak var tableView: UITableView!
    var shoppingCarts: Results<ShoppingCart>?
    var productsInFridge: Results<Product>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        dataManager.loadFromRealm(vc: self, parentObject: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }

    //MARK: - Buttons and additional methods
    @IBAction func addShoppingCart(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Title", message: "Message", preferredStyle: .alert)
        var textField = UITextField()
        
        let action = UIAlertAction(title: "Add", style: .default) { (action) in
            
            guard textField.text!.isEmpty != true else { return }
            let cart = ShoppingCart()
            cart.name = textField.text!
            self.dataManager.saveToRealm(parentObject: nil, object: cart)
            self.tableView.reloadData()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Add new Shopping Cart"
            textField = alertTextField
        }
        alert.addAction(action)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
   
    //MARK: - Data Manipulation Methods
    func addProductsToFridge(at indexPath: IndexPath){
        guard let products = self.shoppingCarts?[indexPath.row].products.filter("inFridge == NO") else { return }
        
        for product in products {
            //Checks if the similar product is already in the fridge
            for fridgeProduct in productsInFridge!{
                // if products name and measure coincide, adds quantity and deletes product from the shopping list
                if product.name == fridgeProduct.name && product.measure == fridgeProduct.measure{
                    
                    let newQuantity = fridgeProduct.quantity + product.quantity
                    dataManager.changeElementIn(object: fridgeProduct,
                                                keyValue: "quantity",
                                                objectParameter: fridgeProduct.quantity,
                                                newParameter: newQuantity)
                    dataManager.deleteFromRealm(object: product)
                    break
                }
            }
            if product.isInvalidated == false{
                dataManager.changeElementIn(object: product,
                                            keyValue: "inFridge",
                                            objectParameter: product.inFridge,
                                            newParameter: true)
            }
        }
        tableView.reloadData()
    }
    
    override func deleteObject(at indexPath: IndexPath) {
        if let cart = self.shoppingCarts?[indexPath.row] {
            dataManager.deleteFromRealm(object: cart)
            tableView.reloadData()
        }
    }
    
    //MARK: - Adds SwipeTableViewCell Delegate Method AppendToFridge actiona
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        
        let appendAction = SwipeAction(style: .default, title: "Add to Fridge") { (action, indexPath) in
            self.addProductsToFridge(at: indexPath)
        }
        
        guard let actionArray = super.tableView(tableView, editActionsForRowAt: indexPath, for: orientation), let deleteAction = actionArray.first else { return [appendAction] }
        
        return [deleteAction, appendAction]
    }
}





//MARK: - Extension for TableView Methods
extension CartCollectionViewController: UITableViewDelegate, UITableViewDataSource {
    
    //MARK: - TableView DataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shoppingCarts?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CartCell", for: indexPath) as! SwipeTableViewCell
        cell.delegate = self as SwipeTableViewCellDelegate
        
        if let cart = shoppingCarts?[indexPath.row]{
            cell.textLabel?.text = cart.name
        }
        return cell
    }
    
    //MARK: - TableView Delegate Methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToCart", sender: self)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! CartViewController
        
        if let indexPath = tableView.indexPathForSelectedRow{
            destinationVC.selectedCart = shoppingCarts?[indexPath.row]
        }
    }
}
