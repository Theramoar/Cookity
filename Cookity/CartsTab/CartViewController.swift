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
    
    
    var viewModel: CartViewModel!
    @IBOutlet var productsTable: UITableView!
    @IBOutlet var productTextField: UITextField!
    @IBOutlet var quantityTextField: UITextField!
    @IBOutlet var measureTextField: UITextField!
    @IBOutlet var addButton: UIButton!
    
    @IBOutlet weak var tfHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tfView: TextFieldView!
    // не надо
    var measurePicker: MeasurePicker!
    var selectedIndexPath: IndexPath? //variable is used to store the IndexPath selected by LongTap Gesture
    
    // Variable used to stop the table scrolling till the final row, when view is appeared
    var productAdded: Bool = false
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
        title = viewModel.cartName
        productsTable.delegate = self
        productsTable.dataSource = self
        productsTable.separatorStyle = .none
        
        productsTable.rowHeight = UITableView.automaticDimension
        productsTable.estimatedRowHeight = 100
        productsTable.register(UINib(nibName: "ProductCell", bundle: nil), forCellReuseIdentifier: "ProductCell")
        
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
        
        let image = UIImage(systemName: "plus.circle")?.withTintColor(Colors.appColor!, renderingMode: .alwaysOriginal)
        addButton.setImage(image, for: .normal)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        tapGesture.cancelsTouchesInView = false
        self.productsTable.addGestureRecognizer(tapGesture)

        //add long gesture recognizer
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressed))
        self.view.addGestureRecognizer(longPressRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tabBarController?.tabBar.isHidden = true
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        UIView.setAnimationsEnabled(true)
        self.view.endEditing(true)
        return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if textField == productTextField, let text = textField.text {
            quantityTextField.placeholder = text.isEmpty ? "How much?" : "1"
            measureTextField.placeholder = text.isEmpty ? "Measure?" : "Piece"
        }
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
            viewModel.longTapRow(atIndexPath: selectedIndexPath!)
            let vc = PopupEditViewController()
            vc.viewModel = viewModel.viewModelForSelectedRow() as? PopupEditViewModel
            vc.parentVC = self
            present(vc, animated: true, completion: nil)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard productAdded, viewModel.numberOfRows > 0 else { return }
        let indexPath = IndexPath(row: viewModel.numberOfRows - 1, section: 0)
        productsTable.scrollToRow(at: indexPath, at: .bottom, animated: true)
        productAdded = false
    }
    
    @IBAction func shareButtonPressed(_ sender: UIBarButtonItem) {
        var activityController: UIActivityViewController?
        
        let alert = UIAlertController(title: "How would you like to share this cart?", message: nil, preferredStyle: .actionSheet)
        alert.view.tintColor = Colors.appColor
        let textAction = UIAlertAction(title: "Send as text", style: .default) { (_) in
            activityController = self.viewModel.shareCart(as: .text)
            guard let activity = activityController else { return }
            activity.popoverPresentationController?.barButtonItem = sender
            self.present(activity, animated: true)
        }
        let fileAction = UIAlertAction(title: "Send as Cookity file", style: .default) { (_) in
            activityController = self.viewModel.shareCart(as: .file)
            guard let activity = activityController else { return }
            activity.popoverPresentationController?.barButtonItem = sender
            self.present(activity, animated: true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(textAction)
        alert.addAction(fileAction)
        alert.addAction(cancelAction)
        present(alert, animated: true) {}
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
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
            alert.view.tintColor = Colors.appColor
            present(alert, animated: true, completion: nil)
            return false
        }
        let newProduct = viewModel.createNewProduct(productName: nameText, productQuantity: quantityText, productMeasure: measureText)
        viewModel.saveProductToCart(product: newProduct)
        productAdded = true
        productsTable.insertRows(at: [IndexPath(row: viewModel.numberOfRows-1, section: 0)], with: .right)
        return true
    }

    
    override func deleteObject(at indexPath: IndexPath) {
        viewModel.deleteProductFromCart(at: indexPath.row)
        productsTable.deleteRows(at: [indexPath], with: .right)
    }
    
}

//MARK: - Extension for TableView DataSource and Delegate Methods
extension CartViewController: UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath) as! ProductTableViewCell
        cell.delegate = self as SwipeTableViewCellDelegate
        cell.viewModel = viewModel.cellViewModel(forIndexPath: indexPath) as? ProductTableCellViewModel
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
        
        guard viewModel.checkProduct(at: indexPath.row) else {
            tableView.reloadData()
            return
        }
        tableView.reloadData()

        let alert = UIAlertController(title: "Add products to the fridge?", message: "", preferredStyle: .actionSheet)
        alert.view.tintColor = Colors.appColor
        let yesAction = UIAlertAction(title: "Yes", style: .default) { (_) in
            self.viewModel.moveProductsToFridge()
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
