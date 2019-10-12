//
//  ListViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 03/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift
import SwipeCellKit


class CartViewController: SwipeTableViewController, MeasurePickerDelegate, IsEditedDelegate {
    
    @IBOutlet var cartDataManager: CartDataManager!
    @IBOutlet var productsTable: UITableView!
    @IBOutlet var productTextField: UITextField!
    @IBOutlet var quantityTextField: UITextField!
    @IBOutlet var measureTextField: UITextField!
    @IBOutlet var tfView: TextFieldView!
    @IBOutlet var addButton: UIButton!
    @IBOutlet weak var tfHeightConstraint: NSLayoutConstraint!
    
    // не надо
    var measurePicker: MeasurePicker!
    var selectedIndexPath: IndexPath? //variable is used to store the IndexPath selected by LongTap Gesture
    
    // used for to disable touches while textfield are edited.
    var isEdited: Bool = false {
        didSet {
            if isEdited == true {
                productsTable.allowsSelection = false
            }
            else {
                productsTable.allowsSelection = true
            }
        }
    }

    var pickedMeasure: String? {
        didSet {
            measureTextField.text = pickedMeasure
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = cartDataManager.selectedCart?.name
        productsTable.delegate = self
        productsTable.dataSource = self
        productsTable.separatorStyle = .none
        productsTable.rowHeight = 45
        
        tfView.delegate = self
        tfView.heightConstraint = tfHeightConstraint
        tfView.initialHeight = tfHeightConstraint.constant
        
        productTextField.delegate = self
        quantityTextField.delegate = self
        measureTextField.delegate = self

        measurePicker = MeasurePicker()
        measurePicker.mpDelegate = self
        measureTextField.inputView = measurePicker
        
        quantityTextField.keyboardType = .decimalPad
        productTextField.autocapitalizationType = .sentences
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)

        //add long gesture recognizer
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressed))
        self.view.addGestureRecognizer(longPressRecognizer)
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        UIView.setAnimationsEnabled(true)
        self.view.endEditing(true)
        return true
    }
    
    
    @objc func viewTapped(sender: UITapGestureRecognizer) {
        //wait for isEdited to change its value
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if self.isEdited == false {
                self.productsTable.allowsSelection = true
            }
            UIView.setAnimationsEnabled(true)
            self.view.endEditing(true)
            self.isEdited = false
        }
    }
    
    
    @objc func longPressed(longPressRecognizer: UILongPressGestureRecognizer) {
        // find the IndexPath of the cell which was "longtouched"
        let touchPoint = longPressRecognizer.location(in: self.productsTable)
        selectedIndexPath = productsTable.indexPathForRow(at: touchPoint)
        if selectedIndexPath != nil {
            performSegue(withIdentifier: "popupEdit", sender: self)
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! PopupEditViewController
        if let indexPath = selectedIndexPath, let product = cartDataManager.selectedCart?.products[indexPath.row] {
//            destinationVC.selectedProduct = product
            destinationVC.popupDataManager.products.append(product)
            destinationVC.parentVC = self
        }
    }
    
    
    @IBAction func shareButtonPressed(_ sender: UIBarButtonItem) {
        let activityController = cartDataManager.shareCart()
        guard let activity = activityController else { return }
        activity.popoverPresentationController?.barButtonItem = sender
        present(activity, animated: true, completion: nil)
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
        let alert = cartDataManager.checkDataFromTextFields(productName: nameText, productQuantity: quantityText, productMeasure: measureText)
        if let alert = alert {
            present(alert, animated: true, completion: nil)
            return false
        }
        let newProduct = cartDataManager.createNewProduct(productName: nameText, productQuantity: quantityText, productMeasure: measureText)
        cartDataManager.saveProductToCart(product: newProduct)
        productsTable.reloadData()
        return true
    }

    
    override func deleteObject(at indexPath: IndexPath) {
        cartDataManager.deleteProductFromCart(at: indexPath.row)
        productsTable.reloadData()
    }
    
}

//MARK: - Extension for TableView DataSource and Delegate Methods
extension CartViewController: UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cartDataManager.products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath) as! ProductTableViewCell
        cell.delegate = self as SwipeTableViewCellDelegate
        let item = cartDataManager.products[indexPath.row]
            cell.product = item
            cell.isChecked = item.checked
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
        
        guard cartDataManager.checkProduct(at: indexPath.row) else {
            tableView.reloadData()
            return
        }
        tableView.reloadData()

        let alert = UIAlertController(title: "Add products to the fridge?", message: "", preferredStyle: .actionSheet)
        let yesAction = UIAlertAction(title: "Yes", style: .default) { (_) in
            guard let cart = self.cartDataManager.selectedCart else { return }
            self.cartDataManager.moveProductsToFridge(from: cart)
            if let nav = self.navigationController {
                nav.popToRootViewController(animated: true)
            }
            self.dismiss(animated: true, completion: nil)
        }
        let noAction = UIAlertAction(title: "No", style: .default) { (_) in
            return
        }
        alert.addAction(yesAction)
        alert.addAction(noAction)
        present(alert, animated: true, completion: nil)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
