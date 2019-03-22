//
//  MeasurePicker.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 20/03/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit

//доделать

class MeasurePicker: UIPickerView, UIPickerViewDataSource, UIPickerViewDelegate {

    let measures = Measures.allCases
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return measures.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return measures[row].rawValue
    }
    
//    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//    }

}
