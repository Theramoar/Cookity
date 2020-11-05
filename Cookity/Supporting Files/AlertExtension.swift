//
//  Alert.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 10/03/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit



enum AlertMessage: String, CaseIterable {
    case name = "Name"
    case quantity = "Quantity"
    case recipeName = "Recipe Name"
    case recipeStep = "Recipe Step"
}

extension UIAlertController {

    func check(data: String, dataName: AlertMessage) -> Bool {
        if dataName == .name, data.isEmpty {
            self.title = "\(dataName) is not entered!"
            self.message = "Enter the \(dataName)"
            return false
        }
        if dataName == .quantity {
            let quantity = data.isEmpty ? "1" : data.replacingOccurrences(of: ",", with: ".")
            guard Float(quantity) != nil else {
                self.title = "Incorrect \(dataName.rawValue)"
                self.message = "Please enter the \(dataName.rawValue) in numbers"
                return false
            }
        }
        return true
    }
}
