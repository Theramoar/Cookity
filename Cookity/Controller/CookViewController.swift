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

class CookViewController: SwipeTableViewController {

    var isEdited: Bool = false // used for to disable touches while textfield are edited.
    
    @IBOutlet weak var productsTable: UITableView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var recipeName: UITextField!
    
    var recipeVC: RecipeViewController? // VC of the Recipe that is edited
    var recipeSteps: [RecipeStep]?
    var products = [Product]()
    let sections = CookSections.allCases
    var editedRecipe: Recipe? {
        didSet{
            dataManager.loadFromRealm(vc: self, parentObject: editedRecipe)
        }
    }
    
    //Temporary storage for edited values, until they are checked and saved into the Realm
    var editedQuantity = [Product : Int]()
    var editedMeasure = [Product : String]()
    var editedName = [Product: String]()
    var editedRecipeStep = [RecipeStep: String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recipeName.delegate = self
        productsTable.delegate = self
        productsTable.dataSource = self
        productsTable.keyboardDismissMode = .interactive
        if editedRecipe != nil {
            recipeName.text = editedRecipe?.name
        }
        else {
            deleteButton.isEnabled = false
            deleteButton.isHidden = true
        }
        
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
    
    //MARK:- Data Management Methods
    func saveStep(step: String) {
        let newStep = RecipeStep()
        newStep.name = step
        if recipeSteps?.append(newStep) == nil {
            recipeSteps = [newStep]
        }
        productsTable.reloadData()
    }
    
    override func deleteObject(at indexPath: IndexPath) {
        
        let object: Object?
        
        switch indexPath.section {
        case 0:
            object = products[indexPath.row - 1]
        case 1:
            object = (recipeSteps?[indexPath.row - 1])!
        default:
            return
        }
        
        if let recipe = editedRecipe {
            if let product = object as? Product {
                for editedProduct in recipe.products {
                    guard !(product.isSameObject(as: editedProduct)) else {
                        dataManager.deleteFromRealm(object: product)
                        break
                    }
                }
                products.remove(at: indexPath.row - 1)
            }
            else if let recipeStep = object as? RecipeStep {
                for editedStep in recipe.recipeSteps {
                    guard !(recipeStep.isSameObject(as: editedStep)) else {
                        dataManager.deleteFromRealm(object: recipeStep)
                        break
                    }
                }
                recipeSteps?.remove(at: indexPath.row - 1)
            }
        }
        productsTable.reloadData()
    }
    
    
    func isEnteredDataCorrect() -> Bool {
        let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { (_) in return }
        alert.addAction(action)
        
        if (productsTable.numberOfRows(inSection: 0)-1) >= 1 {
            for row in 1...(productsTable.numberOfRows(inSection: 0)-1) {
                
                let cell = productsTable.cellForRow(at: NSIndexPath(row: row, section: 0) as IndexPath) as! CookTableViewCell
                
                let selectedIndexPath = productsTable.indexPath(for: cell)
                //throws the alert if entered quantity is empty and breaks the cooking.
                
                guard let name = cell.productName.text,
                    let quantity = cell.quantityForRecipe.text,
                    let measure = cell.productMeasure.text
                    else { return false }
                
                guard alert.check(data: name, dataName: .name),
                    alert.check(data: quantity, dataName: .quantity)
                    else {
                        editedQuantity.removeAll()
                        editedMeasure.removeAll()
                        editedName.removeAll()
                        present(alert, animated: true, completion: nil)
                        return false
                }
                
                
                if let indexPath = selectedIndexPath {
                    let product = products[indexPath.row - 1]
                    let configedMeasure = Configuration.configMeasure(measure: measure)
                    let (quantity, finalMeasure) = Configuration.configNumbers(quantity: quantity, measure: configedMeasure)
                    
                    editedQuantity[product] = quantity
                    editedMeasure[product] = finalMeasure
                    editedName[product] = name
                }
            }
        }
        
        if (productsTable.numberOfRows(inSection: 1)-1) >= 1 {
            for row in 1...(productsTable.numberOfRows(inSection: 1)-1) {
                let cell = productsTable.cellForRow(at: NSIndexPath(row: row, section: 1) as IndexPath) as! RecipeStepCell
                let selectedIndexPath = productsTable.indexPath(for: cell)
                guard let recipeName = recipeName.text,
                    let recipeStepText = cell.recipeStepCell.text
                    else { return false }
                
                guard
                    alert.check(data: recipeName, dataName: .recipeName),
                    alert.check(data: recipeStepText, dataName: .recipeStep)
                    else {
                        editedQuantity.removeAll()
                        editedMeasure.removeAll()
                        editedName.removeAll()
                        present(alert, animated: true, completion: nil)
                        return false
                }
                
                guard let indexPath = selectedIndexPath else { return false }
                guard let recipeStep = recipeSteps?[indexPath.row - 1] else { return false }
                
                editedRecipeStep[recipeStep] = recipeStepText
                //доделать и отрефакторить
            }
        }
        return true
    }
    
    func saveRecipe() {
        var recipe: Recipe
        
        if editedRecipe != nil {
            recipe = editedRecipe!
            let newName = (recipeName?.text)!
            dataManager.changeElementIn(object: recipe, keyValue: "name", objectParameter: recipe.name, newParameter: newName)
            
        }
        else {
            recipe = Recipe()
            recipe.name = (recipeName?.text)!
            dataManager.saveToRealm(parentObject: nil, object: recipe)
        }
        
        for product in products {
            if recipe.products.isEmpty {
                dataManager.saveToRealm(parentObject: recipe, object: product)
            }
            
            for recipeProduct in recipe.products {
                let lastProduct = recipe.products.last
                if product.isSameObject(as: recipeProduct) {
                    dataManager.changeElementIn(object: product, keyValue: "quantity", objectParameter: product.quantity, newParameter: editedQuantity[product]!)  // почему тут Optional?
                    dataManager.changeElementIn(object: product, keyValue: "measure", objectParameter: product.measure, newParameter: editedMeasure[product]!)
                    dataManager.changeElementIn(object: product, keyValue: "name", objectParameter: product.name, newParameter: editedName[product]!)
                    break
                }
                else if recipeProduct.isSameObject(as: lastProduct){
                    product.quantity = editedQuantity[product]!
                    product.measure = editedMeasure[product]!
                    product.name = editedName[product]!
                    dataManager.saveToRealm(parentObject: recipe, object: product)
                }
            }
        }
        
        if let recipeSteps = recipeSteps {
            for recipeStep in recipeSteps {
                if recipe.recipeSteps.isEmpty {
                    dataManager.saveToRealm(parentObject: recipe, object: recipeStep)
                }
                for savedStep in recipe.recipeSteps {
                    let lastStep = recipe.recipeSteps.last
                    if recipeStep.isSameObject(as: savedStep) {
                        dataManager.changeElementIn(object: savedStep, keyValue: "name", objectParameter: savedStep.name, newParameter: editedRecipeStep[recipeStep])
                        break
                    }
                    else if savedStep.isSameObject(as: lastStep)  {
                        dataManager.saveToRealm(parentObject: recipe, object: recipeStep)
                    }
                }
            }
        }
    }
    

    //MARK: - Methods for Buttons
    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        if let recipe = editedRecipe {
            for product in recipe.products {
                dataManager.deleteFromRealm(object: product)
            }
            for step in recipe.recipeSteps {
                dataManager.deleteFromRealm(object: step)
            }
            dataManager.deleteFromRealm(object: recipe)
        }
        products.removeAll()
        
        if let nav = recipeVC?.navigationController {
            nav.popToRootViewController(animated: true)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        products.removeAll()
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func cookButtonPressed(_ sender: UIButton) {
        guard isEnteredDataCorrect() else { return }
        saveRecipe()
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
            return (products.count) + 1
        }
        else {
            
            return (recipeSteps?.count ?? 0) + 1
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            
            if indexPath.row == 0 {
                let textCell = tableView.dequeueReusableCell(withIdentifier: "TextCell") as! TextFieldCell
                textCell.delegate = self
                textCell.insertMeasure.delegate = self
                textCell.insertProduct.delegate = self
                textCell.insertQuantity.delegate = self

                return textCell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CookCell", for: indexPath) as! CookTableViewCell
                cell.delegate = self as SwipeTableViewCellDelegate
                cell.quantityForRecipe.delegate = self
                
                let product = products[indexPath.row - 1]
                cell.product = product
                
                return cell
            }
        }
        else {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddRecipeCell", for: indexPath) as! RecipeStepTableViewCell
                cell.delegate = self
                cell.recipeStep.delegate = self
                
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeCell", for: indexPath) as! RecipeStepCell
                cell.delegate = self as SwipeTableViewCellDelegate
                if let recipeStep = recipeSteps?[indexPath.row - 1] {
                    cell.recipeStep = recipeStep
                }
                
                return cell
            }
        }
    }
}


//MARK:- TextField Cell Delegate Method
extension CookViewController: TextFieldDelegate {
    
    //выделить в отдельную функцию, чтобыне повторять код
    func saveProduct(productName: String, productQuantity: String, productMeasure: String) {
        
        let newProduct = Product()
        
        let alert = UIAlertController(title: "title", message: "message", preferredStyle: .alert)
        
        guard
            alert.check(data: productName, dataName: .name),
            alert.check(data: productQuantity, dataName: .quantity)
        else {
            present(alert, animated: true, completion: nil)
            return
        }
    
        
        let measure = Configuration.configMeasure(measure: productMeasure)
        let (savedQuantity, savedMeasure) = Configuration.configNumbers(quantity: productQuantity, measure: measure)
        
        newProduct.name = productName
        newProduct.quantity = savedQuantity
        newProduct.measure = savedMeasure
        products.append(newProduct)

        productsTable.reloadData()
    }
}

