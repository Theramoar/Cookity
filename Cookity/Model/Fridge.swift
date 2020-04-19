//
//  Fridge.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 18/08/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import RealmSwift
import CloudKit


class Fridge: Object, ParentObject {
    
    static var shared = Fridge()
    @objc dynamic var name: String = ""
    var products = List<Product>()
    @objc dynamic var cloudID: String?
    
    func appendObject(_ object: Object) {
        products.append(object as! Product)
    }
    
    func returnCloudValues() -> [String : Any] {
        ["name" : name]
    }
    
    func allChildrenObjects() -> [ChildObject] {
        var objects = [ChildObject]()
        for product in products {
            objects.append(product)
        }
        return objects
    }
    
    required convenience init(record: CKRecord) {
        self.init()
        self.name = record.value(forKey: "name") as! String
        self.cloudID = record.recordID.recordName
    }
}
