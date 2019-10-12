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
    
    var selectedIndexPath: IndexPath? //variable is used to store the IndexPath selected by LongTap Gesture
    
    @IBOutlet var fridgeDataManager: FridgeDataManager!
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
        
        //add long gesture recognizer
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressed))
        self.view.addGestureRecognizer(longPressRecognizer)
        
        guard SettingsVariables.isCloudEnabled else { return }
        CloudManager.syncData(ofType: .Fridge, parentObjects: [Fridge.shared])
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        updateVC()
    }
    
    func updateVC() {
        fridgeTableView.reloadData()
        uncheck()
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
            if let indexPath = selectedIndexPath {
                let product = fridgeDataManager.productsInFridge[indexPath.row]
                destinationVC.popupDataManager.products.append(product)
                destinationVC.parentVC = self
            }
        }
        else if segue.identifier == "goToCookingAreaFromFridge" {
            let destinationVC = segue.destination as! CookViewController
            destinationVC.updateVCDelegate = self
            destinationVC.cookDataManager.products = fridgeDataManager.moveProductsToCookArea()
            uncheck()
        }
    }
    
    override func deleteObject(at indexPath: IndexPath) {
        fridgeDataManager.deleteProductFromFridge(at: indexPath.row)
        fridgeTableView.reloadData()
    }
    
    func uncheck() {
        fridgeDataManager.uncheckProducts()
        configButton()
    }
    
    func configButton() {
        if fridgeDataManager.checkedProducts > 0 {
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
        if fridgeDataManager.productsInFridge.count == 0 {
            emptyFridgeImageView.isHidden = false
            emptyFridgeLabel.isHidden = false
            emptyFridgeDescriptionLabel.isHidden = false
        } else {
            emptyFridgeImageView.isHidden = true
            emptyFridgeLabel.isHidden = true
            emptyFridgeDescriptionLabel.isHidden = true
        }
        return fridgeDataManager.productsInFridge.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FridgeCell", for: indexPath) as! ProductTableViewCell
        cell.delegate = self as SwipeTableViewCellDelegate
        
        let product = fridgeDataManager.productsInFridge[indexPath.row]
            cell.isChecked = product.checkForRecipe // вместо этого можно использовать checked
            cell.product = product
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        fridgeDataManager.checkProduct(at: indexPath.row)
        configButton()
        tableView.reloadData()
    }
}
