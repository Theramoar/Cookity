//
//  FridgeViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 24/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift

class FridgeViewController: UITableViewController {

    let realm = try! Realm()
    var products: Results<Product>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadproducts()
        
    }

    // MARK: - Table view data source
  
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FridgeCell", for: indexPath)
        
        if let products = products?[indexPath.row]{
            cell.textLabel?.text = products.name
        }
        return cell
    }

    func loadproducts(){
       products = realm.objects(Product.self).filter("inFridge == YES")
    }
   
    
    
    @IBAction func refreshPressed(_ sender: UIBarButtonItem) {
        
        tableView.reloadData()
    }
    
}
