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
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addCartButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var cartTableView: UITableView!
    
    
    @IBOutlet weak var emptycartImageView: UIImageView!
    @IBOutlet weak var emptyCartMainLabel: UILabel!
    @IBOutlet weak var emptyCartSecondLabel: UILabel!
    
    let viewModel = CartCollectionViewModel()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: "CartCell", bundle: nil), forCellReuseIdentifier: "CartCell")
        
        addCartButton.layer.shadowOffset = CGSize(width: 0, height: 3.0)
        addCartButton.layer.shadowOpacity = 0.7
        addCartButton.layer.shadowRadius = 5.0
        
        viewModel.loadCartsFromCloud {
            self.cartTableView.reloadData()
        }
    }
    
    func updateVC() {
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
        tabBarController?.tabBar.isHidden = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToCart" {
            let destinationVC = segue.destination as! CartViewController
            destinationVC.viewModel = viewModel.viewModelForSelectedRow() as? CartViewModel
        }
        else if segue.identifier == "addShoppingCart" {
            let destinationVC = segue.destination as! AddCartViewController
            destinationVC.viewModel = viewModel.viewModelForNewCart()
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
        viewModel.deleteCart(at: indexPath.row)
        tableView.reloadData()
    }
    
    
    //MARK: - Adds SwipeTableViewCell Delegate Method AppendToFridge action
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        
        let appendAction = SwipeAction(style: .default, title: nil) { (action, indexPath) in
            self.viewModel.moveProductsToFridge(fromCartAtIndexPath: indexPath)
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
        
        emptycartImageView.isHidden = !viewModel.cartCollectionIsEmpty
        emptyCartMainLabel.isHidden = !viewModel.cartCollectionIsEmpty
        emptyCartSecondLabel.isHidden = !viewModel.cartCollectionIsEmpty
        
        tableView.rowHeight = 70
        tableView.separatorInset = .init(top: 0, left: 30, bottom: 0, right: 30)
        return viewModel.numberOfRows
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CartCell", for: indexPath) as! CartCell
        cell.delegate = self as SwipeTableViewCellDelegate
        cell.viewModel = viewModel.cellViewModel(forIndexPath: indexPath) as? CartCellViewModel
        return cell
    }
    
    //MARK: - TableView Delegate Methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectRow(atIndexPath: indexPath)
        performSegue(withIdentifier: "goToCart", sender: self)
    }
}
