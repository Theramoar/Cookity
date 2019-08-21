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
    
    let impact = UIImpactFeedbackGenerator()
    
    var productsInFridge: List<Product>?
    var products: Results<Product>?
    
    @IBOutlet var tableView: UITableView!
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
                tableView.allowsSelection = false
            }
            else {
                tableView.allowsSelection = true
            }
        }
    }

    var selectedCart: ShoppingCart?{
        didSet{
            Configuration.configureViewController(ofType: self, parentObject: selectedCart)
            products = selectedCart?.products.filter(NSPredicate(value: true))
            productsInFridge = Fridge.shared.products
            
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
        tableView.rowHeight = 45
        
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
    
    
    @IBAction func shareButtonPressed(_ sender: UIBarButtonItem) {
        let shareManager = ShareDataManager()
        guard
            let cart = selectedCart,
            let url = shareManager.exportToURL(object: cart)
            else { return }
        
        let activity = UIActivityViewController(
            activityItems: ["I prepared the Shopping List for you! You can read it using Cookity app.", url],
            applicationActivities: nil
        )
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
        
        if saveProduct(productName: nameText, productQuantity: quantityText, productMeasure: measureText) {
            return true
        }
        return false
    }
    
    
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
        
        if let currentCart = selectedCart {
            newProduct.name = productName
            newProduct.quantity = savedQuantity
            newProduct.measure = savedMeasure
            RealmDataManager.saveToRealm(parentObject: currentCart, object: newProduct)
            CloudManager.updateCartInCloud(with: newProduct, cart: currentCart)
        }
        tableView.reloadData()
        return true
    }
    
    
    func moveProductsToFridge() {
        guard let products = products,
            let productsInFridge = productsInFridge,
            let selectedCart = selectedCart
        else { return }
        
        var copiedProducts = [Product]()
        for product in products {
            //Checks if the similar product is already in the fridge
            for fridgeProduct in productsInFridge{
                // if products name and measure coincide, adds quantity and deletes product from the shopping list
                if product.name.lowercased() == fridgeProduct.name.lowercased() && product.measure == fridgeProduct.measure {
                    let newQuantity = fridgeProduct.quantity + product.quantity
                    RealmDataManager.changeElementIn(object: fridgeProduct,
                                                     keyValue: "quantity",
                                                     objectParameter: fridgeProduct.quantity,
                                                     newParameter: newQuantity)
                    RealmDataManager.deleteFromRealm(object: product)
                    CloudManager.updateProductInCloud(product: fridgeProduct)
                    break
                }
            }
            if product.isInvalidated == false{
                let coppiedProduct = Product(value: product)
                coppiedProduct.checked = false
                RealmDataManager.saveToRealm(parentObject: Fridge.shared, object: coppiedProduct)
                RealmDataManager.deleteFromRealm(object: product)
                copiedProducts.append(coppiedProduct)
            }
        }
        CloudManager.saveChildrenToCloud(ofType: .Product, objects: copiedProducts, parentRecord: nil)
        //Delete Cart from Cloud
        RealmDataManager.deleteFromRealm(object: selectedCart)
        
        if let nav = self.navigationController {
            nav.popToRootViewController(animated: true)
        }
        dismiss(animated: true, completion: nil)
    }
    
    override func deleteObject(at indexPath: IndexPath) {
        if let product = products?[indexPath.row] {
            RealmDataManager.deleteFromRealm(object: product)
            tableView.reloadData()
        }
    }
    
}

//MARK: - Extension for TableView DataSource and Delegate Methods
extension CartViewController: UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products?.count ?? 0
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let products = products else { return }
        impact.impactOccurred()
        
        let product = products[indexPath.row]
        RealmDataManager.changeElementIn(object: product,
                                    keyValue: "checked",
                                    objectParameter: product.checked,
                                    newParameter: !product.checked)
        
        tableView.reloadData()
        
        //If all products are checked, App offers to add them to the Fridge
        for product in products {
            guard product.checked == true else { return }
        }
        
        let alert = UIAlertController(title: "Add products to the fridge?", message: "", preferredStyle: .actionSheet)
        
        let yesAction = UIAlertAction(title: "Yes", style: .default) { (_) in
            self.moveProductsToFridge()
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
