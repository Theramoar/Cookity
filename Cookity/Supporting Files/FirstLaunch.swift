//
//  FirstLaunch.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 09/06/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import Foundation


final class FirstLaunch {
    
    let userDefaults: UserDefaults = .standard
    
    let wasLaunchedBefore: Bool
    var isFirstLaunch: Bool {
        return !wasLaunchedBefore
    }
    
    init() {
        let key = "com.michaelk.Cookity.WasLaunchedBefore"
        let wasLaunchedBefore = userDefaults.bool(forKey: key)
        self.wasLaunchedBefore = wasLaunchedBefore
        if !wasLaunchedBefore {
            userDefaults.set(true, forKey: key)
        }
    }
    
    func createTutorial() {
        let cart = ShoppingCart()
        cart.name = "Tutorial"
        
        let names = ["Touch it to cross out",
                       "Long touch it to edit",
                       "Swipe it to delete",
                       "Cross out every item...",
                       "...to move the items to the fridge"]
    
        for name in names {
            let product = Product()
            product.name = name
            product.quantity = 1
            product.measure = "pcs"
            cart.products.append(product)
        }
        
        RealmDataManager.saveToRealm(parentObject: nil, object: cart)
    }
    
}
