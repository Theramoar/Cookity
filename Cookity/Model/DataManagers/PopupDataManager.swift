//
//  PopupDataManager.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 07/10/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import Foundation


class PopupDataManager: DataManager {
    
    func configVCData() -> (String, String, String) {
        guard let product = products.first else { return ("Product", "2", "Pieces")}
        var (presentedQuantity, presentedMeasure) = Configuration.presentNumbers(quantity: product.quantity, measure: product.measure)
        presentedMeasure = Configuration.configMeasure(measure: presentedMeasure)
        return (product.name, presentedQuantity, presentedMeasure)
    }
    
    func changeProduct(_ product: Product, newName productName: String, newQuantity productQuantity: String, newMeasure productMeasure: String) {
        
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
        CloudManager.updateProductInCloud(product: product)
    }
}
