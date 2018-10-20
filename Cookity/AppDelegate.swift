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
        return true
    }
}

