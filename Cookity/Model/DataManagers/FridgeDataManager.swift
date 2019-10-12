//
//  FridgeDataManager.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 06/10/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import Foundation
import RealmSwift


class FridgeDataManager: DataManager {
        
    var checkedProducts = 0
    
    func deleteProductFromFridge(at position: Int) {
        if let productID = deleteProduct(from: productsInFridge, at: position),
            let fridgeID = Fridge.shared.cloudID {
            CloudManager.deleteProductFromCloud(parentRecordID: fridgeID, productRecordID: productID)
        }
    }
    
    func moveProductsToCookArea() -> List<Product> {
        let copiedProducts = List<Product>()
        for product in productsInFridge {
            if product.checkForRecipe {
                //creates the separate product in the Realm which can be used and edited in the recipe, not touching the existing product in the fridge
                let copiedProduct = Product()
                copiedProduct.name = product.name
                copiedProduct.quantity = product.quantity
                copiedProduct.measure = product.measure
                copiedProducts.append(copiedProduct)
            }
        }
        return copiedProducts
    }
    
    func uncheckProducts() {
        for product in productsInFridge {
            RealmDataManager.changeElementIn(object: product,
                                        keyValue: "checkForRecipe",
                                        objectParameter: product.checkForRecipe,
                                        newParameter: false)
        }
        checkedProducts = 0
    }
    
    func checkProduct(at position: Int) {
        let product = productsInFridge[position]
            RealmDataManager.changeElementIn(object: product,
                                             keyValue: "checkForRecipe",
                                             objectParameter: product.checkForRecipe,
                                             newParameter: !product.checkForRecipe)
            checkedProducts = product.checkForRecipe ? checkedProducts + 1  : checkedProducts - 1
        
    }
}
