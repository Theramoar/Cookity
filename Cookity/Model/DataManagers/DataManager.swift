//
//  DataManager.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 05/10/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import Foundation
import RealmSwift

class DataManager: NSObject {
    
    var products = List<Product>()
    var productsInFridge = Fridge.shared.products
    
    func createNewProduct(productName: String, productQuantity: String, productMeasure: String) -> Product {
        let newProduct = Product()
        
        let measure = Configuration.configMeasure(measure: productMeasure)
        let (savedQuantity, savedMeasure) = Configuration.configNumbers(quantity: productQuantity, measure: measure)
        
        newProduct.name = productName
        newProduct.quantity = savedQuantity
        newProduct.measure = savedMeasure
        
        return newProduct
    }

    
    func deleteProduct(from products: List<Product>, at position: Int) -> String? {
        let product = products[position]
        guard product.realm != nil else { products.remove(at: position) ; return nil }
        let productID = product.cloudID
        RealmDataManager.deleteFromRealm(object: product)
        return productID
    }
    
    
    func saveCart(name: String, products: List<Product>) {
        let cart = ShoppingCart()
        cart.name = name
        for product in products {
            cart.products.append(product)
        }
        RealmDataManager.saveToRealm(parentObject: nil, object: cart)
        CloudManager.saveDataToCloud(ofType: .Cart, object: cart) { (recordID) in
            DispatchQueue.main.async {
                RealmDataManager.changeElementIn(object: cart,
                                                 keyValue: "cloudID",
                                                 objectParameter: cart.cloudID,
                                                 newParameter: recordID)
            }
        }
    }
    
    
    func checkDataFromTextFields(productName: String, productQuantity: String, productMeasure: String) -> UIAlertController? {
        let alert = UIAlertController(title: "title", message: "message", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { (_) in return }
        alert.addAction(action)
        
        guard alert.check(data: productName, dataName: AlertMessage.name),
        alert.check(data: productQuantity, dataName: AlertMessage.quantity)
        else {
            return (alert)
        }
        return nil
    }
    
    
    func shareObject(_ object: ParentObject) -> UIActivityViewController? {
        let shareManager = ShareDataManager()
        guard
            let url = shareManager.exportToURL(object: object)
            else { return nil }
            
        let activity = UIActivityViewController(
            activityItems: [/*"I prepared the Shopping List for you! You can read it using Cookity app.", */url],
            applicationActivities: nil
        )
        return activity
    }
}
