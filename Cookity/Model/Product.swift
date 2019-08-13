//
//  File.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 03/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import Foundation
import RealmSwift
import CloudKit


class Product: Object, Codable {
    @objc dynamic var name: String = ""
    @objc dynamic var quantity: Int = 0
    @objc dynamic var measure: String = ""
    
    @objc dynamic var checked: Bool = false
    @objc dynamic var inFridge: Bool = false
    @objc dynamic var checkForRecipe = false
    
    convenience init(record: CKRecord) {
        self.init()
        
        name = record.value(forKey: "name") as! String
        quantity = record.value(forKey: "quantity") as! Int
        measure = record.value(forKey: "measure") as! String
        
        checked = false
        inFridge = false
        checkForRecipe = false
    }
    
}
