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


class ChildObject: Object, CloudObject {
    @objc dynamic var cloudID: String?
    func returnCloudValues() -> [String : Any] {
        [:]
    }
    required convenience init(record: CKRecord) {
        self.init()
        self.cloudID = record.recordID.recordName
    }
}


class Product: ChildObject, Codable {
    @objc dynamic var name: String = ""
    @objc dynamic var quantity: Int = 0
    @objc dynamic var measure: String = ""
    @objc dynamic var expirationDate: Date?
    @objc dynamic var checked: Bool = false
    @objc dynamic var checkForRecipe: Bool = false
    
    
    
    convenience required init(record: CKRecord) {
        self.init()
        name = record.value(forKey: "name") as! String
        quantity = record.value(forKey: "quantity") as! Int
        measure = record.value(forKey: "measure") as! String
        self.cloudID = record.recordID.recordName
        checked = record.value(forKey: "checked") as! Bool
        if let expirationDate = record.value(forKey: "expirationDate") as? Date {
            self.expirationDate = expirationDate
        }
        checkForRecipe = false
    }
    
    override func returnCloudValues() -> [String : Any] {
        var cloudValues = ["name": name,
                           "quantity" : quantity,
                           "measure" : measure,
                           "checked" : checked
            ] as [String : Any]
        if let date = expirationDate {
            cloudValues["expirationDate"] = date
        }
        return cloudValues
    }
}
