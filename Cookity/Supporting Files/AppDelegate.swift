//
//  AppDelegate.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 03/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Realm Data manipulation Starts
        print(Realm.Configuration.defaultConfiguration.fileURL as Any)

        do{
            _ = try Realm()
        }
        catch{
            print("Error in Realm \(error)")
        }
        // Realm Data manipulation Ends
        
        //confing Database schema
        let schemaVersion: UInt64 = 3
        
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: schemaVersion,
            
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < schemaVersion) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
        })
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
        
        let firstLaunch = FirstLaunch()
        if firstLaunch.isFirstLaunch {
            SettingsVariables.isCloudEnabled = true
            SettingsVariables.isIngridientSearchEnabled = true
            firstLaunch.createTutorial()
        }
        
        let _: Results<Fridge>? = RealmDataManager.dataLoadedFromRealm(ofType: .Fridge)
        if Fridge.shared.cloudID == nil {
            CloudManager.loadFridgeFromCloud { (recordID) in
                DispatchQueue.main.async {
                    RealmDataManager.saveToRealm(parentObject: Fridge.shared, object: recordID)
                }
                
            }
        }
        return true
    }
    
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        
        guard url.pathExtension == "ckty" else { return false }
        
        guard let object = ShareDataManager.importData(from: url) else { return false }
        
        if let cart = object as? ShoppingCart {
            CloudManager.saveDataToCloud(ofType: .Cart, object: cart) { (recordID) in
                DispatchQueue.main.async {
                    RealmDataManager.changeElementIn(object: cart,
                                                     keyValue: "cloudID",
                                                     objectParameter: cart.cloudID,
                                                     newParameter: recordID)
                }
            }
            guard
                let tabBarViewController = window?.rootViewController as? UITabBarController,
                let navigationController  = tabBarViewController.viewControllers?.first as? UINavigationController,
                let vc1 = navigationController.viewControllers.first as? CartCollectionViewController
                else { return true }
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: CartViewController.self))
            guard let vc2 = vc as? CartViewController else { return true }
            vc2.cartDataManager.selectedCart = cart
            navigationController.viewControllers = [vc1,vc2]
            return true
        }
        else if let recipe = object as? Recipe {
            CloudManager.saveDataToCloud(ofType: .Recipe, object: recipe) { (recordID) in
                DispatchQueue.main.async {
                    RealmDataManager.changeElementIn(object: recipe,
                                                     keyValue: "cloudID",
                                                     objectParameter: recipe.cloudID,
                                                     newParameter: recordID)
                }
            }
            guard
                let tabBarViewController = window?.rootViewController as? UITabBarController
                else { return true }
            tabBarViewController.selectedIndex = 1
            
            guard
                let navigationController = tabBarViewController.selectedViewController as? UINavigationController,
                let vc1 = navigationController.viewControllers.first as? RecipeCollectionViewController
            else { return true }
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: RecipeViewController.self))
            guard let vc2 = vc as? RecipeViewController else { return true }
            vc2.recipeDataManager.selectedRecipe = recipe
            navigationController.viewControllers = [vc1,vc2]
            return true
        }
        return true
    }
}

