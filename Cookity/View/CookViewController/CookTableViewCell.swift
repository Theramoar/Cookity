//
//  CookTableViewCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 30/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import SwipeCellKit

class CookTableViewCell: SwipeTableViewCell, MeasurePickerDelegate {
    
//    @IBOutlet weak var productName: UITextField!
//    @IBOutlet weak var productMeasure: UITextField!
//    @IBOutlet weak var quantityForRecipe: UITextField!
    
    
    @IBOutlet weak var productName: UITextField!
    @IBOutlet weak var productMeasure: UITextField!
    @IBOutlet weak var quantityForRecipe: UITextField!
    
    var pickedMeasure: String? {
        didSet {
            productMeasure.text = pickedMeasure
        }
    }
    
    override func awakeFromNib() {
        let measurePicker = MeasurePicker()
        measurePicker.mpDelegate = self
        productMeasure?.inputView = measurePicker
        self.selectionStyle = .none
        quantityForRecipe.keyboardType = .decimalPad
    }
}
