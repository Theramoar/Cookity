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

class FridgeViewController: SwipeTableViewController, UpdateVCDelegate {
    
    

    
    var products: List<Product>? {
        didSet {
            guard SettingsVariables.isCloudEnabled else { return }
            CloudManager.syncData(ofType: .Fridge, parentObjects: [Fridge.shared])
        }
    }
    var selectedIndexPath: IndexPath? //variable is used to store the IndexPath selected by LongTap Gesture
    var checkedProducts = 0

    @IBOutlet weak var fridgeTableView: UITableView!
    @IBOutlet weak var addButton: UIButton!
    
    
    @IBOutlet weak var emptyFridgeImageView: UIImageView!
    @IBOutlet weak var emptyFridgeLabel: UILabel!
    @IBOutlet weak var emptyFridgeDescriptionLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fridgeTableView.delegate = self
        fridgeTableView.dataSource = self
        fridgeTableView.separatorStyle = .none
        fridgeTableView.rowHeight = 45
        
        addButton.layer.shadowOffset = CGSize(width: 0, height: 3.0)
        addButton.layer.shadowOpacity = 0.7
        addButton.layer.shadowRadius = 5.0
        
        products = Fridge.shared.products

        //add long gesture recognizer
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressed))
        self.view.addGestureRecognizer(longPressRecognizer)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        updateVC()
    }
    
    func updateVC() {
        fridgeTableView.reloadData()
        uncheck(products)
    }
    
    //MARK:- Methods for Buttons
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
    }

    //MARK:- Data Manipulation Methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "popupEditFridge"{
            let destinationVC = segue.destination as! PopupEditViewController
            if let indexPath = selectedIndexPath, let product = products?[indexPath.row] {
                destinationVC.selectedProduct = product
                destinationVC.parentVC = self
            }
        }
        else if segue.identifier == "goToCookingAreaFromFridge" {
            let destinationVC = segue.destination as! CookViewController
            destinationVC.updateVCDelegate = self
            guard let products = products else { return }
            for product in products {
                if product.checkForRecipe {
                    //creates the separate product in the Realm which can be used and edited in the recipe, not touching the existing product in the fridge
                    let copiedProduct = Product()
                    copiedProduct.name = product.name
                    copiedProduct.quantity = product.quantity
                    copiedProduct.measure = product.measure
                    destinationVC.products.append(copiedProduct)
                }
            }
            uncheck(products)
        }
    }
    
    override func deleteObject(at indexPath: IndexPath) {
        if let product = self.products?[indexPath.row] {
            if let productID = product.cloudID, let fridgeID = Fridge.shared.cloudID {
                CloudManager.deleteProductFromCloud(parentRecordID: fridgeID, productRecordID: productID)
            }
            RealmDataManager.deleteFromRealm(object: product)
            fridgeTableView.reloadData()
        }
    }
    
    func uncheck(_ products: List<Product>?) {
        guard let products = products else { return }
        for product in products {
            RealmDataManager.changeElementIn(object: product,
                                        keyValue: "checkForRecipe",
                                        objectParameter: product.checkForRecipe,
                                        newParameter: false)
        }
        checkedProducts = 0
//        fridgeTableView.reloadData()
        configButton()
    }
    
    func configButton() {
        if checkedProducts > 0 {
            addButton.isEnabled = true
            addButton.isHidden = false
        }
        else {
            addButton.isEnabled = false
            addButton.isHidden = true
        }
    }
}




//MARK: - Extension for TableView Methods
extension FridgeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if products?.count == 0 {
            emptyFridgeImageView.isHidden = false
            emptyFridgeLabel.isHidden = false
            emptyFridgeDescriptionLabel.isHidden = false
        } else {
            emptyFridgeImageView.isHidden = true
            emptyFridgeLabel.isHidden = true
            emptyFridgeDescriptionLabel.isHidden = true
        }
        
        return products?.count ?? 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FridgeCell", for: indexPath) as! ProductTableViewCell
        cell.delegate = self as SwipeTableViewCellDelegate
        
        if let product = products?[indexPath.row]{
            cell.isChecked = product.checkForRecipe // вместо этого можно использовать checked
            cell.product = product
        }
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let product = products?[indexPath.row]{
            RealmDataManager.changeElementIn(object: product,
                                        keyValue: "checkForRecipe",
                                        objectParameter: product.checkForRecipe,
                                        newParameter: !product.checkForRecipe)
            checkedProducts = product.checkForRecipe ? checkedProducts + 1  : checkedProducts - 1
        }
        configButton()
        tableView.reloadData()
    }
}
