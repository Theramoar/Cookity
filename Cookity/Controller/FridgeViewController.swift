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

class FridgeViewController: UITableViewController, PopUpDelegate {


    let realm = try! Realm()
    let config = Configuration()
    var products: Results<Product>?
    var selectedIndexPath: IndexPath? //variable is used to store the IndexPath selected by LongTap Gesture
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadProducts()
        
        //add long gesture recognizer
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressed))
        self.view.addGestureRecognizer(longPressRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateView()
    }
   
    
    func loadProducts(){
        products = realm.objects(Product.self).filter("inFridge == YES")
    }
    
    
    //PopUpDelegate method used to reload data while dismissing popup View Controller
    func updateView() {
        tableView.reloadData()
    }
    
    func deleteProduct(at indexPath: IndexPath){
        if let product = self.products?[indexPath.row] {
            do{
                try self.realm.write {
                    self.realm.delete(product)
                }
            }catch
            {
                print("Error while deleting items \(error)")
            }
            updateView()
        }
    }
    
    
    // Methods for buttons
    @objc func longPressed(longPressRecognizer: UILongPressGestureRecognizer) {

        // find the IndexPath of the cell which was "longtouched"
        let touchPoint = longPressRecognizer.location(in: self.view)
        selectedIndexPath = tableView.indexPathForRow(at: touchPoint)
        guard selectedIndexPath != nil else { return }
        if self.presentedViewController == nil {
            performSegue(withIdentifier: "popupEditFridge", sender: self)
        }
    }
    
    
    @IBAction func cookPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "goToRecipes", sender: self)
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "popupEditFridge"{
            let destinationVC = segue.destination as! PopupEditViewController
            if let indexPath = selectedIndexPath, let product = products?[indexPath.row] {
                destinationVC.selectedProduct = product
                destinationVC.delegate = self
            }
        }

        
    }
}




//MARK: - Extension for TableView Methods
extension FridgeViewController: SwipeTableViewCellDelegate {
    
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            self.deleteProduct(at: indexPath)
        }
        return [deleteAction]
    }
    
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FridgeCell", for: indexPath) as! SwipeTableViewCell
        cell.delegate = self as SwipeTableViewCellDelegate
        cell.selectionStyle = .none
        
        if let products = products?[indexPath.row]{
            let (presentedQuantity, presentedMeasure) = config.presentNumbers(quantity: products.quantity, measure: products.measure)
            cell.textLabel?.text = "\(presentedQuantity) \(presentedMeasure) of \(products.name)"
        }
        return cell
    }
}
