//
//  ShareDataManager.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 09/04/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import Foundation
import RealmSwift


class ShareDataManager {
    
    
    static func importData(from url: URL) -> Object? {

        guard let data = try? Data(contentsOf: url) else {
            try? FileManager.default.removeItem(at: url)
            return nil
        }
        
        if let recipe = try? JSONDecoder().decode(Recipe.self, from: data) {
            RealmDataManager.saveToRealm(parentObject: nil, object: recipe)
            try? FileManager.default.removeItem(at: url)
            return recipe
        }
        else if let cart = try? JSONDecoder().decode(ShoppingCart.self, from: data) {
            RealmDataManager.saveToRealm(parentObject: nil, object: cart)
            try? FileManager.default.removeItem(at: url)
            return cart
        }
        else {
            try? FileManager.default.removeItem(at: url)
            return nil
        }
    }
    
    
    func exportToURL(object: Object) -> URL? {
        
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
            ).first
        if let cart = object as? ShoppingCart {
            guard let path = documents?.appendingPathComponent("/\(cart.name).ckty") else { return nil }
            return encodeObject(object: cart, path: path)
        }
        else if let recipe = object as? Recipe {
            guard let path = documents?.appendingPathComponent("/\(recipe.name).ckty") else { return nil }
            return encodeObject(object: recipe, path: path)
        }
        else {
            return nil
        }
    }
    
    func prepareExportMessage(for cart: ShoppingCart) -> String {
        var exportMessage = "I prepared the Shopping List for you:\n"
        var position = 1
        cart.products.forEach { (product) in
           let (productQuantity, productMeasure) = Configuration.presentNumbers(quantity: product.quantity, measure: product.measure)
            exportMessage += "\(position). \(product.name) - \(productQuantity) \(productMeasure)\n"
            position += 1
        }
//        exportMessage += "\nYou can read it using Cookity app."
        return exportMessage
    }
    
        func prepareExportMessage(for recipe: Recipe) -> String {
            var exportMessage = "Checkout the Recipe I found for you:\n"
            var position = 1
            exportMessage += "\nIngridiets:\n"
            recipe.products.forEach { (product) in
               let (productQuantity, productMeasure) = Configuration.presentNumbers(quantity: product.quantity, measure: product.measure)
                exportMessage += "\(position). \(product.name) - \(productQuantity) \(productMeasure)\n"
                position += 1
            }
            guard !recipe.recipeSteps.isEmpty else { return exportMessage }
            position = 1
            exportMessage += "\nCooking Steps:\n"
            recipe.recipeSteps.forEach { (step) in
                exportMessage += "\(position). \(step.name)\n"
                position += 1
            }
            return exportMessage
        }
    
    
    private func encodeObject<T: Codable>(object: T, path: URL) -> URL? {
        guard let encodedObject = try? JSONEncoder().encode(object) else { return nil }
        
        do {
            try encodedObject.write(to: path, options: .atomicWrite)
            return path
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}
