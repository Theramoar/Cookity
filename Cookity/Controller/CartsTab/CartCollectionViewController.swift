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

class CartCollectionViewController: SwipeTableViewController, UpdateVCDelegate {
    

    @IBOutlet var cartDataManager: CartDataManager!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addCartButton: UIButton!
    

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
        
        cartDataManager.updateVCDelegate = self
        
        cartDataManager.shoppingCarts = RealmDataManager.dataLoadedFromRealm(ofType: .Cart)
        cartDataManager.productsInFridge = Fridge.shared.products
        cartDataManager.loadCartsFromCloud()
    }
    
    func updateVC() {
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToCart" {
            let destinationVC = segue.destination as! CartViewController
            if let indexPath = tableView.indexPathForSelectedRow{
                destinationVC.cartDataManager.selectedCart = cartDataManager.shoppingCarts?[indexPath.row]
            }
        }
        else if segue.identifier == "addShoppingCart" {
            let destinationVC = segue.destination as! AddCartViewController
            destinationVC.updateVCDelegate = self
        }
    }

    //MARK: - Buttons and additional methods
    @IBAction func addCartPressed(_ sender: UIButton) {
        DecorationHandler.putShadowOnView(vc: self)
        performSegue(withIdentifier: "addShoppingCart", sender: self)
    }
    
    //MARK: - Data Manipulation Methods
    override func deleteObject(at indexPath: IndexPath) {
        cartDataManager.deleteCart(at: indexPath.row)
        tableView.reloadData()
    }
    
    
    //MARK: - Adds SwipeTableViewCell Delegate Method AppendToFridge action
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        
        let appendAction = SwipeAction(style: .default, title: nil) { (action, indexPath) in
            guard let cart = self.cartDataManager.shoppingCarts?[indexPath.row] else { return }
            self.cartDataManager.moveProductsToFridge(from: cart)
            tableView.reloadData()
        }
        appendAction.image = UIImage(named: "AddToFridge")
        appendAction.backgroundColor = Colors.darkGreen
        
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
        return cartDataManager.shoppingCarts?.count ?? 1
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CartCell", for: indexPath) as! CartCell
        cell.delegate = self as SwipeTableViewCellDelegate
        
        if let cart = cartDataManager.shoppingCarts?[indexPath.row]{
            cell.cartName.text = cart.name
        }
        return cell
    }
    
    //MARK: - TableView Delegate Methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToCart", sender: self)
    }
}
