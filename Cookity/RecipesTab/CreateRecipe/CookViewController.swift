//
//  CookViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 30/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import SwipeCellKit


protocol UpdateVCDelegate {
    func updateVC()
}

class CookViewController: UIViewController {

    var isEdited: Bool = false // used for to disable touches while textfield are edited.
    
    
    var viewModel: CookViewModel!
    @IBOutlet weak var productsTable: UITableView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var recipeName: UITextField!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    var updateVCDelegate: UpdateVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recipeName.delegate = self
        recipeName.autocapitalizationType = .sentences
        
        productsTable.register(UINib(nibName: "TextFieldCell", bundle: nil), forCellReuseIdentifier: "TextFieldCell")
        productsTable.register(UINib(nibName: "CookTableViewCell", bundle: nil), forCellReuseIdentifier: "CookTableViewCell")
        productsTable.register(UINib(nibName: "EnterRecipeStepCell", bundle: nil), forCellReuseIdentifier: "EnterRecipeStepCell")
        productsTable.register(UINib(nibName: "RecipeStepCell", bundle: nil), forCellReuseIdentifier: "RecipeStepCell")
        
        productsTable.delegate = self
        productsTable.dataSource = self
        productsTable.isEditing = true
        productsTable.keyboardDismissMode = .onDrag
        recipeName.text = viewModel.recipeName
        
        deleteButton.isEnabled = viewModel.isNewRecipe ? false : true
        deleteButton.isHidden = viewModel.isNewRecipe ? true : false
        
        saveButton.layer.shadowOffset = CGSize(width: 0, height: -1)
        saveButton.layer.shadowOpacity = 0.1
        saveButton.layer.shadowRadius = 0.1
        saveButton.layer.shadowColor = Colors.shadowColor?.cgColor
        
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
    
    override func viewWillDisappear(_ animated: Bool) {
         updateVCDelegate?.updateVC()
     }
    
    //MARK:- Data Management Methods
    internal func saveStep(step: String) {
        viewModel.saveStep(step: step)
        productsTable.reloadData()
    }
    
    //MARK: - Methods for Buttons
    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "Delete recipe?", message: "Recipe will be permanently deleted", preferredStyle: .alert)
        alert.view.tintColor = Colors.textColor
        let delete = UIAlertAction(title: "Yes", style: .destructive) { _ in
            self.viewModel.deleteRecipe()
            self.updateVCDelegate?.updateVC()
            self.dismiss(animated: true, completion: nil)
        }
        let cancel = UIAlertAction(title: "No", style: .cancel, handler: nil)
        alert.addAction(delete)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addImageButtonPressed(_ sender: UIButton) {
        DecorationHandler.putShadowOnView(vc: self)
        let vc = EditImageViewController()
        vc.parentVC = self
        if let recipeImage = viewModel.recipeImage {
            vc.editedImage = recipeImage
        }
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        guard let newName = recipeName?.text else { /*вставить сюда алерт*/ return }
        viewModel.saveRecipe(withName: newName)
        updateVCDelegate?.updateVC()
        self.dismiss(animated: true, completion: nil)
    }
}




//MARK: - TableView Methods
extension CookViewController: UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, RecipeStepDelegate {    
    

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.sections[section].rawValue
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.currentSection(section)
        tableView.rowHeight = section == 0 ? 60 : 40
        return viewModel.numberOfRows
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let textCell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell") as! TextFieldCell
                textCell.delegate = self
                return textCell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CookTableViewCell", for: indexPath) as! CookTableViewCell
                cell.viewModel = viewModel.cellViewModel(forIndexPath: indexPath) as? CookCellViewModel
                return cell
            }
        }
        else {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "EnterRecipeStepCell", for: indexPath) as! RecipeStepTableViewCell
                cell.delegate = self
                cell.isEditing = false
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeStepCell", for: indexPath) as! RecipeStepCell
                cell.viewModel = viewModel.cellViewModel(forIndexPath: indexPath) as? RecipeStepCellViewModel
                return cell
            }
        }
    }
        
    //MARK:- TableView Cell Edit Methods
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.row == 0 else { return true }
        return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
         if (editingStyle == .delete) {
            viewModel.deleteObject(at: indexPath)
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.row == 0 else { return true }
        return false
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            return IndexPath(row: sourceIndexPath.row, section: sourceIndexPath.section)
        }
        else if proposedDestinationIndexPath.row == 0 {
            return IndexPath(row: 1, section: sourceIndexPath.section)
            
        }
        return proposedDestinationIndexPath
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard destinationIndexPath.row != 0 else { return }
        viewModel.moveObjects(from: sourceIndexPath, to: destinationIndexPath)
    }
}


//MARK:- TextField Cell Delegate Method
extension CookViewController: TextFieldDelegate {
    
    //выделить в отдельную функцию, чтобыне повторять код
    func saveProduct(productName: String, productQuantity: String, productMeasure: String) {
        let alert = viewModel.checkDataFromTextFields(productName: productName, productQuantity: productQuantity, productMeasure: productMeasure)
        if let alert = alert {
            present(alert, animated: true, completion: nil)
            return
        }
        viewModel.createNewProduct(productName: productName, productQuantity: productQuantity, productMeasure: productMeasure)
        productsTable.reloadData()
    }
}
