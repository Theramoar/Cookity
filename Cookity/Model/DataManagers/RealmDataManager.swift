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

    private static var realm: Realm {
        let schemaVersion: UInt64 = 8
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: schemaVersion,
            
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                print(oldSchemaVersion)
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < schemaVersion) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
        })
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
        do{
            _ = try Realm()
        }
        catch{
            print("Error in Realm \(error)")
        }
        return try! Realm()
    }

    static func dataLoadedFromRealm<T: ParentObject>(ofType type: T.Type) -> Results<T>? {
        realm.objects(type.self)
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

    static func saveToRealm<T: Object>(parentObject: ParentObject?, object: T) {
        if let parentObject = parentObject {
            do{
                try realm.write {
                    parentObject.appendObject(object)
                }
            }
            catch{
                print("Error saving context in Product \(error)")
            }
        }
        else {
            do{
                try realm.write {
                    realm.add(object)
                }
            }catch{
                print("Error while saving Parent Object \(error)")
            }
        }
    }


    static func changeElementIn<T>(object: Object, keyValue: String, objectParameter: T, newParameter: T) {
        guard object.isInvalidated == false else { return }
        do{
            try self.realm.write {
                object.setValue(newParameter, forKey: keyValue)
            }
        }catch
        {
            print("Error while changing items \(error)")
        }
    }

    static func saveCloudID(parentObject: ParentObject, cloudID: String) {
        guard parentObject.isInvalidated == false else { return }
        do{
            try realm.write {
                parentObject.cloudID = cloudID
            }
        }
        catch{
            print("Error saving CloudID \(error)")
        }
    }

    //MARK:- Filepath data saving
    static func savePicture(to recipe: Recipe, image: UIImage?) -> Bool {
        guard let image = image else { return false }
        let imageFileName = "\(UUID().uuidString).png"
        let imagePath: String = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(imageFileName)"
        let imageUrl: URL = URL(fileURLWithPath: imagePath)
        do{
            try image.pngData()?.write(to: imageUrl)
            try realm.write {
                recipe.imageFileName = imageFileName

            }
        }catch{
            print("Error saving Image \(error)")
        }
        return true
    }

    static func deletePicture(withName imageFileName: String) {
        let imagePath: String = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(imageFileName)"
        let imageUrl: URL = URL(fileURLWithPath: imagePath)
        try? FileManager.default.removeItem(at: imageUrl)
    }

}
