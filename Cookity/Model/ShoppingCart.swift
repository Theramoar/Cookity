//
//  File.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 21/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import Foundation
import RealmSwift
import CloudKit


protocol CloudObject: Object {
    var cloudID: String? { get set }
    func returnCloudValues() -> [String : Any]
    init(record: CKRecord)
}

protocol ParentObject: CloudObject {
    var name: String { get set }
    var products: List<Product> { get set }
    func appendObject(_ object: Object)
    func allChildrenObjects() -> [ChildObject]
}

enum ShoppingCartCodingKeys: String, CodingKey {
    case cartName
    case cartProducts
}

class ShoppingCart: Object, ParentObject, Codable {
    @objc dynamic var name: String = ""
    @objc dynamic var cloudID: String?
    var products = List<Product>()
    
    func returnCloudValues() -> [String : Any] {
        ["name" : name]
    }
    
    func appendObject(_ object: Object) {
        products.append(object as! Product)
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
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ShoppingCartCodingKeys.self)
        try container.encode(name, forKey: .cartName)
        let productArray = Array(products)
        try container.encode(productArray, forKey: .cartProducts)
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: ShoppingCartCodingKeys.self)
        name = try container.decode(String.self, forKey: .cartName)
        let productArray = try container.decode([Product].self, forKey: .cartProducts)
        products.append(objectsIn: productArray)
    }
}
