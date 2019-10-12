//
//  CartDataManager.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 03/10/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift


class CartDataManager: DataManager {
    
    var shoppingCarts: Results<ShoppingCart>? {
        didSet {
            guard SettingsVariables.isCloudEnabled else { return }
            var carts = [ShoppingCart]()
            for cart in shoppingCarts! {
                carts.append(cart)
            }
            CloudManager.syncData(ofType: .Cart, parentObjects: carts)
        }
    }
    var selectedCart: ShoppingCart? {
        didSet {
            products = selectedCart!.products
        }
    }
    
    var updateVCDelegate: UpdateVCDelegate?

    
    func saveProductToCart(product: Product) {
        guard let cart = selectedCart else { return }
        RealmDataManager.saveToRealm(parentObject: cart, object: product)
        if let cloudID = cart.cloudID {
            CloudManager.saveProductsToCloud(to: .Cart, products: [product], parentRecordID: cloudID)
        }
    }
    
    func deleteProductFromCart(at position: Int) {
        if let productID = deleteProduct(from: products, at: position),
            let cartID = selectedCart?.cloudID {
            CloudManager.deleteProductFromCloud(parentRecordID: cartID, productRecordID: productID)
        }
    }
    
    
    //DataManager - там есть эта функция
    func deleteCart(at position: Int) {
        guard let cart = shoppingCarts?[position] else { return }
        for product in cart.products {
            RealmDataManager.deleteFromRealm(object: product)
        }
        if let recordID = cart.cloudID {
            CloudManager.deleteRecordFromCloud(ofType: .Cart, recordID: recordID)
        }
        RealmDataManager.deleteFromRealm(object: cart)
    }

    
    func checkProduct(at position: Int) -> Bool {
        guard let products = selectedCart?.products else { return false }
        
        let product = products[position]
        RealmDataManager.changeElementIn(object: product,
                                    keyValue: "checked",
                                    objectParameter: product.checked,
                                    newParameter: !product.checked)
        //If all products are checked, App offers to add them to the Fridge
        for product in products {
            guard product.checked == true else { return false }
        }
        return true
    }
    
    func shareCart() -> UIActivityViewController? {
        let shareManager = ShareDataManager()
        guard
            let cart = selectedCart,
            let url = shareManager.exportToURL(object: cart)
            else { return nil }
            
        let activity = UIActivityViewController(
            activityItems: ["I prepared the Shopping List for you! You can read it using Cookity app.", url],
            applicationActivities: nil
        )
        return activity
    }
    
    
    func moveProductsToFridge(from cart: ShoppingCart) {
        let products = cart.products
        var copiedProducts = [Product]()
        for product in products {
            //Checks if the similar product is already in the fridge
            for fridgeProduct in productsInFridge{
                // if products name and measure coincide, adds quantity and deletes product from the shopping list
                if product.name.lowercased() == fridgeProduct.name.lowercased() && product.measure == fridgeProduct.measure {
                    let newQuantity = fridgeProduct.quantity + product.quantity
                    RealmDataManager.changeElementIn(object: fridgeProduct,
                                                     keyValue: "quantity",
                                                     objectParameter: fridgeProduct.quantity,
                                                     newParameter: newQuantity)
                    RealmDataManager.deleteFromRealm(object: product)
                    CloudManager.updateProductInCloud(product: fridgeProduct)
                    break
                }
            }
            if product.isInvalidated == false{
                let coppiedProduct = Product(value: product)
                coppiedProduct.cloudID = nil
                coppiedProduct.checked = false
                RealmDataManager.saveToRealm(parentObject: Fridge.shared, object: coppiedProduct)
                RealmDataManager.deleteFromRealm(object: product)
                copiedProducts.append(coppiedProduct)
            }
        }
        if let fridgeRecordID = Fridge.shared.cloudID {
            CloudManager.saveProductsToCloud(to: .Fridge, products: copiedProducts, parentRecordID: fridgeRecordID)
        }
        //Delete Cart from Cloud
        if let recordID = cart.cloudID {
            CloudManager.deleteRecordFromCloud(ofType: .Cart, recordID: recordID)
        }
        RealmDataManager.deleteFromRealm(object: cart)
    }
    
    
    func loadCartsFromCloud() {
        guard let carts = shoppingCarts else { return }
        let objects = Array(carts)
        CloudManager.loadDataFromCloud(ofType: .Cart, recipes: objects) { (parentObject) in
            RealmDataManager.saveToRealm(parentObject: nil, object: parentObject)
            self.updateVCDelegate?.updateVC()
        }
    }
}
