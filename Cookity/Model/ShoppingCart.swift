//
//  File.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 21/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import Foundation
import RealmSwift


enum ShoppingCartCodingKeys: String, CodingKey {
    case cartName
    case cartProducts
}

class ShoppingCart: Object, Codable {
    
    @objc dynamic var name: String = ""
    let products = List<Product>()
    
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
