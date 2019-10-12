//
//  PopupEditViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 07/11/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit


class PopupEditViewController: UIViewController, UITextFieldDelegate, MeasurePickerDelegate, IsEditedDelegate {
    
    
    var isEdited: Bool = false {
        didSet {
            print(isEdited)
        }
    }
    
//    var selectedProduct: Product?
    var parentVC: UIViewController?
    let measures = Measures.allCases
    
    var panStartPoint = CGPoint(x: 0, y: 0)
    var panEndPoint = CGPoint(x: 0, y: 0)
    
    
    @IBOutlet var popupDataManager: PopupDataManager!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var editView: EditTextView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var measureText: UITextField!
    @IBOutlet weak var quantityText: UITextField!
    
    @IBOutlet weak var editViewHeight: NSLayoutConstraint!
    
    var pickedMeasure: String? {
        didSet {
            measureText.text = pickedMeasure
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
 
        nameText.delegate = self
        quantityText.delegate = self
        nameText.autocapitalizationType = .sentences
        measureText.autocapitalizationType = .sentences
        
        editView.delegate = self
        editView.heightConstraint = editViewHeight
        editView.initialHeight = editViewHeight.constant
    
        let measurePicker = MeasurePicker()
        measurePicker.mpDelegate = self
        measureText.inputView = measurePicker
        
        quantityText.keyboardType = .decimalPad
        quantityText.autocapitalizationType = .sentences
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        tapGesture.cancelsTouchesInView = false
        self.editView.addGestureRecognizer(tapGesture)
        

        let dismissTapGesture = UIPanGestureRecognizer(target: self, action: #selector(backgroundViewDragged))
        dismissTapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(dismissTapGesture)
        
        let (name, quantity, measure) = popupDataManager.configVCData()
        nameText.text = name
        quantityText.text = quantity
        measureText.text = measure
        
    }
    
    override func viewDidLayoutSubviews() {
        let size = CGSize(width: 20, height: 20)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = UIBezierPath(roundedRect: editView.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: size).cgPath
        editView.layer.mask = shapeLayer
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let parentVC = parentVC {
            DecorationHandler.putShadowOnView(vc: parentVC)
        }
    }
    
    @objc func backgroundViewDragged(sender: UITapGestureRecognizer) {
        switch sender.state {
            case .began:
                panStartPoint = sender.location(in: view)
            case .ended:
                panEndPoint = sender.location(in: view)
            default:
                break
        }
        guard (panEndPoint.y - panStartPoint.y) > 40, abs(panStartPoint.x - panEndPoint.x) < 40 else { return }
        
        if self.isEdited {
            self.view.endEditing(true)
            return
        }
        else {
            shadow.removeFromSuperview()
            self.dismiss(animated: true, completion: nil)
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
        
        guard let productName = nameText.text,
            let productQuantity = quantityText.text,
            let productMeasure = measureText.text
            else { return }
        
        let alert = popupDataManager.checkDataFromTextFields(productName: productName, productQuantity: productQuantity, productMeasure: productMeasure)
        if let alert = alert {
            present(alert, animated: true, completion: nil)
            return
        }
        guard let product = popupDataManager.products.first else { return }
        popupDataManager.changeProduct(product, newName: productName, newQuantity: productQuantity, newMeasure: productMeasure)
        
        if let parentVC = parentVC as? CartViewController {
            parentVC.productsTable.reloadData()
        }
        else if let parentVC = parentVC as? FridgeViewController {
            parentVC.fridgeTableView.reloadData()
        }
        shadow.removeFromSuperview()
        self.dismiss(animated: true, completion: nil)
    }
}
