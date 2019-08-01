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
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    
    var recipeVC: RecipeViewController? // VC of the Recipe that is edited
    var recipeSteps: [RecipeStep]?
    var products = [Product]()
    let sections = CookSections.allCases
    var pickedImage: UIImage?
    var editedRecipe: Recipe? {
        didSet{
            dataManager.loadFromRealm(vc: self, parentObject: editedRecipe)
        }
    }
    
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
        
        if editedRecipe != nil {
            recipeName.text = editedRecipe?.name
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
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        backButton.isEnabled = true
        deleteButton.isEnabled = true
        guard let text = textField.text else { return }
        if text.isEmpty {
            textField.text = editedText
            return
        }
        if textField.frame.maxX == 289, Float(text) == nil {
            textField.text = editedText
            return
        }
        
        editedValue[textField] = textField.text
        productsTable.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! EditImageViewController
        vc.parentVC = self
        if let pickedImage = pickedImage {
            vc.editedImage = pickedImage
        }
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
        
        switch indexPath.section {
        case 0:
            products.remove(at: indexPath.row - 1)
        case 1:
            recipeSteps?.remove(at: indexPath.row - 1)
        default:
            return
        }
        productsTable.reloadData()
    }
    
    func saveRecipe() {
        var recipe: Recipe
        
        if editedRecipe != nil {
            recipe = editedRecipe!
            let newName = (recipeName?.text)!
            dataManager.changeElementIn(object: recipe, keyValue: "name", objectParameter: recipe.name, newParameter: newName)
            for product in recipe.products {
                dataManager.deleteFromRealm(object: product)
            }
            for recipeStep in recipe.recipeSteps {
                dataManager.deleteFromRealm(object: recipeStep)
            }
        }
        else {
            recipe = Recipe()
            recipe.name = (recipeName?.text)!
            dataManager.saveToRealm(parentObject: nil, object: recipe)
        }

        for product in products {
            dataManager.saveToRealm(parentObject: recipe, object: product)
        }
        
        if let recipeSteps = recipeSteps {
            for recipeStep in recipeSteps {
                dataManager.saveToRealm(parentObject: recipe, object: recipeStep)
            }
        }
        
        if let imagePath = savePicture(image: pickedImage, imageName: recipe.name) {
            dataManager.saveToRealm(parentObject: recipe, object: imagePath)
        }
        else if let imagePath = recipe.imagePath {
            deletePicture(imagePath: imagePath)
        }
    }
    
    
    func savePicture(image: UIImage?, imageName: String) -> String? {
        guard let image = image else { return nil }
        let imagePath: String = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(imageName).png"
        let imageUrl: URL = URL(fileURLWithPath: imagePath)
        try? image.pngData()?.write(to: imageUrl)
        return imagePath
    }
    
    func deletePicture(imagePath: String) {
        let imageUrl: URL = URL(fileURLWithPath: imagePath)
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: imageUrl)
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
            if let imagePath = recipe.imagePath {
               deletePicture(imagePath: imagePath)
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
    
    
    
    @IBAction func addImageButtonPressed(_ sender: UIButton) {
        DecorationHandler.putShadowOnView(vc: self)
        performSegue(withIdentifier: "GoToEditImage", sender: self)
    }
    
    
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
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
                return textCell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CookCell", for: indexPath) as! CookTableViewCell
                cell.delegate = self as SwipeTableViewCellDelegate
                cell.quantityForRecipe.delegate = self
                cell.quantityForRecipe.keyboardType = .decimalPad
                cell.productName.delegate = self
                cell.productName.autocapitalizationType = .sentences
                cell.productMeasure.delegate = self
                
                let product = products[indexPath.row - 1]
    
                
                if editedValue[cell.productName] != nil {
                    dataManager.changeElementIn(object: product, keyValue: "name", objectParameter: product.name, newParameter: editedValue[cell.productName])
                    editedValue.removeAll()
                }
                
                if editedValue[cell.quantityForRecipe] != nil {
                    let newQuantity = Int(editedValue[cell.quantityForRecipe]!)
                    dataManager.changeElementIn(object: product, keyValue: "quantity", objectParameter: product.quantity, newParameter: newQuantity)
                    editedValue.removeAll()
                }
                
                if editedValue[cell.productMeasure] != nil {
                    let measure = Configuration.configMeasure(measure: editedValue[cell.productMeasure]!)
                    dataManager.changeElementIn(object: product, keyValue: "measure", objectParameter: product.measure, newParameter: measure)
                    editedValue.removeAll()
                }

                var (presentedQuantity, presentedMeasure) = Configuration.presentNumbers(quantity: product.quantity, measure: product.measure)
                presentedMeasure = Configuration.configMeasure(measure: presentedMeasure)
                cell.productName.text = product.name
                cell.quantityForRecipe.text = presentedQuantity
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
                

                
                if let recipeStep = recipeSteps?[indexPath.row - 1] {
                    
                    if editedValue[cell.recipeStepCell] != nil {
                        dataManager.changeElementIn(object: recipeStep, keyValue: "name", objectParameter: recipeStep.name, newParameter: editedValue[cell.recipeStepCell])
                        editedValue.removeAll()
                    }
                    cell.recipeStepCell.text = recipeStep.name
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
        let action = UIAlertAction(title: "OK", style: .default) { (_) in return }
        alert.addAction(action)
        
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
