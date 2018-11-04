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

class CartCollectionViewController: UITableViewController, SwipeTableViewCellDelegate {
    

    var shoppingCarts: Results<ShoppingCart>?
    let realm = try! Realm()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadCarts()
    }

    //MARK: - Buttons and additional methods
    @IBAction func addShoppingCart(_ sender: UIBarButtonItem) {
        
        let alert = UIAlertController(title: "Title", message: "Message", preferredStyle: .alert)
        var textField = UITextField()
        
        let action = UIAlertAction(title: "Add", style: .default) { (action) in
            
            let cart = ShoppingCart()
            cart.name = textField.text!
            self.saveCart(cart: cart)
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Add new Shopping Cart"
            textField = alertTextField
        }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
   
    //MARK: - Data Manipulation Methods
    func saveCart(cart: ShoppingCart){
        do{
            try realm.write {
                realm.add(cart)
            }
        }catch{
            print("Error while saving cart \(error)")
        }
       self.tableView.reloadData()
    }
    
    func loadCarts(){
        shoppingCarts = realm.objects(ShoppingCart.self)
    }
    
    func updateModel(at indexPath: IndexPath){
        if let cart = self.shoppingCarts?[indexPath.row] {
            do{
                try self.realm.write {
                    self.realm.delete(cart)
                }
            }catch
            {
                print("Error while deleting items \(error)")
            }
            tableView.reloadData()
        }
    }
    
    func addProductsToFridge(at indexPath: IndexPath){
        guard let products = self.shoppingCarts?[indexPath.row].products.filter("inFridge == NO") else { return }
        for product in products {
            
            //Checks if the similar product is already in the fridge
            var productsInFridge: Results<Product>?
            productsInFridge = realm.objects(Product.self).filter("inFridge == YES")
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
            }catch{
                print("Error while appending products to the fridge \(error)")
                }
            }
        }
    }
}





//MARK: - Extension for TableView Methods
extension CartCollectionViewController {
    
    //MARK: - TableView DataSource Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shoppingCarts?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CartCell", for: indexPath) as! SwipeTableViewCell
        cell.delegate = self as SwipeTableViewCellDelegate
        
        if let cart = shoppingCarts?[indexPath.row]{
            cell.textLabel?.text = cart.name
        }
        return cell
    }
    
    //MARK: - SwipeTableViewCell Delegate Methods
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else {return nil}
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            self.updateModel(at: indexPath)
        }
        
        let appendAction = SwipeAction(style: .default, title: "Add to Fridge") { (action, indexPath) in
            self.addProductsToFridge(at: indexPath)
        }
        return [deleteAction, appendAction]
    }
    
    //MARK: - TableView Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToCart", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! CartViewController
        
        if let indexPath = tableView.indexPathForSelectedRow{
            destinationVC.selectedCart = shoppingCarts?[indexPath.row]
        }
    }
}
