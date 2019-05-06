//
//  RecipeStep.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 07/03/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import Foundation
import RealmSwift

class RecipeStep: Object, Codable {
    
    @objc dynamic var name: String = ""
}
