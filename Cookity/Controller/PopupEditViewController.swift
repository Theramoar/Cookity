//
//  PopupEditViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 07/11/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit


class PopupEditViewController: UIViewController, UITextFieldDelegate {

    private let config = Configuration()
    private let dataManager = RealmDataManager()
    
    var selectedProduct: Product?
    var parentVC: UIViewController?
    let measuresArray = ["Pieces", "Litres", "Mililiters", "Grams", "Kilograms"]
    
    @IBOutlet weak var editView: UIView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var measureText: UITextField!
    @IBOutlet weak var quantityText: UITextField!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameText.delegate = self
        quantityText.delegate = self

        let measurePicker = UIPickerView()
        measurePicker.delegate = self
        measureText.inputView = measurePicker
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
        dataManager.loadFromRealm(vc: self, parentObject: selectedProduct)
    }
    
    
    @objc func viewTapped() {
       self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    
    @IBAction func doneButtonPressed(_ sender: UIButton) {
        
        guard let productName = nameText.text, let productQuantity = quantityText.text else { return }
        
        let alert = UIAlertController(title: "title", message: "message", preferredStyle: .alert)
        let dataIsCorrect = alert.checkData(productName: productName, productQuantity: productQuantity)
        guard dataIsCorrect else {
            present(alert, animated: true, completion: nil)
            return
        }
        
        let measure = config.configMeasure(measure: measureText.text!)
        let (savedQuantity, savedMeasure) = config.configNumbers(quantity: productQuantity, measure: measure)
        
        guard let selectedProduct = selectedProduct else { return }
        dataManager.changeElementIn(object: selectedProduct,
                                    keyValue: "name",
                                    objectParameter: selectedProduct.name,
                                    newParameter: productName)
        dataManager.changeElementIn(object: selectedProduct,
                                    keyValue: "quantity",
                                    objectParameter: selectedProduct.quantity,
                                    newParameter: savedQuantity)
        dataManager.changeElementIn(object: selectedProduct,
                                    keyValue: "measure",
                                    objectParameter: selectedProduct.measure,
                                    newParameter: savedMeasure)
        
        if let parentVC = parentVC as? CartViewController {
            parentVC.tableView.reloadData()
        }
        else if let parentVC = parentVC as? FridgeViewController {
            parentVC.fridgeTableView.reloadData()
        }
        self.dismiss(animated: true, completion: nil)
    }
}





extension PopupEditViewController: UIPickerViewDataSource, UIPickerViewDelegate{
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return measuresArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return measuresArray[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        measureText.text = measuresArray[row]
    }
}
