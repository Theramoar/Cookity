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

class Recipe: Object, ParentObject, Codable {
    
    @objc dynamic var name: String = ""
    var products = List<Product>()
    var recipeSteps = List<RecipeStep>()
    @objc dynamic var imageFileName: String?
    @objc dynamic var cloudID: String?
    
    @objc dynamic var checkedForGroup: Bool = false
    @objc dynamic var recipeGroup: String?
    
    
    func getImageFromFileManager() -> UIImage? {
        guard let imageFileName = imageFileName else { return nil }
        let imagePath: String = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(imageFileName)"
        let imageUrl: URL = URL(fileURLWithPath: imagePath)
        if FileManager.default.fileExists(atPath: imagePath),
            let imageData: Data = try? Data(contentsOf: imageUrl),
            let image: UIImage = UIImage(data: imageData) {
            return image
        }
        else {
            return nil
        }
    }
    
    
    
    
    func appendObject(_ object: Object) {
        if type(of: object) == Product.self {
            products.append(object as! Product)
        }
        else if type(of: object) == RecipeStep.self {
            recipeSteps.append(object as! RecipeStep)
        }
    }
    func returnCloudValues() -> [String : Any] {
        ["name" : name]
    }
    
    func allChildrenObjects() -> [ChildObject] {
        var objects = [ChildObject]()
        for product in products {
            objects.append(product)
        }
        for step in recipeSteps {
            objects.append(step)
        }
        return objects
    }
    
    required convenience init(record: CKRecord) {
        self.init()
        self.name = record.value(forKey: "name") as! String
        self.cloudID = record.recordID.recordName
    }
    
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RecipeCodingKeys.self)
        try container.encode(name, forKey: .name)
        let productArray = Array(products)
        let recipeStepsArray = Array(recipeSteps)
        try container.encode(productArray, forKey: .products)
        try container.encode(recipeStepsArray, forKey: .recipeSteps)
        
        if let imageFileName = self.imageFileName {
            let imagePath: String = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(imageFileName)"
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
        
        let imageFileName = "\(UUID().uuidString).png"
        let imagePath: String = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(imageFileName)"
        let imageUrl: URL = URL(fileURLWithPath: imagePath)
    
        if let imageData = imageData {
            try? imageData.write(to: imageUrl)
            self.imageFileName = imageFileName
        }
        else {
            self.imageFileName = nil
        }
    }
}
