//
//  PopupEditViewModel.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 12/04/2020.
//  Copyright © 2020 Mihails Kuznecovs. All rights reserved.
//

import UIKit


class PopupEditViewModel: DetailViewModelType {
    
    private var product: Product
    var presentedName: String
    var presentedQuantity: String
    var presentedMeasure: String
    var presentedDate: String
    
    init(product: Product) {
        self.product = product
        self.presentedName = product.name
        (self.presentedQuantity, self.presentedMeasure) = Configuration.presentNumbers(quantity: product.quantity, measure: product.measure)
        self.presentedMeasure = Configuration.configMeasure(measure: self.presentedMeasure)
        if let date = product.expirationDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy"
            let result = formatter.string(from: date)
            self.presentedDate = result
        }
        else {
            self.presentedDate = ""
        }
    }
    func checkDataFromTextFields(productName: String, productQuantity: String, productMeasure: String) -> UIAlertController? {
          let alert = UIAlertController(title: "title", message: "message", preferredStyle: .alert)
          let action = UIAlertAction(title: "OK", style: .default) { (_) in return }
          alert.addAction(action)
          
          guard alert.check(data: productName, dataName: AlertMessage.name),
          alert.check(data: productQuantity, dataName: AlertMessage.quantity)
          else {
              return (alert)
          }
          return nil
      }
    func changeProduct(newName productName: String, newQuantity productQuantity: String, newMeasure productMeasure: String, newDate: String) {
        
        let measure = Configuration.configMeasure(measure: productMeasure)
        let (savedQuantity, savedMeasure) = Configuration.configNumbers(quantity: productQuantity, measure: measure)
        
        RealmDataManager.changeElementIn(object: product,
                                    keyValue: "name",
                                    objectParameter: product.name,
                                    newParameter: productName)
        RealmDataManager.changeElementIn(object: product,
                                    keyValue: "quantity",
                                    objectParameter: product.quantity,
                                    newParameter: savedQuantity)
        RealmDataManager.changeElementIn(object: product,
                                    keyValue: "measure",
                                    objectParameter: product.measure,
                                    newParameter: savedMeasure)
        
        if let date = Configuration.createDateFromString(newDate) {
            RealmDataManager.changeElementIn(object: product,
                                             keyValue: "expirationDate",
                                             objectParameter: product.expirationDate,
                                             newParameter: date)
        }
        
        CloudManager.updateChildInCloud(childObject: product)
    }
}

class RecipeGroupEditViewModel: DetailViewModelType {
    
}
