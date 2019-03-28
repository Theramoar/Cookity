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
    
    
    var productsInFridge: Results<Product>?
    var products: Results<Product>?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var productTextField: UITextField!
    @IBOutlet weak var quantityTextField: UITextField!
    @IBOutlet weak var measureTextField: UITextField!
    @IBOutlet weak var tfView: TextFieldView!
    @IBOutlet weak var addButton: UIButton!
    
    // не надо
    var measurePicker: MeasurePicker!
    var selectedIndexPath: IndexPath? //variable is used to store the IndexPath selected by LongTap Gesture
    
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

    var selectedCart: ShoppingCart?{
        didSet{
            dataManager.loadFromRealm(vc: self, parentObject: selectedCart)
        }
    }
    
    var pickedMeasure: String? {
        didSet {
            measureTextField.text = pickedMeasure
        }
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        title = selectedCart?.name
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        
        tfView.delegate = self
//        self.view.addSubview(tfView)
        
        productTextField.delegate = self
        quantityTextField.delegate = self
        measureTextField.delegate = self

        measurePicker = MeasurePicker()
        measurePicker.mpDelegate = self
        measureTextField.inputView = measurePicker
        
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            if self.isEdited == false {
                self.tableView.allowsSelection = true
            }
            UIView.setAnimationsEnabled(true)
            self.view.endEditing(true)
            self.isEdited = false
        }
    }
    
    @objc func longPressed(longPressRecognizer: UILongPressGestureRecognizer) {
        // find the IndexPath of the cell which was "longtouched"
        let touchPoint = longPressRecognizer.location(in: self.tableView)
        selectedIndexPath = tableView.indexPathForRow(at: touchPoint)
        if selectedIndexPath != nil {
            performSegue(withIdentifier: "popupEdit", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! PopupEditViewController
        if let indexPath = selectedIndexPath, let product = products?[indexPath.row] {
            destinationVC.selectedProduct = product
            destinationVC.parentVC = self
        }
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
    
    
    func saveProduct(productName: String, productQuantity: String, productMeasure: String) -> Bool
    {
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
        
        if let currentCart = selectedCart {
            newProduct.name = productName
            newProduct.quantity = savedQuantity
            newProduct.measure = savedMeasure
            dataManager.saveToRealm(parentObject: currentCart, object: newProduct)
        }
        tableView.reloadData()
        return true
    }
    
    override func deleteObject(at indexPath: IndexPath) {
        if let product = products?[indexPath.row] {
            dataManager.deleteFromRealm(object: product)
            tableView.reloadData()
        }
    }
    
}

//MARK: - Extension for TableView Methods
extension CartViewController: UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    //MARK: - TableView DataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

            let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath) as! ProductTableViewCell
            cell.delegate = self as SwipeTableViewCellDelegate
            if let item = products?[indexPath.row] {                
                cell.product = item
                cell.isChecked = item.checked
                
            }
            return cell
    }
    
    //MARK: - TableView Delegate Methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let product = products?[indexPath.row]{
            dataManager.changeElementIn(object: product,
                                        keyValue: "checked",
                                        objectParameter: product.checked,
                                        newParameter: !product.checked)
        }
        tableView.reloadData()
        
        //If all products are checked, App offers to add them to the Fridge
        for product in products! {
            guard product.checked == true else { return }
        }
        
        let alert = UIAlertController(title: "Add products to the fridge?", message: "", preferredStyle: .actionSheet)
        let yesAction = UIAlertAction(title: "Yes", style: .default) { (_) in
            for product in self.products! {
                //Checks if the similar product is already in the fridge
                for fridgeProduct in self.productsInFridge!{
                    // if products name and measure coincide, adds quantity and deletes product from the shopping list
                    if product.name == fridgeProduct.name && product.measure == fridgeProduct.measure{
                        let newQuantity = fridgeProduct.quantity + product.quantity
                        self.dataManager.changeElementIn(object: fridgeProduct,
                                                         keyValue: "quantity",
                                                         objectParameter: fridgeProduct.quantity,
                                                         newParameter: newQuantity)
                        self.dataManager.deleteFromRealm(object: product)
                        break
                    }
                }
                if product.isInvalidated == false{
                    self.dataManager.changeElementIn(object: product,
                                                     keyValue: "inFridge",
                                                     objectParameter: product.inFridge,
                                                     newParameter: true)
                }
                self.tableView.reloadData()
            }
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
