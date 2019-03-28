//
//  TextFieldCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 08/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit


protocol TextFieldDelegate {
    func saveProduct (productName: String, productQuantity: String, productMeasure: String)
}

class TextFieldCell: UITableViewCell, MeasurePickerDelegate{
    
    @IBOutlet weak var insertProduct: UITextField!
    @IBOutlet weak var insertQuantity: UITextField!
    @IBOutlet weak var insertMeasure: UITextField!
    var delegate: TextFieldDelegate?
    
    var pickedMeasure: String? {
        didSet {
            insertMeasure.text = pickedMeasure
        }
    }
    
    override func awakeFromNib() {

        let measurePicker = MeasurePicker()
        measurePicker.mpDelegate = self
        insertMeasure.inputView = measurePicker
    }
    
    
    @IBAction func addButtonPressed(_ sender: UIButton) {
        if let nameText = insertProduct?.text, let quantityText = insertQuantity?.text, let measureText = insertMeasure.text{
           delegate?.saveProduct(productName: nameText, productQuantity: quantityText, productMeasure: measureText)
        } else {
            fatalError("Fatal Error in the text fields")
        }
        insertProduct.text = ""
        insertQuantity.text = ""
    }
}
