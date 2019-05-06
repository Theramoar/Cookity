//
//  DataManager.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 04/03/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import Foundation
import RealmSwift

enum DataLoaded {
    case Fridge
    case Recipes
}

class RealmDataManager {
    
    private let realm = try! Realm()
    
    
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
            for product in recipe.products {
                let product = Product(value: product)
                vc.products.append(product)
            }
            for recipeStep in recipe.recipeSteps {
                let recipeStep = RecipeStep(value: recipeStep)
                if vc.recipeSteps?.append(recipeStep) == nil {
                    vc.recipeSteps = [recipeStep]
                }
            }
            if let imagePath = recipe.imagePath {
                let imageUrl: URL = URL(fileURLWithPath: imagePath)
                if FileManager.default.fileExists(atPath: imagePath),
                    let imageData: Data = try? Data(contentsOf: imageUrl),
                    let image: UIImage = UIImage(data: imageData) {
                    vc.pickedImage = image
                }
            }
        }
        else if let vc = vc as? PopupEditViewController, let product = parentObject as? Product {
            
            var (presentedQuantity, presentedMeasure) = Configuration.presentNumbers(quantity: product.quantity, measure: product.measure)
            presentedMeasure = Configuration.configMeasure(measure: presentedMeasure)
            
            vc.nameText.text = product.name
            vc.quantityText.text = presentedQuantity
            vc.measureText.text = presentedMeasure
        }
    }
    //Попробовать данную функцию для загрузки данных
//    func load<T>(data: DataLoaded) -> Results<T> {
//
//        switch data {
//        case .Fridge:
//            let objects = realm.objects(Product.self).filter("inFridge == YES")
//            return objects as! Results<T>
//        case .Recipes:
//            let objects = realm.objects(Recipe.self)
//            return objects as! Results<T>
//        }
//    }
    
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
    
    
    func saveToRealm<T>(parentObject: Object?, object: T) {
        
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
                    else if let path = object as? String {
                        print("PATH - \(path)")
                        parentObject.imagePath = path
                    }
                }
            }catch{
                print("Error saving context in Product \(error)")
            }
        }

        else {
            do{
                try realm.write {
                    if type(of: object) == ShoppingCart.self {
                        realm.add(object as! ShoppingCart)
                    }
                    else if type(of: object) == Recipe.self {
                        realm.add(object as! Recipe)
                    }
                }
            }catch{
                print("Error while saving cart \(error)")
            }
        }
    }

    
    func changeElementIn<T>(object: Object, keyValue: String, objectParameter: T, newParameter: T) {
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
