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


enum ParentData: String {
    case Cart = "ShoppingCart"
    case Recipe = "Recipe"
    case Fridge = "Fridge"
}

enum CloudChildData: String {
    case Product = "Product"
    case RecipeStep = "RecipeStep"
}


class CloudManager {
    
    private static let privateCloudDatabase = CKContainer.default().privateCloudDatabase
    private static var records: [CKRecord] = []
    
    
    //MARK:- Save Data
    static func saveDataToCloud(ofType objectType: ParentData, object: ParentObject, closure: @escaping (String) -> Void) {
        guard SettingsVariables.isCloudEnabled else { return }
        //Create parent record and save it to cloud
        let record = CKRecord(recordType: objectType.rawValue)
        record.setValue(object.name, forKey: "name")
        privateCloudDatabase.save(record, completionHandler: { (record, error) in
            if let error = error { print(error); return }
            guard let record = record else { return }
            closure(record.recordID.recordName)
        })
    
        //Save products and create reference to the parent
        let products = Array(object.products)
        saveChildrenToCloud(ofType: .Product, objects: products, parentRecord: record)
        
        if objectType == .Recipe {
            guard let recipe = object as? Recipe else { return }
            //Save recipe steps create reference to the parent
            let recipeSteps = Array(recipe.recipeSteps)
            saveChildrenToCloud(ofType: .RecipeStep, objects: recipeSteps, parentRecord: record)
            //Save Image
            if let imagePath = recipe.imagePath, FileManager.default.fileExists(atPath: imagePath) {
                let imageAsset = prepareImageToSaveToCloud(imagePath: imagePath)
                record.setValue(imageAsset, forKey: "imageAsset")
            }
        }
    }
    
    
    static func saveProductsToCloud(to parentData: ParentData, products: [Product], parentRecordID: String) {
        guard SettingsVariables.isCloudEnabled else { return }
        let recordID = CKRecord.ID(recordName: parentRecordID)
        let record = CKRecord(recordType: parentData.rawValue, recordID: recordID)
        saveChildrenToCloud(ofType: .Product, objects: products, parentRecord: record)
    }
    
    
    static func saveFridgeToCloud(_ fridge: Fridge) {
        guard SettingsVariables.isCloudEnabled else { return }
        let record = CKRecord(recordType: "Fridge")
        privateCloudDatabase.save(record) { (record, error) in
            if let error = error { print(error); return }
            guard let record = record else { return }
            DispatchQueue.main.async {
                RealmDataManager.saveToRealm(parentObject: Fridge.shared, object: record.recordID.recordName)
            }
        }
    }
    
    
    private static func saveChildrenToCloud(ofType objectType: CloudChildData, objects: [Object], parentRecord: CKRecord) {
        objects.forEach { (object) in
            let record = CKRecord(recordType: objectType.rawValue)
            
            switch objectType {
            case .Product:
                let product = object as! Product
                record.setValue(product.name, forKey: "name")
                record.setValue(product.quantity, forKey: "quantity")
                record.setValue(product.measure, forKey: "measure")
                record.setValue(product.checked, forKey: "checked")
            case .RecipeStep:
                let step = object as! RecipeStep
                record.setValue(step.name, forKey: "name")
            }
            record["parent"] = CKRecord.Reference(record: parentRecord, action: .deleteSelf)

            privateCloudDatabase.save(record, completionHandler: { (record, error) in
                if let error = error { print(error); return }
                guard let record = record, let product = object as? Product else { return }
                DispatchQueue.main.async {
                    RealmDataManager.changeElementIn(object: product, keyValue: "cloudID", objectParameter: product.cloudID, newParameter: record.recordID.recordName)
                }
            })
        }
    }
    
    
    //MARK:- Update Data
    static func updateRecipeInCloud(recipe: Recipe) {
        guard SettingsVariables.isCloudEnabled else { return }
        guard let cloudID = recipe.cloudID else { return }
        saveDataToCloud(ofType: .Recipe, object: recipe) { (recordID) in
            DispatchQueue.main.async {
                RealmDataManager.changeElementIn(object: recipe,
                                                 keyValue: "cloudID",
                                                 objectParameter: recipe.cloudID,
                                                 newParameter: recordID)
            }
        }
        deleteRecordFromCloud(ofType: .Recipe, recordID: cloudID)
    }
    
    
    static func updateProductInCloud(product: Product) {
        guard SettingsVariables.isCloudEnabled else { return }
        guard let cloudID = product.cloudID else { return }
        let recordID = CKRecord.ID(recordName: cloudID)
        privateCloudDatabase.fetch(withRecordID: recordID) { (record, error) in
            guard let record = record, error == nil else { return }
            DispatchQueue.main.async {
                record.setValue(product.name, forKey: "name")
                record.setValue(product.quantity, forKey: "quantity")
                record.setValue(product.measure, forKey: "measure")
                record.setValue(product.checked, forKey: "checked")
                privateCloudDatabase.save(record, completionHandler: { (_, error) in
                    if let error = error { print(error); return }
                })
            }
        }
    }
    
