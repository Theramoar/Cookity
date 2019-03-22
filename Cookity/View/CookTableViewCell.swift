//
//  CookTableViewCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 30/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import SwipeCellKit

class CookTableViewCell: SwipeTableViewCell {
    
    let measures = Measures.allCases
    
    @IBOutlet weak var productName: UITextField!
    @IBOutlet weak var productMeasure: UITextField!
    @IBOutlet weak var quantityForRecipe: UITextField!
    
    
    var product: Product! {
        didSet{
            let measure = Configuration.configMeasure(measure: product.measure)
            productName.text = product.name
            quantityForRecipe.text = "\(product.quantity)"
            productMeasure.text = measure
        }
    }
    
    override func awakeFromNib() {
        let measurePicker = UIPickerView()
        measurePicker.delegate = self
        productMeasure?.inputView = measurePicker
        
        self.selectionStyle = .none
    }
}


extension CookTableViewCell: UIPickerViewDataSource, UIPickerViewDelegate{

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
        productMeasure.text = measures[row].rawValue
    }
}
