//
//  RecipeStep.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 07/03/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import Foundation
import RealmSwift
import CloudKit

class RecipeStep: Object, Codable {
    
    @objc dynamic var name: String = ""
    
    convenience init(record: CKRecord) {
        self.init()
        name = record.value(forKey: "name") as! String
    }
}
