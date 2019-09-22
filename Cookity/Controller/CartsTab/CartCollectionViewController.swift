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
    @IBOutlet weak var addCartButton: UIButton!
    
    var shoppingCarts: Results<ShoppingCart>? {
        didSet {
            guard SettingsVariables.isCloudEnabled else { return }
            var carts = [ShoppingCart]()
            for cart in shoppingCarts! {
                carts.append(cart)
            }
            CloudManager.syncData(ofType: .Cart, parentObjects: carts)
        }
    }
    var productsInFridge: List<Product>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: "CartCell", bundle: nil), forCellReuseIdentifier: "CartCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120.0
        
        addCartButton.layer.shadowOffset = CGSize(width: 0, height: 3.0)
        addCartButton.layer.shadowOpacity = 0.7
        addCartButton.layer.shadowRadius = 5.0
        
        shoppingCarts = RealmDataManager.dataLoadedFromRealm(ofType: .Cart)
        productsInFridge = Fridge.shared.products
        loadDataFromCloud()
        
        
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
    private func loadDataFromCloud() {
        let objects = Array(shoppingCarts!)
        CloudManager.loadDataFromCloud(ofType: .Cart, recipes: objects) { (parentObject) in
            RealmDataManager.saveToRealm(parentObject: nil, object: parentObject)
            self.tableView.reloadData()
        }
    }
    
    func addProductsToFridge(at indexPath: IndexPath){
        guard let cart = shoppingCarts?[indexPath.row],
            let productsInFridge = productsInFridge
        else { return }
        
        var copiedProducts = [Product]()
        for product in cart.products {
            //Checks if the similar product is already in the fridge
            for fridgeProduct in productsInFridge {
                // if products name and measure coincide, adds quantity and deletes product from the shopping list
                if product.name.lowercased() == fridgeProduct.name.lowercased() && product.measure == fridgeProduct.measure{
                    
                    let newQuantity = fridgeProduct.quantity + product.quantity
                    RealmDataManager.changeElementIn(object: fridgeProduct,
                                                keyValue: "quantity",
                                                objectParameter: fridgeProduct.quantity,
                                                newParameter: newQuantity)
                    RealmDataManager.deleteFromRealm(object: product)
                    break
                }
            }
            // вылетает приложение
            if product.isInvalidated == false{
                let coppiedProduct = Product(value: product)
                coppiedProduct.cloudID = nil
                coppiedProduct.checked = false
                RealmDataManager.saveToRealm(parentObject: Fridge.shared, object: coppiedProduct)
                copiedProducts.append(coppiedProduct)
            }
        }
        if let fridgeRecordID = Fridge.shared.cloudID {
            CloudManager.saveProductsToCloud(to: .Fridge, products: copiedProducts, parentRecordID: fridgeRecordID)
        }
    }
    
    override func deleteObject(at indexPath: IndexPath) {
        if let cart = self.shoppingCarts?[indexPath.row] {
            for product in cart.products {
                RealmDataManager.deleteFromRealm(object: product)
            }
            if let recordID = cart.cloudID {
                CloudManager.deleteRecordFromCloud(ofType: .Cart, recordID: recordID)
            }

            RealmDataManager.deleteFromRealm(object: cart)
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
