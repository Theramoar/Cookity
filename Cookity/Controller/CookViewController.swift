//
//  CookViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 30/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift

class CookViewController: UIViewController {


    @IBOutlet weak var productsTable: UITableView!
    @IBOutlet weak var recipeName: UITextField!
    
    let realm = try! Realm()
    var products: Results<Product>?
    var chosenIndexPaths = [Int : IndexPath]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        productsTable.delegate = self
        productsTable.dataSource = self
    }
    
    
    @IBAction func cookButtonPressed(_ sender: UIButton) {
        
        
        //1st circle is used to iterate over the array and check if all entered quantities are correct
        for (_, indexPath) in chosenIndexPaths{
            let cell = productsTable.cellForRow(at: indexPath) as! CookTableViewCell
            //throws the alert if entered quantity is empty and breaks the cooking
            guard let quantity = Int(cell.quantityForRecipe.text!)  else {
                let alert = UIAlertController(title: "Amount is not entered!", message: "Enter the amount used for for the recipe", preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default) { (_) in
                    return
                }
                alert.addAction(action)
                present(alert, animated: true, completion: nil)
                return
            }
            
            if let product = products?[indexPath.row]{
                //throws the alert if entered quantity suprass the amount in the fridge and breaks the cooking
                guard product.quantity >= quantity else{
                    let alert = UIAlertController(title: "Not enough products", message: "You don't have enough \(product.name) in your fridge", preferredStyle: .alert)
                    let action = UIAlertAction(title: "OK", style: .default) { (_) in
                        return
                    }
                    alert.addAction(action)
                    present(alert, animated: true, completion: nil)
                    return
                }
            }
        }
        
        //2nd circle is used for the Data manipulation
        for (_, indexPath) in chosenIndexPaths{
            let cell = productsTable.cellForRow(at: indexPath) as! CookTableViewCell
            guard let quantity = Int(cell.quantityForRecipe.text!) else {return}
            if let product = products?[indexPath.row]{

            // if the entered amount equals to the amount in the fridge - deletes the product from database, otherwise substract the quantity
                if product.quantity == quantity {
                    do{
                        try realm.write {
                            self.realm.delete(product)
                        }
                    }catch{
                        print("Error while cooking items \(error)")
                    }
                } else{
                    do{
                        try realm.write {
                            product.quantity -= quantity
                            product.checkForRecipe = false
                        }
                    }catch{
                        print("Error while cooking items \(error)")
                        }
                }
            }
        }
        chosenIndexPaths.removeAll()
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        
        // Unchecks all checked products and dismisses VC
        if let loadedProducts = products{
            for product in loadedProducts{
                do{
                    try realm.write {
                        product.checkForRecipe = false
                    }
                }catch{
                    print("Error while cooking items \(error)")
                }
            }
        }
        self.dismiss(animated: true, completion: nil)
    }
}





extension CookViewController: UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView.rowHeight = 60
        return products?.count ?? 1
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        let cell = tableView.dequeueReusableCell(withIdentifier: "CookCell", for: indexPath) as! CookTableViewCell
        cell.quantityForRecipe.delegate = self
        
        // Set up a cell selection color to white
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.white
        cell.selectedBackgroundView = backgroundView
        
        if let product = products?[indexPath.row]{
            cell.textLabel?.text = "\(product.name) - (you have \(product.quantity) \(product.measure))"

        }
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let product = products?[indexPath.row]{
            do{
                try realm.write {
                    product.checkForRecipe = !product.checkForRecipe
                }
            }catch{
                print("Error while updating items \(error)")
            }
            
            if  product.checkForRecipe == true{
                productsTable.cellForRow(at: indexPath)?.textLabel?.textColor = UIColor.orange
                //adds the chosen cell indexPath to the dictionary to reach the selected products while pressing Cook Button
                chosenIndexPaths[indexPath.row] = indexPath
            } else {
                //deletes the chosen cell indexPath from the dictionary if the user unchecks the product
                productsTable.cellForRow(at: indexPath)?.textLabel?.textColor = UIColor.black
                chosenIndexPaths.removeValue(forKey: indexPath.row)
            }
        }
        productsTable.deselectRow(at: indexPath, animated: true)
    }
    
}
