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
    var updateVCDelegate: UpdateVCDelegate?
    
    var panStartPoint = CGPoint(x: 0, y: 0)
    var panEndPoint = CGPoint(x: 0, y: 0)
    
    
    var viewModel: AddCartViewModel!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var productTextField: UITextField!
    @IBOutlet weak var quantityTextField: UITextField!
    @IBOutlet weak var measureTextField: UITextField!
    @IBOutlet weak var cartNameTextField: UITextField!
    @IBOutlet weak var visibleView: UIView!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var tfView: TextFieldView!
    @IBOutlet weak var tfHeight: NSLayoutConstraint!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var tfViewBottomConstraint: NSLayoutConstraint!
    
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
        tableView.separatorStyle = .none
        tableView.rowHeight = 45
        tableView.register(UINib(nibName: "ProductCell", bundle: nil), forCellReuseIdentifier: "ProductCell")
        
        tfView.heightConstraint = tfHeight
        tfView.initialHeight = tfHeight.constant
        
        productTextField.delegate = self
        quantityTextField.delegate = self
        measureTextField.delegate = self
        cartNameTextField.delegate = self
        productTextField.autocapitalizationType = .sentences
        cartNameTextField.autocapitalizationType = .sentences
        
        let image = UIImage(systemName: "plus.circle")?.withTintColor(Colors.appColor!, renderingMode: .alwaysOriginal)
        addButton.setImage(image, for: .normal)
        
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
        
        setupTextFieldBottomConstraint()
    }
    
    
    private func setupTextFieldBottomConstraint() {
        //Add to TF bottomConstraint lower safe area height, so it looks the same on iPhone 8 and iPhone X models
        let window = UIApplication.shared.windows[0]
        let bottomPadding = window.safeAreaInsets.bottom
        tfViewBottomConstraint.constant = bottomPadding
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let size = CGSize(width: 20, height: 20)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = UIBezierPath(roundedRect: visibleView.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: size).cgPath
        visibleView.layer.mask = shapeLayer

        guard viewModel.numberOfRows > 0 else { return }
        let indexPath = IndexPath(row: viewModel.numberOfRows - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
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
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if textField == productTextField, let text = textField.text {
            quantityTextField.placeholder = text.isEmpty ? "How much?" : "1"
            measureTextField.placeholder = text.isEmpty ? "Measure?" : "Piece"
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        UIView.setAnimationsEnabled(true)
        self.view.endEditing(true)
        return true
    }
    
    func dismissView() {
        updateVCDelegate?.updateVC()
        shadow.removeFromSuperview()
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK:- Methods for Buttons
    @IBAction func doneButtonPresed(_ sender: UIButton) {
        guard let cartName = cartNameTextField.text, cartName != "" else { return }
        viewModel.saveCart(name: cartName)
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
        
        let alert = viewModel.checkDataFromTextFields(productName: nameText, productQuantity: quantityText, productMeasure: measureText)
        if let alert = alert {
            present(alert, animated: true, completion: nil)
            return false
        }
        
        viewModel.createNewProduct(productName: nameText, productQuantity: quantityText, productMeasure: measureText)
        tableView.insertRows(at: [IndexPath(row: viewModel.numberOfRows-1, section: 0)], with: .right)
        return true
    }
    
    //MARK:- Data Manipulation Products
    override func deleteObject(at indexPath: IndexPath) {
        viewModel.deleteProductFromCart(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .right)
    }
}



extension AddCartViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath) as! ProductTableViewCell
        cell.delegate = self as SwipeTableViewCellDelegate
        cell.viewModel = viewModel.cellViewModel(forIndexPath: indexPath) as? ProductTableCellViewModel
        return cell
    }
    

}
