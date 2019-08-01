//
//  File.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 03/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import Foundation
import RealmSwift


class Product: Object, Codable {
    @objc dynamic var name: String = ""
    @objc dynamic var quantity: Int = 0
    @objc dynamic var measure: String = ""
    
    @objc dynamic var checked: Bool = false
    @objc dynamic var inFridge: Bool = false
    @objc dynamic var checkForRecipe = false
    
}
