//
//  CloudManager.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 05/08/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import CloudKit
import RealmSwift

class CloudManager {
    
    private static let privateCloudDatabase = CKContainer.default().privateCloudDatabase
    private static var records: [CKRecord] = []
    
//MARK:- Save Data
    static func saveParentDataToCloud<T: ParentObject>(object: T, objectImageName: String?, closure: @escaping (String) -> Void) {
        guard SettingsVariables.isCloudEnabled, object.isInvalidated == false else { return }
        let record = CKRecord(recordType: String(describing: T.self))
        for value in object.returnCloudValues() {
            record.setValue(value.value, forKey: value.key)
        }
        if let imageFileName = objectImageName {
            saveImageToCloud(to: record, imageFileName: imageFileName)
        }
        
        privateCloudDatabase.save(record, completionHandler: { (record, error) in
            if let error = error { print(error); return }
            guard let record = record else { return }
            DispatchQueue.main.async {
                if object.isInvalidated {
                    privateCloudDatabase.delete(withRecordID: record.recordID, completionHandler: { (_, error) in
                        if let error = error { print(error); return }
                    })
                    return
                }
                RealmDataManager.saveCloudID(parentObject: object, cloudID: record.recordID.recordName)
                closure(record.recordID.recordName)
                saveChildrenDataToCloud(objects: object.allChildrenObjects(), to: object)
            }
        })
    }

    static func saveChildrenDataToCloud<T: CloudObject, P: ParentObject>(objects: [T], to parentObject: P) {
        guard SettingsVariables.isCloudEnabled, let parentObjectID = parentObject.cloudID else { print("parentObject.cloudID is invalid") ; return }
        objects.forEach { (object) in
            guard object.isInvalidated == false else { return }
            let record = CKRecord(recordType: String(describing: type(of: object)))
            for value in object.returnCloudValues() {
                record.setValue(value.value, forKey: value.key)
            }

            guard let cloudID = parentObject.cloudID else { return }
            let recordID = CKRecord.ID(recordName: cloudID)
            let parentRecord = CKRecord(recordType: String(describing: P.self), recordID: recordID)

            record["parent"] = CKRecord.Reference(record: parentRecord, action: .deleteSelf)
            privateCloudDatabase.save(record, completionHandler: { (record, error) in
                if let error = error { print(error); return }
                guard let record = record else { return }
                DispatchQueue.main.async {
                    
                    if parentObject.isInvalidated {
                        let parentRecordID = CKRecord.ID(recordName: parentObjectID)
                        privateCloudDatabase.delete(withRecordID: parentRecordID, completionHandler: { (_, error) in
                            if let error = error { print(error); return }
                        })
                        return
                    }
                    else if object.isInvalidated {
                        privateCloudDatabase.delete(withRecordID: record.recordID, completionHandler: { (_, error) in
                            if let error = error { print(error); return }
                        })
                        return
                    }
                    RealmDataManager.changeElementIn(object: object, keyValue: "cloudID", objectParameter: object.cloudID, newParameter: record.recordID.recordName)
                }
            })
        }
    }
    
    private static func saveImageToCloud(to record: CKRecord, imageFileName: String) {
        let imagePath: String = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(imageFileName)"
        guard FileManager.default.fileExists(atPath: imagePath) else { return }
        let imageAsset = prepareImageToSaveToCloud(imagePath: imagePath)
        record.setValue(imageAsset, forKey: "imageAsset")
    }
    
    
    
    //MARK:- Update Data
    static func updateRecipeInCloud(recipe: Recipe) {
        guard SettingsVariables.isCloudEnabled else { return }
        guard recipe.isInvalidated == false else { return }
        saveParentDataToCloud(object: recipe, objectImageName: recipe.imageFileName) { (recordID) in
            DispatchQueue.main.async {
                RealmDataManager.changeElementIn(object: recipe,
                                                 keyValue: "cloudID",
                                                 objectParameter: recipe.cloudID,
                                                 newParameter: recordID)
            }
        }
        deleteRecordFromCloud(ofObject: recipe)
    }
    
    static func updateChildInCloud<T: ChildObject>(childObject: T) {
        guard SettingsVariables.isCloudEnabled else { return }
        guard childObject.isInvalidated == false, let cloudID = childObject.cloudID else { return }
        let recordID = CKRecord.ID(recordName: cloudID)
        privateCloudDatabase.fetch(withRecordID: recordID) { (record, error) in
            guard let record = record, error == nil else { return }
            DispatchQueue.main.async {
                if childObject.isInvalidated {
                    print("INVALIDATED PRODUCT CATCHED AND DELETED")
                    privateCloudDatabase.delete(withRecordID: record.recordID, completionHandler: { (_, error) in
                        if let error = error { print(error); return }
                    })
                    return
                }
                for value in childObject.returnCloudValues() {
                    record.setValue(value.value, forKey: value.key)
                }
                privateCloudDatabase.save(record, completionHandler: { (_, error) in
                    if let error = error { print(error); return }
                })
            }
        }
    }
    
