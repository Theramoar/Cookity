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

enum Measures: String, CaseIterable {
    case pieces = "Pieces"
    case litres = "Litres"
    case mililitres = "Mililiters"
    case grams = "Grams"
    case kilograms = "Kilograms"
}

class TextFieldCell: UITableViewCell{
    
    @IBOutlet weak var insertProduct: UITextField!
    @IBOutlet weak var insertQuantity: UITextField!
    @IBOutlet weak var insertMeasure: UITextField!
    let measures = Measures.allCases
    var delegate: TextFieldDelegate?
    
    
    override func awakeFromNib() {

        let measurePicker = UIPickerView()
        measurePicker.delegate = self
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




//MARK: - Extension for measure TextField UIPickerView
extension TextFieldCell: UIPickerViewDataSource, UIPickerViewDelegate{

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return measures.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return measures[row].rawValue
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        insertMeasure.text = measures[row].rawValue
    }
}
