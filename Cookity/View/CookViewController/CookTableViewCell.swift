//
//  CookTableViewCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 30/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import SwipeCellKit

class CookTableViewCell: UITableViewCell, MeasurePickerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var productName: UITextField!
    @IBOutlet weak var productMeasure: UITextField!
    @IBOutlet weak var quantityForRecipe: UITextField!
    
    var pickedMeasure: String? {
        didSet {
            productMeasure.text = pickedMeasure
        }
    }
    var viewModel: CookCellViewModel? {
        willSet(viewModel) {
            guard let viewModel = viewModel else { return }
            productName.delegate = self
            productMeasure.delegate = self
            quantityForRecipe.delegate = self
            
            productName.text = viewModel.productName
            quantityForRecipe.text = viewModel.productQuantity
            productMeasure.text = viewModel.productMeasure
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let viewModel = viewModel,
            var text = textField.text
        else { return }
        
        if text.isEmpty {
            textField.text = viewModel.userEnteredString
            return
        }
        text = text.replacingOccurrences(of: ",", with: ".")
        if viewModel.userEditedTextField == .quantity, Float(text) == nil {
            textField.text = viewModel.userEnteredString
            return
        }
        viewModel.userEnteredString = text
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        viewModel?.userEnteredString = textField.text ?? ""
        if productName.isEditing {
            viewModel?.userEditedTextField = .name
        }
        else if productMeasure.isEditing {
            viewModel?.userEditedTextField = .measure
        }
        else if quantityForRecipe.isEditing {
             viewModel?.userEditedTextField = .quantity
        }
    }

    override func awakeFromNib() {
        let measurePicker = MeasurePicker()
        measurePicker.mpDelegate = self
        productMeasure?.inputView = measurePicker
        self.selectionStyle = .none
        quantityForRecipe.keyboardType = .decimalPad
        productName.autocapitalizationType = .sentences
    }
}

enum EditedTextField {
    case name
    case quantity
    case measure
    case none
}
class CookCellViewModel: CellViewModelType {
    private var product: Product
    var productMeasure: String {
        Configuration.configMeasure(measure: product.measure)
    }
    var productQuantity: String {
        String(product.quantity)
    }
    var productName: String {
        product.name
    }
    
    var userEditedTextField: EditedTextField = .none
    var userEnteredString: String = "" {
        didSet {
            switch userEditedTextField {
            case .name:
//                RealmDataManager.changeElementIn(object: product, keyValue: "name", objectParameter: product.name, newParameter: userEnteredString)
                product.name = userEnteredString
            case .quantity:
                let (newQuantity, newMeasure) = Configuration.configNumbers(quantity: userEnteredString, measure: product.measure)
                product.quantity = newQuantity
                product.measure = newMeasure
            case .measure:
                let measure = Configuration.configMeasure(measure: userEnteredString)
                product.measure = measure
//                RealmDataManager.changeElementIn(object: product, keyValue: "measure", objectParameter: product.measure, newParameter: measure)
            case .none:
                return
            }
            userEditedTextField = .none
        }
    }
    
    init(product: Product) {
        self.product = product
    }
}
