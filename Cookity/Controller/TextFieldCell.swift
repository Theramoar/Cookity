//
//  TextFieldCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 08/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift


protocol TextFieldDelegate {
    func saveProduct (newProduct: Product)
}

class TextFieldCell: UITableViewCell {

    @IBOutlet weak var insertProduct: UITextField!
    @IBOutlet weak var insertQuantity: UITextField!
    
    let realm = try! Realm()
    var delegate: TextFieldDelegate?

    // Привести всё в порядок!!!
    @IBAction func addButtonPressed(_ sender: UIButton) {
        
        let newProduct = Product()
        
        if let productText = insertProduct.text{
            newProduct.name = productText
        } else{
            fatalError("Product name is not inserted")
        }
        
        if let quantityText = insertQuantity.text{
            newProduct.quantity = Int(quantityText) ?? 0
        } else{
            fatalError("Product quantity is not inserted")
        }
        
        delegate?.saveProduct(newProduct: newProduct)
        insertProduct.text = ""
        insertQuantity.text = ""
    }
}
