//
//  PopupEditViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 07/11/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift

protocol PopUpDelegate {
    func updateView()
}

class PopupEditViewController: UIViewController, UITextFieldDelegate {

    let realm = try! Realm()
    let config = Configuration()
    var selectedProduct: Product?
    var delegate: PopUpDelegate?
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
        
        if let product = selectedProduct{
            var (presentedQuantity, presentedMeasure) = config.presentNumbers(quantity: product.quantity, measure: product.measure)
            presentedMeasure = config.configMeasure(measure: presentedMeasure)
            
            nameText.text = product.name
            quantityText.text = presentedQuantity
            measureText.text = presentedMeasure
        }
       
    }
    
    @objc func viewTapped() {
       self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    
    @IBAction func doneButtonPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "title", message: "message", preferredStyle: .alert)
        let action = UIAlertAction(title: "Okay", style: .cancel) { (_) in
            return
        }
        alert.addAction(action)

        guard nameText.text != "" else {
            alert.title = "No Name"
            alert.message = "Please enter product name"
            present(alert, animated: true, completion: nil)
            return
        }

        guard quantityText.text != "" else {
            alert.title = "No Quantity"
            alert.message = "Please enter product quantity"
            present(alert, animated: true, completion: nil)
            return
        }

        guard Float(quantityText.text!) != nil else {
            alert.title = "Incorrect Quantity"
            alert.message = "Please enter the quantity in numbers"
            present(alert, animated: true, completion: nil)
            return
        }

        let measure = config.configMeasure(measure: measureText.text!)
        let (savedQuantity, savedMeasure) = config.configNumbers(quantity: quantityText.text!, measure: measure)

        do{
            try realm.write {
                selectedProduct?.name = nameText.text!
                selectedProduct?.quantity = savedQuantity
                selectedProduct?.measure = savedMeasure
            }
        }catch{
            print("Error while updating items \(error)")
        }
        delegate?.updateView()
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
