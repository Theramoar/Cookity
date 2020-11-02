//
//  DefaultDatePickerCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 21/04/2020.
//  Copyright © 2020 Mihails Kuznecovs. All rights reserved.
//

import UIKit

protocol DatePickerAnimator {
    func rotateArrow()
}

class DefaultDatePickerCell: UITableViewCell {

    @IBOutlet weak var datePickerHeight: NSLayoutConstraint!
    @IBOutlet weak var defaultDateButton: UIButton!
    @IBOutlet weak var arrowImageView: UIImageView!
    var delegate: UpdateVCDelegate?
    var animator: DatePickerAnimator?
    
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
    
    var datePickerShown = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        arrowImageView.image = UIImage(systemName: "chevron.left")?.withTintColor(Colors.appColor!)
        selectionStyle = .none
        defaultDatePicker.isHidden = true
        datePickerHeight.constant = 0
        defaultDateButton.setTitle("\(SettingsVariables.defaultExpirationDate) days since product purchase", for: .normal)
    }
    
    @IBAction func defaultButtonPressed(_ sender: Any) {
        defaultDatePicker.isHidden.toggle()
        datePickerHeight.constant = defaultDatePicker.isHidden ? 0 : 150
        animator?.rotateArrow()
//        delegate?.updateVC()
//        NotificationCenter.default.post(name: .datePickerWasToggled, object: nil)
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
