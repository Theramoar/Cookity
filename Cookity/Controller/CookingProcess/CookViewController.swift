//
//  CookViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 30/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import SwipeCellKit
import RealmSwift


enum CookSections: String, CaseIterable {
    case productSection = "Choose ingridients for the recipe:"
    case stepSection = "Describe cooking process:"
}

protocol UpdateVCDelegate {
    func updateVC()
}

class CookViewController: SwipeTableViewController {

    var isEdited: Bool = false // used for to disable touches while textfield are edited.
    
    @IBOutlet var cookDataManager: CookDataManager!
    @IBOutlet weak var productsTable: UITableView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var recipeName: UITextField!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    var updateVCDelegate: UpdateVCDelegate?
    
    let sections = CookSections.allCases

    
    // Storage for edited text used by tableView cellForRow to update data
    var editedValue = [UITextField: String]()
    var editedText: String = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recipeName.delegate = self
        recipeName.autocapitalizationType = .sentences
        productsTable.delegate = self
        productsTable.dataSource = self
        productsTable.keyboardDismissMode = .onDrag
        if let editedRecipe = cookDataManager.selectedRecipe {
            recipeName.text = editedRecipe.name
        }
        else {
            deleteButton.isEnabled = false
            deleteButton.isHidden = true
        }
        saveButton.layer.shadowOffset = CGSize(width: 0, height: -3)
        saveButton.layer.shadowOpacity = 0.1
        saveButton.layer.shadowRadius = 2.5
        
        // tapgesture is used for the keyboard removal
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)
        
        //Used for the table moving while keyboard appear
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    //MARK:- User Interaction Methods
    @objc func keyboardWillAppear(notification: NSNotification){
        productsTable.allowsSelection = false
        isEdited = true
        if let userInfo = notification.userInfo {
            if let keyboardSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
                productsTable.contentInset = contentInsets
                productsTable.scrollIndicatorInsets = contentInsets
            }
        }
    }
    
    @objc func keyboardWillDisappear() {
        productsTable.contentInset = UIEdgeInsets.zero
        productsTable.scrollIndicatorInsets = UIEdgeInsets.zero
        isEdited = false
    }
    
    
    @objc func viewTapped() {
        if isEdited == false {
            productsTable.allowsSelection = true
        }
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        backButton.isEnabled = false
        deleteButton.isEnabled = false
        editedText = textField.text ?? ""
    }
    
    override func viewWillDisappear(_ animated: Bool) {
         updateVCDelegate?.updateVC()
     }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        backButton.isEnabled = true
        deleteButton.isEnabled = true
        guard var text = textField.text else { return }
        if text.isEmpty {
            textField.text = editedText
            return
        }
        text = text.replacingOccurrences(of: ",", with: ".")
        if textField.accessibilityIdentifier == "quantityTextField", Float(text) == nil {
            textField.text = editedText
            return
        }
        
        editedValue[textField] = textField.text
        productsTable.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! EditImageViewController
        vc.parentVC = self
        if let recipeImage = cookDataManager.recipeImage {
            vc.editedImage = recipeImage
        }
    }
    
    //MARK:- Data Management Methods
    internal func saveStep(step: String) {
        cookDataManager.saveStep(step: step)
        productsTable.reloadData()
    }
    
    override func deleteObject(at indexPath: IndexPath) {
        cookDataManager.deleteObject(at: indexPath)
        productsTable.reloadData()
    }
    
    //MARK: - Methods for Buttons
    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        cookDataManager.deleteRecipe()
        updateVCDelegate?.updateVC()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
 
    
    @IBAction func addImageButtonPressed(_ sender: UIButton) {
        DecorationHandler.putShadowOnView(vc: self)
        performSegue(withIdentifier: "GoToEditImage", sender: self)
    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        guard let newName = recipeName?.text else { /*вставить сюда алерт*/ return }
        cookDataManager.saveRecipe(withName: newName)
        updateVCDelegate?.updateVC()
        self.dismiss(animated: true, completion: nil)
    }
}




//MARK: - TableView Methods
extension CookViewController: UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, RecipeStepDelegate {    
    

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].rawValue
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            tableView.rowHeight = 60
            return (cookDataManager.products.count) + 1
        }
        else {
            
            return (cookDataManager.recipeSteps.count) + 1
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            
            if indexPath.row == 0 {
                let textCell = tableView.dequeueReusableCell(withIdentifier: "TextCell") as! TextFieldCell
                textCell.delegate = self
                return textCell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CookCell", for: indexPath) as! CookTableViewCell
                cell.delegate = self as SwipeTableViewCellDelegate
                cell.quantityForRecipe.delegate = self
                cell.productName.delegate = self
                cell.productName.autocapitalizationType = .sentences
                cell.productMeasure.delegate = self
                
                let product = cookDataManager.products[indexPath.row - 1]
    
                
                if editedValue[cell.productName] != nil {
                    RealmDataManager.changeElementIn(object: product, keyValue: "name", objectParameter: product.name, newParameter: editedValue[cell.productName])
                    editedValue.removeAll()
                }
                
                if let quantity = editedValue[cell.quantityForRecipe] {
                    let (newQuantity, newMeasure) = Configuration.configNumbers(quantity: quantity, measure: product.measure)

                    product.quantity = newQuantity
                    product.measure = newMeasure
                    editedValue.removeAll()
                }
                
                if editedValue[cell.productMeasure] != nil {
                    let measure = Configuration.configMeasure(measure: editedValue[cell.productMeasure]!)
                    RealmDataManager.changeElementIn(object: product, keyValue: "measure", objectParameter: product.measure, newParameter: measure)
                    editedValue.removeAll()
                }

                let presentedMeasure = Configuration.configMeasure(measure: product.measure)
                cell.productName.text = product.name
                cell.quantityForRecipe.text = String(product.quantity)
                cell.productMeasure.text = presentedMeasure
                
                return cell
            }
        }
        else {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddRecipeCell", for: indexPath) as! RecipeStepTableViewCell
                cell.delegate = self
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeCell", for: indexPath) as! RecipeStepCell
                cell.delegate = self as SwipeTableViewCellDelegate
                cell.recipeStepCell.delegate = self
                

                
                let recipeStep = cookDataManager.recipeSteps[indexPath.row - 1]
                if editedValue[cell.recipeStepCell] != nil {
                    RealmDataManager.changeElementIn(object: recipeStep, keyValue: "name", objectParameter: recipeStep.name, newParameter: editedValue[cell.recipeStepCell])
                    editedValue.removeAll()
                }
                cell.recipeStepCell.text = recipeStep.name
                
                return cell
            }
        }
    }
}


//MARK:- TextField Cell Delegate Method
extension CookViewController: TextFieldDelegate {
    
    //выделить в отдельную функцию, чтобыне повторять код
    func saveProduct(productName: String, productQuantity: String, productMeasure: String) {
        
        let alert = cookDataManager.checkDataFromTextFields(productName: productName, productQuantity: productQuantity, productMeasure: productMeasure)
        if let alert = alert {
            present(alert, animated: true, completion: nil)
            return
        }
        let newProduct = cookDataManager.createNewProduct(productName: productName, productQuantity: productQuantity, productMeasure: productMeasure)
        cookDataManager.products.append(newProduct)
        productsTable.reloadData()
    }
}
