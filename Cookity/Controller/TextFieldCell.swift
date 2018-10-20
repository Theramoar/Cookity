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
    func saveProduct (productName: String, productQuantity: String)
}

class TextFieldCell: UITableViewCell {

    @IBOutlet weak var insertProduct: UITextField!
    @IBOutlet weak var insertQuantity: UITextField!
    
    let realm = try! Realm()
    var delegate: TextFieldDelegate?

    @IBAction func addButtonPressed(_ sender: UIButton) {
        
        if let nameText = insertProduct?.text, let quantityText = insertQuantity?.text{
           delegate?.saveProduct(productName: nameText, productQuantity: quantityText)
        } else {
            fatalError("Fatal Error in the text fields")
        }
        insertProduct.text = ""
        insertQuantity.text = ""
    }
    

}
