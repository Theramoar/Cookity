//
//  CookViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 30/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift


class CookViewController: UIViewController {

    let realm = try! Realm()
    let config = Configuration()
    
    @IBOutlet weak var productsTable: UITableView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var recipeName: UITextField!
    
    var recipeVC: RecipeViewController? // VC of the Recipe that is edited
    
    var recipeSteps: [String]?
    var products = [Product]()
    var newProducts = List<Product>()
    var chosenIndexPaths = [Int : IndexPath]() // это надо?? видимо нет
    let sections = ["Choose ingridients for the recipe:", "Describe cooking process:"]
    var RecipeIsEdited: Bool = false // is used to detect if the recipe is new and disable delete button
    
    var editedRecipe: Recipe? {
        didSet{
            loadProducts()
            RecipeIsEdited = true
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

        loadProducts()
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
    
    
    func loadProducts(){
        if let recipe = editedRecipe {
            products = Array(recipe.products)
            recipeSteps = Array((editedRecipe?.recipeSteps)!)
        }
    }
    
    
    func deleteRecipe(_ recipe: Recipe) {
        do{
            try realm.write {
                self.realm.delete(recipe)
            }
        }catch{
            print("Error while cooking items \(error)")
        }
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
        if recipeSteps?.append(step) == nil {
            recipeSteps = [step]
        }
        productsTable.reloadData()
    }
    
    
    
    //MARK: - Methods for Buttons
    
    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        if let recipe = editedRecipe {
            deleteRecipe(recipe)
        }
        products.removeAll()
        recipeVC?.isDeleted = true
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
        
        //circle is used to iterate over the array and check if all entered quantities are correct
        for row in 1...(productsTable.numberOfRows(inSection: 0)-1) {
           
            let cell = productsTable.cellForRow(at: NSIndexPath(row: row, section: 0) as IndexPath) as! CookTableViewCell
    
            let selectedIndexPath = productsTable.indexPath(for: cell)
            //throws the alert if entered quantity is empty and breaks the cooking and deletes the recipe from database
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
                
                //throws the alert if entered quantity suprass the amount in the fridge and breaks the cooking and deletes the recipe from database
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
        var recipe = Recipe()
        do{
            try realm.write {
                if editedRecipe != nil {
                    recipe = editedRecipe!
                    
                    recipe.products.removeAll()
                }
                else {
                    realm.add(recipe)
                }
                recipe.name = (recipeName?.text)!
                for product in products {
                    product.quantity = editedQuantity[product]! // почему тут Optional?
                    product.measure = editedMeasure[product]!
                    recipe.products.append(product)
                }
            }
        }catch{
            print("Error saving context in Product \(error)")
        }
        

        if let recipeArray = recipeSteps {
            for recipeStep in recipeArray {
                do{
                    try realm.write {
                        recipe.recipeSteps.append(recipeStep)
                    }
                }catch{
                    print("Error saving context in recipe \(error)")
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
//                if (products?.count ?? 0) >= (indexPath.row) && products != nil {
                let product = products[indexPath.row - 1]
                let measure = config.configMeasure(measure: product.measure)
                cell.textLabel?.text = "\(product.name) - (in \(measure))"
                cell.quantityForRecipe.text = "\(product.quantity)"
                    
//                }
//                else {
//                    let position = (indexPath.row - 1) - (products?.count ?? 0)
//                    let measure = config.configMeasure(measure: newProducts[position].measure)
//                    cell.textLabel?.text = "\(newProducts[position].name) - (in \(measure))"
//                    cell.quantityForRecipe.text = "\(newProducts[position].quantity)"
//                }
                
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
                    cell.textLabel?.text = recipeStep
                }
                cell.selectionStyle = .none
                return cell
            }
        }
    }
    
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//
//        if indexPath.section == 0 {
//            if let product = products?[indexPath.row]{
//                do{
//                    try realm.write {
//                        product.checkForRecipe = !product.checkForRecipe
//                    }
//                }catch{
//                    print("Error while updating items \(error)")
//                }
//
//                if  product.checkForRecipe == true{
//                    productsTable.cellForRow(at: indexPath)?.textLabel?.textColor = UIColor.orange
//                    //adds the chosen cell indexPath to the dictionary to reach the selected products while pressing Cook Button
//                    chosenIndexPaths[indexPath.row] = indexPath
//                } else {
//                    //deletes the chosen cell indexPath from the dictionary if the user unchecks the product
//                    productsTable.cellForRow(at: indexPath)?.textLabel?.textColor = UIColor.black
//                    chosenIndexPaths.removeValue(forKey: indexPath.row)
//                }
//            }
//            productsTable.deselectRow(at: indexPath, animated: true)
//        }
//    }
    
}


//MARK:- TextField Cell Delegate Method
extension CookViewController: TextFieldDelegate {
    
    //выделить в отдельную функцию, чтобыне повторять код
    func saveProduct(productName: String, productQuantity: String, productMeasure: String) {
        
        let newProduct = Product()
        
        //выделить алерт в отдельную функцию => bool и обратится к ней в popupedit
        let alert = UIAlertController(title: "title", message: "message", preferredStyle: .alert)
        let action = UIAlertAction(title: "Okay", style: .cancel) { (_) in
            return
        }
        alert.addAction(action)
        
        guard productName != "" else {
            alert.title = "No Name"
            alert.message = "Please enter product name"
            present(alert, animated: true, completion: nil)
            return
        }
        
        guard productQuantity != "" else {
            alert.title = "No Quantity"
            alert.message = "Please enter product quantity"
            present(alert, animated: true, completion: nil)
            return
        }
        
        guard Float(productQuantity) != nil else {
            alert.title = "Incorrect Quantity"
            alert.message = "Please enter the quantity in numbers"
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
