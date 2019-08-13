//
//  CloudManager.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 05/08/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import Foundation
import CloudKit
import RealmSwift




enum DataLoaded: String {
    case Carts = "ShoppingCart"
    case Recipes = "Recipe"
    case Product = "Product"
    case RecipeStep = "RecipeStep"
}

class CloudManager {
    
    private static let privateCloudDatabase = CKContainer.default().privateCloudDatabase
    private static var records: [CKRecord] = []
    
    static func saveRecipeToCloud(recipe: Recipe, closure: @escaping (String) -> Void) {
        //Create parent record and save it to cloud
        let record = CKRecord(recordType: "Recipe")
        record.setValue(recipe.name, forKey: "name")
        privateCloudDatabase.save(record, completionHandler: { (record, error) in
            if let error = error { print(error); return }
            guard let record = record else { return }
            closure(record.recordID.recordName)
        })
        //Save products and create reference to the parent
        let products = Array(recipe.products)
        saveProductsToCloud(products: products, parentRecord: record)
        //Save recipe steps create reference to the parent
        let recipeSteps = Array(recipe.recipeSteps)
        saveRecipeStepsToCloud(steps: recipeSteps, parentRecord: record)
        //Save Image
        if let imagePath = recipe.imagePath, FileManager.default.fileExists(atPath: imagePath) {
            let imageAsset = prepareImageToSaveToCloud(imagePath: imagePath)
            record.setValue(imageAsset, forKey: "imageAsset")
        }
    }
    
