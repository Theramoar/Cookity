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

class CartViewController: SwipeTableViewController {
    
//    let dataManager = RealmDataManager()
    var productsInFridge: Results<Product>?
    var products: Results<Product>?
    let measures = Measures.allCases
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textFieldView: UIView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var productTextField: UITextField!
    @IBOutlet weak var quantityTextField: UITextField!
    @IBOutlet weak var measureTextField: UITextField!
    
    var selectedIndexPath: IndexPath? //variable is used to store the IndexPath selected by LongTap Gesture
    var isEdited: Bool = false // used for to disable touches while textfield are edited.
    var selectedCart: ShoppingCart?{
        // didSet wil trigger once the selectedCart get set with a value
        didSet{
            dataManager.loadFromRealm(vc: self, parentObject: selectedCart)
        }
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        title = selectedCart?.name
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        
        productTextField.delegate = self
        quantityTextField.delegate = self
        measureTextField.delegate = self

        let measurePicker = UIPickerView()
        measurePicker.delegate = self
        measurePicker.dataSource = self
        measureTextField.inputView = measurePicker

        
        
        //add long gesture recognizer
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressed))
        self.view.addGestureRecognizer(longPressRecognizer)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    
    @objc func keyboardWillChangeFrame(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        guard let keyboardSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        if keyboardSize.origin.y == 667.0 {
            textFieldView.frame.origin.y = self.view.frame.height - textFieldView.frame.height
            isEdited = false
        }
        else {
            //Блок используется для того, чтобы убрать анимацию текстового поля при смене клавиатуры (чтобы текстовое поле не отрывалось от клавиатуры)
            if isEdited == true {
                UIView.setAnimationsEnabled(false)
            }
            
            textFieldView.frame.origin.y = view.frame.height - keyboardSize.height - textFieldView.frame.height
            isEdited = true
        }
    }
    
    
    @objc func viewTapped() {
        if isEdited == false {
            tableView.allowsSelection = true
        }
        UIView.setAnimationsEnabled(true)
        self.view.endEditing(true)
        isEdited = false
    }

    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        UIView.setAnimationsEnabled(true)
        self.view.endEditing(true)
        return true
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
        if let nameText = productTextField?.text,
            let quantityText = quantityTextField?.text,
            let measureText = measureTextField.text {
            saveProduct(productName: nameText, productQuantity: quantityText, productMeasure: measureText)
        } else {
            fatalError("Fatal Error in the text fields")
        }
        productTextField.text = ""
        quantityTextField.text = ""
        measureTextField.text = ""
        self.view.endEditing(true)
        isEdited = false
    }
    
    
    func saveProduct(productName: String, productQuantity: String, productMeasure: String)
    {
        let newProduct = Product()
       
        let alert = UIAlertController(title: "title", message: "message", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { (_) in return }
        alert.addAction(action)
        
        guard alert.check(data: productName, dataName: AlertMessage.name),
            alert.check(data: productQuantity, dataName: AlertMessage.quantity)
            else {
                present(alert, animated: true, completion: nil)
                return
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
    }
    
    override func deleteObject(at indexPath: IndexPath) {
        if let product = products?[indexPath.row] {
            dataManager.deleteFromRealm(object: product)
            tableView.reloadData()
        }
    }
    
}

//MARK: - Extension for TableView Methods
extension CartViewController: UITableViewDelegate, UITableViewDataSource, /*SwipeTableViewCellDelegate,*/ UITextFieldDelegate {
    
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





//MARK:- UIPickerViewDataSource UIPickerViewDelegate Methods
extension CartViewController: UIPickerViewDataSource, UIPickerViewDelegate{
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return measures.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return measures[row].rawValue
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        measureTextField.text = measures[row].rawValue
    }
}


