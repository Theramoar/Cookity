//
//  File.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 21/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import Foundation
import RealmSwift


class ShoppingCart: Object {
    
    @objc dynamic var name: String = ""
    let products = List<Product>()
}
