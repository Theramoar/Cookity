//
//  ListViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 03/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift

class ListViewController: UITableViewController, TextFieldDelegate {
    

    let realm = try! Realm()
    var products: Results<Product>?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadProducts()
    }
    
    
    //MARK: - TableView DataSource Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let numberOfCell = products?.count{
            
            guard numberOfCell == 0 else {
                print("number of rows working - \(numberOfCell)")
                return numberOfCell + 1 }
            return 1
        }
        else {
            return 1
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let textCell = tableView.dequeueReusableCell(withIdentifier: "TextCell") as! TextFieldCell
            textCell.delegate = self
            return textCell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath) as UITableViewCell
        
            if let item = products?[indexPath.row - 1]{
                cell.textLabel?.text = item.name
                cell.accessoryType = item.checked ? .checkmark : .none
                }
            return cell
            }
    }

    
    //MARK: - TableView Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            print("it works")
        }
    
    func loadProducts(){
        products = realm.objects(Product.self)
    }
    
    
    //MARK: - TextFieldDelegate Method
    func saveProduct(newProduct: Product){
        do{
            try realm.write {
                realm.add(newProduct)
            }
        }catch{
            print("Error saving context in Product \(error)")
        }
        tableView.reloadData()
    }
  

    
    
    @IBAction func refreshButtonPressed(_ sender: UIBarButtonItem) {
        self.tableView.reloadData()
    }
    
}


