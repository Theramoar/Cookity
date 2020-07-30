//
//  DefaultDatePickerCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 21/04/2020.
//  Copyright © 2020 Mihails Kuznecovs. All rights reserved.
//

import UIKit

class DefaultDatePickerCell: UITableViewCell {

    @IBOutlet weak var defaultDateButton: UIButton!
    var delegate: UpdateVCDelegate?
    
    @IBOutlet weak var defaultDatePicker: UIPickerView! {
        didSet {
            defaultDatePicker.delegate = self
            defaultDatePicker.dataSource = self
        }
    }
    
    var pickerDates: [Int] {
        var pickerDates = [Int]()
        for i in 1 ... 60 {
            pickerDates.append(i)
        }
        return pickerDates
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        defaultDatePicker.isHidden = true
        defaultDateButton.setTitle("\(SettingsVariables.defaultExpirationDate) days since product purchase", for: .normal)
    }
    
    @IBAction func defaultButtonPressed(_ sender: Any) {
        defaultDatePicker.isHidden = !defaultDatePicker.isHidden
        delegate?.updateVC()
    }
    
    
}

extension DefaultDatePickerCell: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        60
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return row == 0 ? "\(pickerDates[row]) day" : "\(pickerDates[row]) days"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        defaultDateButton.setTitle("\(pickerDates[row]) days since product purchase", for: .normal)
        SettingsVariables.defaultExpirationDate = pickerDates[row]
        delegate?.updateVC()
    }
}
