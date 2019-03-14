//
//  CookViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 30/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit



class CookViewController: UIViewController {


    let config = Configuration()
    let dataManager = RealmDataManager()
    
    @IBOutlet weak var productsTable: UITableView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var recipeName: UITextField!
    
    var recipeVC: RecipeViewController? // VC of the Recipe that is edited
    
    var recipeSteps: [RecipeStep]?
    var products = [Product]()
    var chosenIndexPaths = [Int : IndexPath]() // это надо?? видимо нет
    let sections = ["Choose ingridients for the recipe:", "Describe cooking process:"]
    var RecipeIsEdited: Bool = false // is used to detect if the recipe is new and disable delete button
    
    var editedRecipe: Recipe? {
        didSet{
            dataManager.loadFromRealm(vc: self, parentObject: editedRecipe)
            RecipeIsEdited = true // эта переменная нужна?
        }
    }
    
    var isEdited: Bool = false // used for to disable touches while textfield are edited.
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recipeName.delegate = self
        productsTable.delegate = self
        productsTable.dataSource = self
        productsTable.keyboardDismissMode = .interactive
        
        if RecipeIsEdited == true {
            recipeName.text = editedRecipe?.name
        }
        else if !RecipeIsEdited {
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

        dataManager.loadFromRealm(vc: self, parentObject: editedRecipe) // это надо?!
    }
    
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
    
    
    func saveStep(step: String) {
        let newStep = RecipeStep()
        newStep.name = step
        if recipeSteps?.append(newStep) == nil {
            recipeSteps = [newStep]
        }
        productsTable.reloadData()
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
        
        let alert = UIAlertController(title: "Amount is not entered!", message: "Enter the amount used for for the recipe", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { (_) in
            return
        }
        alert.addAction(action)
        
        //Temporary storage for edited values, until they are checked and saved into the Realm
        var editedQuantity = [Product : Int]()
        var editedMeasure = [Product : String]()
        
        //1st circle is used to iterate over the array and check if all entered quantities are correct
        for row in 1...(productsTable.numberOfRows(inSection: 0)-1) {
            
            let cell = productsTable.cellForRow(at: NSIndexPath(row: row, section: 0) as IndexPath) as! CookTableViewCell
            
            let selectedIndexPath = productsTable.indexPath(for: cell)
            //throws the alert if entered quantity is empty and breaks the cooking.
            guard Float(cell.quantityForRecipe.text!) != nil  else {
                editedQuantity.removeAll()
                editedMeasure.removeAll()
                alert.title = "Amount is not entered!"
                alert.message = "Enter the amount used for for the recipe"
                present(alert, animated: true, completion: nil)
                return
            }
            
            if let indexPath = selectedIndexPath {
                let product = products[indexPath.row - 1]
                let (quantity, measure) = config.configNumbers(quantity: cell.quantityForRecipe.text!, measure: product.measure)
                
                guard quantity != 0 else{
                    editedQuantity.removeAll()
                    editedMeasure.removeAll()
                    alert.title = "The amount of \(product.name) is 0"
                    alert.message = "Please enter the sufficient amount"
                    present(alert, animated: true, completion: nil)
                    return
                }
                
                editedQuantity[product] = quantity
                editedMeasure[product] = measure
            }
        }
        
        //Check for the entered recipe name correctness
        guard recipeName?.text != "" else {
            editedQuantity.removeAll()
            editedMeasure.removeAll()
            alert.title = "Recipe name is not entered!"
            alert.message = "Enter the recipe name"
            present(alert, animated: true, completion: nil)
            return
        }
        
        //Starts Data Manipulation
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
                    break
                }
                else if recipeProduct.isSameObject(as: lastProduct){
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
                        break
                    }
                    else if savedStep.isSameObject(as: lastStep)  {
                        dataManager.saveToRealm(parentObject: recipe, object: recipeStep)
                    }
                }
            }
        }
        
        editedQuantity.removeAll()
        editedMeasure.removeAll()
        self.dismiss(animated: true, completion: nil)
    }
}




//MARK: - TableView Methods
extension CookViewController: UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, RecipeStepDelegate {
    

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
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
                cell.quantityForRecipe.delegate = self
                cell.selectionStyle = .none
                let product = products[indexPath.row - 1]
                let measure = config.configMeasure(measure: product.measure)
                cell.textLabel?.text = "\(product.name) - (in \(measure))"
                cell.quantityForRecipe.text = "\(product.quantity)"
                
                return cell
            }
        }
        else {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddRecipeCell", for: indexPath) as! RecipeStepTableViewCell
                cell.delegate = self
                cell.recipeStep.delegate = self
                cell.selectionStyle = .none
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeCell", for: indexPath)
                if let recipeStep = recipeSteps?[indexPath.row - 1] {
                    cell.textLabel?.text = recipeStep.name
                }
                cell.selectionStyle = .none
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
        let dataIsCorrect = alert.checkData(productName: productName, productQuantity: productQuantity)
        guard dataIsCorrect else {
            present(alert, animated: true, completion: nil)
            return
        }
        
        let measure = config.configMeasure(measure: productMeasure)
        let (savedQuantity, savedMeasure) = config.configNumbers(quantity: productQuantity, measure: measure)
        
        newProduct.name = productName
        newProduct.quantity = savedQuantity
        newProduct.measure = savedMeasure
        products.append(newProduct)

        productsTable.reloadData()
    }
}
