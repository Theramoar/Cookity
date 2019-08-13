//
//  File.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 30/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import Foundation
import RealmSwift
import CloudKit


enum RecipeCodingKeys: String, CodingKey {
    case name
    case products
    case recipeSteps
    case recipeImageData
}

class Recipe: Object, Codable {
    
    @objc dynamic var name: String = ""
    var products = List<Product>()
    var recipeSteps = List<RecipeStep>()
    @objc dynamic var imagePath: String?
    @objc dynamic var cloudID: String?

    
    
    convenience init(record: CKRecord, products: List<Product>?, steps: List<RecipeStep>?) {
        self.init()
        
        self.name = record.value(forKey: "name") as! String
        self.cloudID = record.recordID.recordName
        self.products = products ?? List<Product>()
        self.recipeSteps = steps ?? List<RecipeStep>()
    }
    
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RecipeCodingKeys.self)
        try container.encode(name, forKey: .name)
        let productArray = Array(products)
        let recipeStepsArray = Array(recipeSteps)
        try container.encode(productArray, forKey: .products)
        try container.encode(recipeStepsArray, forKey: .recipeSteps)
        
        if let imagePath = self.imagePath {
            let imageUrl: URL = URL(fileURLWithPath: imagePath)
            guard FileManager.default.fileExists(atPath: imagePath),
                let imageData: Data = try? Data(contentsOf: imageUrl) else { return }
            try container.encode(imageData, forKey: .recipeImageData)
        }
    }
    
    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: RecipeCodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        let productArray = try container.decode([Product].self, forKey: .products)
        let recipeStepsArray = try container.decode([RecipeStep].self, forKey: .recipeSteps)
        products.append(objectsIn: productArray)
        recipeSteps.append(objectsIn: recipeStepsArray)
        
        let imageData = try? container.decode(Data.self, forKey: .recipeImageData)
        
        let imagePath: String = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(name).png"
        let imageUrl: URL = URL(fileURLWithPath: imagePath)
    
        if let imageData = imageData {
            try? imageData.write(to: imageUrl)
            self.imagePath = imagePath
        }
        else {
            self.imagePath = nil
        }
    }
}
