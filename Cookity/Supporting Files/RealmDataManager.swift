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
    
    private static let realm = try! Realm()
    
    static func dataLoadedFromRealm<T>(ofType type: ParentData) -> Results<T>? {
        switch type {
            case .Cart:
                let shoppingCarts = realm.objects(ShoppingCart.self) as? Results<T>
                return shoppingCarts
            case .Recipe:
                let loadedRecipes = realm.objects(Recipe.self) as? Results<T>
                return loadedRecipes
            case .Fridge:
                let loadedFridge = realm.objects(Fridge.self)
                guard let fridge = loadedFridge.first else {
                    saveToRealm(parentObject: nil, object: Fridge.shared)
                    return loadedFridge as? Results<T>
                }
                Fridge.shared = fridge
                return loadedFridge as? Results<T>
        }
    }
    

    
    static func deleteFromRealm(object: Object){
        do{
            try self.realm.write {
                self.realm.delete(object)
            }
        }catch
        {
            print("Error while deleting items \(error)")
        }
    }
    
    
    static func saveToRealm<T>(parentObject: Object?, object: T) {
        
        if let parentObject = parentObject as? Fridge {
            do{
                try realm.write {
                    if let cloudID = object as? String {
                        parentObject.cloudID = cloudID
                    }
                    else if let product = object as? Product {
                        parentObject.products.append(product)
                    }
                    
                }
            }catch{
                print("Error saving context in Product \(error)")
            }
        }
        else if let parentObject = parentObject as? ShoppingCart{
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
                    if let cart = object as? ShoppingCart {
                        realm.add(cart)
                    }
                    else if let recipe = object as? Recipe {
                        realm.add(recipe)
                    }
                    else if let product = object as? Product {
                        realm.add(product)
                    }
                    else if let fridge = object as? Fridge {
                        realm.add(fridge)
                    }
                }
            }catch{
                print("Error while saving cart \(error)")
            }
        }
    }

    
    static func changeElementIn<T>(object: Object, keyValue: String, objectParameter: T, newParameter: T) {
            do{
                try self.realm.write {
                    object.setValue(newParameter, forKey: keyValue)
                }
            }catch
            {
                print("Error while changing items \(error)")
            }
    }
    
    //MARK:- Filepath data saving
    
    static func savePicture(image: UIImage?, imageName: String) -> String? {
        guard let image = image else { return nil }
        let imagePath: String = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(imageName).png"
        let imageUrl: URL = URL(fileURLWithPath: imagePath)
        try? image.pngData()?.write(to: imageUrl)
        return imagePath
    }
    
    static func deletePicture(imagePath: String) {
        let imageUrl: URL = URL(fileURLWithPath: imagePath)
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: imageUrl)
    }
    
}
