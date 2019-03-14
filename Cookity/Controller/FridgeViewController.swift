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

class FridgeViewController: UIViewController {

    private let config = Configuration()
    private let dataManager = RealmDataManager()
    var products: Results<Product>?
    var selectedIndexPath: IndexPath? //variable is used to store the IndexPath selected by LongTap Gesture
    var chosenIndexPaths = [Int : IndexPath]() // dictionary is used to store the indexPaths of chosen cells, Key value is the number of cell is used to find the cell in the dictionary
    @IBOutlet weak var fridgeTableView: UITableView!
    @IBOutlet weak var addButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addButton.isEnabled = false
        addButton.isHidden = true
        
        fridgeTableView.delegate = self
        fridgeTableView.dataSource = self
        
        dataManager.loadFromRealm(vc: self, parentObject: nil)
        
        //add long gesture recognizer
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressed))
        self.view.addGestureRecognizer(longPressRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fridgeTableView.reloadData()
    }
    
    // Methods for buttons
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
        chosenIndexPaths.removeAll()
        addButton.isEnabled = false
        addButton.isHidden = true
    }

    
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
            
            for (_, indexPath) in chosenIndexPaths {
                
                if let product = products?[indexPath.row] {
                    
                    //creates the separate product in the Realm which can be used and edited in the recipe, not touching the existing product in the fridge
                    let copiedProduct = Product()
                    copiedProduct.name = product.name
                    copiedProduct.quantity = product.quantity
                    copiedProduct.measure = product.measure
                    
                    destinationVC.products.append(copiedProduct)
                }
                fridgeTableView.cellForRow(at: indexPath)?.textLabel?.textColor = UIColor.black
            }
        }

        
    }
}




//MARK: - Extension for TableView Methods
extension FridgeViewController: UITableViewDelegate, UITableViewDataSource, SwipeTableViewCellDelegate {
    
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            if let product = self.products?[indexPath.row] {
                self.dataManager.deleteFromRealm(object: product)
                self.fridgeTableView.reloadData()
            }
        }
        return [deleteAction]
    }
    
    
    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FridgeCell", for: indexPath) as! SwipeTableViewCell
        cell.delegate = self as SwipeTableViewCellDelegate
        cell.selectionStyle = .none
        
        if let products = products?[indexPath.row]{
            let (presentedQuantity, presentedMeasure) = config.presentNumbers(quantity: products.quantity, measure: products.measure)
            cell.textLabel?.text = "\(presentedQuantity) \(presentedMeasure) of \(products.name)"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let product = products?[indexPath.row]{
            
            dataManager.changeElementIn(object: product,
                                        keyValue: "checkForRecipe",
                                        objectParameter: product.checkForRecipe,
                                        newParameter: !product.checkForRecipe)
            
            if  product.checkForRecipe == true{
                fridgeTableView.cellForRow(at: indexPath)?.textLabel?.textColor = UIColor.green
                //adds the chosen cell indexPath to the dictionary to reach the selected products while pressing Cook Button
                chosenIndexPaths[indexPath.row] = indexPath
            } else {
                //deletes the chosen cell indexPath from the dictionary if the user unchecks the product
                fridgeTableView.cellForRow(at: indexPath)?.textLabel?.textColor = UIColor.black
                chosenIndexPaths.removeValue(forKey: indexPath.row)
            }
        }
        fridgeTableView.deselectRow(at: indexPath, animated: true)
       
        if chosenIndexPaths.count > 0 {
            addButton.isEnabled = true
            addButton.isHidden = false
        }
        else {
            addButton.isEnabled = false
            addButton.isHidden = true
        }
    }
}
