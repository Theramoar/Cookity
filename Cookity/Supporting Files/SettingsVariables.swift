//
//  SettingsVariables.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 12/08/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import Foundation


struct SettingsVariables {
    static var isIngridientSearchEnabled: Bool = UserDefaults.standard.bool(forKey: "isIngridientSearchEnabled") {
        didSet {
            UserDefaults.standard.set(isIngridientSearchEnabled, forKey: "isIngridientSearchEnabled")
        }
    }
    static var isCloudEnabled: Bool = UserDefaults.standard.bool(forKey: "isCloudEnabled") {
        didSet {
            UserDefaults.standard.set(isCloudEnabled, forKey: "isCloudEnabled")
        }
    }
    static var isDefaultDateEnabled: Bool = UserDefaults.standard.bool(forKey: "isDefaultDateEnabled") {
        didSet {
            UserDefaults.standard.set(isDefaultDateEnabled, forKey: "isDefaultDateEnabled")
        }
    }
    
    static var defaultExpirationDate: Int = UserDefaults.standard.integer(forKey: "defaultExpirationDate") {
        didSet {
            UserDefaults.standard.set(defaultExpirationDate, forKey: "defaultExpirationDate")
            
        }
    }
}