    //MARK:- Loading Data - 363
    static func loadDataFromCloud<T: ParentObject>(objects: [T], closure: @escaping ([T]) -> Void) {
        guard SettingsVariables.isCloudEnabled else { return }
        let query = CKQuery(recordType: String(describing: T.self), predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = ["recordID", "name"]
        //        queryOperation.resultsLimit = 5 - сделать потом
        queryOperation.queuePriority = .veryHigh
        
        queryOperation.recordFetchedBlock = { record in
            self.records.append(record)
            let parentObject = T.init(record: record)
            DispatchQueue.main.async {
                if newCloudRecordIsAvailable(objects: objects, recordID: record.recordID.recordName) { closure([parentObject]) }
            }

            loadChildrenFromCloud(ofType: Product.self, record: record) { loadedObjects in
                DispatchQueue.main.async {
                    for object in loadedObjects {
                        RealmDataManager.saveToRealm(parentObject: parentObject, object: object)
                    }
                }
            }
            loadChildrenFromCloud(ofType: RecipeStep.self, record: record) { loadedObjects in
                DispatchQueue.main.async {
                    for object in loadedObjects {
                        RealmDataManager.saveToRealm(parentObject: parentObject, object: object)
                    }
                }
            }
        }
        queryOperation.queryCompletionBlock = { (_, error) in
                if let error = error { print(error); return }
        }
        privateCloudDatabase.add(queryOperation)
    }
    
    private static func loadChildrenFromCloud<T: ChildObject>(ofType: T.Type, record: CKRecord?, closure: @escaping ([T]) -> Void) {
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
        let query = CKQuery(recordType: String(describing: T.self), predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        
        queryOperation.recordFetchedBlock = { record in
            let object = T.init(record: record)
            objects.append(object)
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
            DispatchQueue.main.async {
                if Fridge.shared.cloudID != record.recordID.recordName {
                    closure(record.recordID.recordName)
                }
                loadChildrenFromCloud(ofType: Product.self, record: record) { (products) in
                    for product in products {
                        DispatchQueue.main.async {
                            if let id = product.cloudID, Fridge.shared.products.first(where: {$0.cloudID == id}) == nil {
                                RealmDataManager.saveToRealm(parentObject: Fridge.shared, object: product)
                            }
                        }
                    }
                }
            }
        }
        queryOperation.queryCompletionBlock = { (_, error) in
            if let error = error { print(error); return }
            if recordFetchCount == 0 {
                DispatchQueue.main.async {
                    saveParentDataToCloud(object: Fridge.shared, objectImageName: nil) { (recordID) in
                        DispatchQueue.main.async {
                            RealmDataManager.changeElementIn(object: Fridge.shared,
                                                             keyValue: "cloudID",
                                                             objectParameter: Fridge.shared.cloudID,
                                                             newParameter: recordID)
                        }
                    }
                }
            }
        }
        privateCloudDatabase.add(queryOperation)
    }
    
    
    //MARK:- Delete Data
    static func deleteRecordFromCloud<T: CloudObject>(ofObject object: T) {
        guard SettingsVariables.isCloudEnabled, let cloudID = object.cloudID else { return }
        let recordID = CKRecord.ID(recordName: cloudID)
        privateCloudDatabase.fetch(withRecordID: recordID) { (record, error) in
            guard let record = record, error == nil else { return }
            privateCloudDatabase.delete(withRecordID: record.recordID, completionHandler: { (_, error) in
                if let error = error { print(error); return }
                print("OBJECT DELETED")
            })
        }
    }
    
    
    //MARK:- Sync Data - перед тем как начать писать протестить как работает без интернета
    static func syncData<T: ParentObject>(parentObjects: [T]) {
        guard SettingsVariables.isCloudEnabled else { return }
        for object in parentObjects {
            if object.cloudID == nil {
                var imageFileName: String?
                if let recipe = object as? Recipe { imageFileName = recipe.imageFileName }
                saveParentDataToCloud(object: object, objectImageName: imageFileName) { (recordID) in
                    DispatchQueue.main.async {
                        RealmDataManager.changeElementIn(object: object,
                                                         keyValue: "cloudID",
                                                         objectParameter: object.cloudID,
                                                         newParameter: recordID)
                    }
                }
            }
            else {
                for childObject in object.allChildrenObjects() {
                    syncChildObject(in: object, childObject: childObject)
                }
            }
        }
    }
    
    private static func syncChildObject<P: ParentObject, C: ChildObject>(in object: P, childObject: C) {
        if childObject.cloudID == nil {
            saveChildrenDataToCloud(objects: [childObject], to: object)
        }
        else {
            updateChildInCloud(childObject: childObject)
        }
    }
    
    
    //MARK:- Supporting Methods
    private static func newCloudRecordIsAvailable<T: ParentObject>(objects: [T], recordID: String) -> Bool {
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
