//
//  DataManager.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 04/03/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import Foundation
import RealmSwift


class RealmDataManager {
    
    private let realm = try! Realm()
    private let config = Configuration()
    
    
    func loadFromRealm(vc: UIViewController?, parentObject: Object?) {
        
        if let vc = vc as? CartViewController, let selectedCart = parentObject as? ShoppingCart {
            vc.products = selectedCart.products.filter("inFridge == NO")
            vc.productsInFridge = realm.objects(Product.self).filter("inFridge == YES")
            
        }
        else if let vc = vc as? CartCollectionViewController {
            vc.shoppingCarts = realm.objects(ShoppingCart.self)
            vc.productsInFridge = realm.objects(Product.self).filter("inFridge == YES")
        }
        else if let vc = vc as? FridgeViewController {
            vc.products = realm.objects(Product.self).filter("inFridge == YES")
        }
        else if let vc = vc as? RecipeCollectionViewController {
            vc.recipeList = realm.objects(Recipe.self)
        }
        else if let vc = vc as? RecipeViewController, let selectedRecipe = parentObject as? Recipe {
            vc.productsForRecipe = selectedRecipe.products.sorted(byKeyPath: "name")
            vc.recipeSteps = selectedRecipe.recipeSteps.sorted(byKeyPath: "name")
            vc.productsInFridge = realm.objects(Product.self).filter("inFridge == YES")
        }
        else if let vc = vc as? CookViewController, let recipe = parentObject as? Recipe {
            vc.products = Array(recipe.products)
            vc.recipeSteps = Array(recipe.recipeSteps)
        }
        else if let vc = vc as? PopupEditViewController, let product = parentObject as? Product {
            
            var (presentedQuantity, presentedMeasure) = config.presentNumbers(quantity: product.quantity, measure: product.measure)
            presentedMeasure = config.configMeasure(measure: presentedMeasure)
            
            vc.nameText.text = product.name
            vc.quantityText.text = presentedQuantity
            vc.measureText.text = presentedMeasure
        }
    }
    
    func deleteFromRealm(object: Object){
        do{
            try self.realm.write {
                self.realm.delete(object)
            }
        }catch
        {
            print("Error while deleting items \(error)")
        }
    }
    
    
    func saveToRealm(parentObject: Object?, object: Object) {
        
        if let parentObject = parentObject as? ShoppingCart{
            do{
                try realm.write {
                    parentObject.products.append(object as! Product)
                }
            }catch{
                print("Error saving context in Product \(error)")
            }
        }
            
        else if let parentObject = parentObject as? Recipe {
            do{
                try realm.write {
                    if type(of: object) == Product.self {
                        parentObject.products.append(object as! Product)
                    }
                    else if type(of: object) == RecipeStep.self {
                        parentObject.recipeSteps.append(object as! RecipeStep)
                    }
                }
            }catch{
                print("Error saving context in Product \(error)")
            }
        }

        else {
            do{
                try realm.write {
                    realm.add(object)
                }
            }catch{
                print("Error while saving cart \(error)")
            }
        }
    }

    
    func changeElementIn<T>(object: Object, keyValue: String, objectParameter: T, newParameter: T) {
        if type(of: objectParameter) == type(of: newParameter) {
            do{
                try self.realm.write {
                    object.setValue(newParameter, forKey: keyValue)
                }
            }catch
            {
                print("Error while changing items \(error)")
            }
        }
    }
    
}
