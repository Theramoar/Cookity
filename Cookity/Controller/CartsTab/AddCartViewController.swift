//
//  AddCartViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 24/03/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import SwipeCellKit



class AddCartViewController: SwipeTableViewController, UITextFieldDelegate, MeasurePickerDelegate, IsEditedDelegate {
    
    let textFieldView = TextFieldView()
    var parentVC: UIViewController?
    
    var panStartPoint = CGPoint(x: 0, y: 0)
    var panEndPoint = CGPoint(x: 0, y: 0)
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var productTextField: UITextField!
    @IBOutlet weak var quantityTextField: UITextField!
    @IBOutlet weak var measureTextField: UITextField!
    @IBOutlet weak var cartNameTextField: UITextField!
    @IBOutlet weak var visibleView: UIView!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var tfView: TextFieldView!
    @IBOutlet weak var tfHeight: NSLayoutConstraint!
    
    
    
    var products = [Product]()
    var pickedMeasure: String? {
        didSet {
            measureTextField.text = pickedMeasure
        }
    }
    
    // used for to disable touches while textfield are edited.
    var isEdited: Bool = false {
        didSet {
            if isEdited == true {
                tableView.allowsSelection = false
            }
            else {
                tableView.allowsSelection = true
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .none
        tableView.rowHeight = 45
        
        tfView.heightConstraint = tfHeight
        tfView.initialHeight = tfHeight.constant
        
        productTextField.delegate = self
        quantityTextField.delegate = self
        measureTextField.delegate = self
        cartNameTextField.delegate = self
        productTextField.autocapitalizationType = .sentences
        cartNameTextField.autocapitalizationType = .sentences
        
        let measurePicker = MeasurePicker()
        measurePicker.mpDelegate = self
        measureTextField.inputView = measurePicker
        
        quantityTextField.keyboardType = .decimalPad
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        tapGesture.cancelsTouchesInView = false
        self.tableView.addGestureRecognizer(tapGesture)
        
        let dismissTapGesture = UIPanGestureRecognizer(target: self, action: #selector(backgroundViewDragged))
        dismissTapGesture.cancelsTouchesInView = false
        self.backgroundView.addGestureRecognizer(dismissTapGesture)
    }
    
    
    
    override func viewDidLayoutSubviews() {
        let size = CGSize(width: 20, height: 20)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = UIBezierPath(roundedRect: visibleView.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: size).cgPath
        visibleView.layer.mask = shapeLayer
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
        
        dismissView()
    }
    
    @objc func viewTapped(sender: UITapGestureRecognizer) {
        //wait for isEdited to change its value
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if self.isEdited == false {
                self.tableView.allowsSelection = true
            }
            UIView.setAnimationsEnabled(true)
            self.view.endEditing(true)
            self.isEdited = false
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        UIView.setAnimationsEnabled(true)
        self.view.endEditing(true)
        return true
    }
    
    func dismissView() {
        if let parentVC = parentVC as? CartCollectionViewController {
            parentVC.tableView.reloadData()
            shadow.removeFromSuperview()
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK:- Methods for Buttons
    @IBAction func doneButtonPresed(_ sender: UIButton) {
        guard let cartName = cartNameTextField.text, cartName != "" else { return }
        saveCart(name: cartName)
        dismissView()
    }
    
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        dismissView()
    }
    
    @IBAction func addButtonPressed(_ sender: UIButton) {
        UIView.setAnimationsEnabled(true)
        guard addProduct() else { return }
        productTextField.text = ""
        quantityTextField.text = ""
        measureTextField.text = ""
    }
    
    func addProduct() -> Bool {
        guard let nameText = productTextField?.text,
            let quantityText = quantityTextField?.text,
            let measureText = measureTextField.text
            else { return false }
        
        if saveProduct(productName: nameText, productQuantity: quantityText, productMeasure: measureText) {
            return true
        }
        return false
    }
    
    //MARK:- Data Manipulation Products
    func saveProduct(productName: String, productQuantity: String, productMeasure: String) -> Bool {
        let newProduct = Product()
        
        let alert = UIAlertController(title: "title", message: "message", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { (_) in return }
        alert.addAction(action)
        
        guard alert.check(data: productName, dataName: AlertMessage.name),
            alert.check(data: productQuantity, dataName: AlertMessage.quantity)
            else {
                present(alert, animated: true, completion: nil)
                return false
        }
        
        let measure = Configuration.configMeasure(measure: productMeasure)
        let (savedQuantity, savedMeasure) = Configuration.configNumbers(quantity: productQuantity, measure: measure)
        
        newProduct.name = productName
        newProduct.quantity = savedQuantity
        newProduct.measure = savedMeasure
        products.append(newProduct)
        tableView.reloadData()
        return true
    }
    
    func saveCart(name: String) {
        let cart = ShoppingCart()
        cart.name = name
        for product in products {
            cart.products.append(product)
        }
        RealmDataManager.saveToRealm(parentObject: nil, object: cart)
    }
    
    override func deleteObject(at indexPath: IndexPath) {
        products.remove(at: indexPath.row)
        tableView.reloadData()
    }
    
}



extension AddCartViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath) as! ProductTableViewCell
        cell.delegate = self as SwipeTableViewCellDelegate
        cell.product = products[indexPath.row]
        return cell
    }
    

}
