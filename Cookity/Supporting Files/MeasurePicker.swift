//
//  MeasurePicker.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 20/03/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit


protocol MeasurePickerDelegate {
    var pickedMeasure: String? { get set }
}

enum Measures: String, CaseIterable {
    case pieces = "Pieces"
    case litres = "Litres"
    case mililitres = "Mililiters"
    case grams = "Grams"
    case kilograms = "Kilograms"
}

class MeasurePicker: UIPickerView, UIPickerViewDataSource, UIPickerViewDelegate {

    let measures = Measures.allCases
    var mpDelegate: MeasurePickerDelegate?
    var pickedMeasure: String? {
        didSet {
            mpDelegate?.pickedMeasure = pickedMeasure
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.delegate = self
        self.dataSource = self
    }
    
//MARK: - UIPickerViewDataSource, UIPickerViewDelegate Methods
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
        pickedMeasure = measures[row].rawValue
    }

}
