//
//  Configuration.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 04/12/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift

class Configuration {
    
    
    static func configNumbers(quantity: String, measure: String) -> (Int, String) {
        let quantity = quantity.isEmpty ? "1" : quantity.replacingOccurrences(of: ",", with: ".")
        var newQuantity: Int = 0
        var newMeasure = measure
        
        if measure.elementsEqual("l") || measure.elementsEqual("kg"){
            
            newQuantity = Int(Float(quantity)! * 1000)
            
            switch newMeasure {
                case "l":
                    newMeasure = "ml"
                default:
                    newMeasure = "g"
            }
            return (newQuantity, newMeasure)
        }
        else {
            newQuantity = Int(Float(quantity)!)
            return (newQuantity, newMeasure)
        }
    }
    
    
    static func presentNumbers(quantity: Int, measure: String) -> (String, String) {
        
        var presentedMeasure = measure
        
        if quantity >= 1000 && presentedMeasure != "pcs" {
            let presentedQuantity = String(Float(quantity) / 1000)
            
            switch presentedMeasure {
            case "ml":
                presentedMeasure = "l"
            case "g":
                presentedMeasure = "kg"
            default:
                break
            }
            return (presentedQuantity, presentedMeasure)
        }
        else {
            let presentedQuantity = String(quantity)
            return (presentedQuantity, presentedMeasure)
        }
    }
    
    
    static func configMeasure(measure: String) -> String {
        
        var savedMeasure = measure

        switch savedMeasure {
        case "Mililiters":
            savedMeasure = "ml"
        case "ml":
            savedMeasure = "Mililiters"
        case "Kilograms":
            savedMeasure = "kg"
        case "kg":
            savedMeasure = "Kilograms"
        case "Litres":
            savedMeasure = "l"
        case "l":
            savedMeasure = "Litres"
        case "Grams":
            savedMeasure = "g"
        case "g":
            savedMeasure = "Grams"
        case "Pieces":
            savedMeasure = "pcs"
        case "pcs":
            savedMeasure = "Pieces"
        default:
            savedMeasure = "pcs"
    }
        return savedMeasure
    }
    
    
    static func compareFridgeToRecipe(selectedProduct: Product, compareTo productList: [Product]) -> (Bool, Product?) {
            for product in productList{
                if selectedProduct.name.lowercased() == product.name.lowercased(){
                    return (true, product)
                }
            }
        return (false, nil)
    }
    
    static func createDateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.date(from: dateString)
    }
    
    static func createStringFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
    
    //Удалить эту функцию/ вызывать её с рецепта
    static func getImageFromFileManager(with imageFileName: String) -> UIImage? {
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
}
