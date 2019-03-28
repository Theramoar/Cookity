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
    }
}
