//
//  Alert.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 10/03/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit

extension UIAlertController {
    
    func checkData(productName: String, productQuantity: String) -> Bool {
        let action = UIAlertAction(title: "Okay", style: .cancel) { (_) in
            return
        }
        self.addAction(action)
        
        guard productName != "" else {
            self.title = "No Name"
            self.message = "Please enter product name"
            return false
        }
        
        guard productQuantity != "" else {
            self.title = "No Quantity"
            self.message = "Please enter product quantity"
            return false
        }
        
        guard Float(productQuantity) != nil else {
            self.title = "Incorrect Quantity"
            self.message = "Please enter the quantity in numbers"
            return false
        }
        return true
    }
}
