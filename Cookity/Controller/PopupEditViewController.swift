//
//  PopupEditViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 07/11/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit


class PopupEditViewController: UIViewController, UITextFieldDelegate, MeasurePickerDelegate {

    private let dataManager = RealmDataManager()
    
    var selectedProduct: Product?
    var parentVC: UIViewController?
    let measures = Measures.allCases
    
    @IBOutlet weak var editView: UIView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var measureText: UITextField!
    @IBOutlet weak var quantityText: UITextField!
    
    var pickedMeasure: String? {
        didSet {
            measureText.text = pickedMeasure
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameText.delegate = self
        quantityText.delegate = self
    
        let measurePicker = MeasurePicker()
        measurePicker.mpDelegate = self
        measureText.inputView = measurePicker
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
        dataManager.loadFromRealm(vc: self, parentObject: selectedProduct)
        
        let size = CGSize(width: 30, height: 30)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = UIBezierPath(roundedRect: editView.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: size).cgPath
        editView.layer.mask = shapeLayer
    }
    
    
    @objc func viewTapped() {
       self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    
    @IBAction func doneButtonPressed(_ sender: UIButton) {
        
        guard let productName = nameText.text,
            let productQuantity = quantityText.text,
            let productMeasure = measureText.text
            else { return }
        
        let alert = UIAlertController(title: "title", message: "message", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { (_) in return }
        alert.addAction(action)

        guard alert.check(data: productName, dataName: .name),
            alert.check(data: productQuantity, dataName: .quantity)
        else {
            present(alert, animated: true, completion: nil)
            return
        }

        let measure = Configuration.configMeasure(measure: productMeasure)
        let (savedQuantity, savedMeasure) = Configuration.configNumbers(quantity: productQuantity, measure: measure)
        
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
