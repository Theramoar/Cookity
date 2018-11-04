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
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    

    // MARK: - Table view data source
  
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FridgeCell", for: indexPath)
        
        if let products = products?[indexPath.row]{
            var measure = products.measure
            switch measure {
            case "Mililiters":
                measure = "ml"
            case "Kilograms":
                measure = "kg"
            case "Litres":
                measure = "l"
            case "Grams":
                measure = "g"
            default:
                if products.quantity == 1 {
                    measure = "piece"
                }
                else{
                    measure = "pieces"
                }
            }
            cell.textLabel?.text = "\(products.quantity) \(measure) of \(products.name)"
        }
        return cell
    }

    func loadproducts(){
       products = realm.objects(Product.self).filter("inFridge == YES")
    }
   
    
    @IBAction func cookPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "goToCookingArea", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! CookViewController
        destinationVC.products = products
    }

    
}
