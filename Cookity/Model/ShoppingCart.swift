//
//  File.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 21/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import Foundation
import RealmSwift


class ShoppingCart: Object, Codable {
    
    @objc dynamic var name: String = ""
    let products = List<Product>()
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        let productArray = Array(products)
        try container.encode(productArray, forKey: .products)
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        let productArray = try container.decode([Product].self, forKey: .products)
        products.append(objectsIn: productArray)
    }
}
