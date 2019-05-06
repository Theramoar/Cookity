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
//    let shadow = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        
        tableView.register(UINib(nibName: "CartCell", bundle: nil), forCellReuseIdentifier: "CartCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120.0
        
        dataManager.loadFromRealm(vc: self, parentObject: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }

    //MARK: - Buttons and additional methods
    @IBAction func addCartPressed(_ sender: UIButton) {
        DecorationHandler.putShadowOnView(vc: self)
        performSegue(withIdentifier: "addShoppingCart", sender: self)
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
            for product in cart.products {
                dataManager.deleteFromRealm(object: product)
            }
            dataManager.deleteFromRealm(object: cart)
            tableView.reloadData()
        }
    }
    
    //MARK: - Adds SwipeTableViewCell Delegate Method AppendToFridge action
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        
        let appendAction = SwipeAction(style: .default, title: nil) { (action, indexPath) in
            self.addProductsToFridge(at: indexPath)
            self.deleteObject(at: indexPath)
        }
        appendAction.image = UIImage(named: "AddToFridge")
        appendAction.backgroundColor = darkGreen
        
        guard let actionArray = super.tableView(tableView, editActionsForRowAt: indexPath, for: orientation), let deleteAction = actionArray.first else { return [appendAction] }
        
        return [deleteAction, appendAction]
    }
}





//MARK: - Extension for TableView Methods
extension CartCollectionViewController: UITableViewDelegate, UITableViewDataSource {
    
    //MARK: - TableView DataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView.rowHeight = 60
        tableView.separatorInset = .init(top: 0, left: 30, bottom: 0, right: 30)
        return shoppingCarts?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CartCell", for: indexPath) as! CartCell
        cell.delegate = self as SwipeTableViewCellDelegate
        
        if let cart = shoppingCarts?[indexPath.row]{
            cell.cartName.text = cart.name
        }
        return cell
    }
    
    //MARK: - TableView Delegate Methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToCart", sender: self)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToCart" {
            let destinationVC = segue.destination as! CartViewController
            if let indexPath = tableView.indexPathForSelectedRow{
                destinationVC.selectedCart = shoppingCarts?[indexPath.row]
            }
        }
        else if segue.identifier == "addShoppingCart" {
            let destinationVC = segue.destination as! AddCartViewController
            destinationVC.parentVC = self
        }
    }
}
