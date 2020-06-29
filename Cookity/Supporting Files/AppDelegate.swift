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
        
        let firstLaunch = FirstLaunch()
        if firstLaunch.isFirstLaunch {
            SettingsVariables.isCloudEnabled = true
            SettingsVariables.isIngridientSearchEnabled = true
            firstLaunch.createTutorial()
        }
        
        configFridge()
        configPayments()
        return true
    }
    
    private func configPayments() {
        IAPManager.shared.setupPurchases { successful in
            if successful {
                print("Can make payments")
                IAPManager.shared.getProducts()
            }
        }
    }
    
    private func configFridge() {
        let loadedFridge: Results<Fridge>? = RealmDataManager.dataLoadedFromRealm(ofType: Fridge.self)
        if let fridge = loadedFridge?.first {
            Fridge.shared = fridge
        }
        else {
            RealmDataManager.saveToRealm(parentObject: nil, object: Fridge.shared)
        }
        CloudManager.loadFridgeFromCloud { (recordID) in
            DispatchQueue.main.async {
                RealmDataManager.saveCloudID(parentObject: Fridge.shared, cloudID: recordID)
            }
        }
        
    }
}





