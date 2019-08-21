//
//  Fridge.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 18/08/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import RealmSwift


class Fridge: Object, ParentObject {
    
    static var shared = Fridge()

    @objc dynamic var name: String = ""
    var products = List<Product>()
    @objc dynamic var cloudID: String?
}
