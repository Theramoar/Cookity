//
//  UserPurchases.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 29/06/2020.
//  Copyright © 2020 Mihails Kuznecovs. All rights reserved.
//

import Foundation

struct UserPurchases {
    static var fullPro: Bool = UserDefaults.standard.bool(forKey: IAPProducts.fullPro.rawValue) {
        didSet {
            UserDefaults.standard.set(fullPro, forKey: IAPProducts.fullPro.rawValue)
        }
    }
    static var monthlyPro: Bool = UserDefaults.standard.bool(forKey: IAPProducts.monthlyPro.rawValue) {
        didSet {
            UserDefaults.standard.set(fullPro, forKey: IAPProducts.monthlyPro.rawValue)
        }
    }
    
    static func isProEnabled() -> Bool {
        fullPro || monthlyPro
    }
}
