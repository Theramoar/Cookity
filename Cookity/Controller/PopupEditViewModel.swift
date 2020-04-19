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
    
    
    init(product: Product) {
        self.product = product
        self.presentedName = product.name
        (self.presentedQuantity, self.presentedMeasure) = Configuration.presentNumbers(quantity: product.quantity, measure: product.measure)
        self.presentedMeasure = Configuration.configMeasure(measure: self.presentedMeasure)
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
    
    
    
    
    func changeProduct(newName productName: String, newQuantity productQuantity: String, newMeasure productMeasure: String) {
        
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
        CloudManager.updateChildInCloud(childObject: product)
    }
}