    //MARK:- Loading Data
    static func loadDataFromCloud(ofType data: ParentData, recipes: [ParentObject], closure: @escaping (ParentObject) -> Void) {
        guard SettingsVariables.isCloudEnabled else { return }
        let query = CKQuery(recordType: data.rawValue, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = ["recordID", "name"]
//        queryOperation.resultsLimit = 5 - сделать потом
        queryOperation.queuePriority = .veryHigh
        
        queryOperation.recordFetchedBlock = { record in
            self.records.append(record)
            var parentObject: ParentObject!
            switch data {
            case .Recipe:
                parentObject = Recipe(record: record,
                                      products: nil,
                                      steps: nil)
            case .Cart:
                parentObject = ShoppingCart(record: record,
                                            products: nil)
            case .Fridge:
                return
            }
            loadChildrenFromCloud(ofType: .Product, record: record, closure: { (products) in
                let loadedProducts = List<Product>()
                for product in products {
                    loadedProducts.append(product as! Product)
                }
                
                parentObject.products = loadedProducts
                DispatchQueue.main.async {
                    if newCloudRecordIsAvailable(objects: recipes, recordID: record.recordID.recordName) { closure(parentObject)}
                }
            })
            
            if data == .Recipe {
                loadChildrenFromCloud(ofType: .RecipeStep, record: record, closure: { (recipeSteps) in
                    for step in recipeSteps {
                        guard let step = step as? RecipeStep else { return }
                        DispatchQueue.main.async {
                            RealmDataManager.saveToRealm(parentObject: parentObject, object: step)
                        }
                    }
                })
            }
        }
        
        queryOperation.queryCompletionBlock = { (_, error) in
            if let error = error { print(error); return }
        }
        
        privateCloudDatabase.add(queryOperation)
    }
    
    
    private static func loadChildrenFromCloud<T: Object>(ofType objectType: CloudChildData, record: CKRecord?, closure: @escaping ([T]) -> Void) {
        var objects = [T]()
        let predicate: NSPredicate!
        if let record = record {
            let recordID = record.recordID
            let recordToMatch = CKRecord.Reference(recordID: recordID, action: .deleteSelf)
            predicate = NSPredicate(format: "parent == %@", recordToMatch)
        }
        else {
            guard let recordName = Fridge.shared.cloudID else { return }
            let recordID = CKRecord.ID(recordName: recordName)
            let recordToMatch = CKRecord.Reference(recordID: recordID, action: .deleteSelf)
            predicate = NSPredicate(format: "parent == %@", recordToMatch)
        }
        
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
            }
            
        }
        queryOperation.queryCompletionBlock = { (_, error) in
            if let error = error { print(error); return }
            closure(objects)
        }
        privateCloudDatabase.add(queryOperation)
    }
    
    
    static func loadImageFromCloud(recipe: Recipe, closure: @escaping (Data?) -> Void) {
        guard SettingsVariables.isCloudEnabled else { return }
        for record in records {
            if record.recordID.recordName == recipe.cloudID {
                let fetchRecordsOperation = CKFetchRecordsOperation(recordIDs: [record.recordID])
                fetchRecordsOperation.desiredKeys = ["imageAsset"]
                fetchRecordsOperation.perRecordCompletionBlock = { record, _, error in
                    guard error == nil else { return }
                    guard let record = record else { return }
                    guard let passableImage = record.value(forKey: "imageAsset") as? CKAsset else { return }
                    guard let imageData = try? Data(contentsOf: passableImage.fileURL!) else { return }
                    DispatchQueue.main.async {
                        closure(imageData)
                    }
                }
                privateCloudDatabase.add(fetchRecordsOperation)
            }
        }
        
    }
    
    
    static func loadFridgeFromCloud(closure: @escaping (String) -> Void) {
        guard SettingsVariables.isCloudEnabled else { return }
        var recordFetchCount = 0
        let query = CKQuery(recordType: "Fridge", predicate: NSPredicate(value: true))
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = ["recordID"]
        queryOperation.resultsLimit = 1
        queryOperation.queuePriority = .veryHigh
        queryOperation.recordFetchedBlock = { record in
            
            recordFetchCount += 1
            closure(record.recordID.recordName)
            loadChildrenFromCloud(ofType: .Product, record: record, closure: { (products) in
                DispatchQueue.main.async {
                    for product in products {
                        RealmDataManager.saveToRealm(parentObject: Fridge.shared, object: product)
                    }
                }
            })
        }
        queryOperation.queryCompletionBlock = { (_, error) in
            if let error = error { print(error); return }
            if recordFetchCount == 0 {
                saveFridgeToCloud(Fridge.shared)
            }
        }
        privateCloudDatabase.add(queryOperation)
    }
    
    
    //MARK:- Delete Data
    static func deleteRecordFromCloud(ofType type: ParentData, recordID: String) {
        guard SettingsVariables.isCloudEnabled else { return }
        let query = CKQuery(recordType: type.rawValue, predicate: NSPredicate(value: true))
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = ["recordID"]
        queryOperation.queuePriority = .veryHigh
        
        queryOperation.recordFetchedBlock = { record in
            if record.recordID.recordName == recordID {
                privateCloudDatabase.delete(withRecordID: record.recordID, completionHandler: { (_, error) in
                    if let error = error { print(error); return }
                })
            }
        }
        queryOperation.queryCompletionBlock = { _, error in
            if let error = error { print(error); return }
        }
        privateCloudDatabase.add(queryOperation)
    }
    
    
    static func deleteProductFromCloud(parentRecordID: String, productRecordID: String) {
        guard SettingsVariables.isCloudEnabled else { return }
        let recordID = CKRecord.ID(recordName: parentRecordID)
        let recordToMatch = CKRecord.Reference(recordID: recordID, action: .deleteSelf)
        let predicate = NSPredicate(format: "parent == %@", recordToMatch)
        
        let query = CKQuery(recordType: "Product", predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        
        queryOperation.recordFetchedBlock = { record in
            if record.recordID.recordName == productRecordID {
                privateCloudDatabase.delete(withRecordID: record.recordID, completionHandler: { (_, error) in
                    if let error = error { print(error); return }
                })
            }
        }
        queryOperation.queryCompletionBlock = { _, error in
            if let error = error { print(error); return }
        }
        privateCloudDatabase.add(queryOperation)
    }
    
    
    //MARK:- Sync Data - перед тем как начать писать протестить как работает без интернета
    
    static func syncData(ofType data: ParentData, parentObjects: [ParentObject]) {
        guard SettingsVariables.isCloudEnabled else { return }
        
        switch data {
        case .Cart:
            for object in parentObjects {
                guard let cart = object as? ShoppingCart else { return }
                syncCart(cart)
            }
        case .Recipe:
            
            for object in parentObjects {
                guard let recipe = object as? Recipe else { return }
                syncRecipe(recipe)
            }
        case .Fridge:
            syncFridge()
        }
    }
    
    private static func syncFridge() {
        guard let fridgeID = Fridge.shared.cloudID else { return }
        for product in Fridge.shared.products {
            syncProduct(in: .Fridge, product: product, parentRecordID: fridgeID)
        }
        
    }
    
    private static func syncRecipe(_ recipe: Recipe) {
        if recipe.cloudID == nil {
            saveDataToCloud(ofType: .Recipe, object: recipe) { (recordID) in
                DispatchQueue.main.async {
                    RealmDataManager.changeElementIn(object: recipe,
                                                     keyValue: "cloudID",
                                                     objectParameter: recipe.cloudID,
                                                     newParameter: recordID)
                }
            }
        }
        else {
            for product in recipe.products {
                syncProduct(in: .Recipe, product: product, parentRecordID: recipe.cloudID!)
            }
        }
    }
    
    private static func syncCart(_ cart: ShoppingCart) {
        if cart.cloudID == nil {
            saveDataToCloud(ofType: .Cart, object: cart) { (recordID) in
                DispatchQueue.main.async {
                    RealmDataManager.changeElementIn(object: cart,
                                                     keyValue: "cloudID",
                                                     objectParameter: cart.cloudID,
                                                     newParameter: recordID)
                }
            }
        }
        else {
            for product in cart.products {
                syncProduct(in: .Cart, product: product, parentRecordID: cart.cloudID!)
            }
        }
    }
    
    private static func syncProduct(in data: ParentData, product: Product, parentRecordID: String) {
        if product.cloudID == nil {
            switch data {
                case .Cart:
                    saveProductsToCloud(to: .Cart, products: [product], parentRecordID: parentRecordID)
                case .Recipe:
                    saveProductsToCloud(to: .Recipe, products: [product], parentRecordID: parentRecordID)
                case .Fridge: return
                    saveProductsToCloud(to: .Fridge, products: [product], parentRecordID: parentRecordID)
            }
        }
        else {
            updateProductInCloud(product: product)
        }
    }
    
    
    //MARK:- Supporting Methods
    private static func newCloudRecordIsAvailable(objects: [ParentObject], recordID: String) -> Bool {
        for object in objects {
            if object.cloudID == recordID { return false }
        }
        return true
    }
    
    private static func prepareImageToSaveToCloud(imagePath: String) -> CKAsset {
        let imageUrl = URL(fileURLWithPath: imagePath)
        let imageAsset = CKAsset(fileURL: imageUrl)
        return imageAsset
    }
}