    static func updateRecipeInCloud(recipe: Recipe) {
        guard let cloudID = recipe.cloudID else { return }
        saveRecipeToCloud(recipe: recipe) { (recordID) in
            DispatchQueue.main.async {
                RealmDataManager.changeElementIn(object: recipe,
                                                 keyValue: "cloudID",
                                                 objectParameter: recipe.cloudID,
                                                 newParameter: recordID)
            }
        }
        deleteRecordFromCloud(recordID: cloudID)
    }
    
    
    static func loadDataFromCloud(data: DataLoaded, recipes: Results<Recipe>, closure: @escaping (Recipe) -> Void) {
        

        let query = CKQuery(recordType: "Recipe", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = ["recordID", "name"]
//        queryOperation.resultsLimit = 5 - сделать потом
        queryOperation.queuePriority = .veryHigh
        
        queryOperation.recordFetchedBlock = { record in
            self.records.append(record)
            let loadedRecipe = Recipe(record: record,
                                      products: nil,
                                      steps: nil)
            
            loadChildrenFromCloud(ofType: .Product, record: record, closure: { (products) in
                let loadedProducts = List<Product>()
                for product in products {
                    loadedProducts.append(product as! Product)
                }
                loadedRecipe.products = loadedProducts
                DispatchQueue.main.async {
                    if newCloudRecordIsAvailable(recipes: recipes, recordID: record.recordID.recordName) { closure(loadedRecipe)}
                }
            })
            
            loadChildrenFromCloud(ofType: .RecipeStep, record: record, closure: { (recipeSteps) in
                for step in recipeSteps {
                    guard let step = step as? RecipeStep else { return }
                    DispatchQueue.main.async {
                        RealmDataManager.saveToRealm(parentObject: loadedRecipe, object: step)
                    }
                }
                
            })
            
//            loadChildrenFromCloud(record: record,
//                                  productClosure: { (products) in
//                                    loadedRecipe.products = products
//                                    DispatchQueue.main.async {
//                                        if newCloudRecordIsAvailable(recipes: recipes, recordID: record.recordID.recordName) { closure(loadedRecipe)
//                                        }
//                                    }
//            },
//                                  stepClosure: { (recipeSteps) in
//                                    DispatchQueue.main.async {
//                                        for step in recipeSteps {
//                                        RealmDataManager.saveToRealm(parentObject: loadedRecipe, object: step)
//                                        }
//                                    }
//
//            })
            
            
        }
        
        queryOperation.queryCompletionBlock = { (_, error) in
            if let error = error { print(error); return }
        }
        
        privateCloudDatabase.add(queryOperation)
    }
    
    
//    private static func loadChildrenFromCloud(record: CKRecord, productClosure: @escaping (List<Product>) -> Void, stepClosure: @escaping (List<RecipeStep>) -> Void) {
//        let products = List<Product>()
//        let recipeSteps = List<RecipeStep>()
//        let listID = record.recordID
//        let recordToMatch = CKRecord.Reference(recordID: listID, action: .deleteSelf)
//        let predicate = NSPredicate(format: "parent == %@", recordToMatch)
//
//        // Load Products
//        let query = CKQuery(recordType: "Product", predicate: predicate)
//        let queryOperation = CKQueryOperation(query: query)
//
//        queryOperation.recordFetchedBlock = { record in
//            DispatchQueue.main.async {
//                let product = Product(record: record)
//                products.append(product)
//            }
//        }
//        queryOperation.queryCompletionBlock = { (_, error) in
//            if let error = error { print(error); return }
//            productClosure(products)
//        }
//
//        //Load Recipe Steps
//        let secondQuery = CKQuery(recordType: "RecipeStep", predicate: predicate)
//        let secondQueryOperation = CKQueryOperation(query: secondQuery)
//        secondQueryOperation.recordFetchedBlock = { record in
//            DispatchQueue.main.async {
//                let recipeStep = RecipeStep(record: record)
//                recipeSteps.append(recipeStep)
//            }
//        }
//        secondQueryOperation.queryCompletionBlock = { (_, error) in
//            if let error = error { print(error); return }
//            stepClosure(recipeSteps)
//        }
//
//        privateCloudDatabase.add(queryOperation)
//        privateCloudDatabase.add(secondQueryOperation)
//    }
    

    private static func loadChildrenFromCloud<T: Object>(ofType objectType: DataLoaded, record: CKRecord, closure: @escaping ([T]) -> Void) {
        
        var objects = [T]()
        let recordID = record.recordID
        let recordToMatch = CKRecord.Reference(recordID: recordID, action: .deleteSelf)
        let predicate = NSPredicate(format: "parent == %@", recordToMatch)
        
        // Load Products
        let query = CKQuery(recordType: objectType.rawValue, predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        
        
        queryOperation.recordFetchedBlock = { record in
            switch objectType {
            case .Product:
                guard let object: T = Product(record: record) as? T else { return }
                objects.append(object)
            case .RecipeStep:
                guard let object = RecipeStep(record: record) as? T else { return }
                objects.append(object)
            case .Carts:
                return
            case .Recipes:
                return
            }
            
        }
        queryOperation.queryCompletionBlock = { (_, error) in
            if let error = error { print(error); return }
            closure(objects)
        }
        privateCloudDatabase.add(queryOperation)
    }
    
    
    
    
    
    
    
    
    
    static func deleteRecordFromCloud(recordID: String) {
        let query = CKQuery(recordType: "Recipe", predicate: NSPredicate(value: true))
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = ["recordID"]
        queryOperation.queuePriority = .veryHigh
        queryOperation.recordFetchedBlock = { record in
            if record.recordID.recordName == recordID {
                privateCloudDatabase.delete(withRecordID: record.recordID, completionHandler: { (_, error) in
                    print("deleted")
                    if let error = error { print(error); return }
                })
            }
        }
        queryOperation.queryCompletionBlock = { _, error in
            if let error = error { print(error); return }
        }
        privateCloudDatabase.add(queryOperation)
    }
    
    private static func saveProductsToCloud(products: [Product], parentRecord: CKRecord) {
        products.forEach { (product) in
            let record = CKRecord(recordType: "Product")
            record.setValue(product.name, forKey: "name")
            record.setValue(product.quantity, forKey: "quantity")
            record.setValue(product.measure, forKey: "measure")
            record.setValue(product.checked, forKey: "checked")
            record.setValue(product.inFridge, forKey: "inFridge")
            record["parent"] = CKRecord.Reference(record: parentRecord, action: .deleteSelf)
            privateCloudDatabase.save(record, completionHandler: { (_, error) in
                if let error = error { print(error); return }
            })
        }
    }
    
    
    private static func saveRecipeStepsToCloud(steps: [RecipeStep], parentRecord: CKRecord) {
        steps.forEach { (recipeStep) in
            let record = CKRecord(recordType: "RecipeStep")
            record.setValue(recipeStep.name, forKey: "name")
            record["parent"] = CKRecord.Reference(record: parentRecord, action: .deleteSelf)
            privateCloudDatabase.save(record, completionHandler: { (_, error) in
                if let error = error { print(error); return }
            })
        }
    }
    
    
     private static func prepareImageToSaveToCloud(imagePath: String) -> CKAsset {
        let imageUrl = URL(fileURLWithPath: imagePath)
        let imageAsset = CKAsset(fileURL: imageUrl)
        return imageAsset
    }
    
    
    private static func newCloudRecordIsAvailable(recipes: Results<Recipe>, recordID: String) -> Bool {
        for recipe in recipes {
            if recipe.cloudID == recordID { return false }
        }
        return true
    }
}
