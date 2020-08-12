//
//  RecipeGroupViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 30/04/2020.
//  Copyright © 2020 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import SwipeCellKit

class RecipeGroupViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var textFieldConstraint: NSLayoutConstraint!
    @IBOutlet weak var textFieldHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewConstraint: NSLayoutConstraint!
    
    
    var viewModel: RecipeGroupViewModel!
    
//MARK:- View Setup Methods
    override func viewDidLoad() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "RecipeCell", bundle: nil), forCellWithReuseIdentifier: "RecipeCell")
        
        switch viewModel.recipeCollectionType {
        case .recipCollection:
            return
        case .recipeGroupCollection:
            NotificationCenter.default.addObserver(self, selector: #selector(reload), name: NSNotification.Name(NotificationNames.groupIsUpdated), object: nil)
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
            tapGesture.cancelsTouchesInView = false
            self.view.addGestureRecognizer(tapGesture)
        case .addRecipeToGroupCollection:
            return
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupNameTextField()
        switch viewModel.recipeCollectionType {
        case .recipCollection:
            return
        case .recipeGroupCollection:
            title = viewModel.groupName
            navigationController?.navigationBar.tintColor = Colors.appColor
            navigationController?.navigationBar.prefersLargeTitles = true
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "edit"), style: .plain, target: self, action: #selector(editGroup))
        case .addRecipeToGroupCollection:
            navigationController?.navigationBar.isTranslucent = true
            navigationController?.navigationBar.largeTitleTextAttributes = [.foregroundColor : Colors.textColor!]
            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor : Colors.textColor!]
            navigationController?.navigationBar.tintColor = Colors.appColor
            navigationController?.navigationBar.prefersLargeTitles = true
            navigationItem.title = "Select recipes"
            addButton.isHidden = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        viewModel.uncheckSelectedRecipes()
    }
    
    private func setupNameTextField() {
        self.nameTextField.isHidden = !self.viewModel.isGroupEdited
        collectionViewConstraint.constant = viewModel.isGroupEdited ? 20 : 0
        textFieldConstraint.constant = viewModel.isGroupEdited ? 20 : 0
        textFieldHeightConstraint.constant = viewModel.isGroupEdited ? 32 : 0
        nameTextField.text = viewModel.isGroupEdited ? viewModel.groupName : "" 
        
    }
    
    @objc private func reload() {
        viewModel.fillRecipeGroup()
        collectionView.reloadData()
    }
    
    private func animateAddButtonChange() {
        let buttonImage = viewModel.isGroupEdited ? UIImage(named: "deleteGroupButton") : UIImage(named: "addButton")
        
        let originButtonY = addButton.frame.origin.y

        UIView.animate(withDuration: 0.2, animations: {
            self.addButton.frame.origin.y = UIScreen.main.bounds.maxY
        }) { (completed) in
            self.addButton.setImage(buttonImage, for: .normal)
        }
        
        UIView.animate(withDuration: 0.2, delay: 0.2, animations: {
            self.addButton.frame.origin.y = originButtonY
        }, completion: nil)
        

    }
    
    
//MARK:- Methods for Buttons
    @objc private func editGroup() {
        viewModel.isGroupEdited = !viewModel.isGroupEdited
        collectionView.reloadData()
        if !viewModel.isGroupEdited, let name = nameTextField.text, !name.isEmpty {
            viewModel.saveGroupName(name)
        }
        setupNameTextField()
        navigationItem.rightBarButtonItem?.image = viewModel.isGroupEdited ? nil : UIImage(named: "edit")
        navigationItem.rightBarButtonItem?.title = viewModel.isGroupEdited ? "Done" : nil
        title = viewModel.isGroupEdited ? nil : viewModel.groupName
        navigationController?.navigationBar.prefersLargeTitles = !viewModel.isGroupEdited
        animateAddButtonChange()
    }
    
    @objc func viewTapped(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
     }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        switch viewModel.recipeCollectionType {
            
        case .recipCollection:
            return
        case .recipeGroupCollection:
            if viewModel.isGroupEdited {
                presentDeleteAlert()
            }
            else {
                guard UserPurchases.isProEnabled() else {
                    let vc = InAppPurchaseViewController()
                    present(vc, animated: true, completion: nil)
                    return
                }
                presentAddAlert()
            }
        case .addRecipeToGroupCollection:
            viewModel.appendExistingRecipesToGroup()
            NotificationCenter.default.post(name: NSNotification.Name(NotificationNames.groupIsUpdated), object: nil)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    
//MARK:- Alert Presentation
    private func presentAddAlert() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.view.tintColor = Colors.textColor
        let addNew = UIAlertAction(title: "Add new recipe to group", style: .default) { (_) in
            let vc = CookViewController()
            vc.viewModel = self.viewModel.viewModelForNewRecipe()
            self.present(vc, animated: true, completion: nil)
        }
        let addExisting = UIAlertAction(title: "Add existing recipe to group", style: .default) { _ in
            let vc = RecipeGroupViewController()
            vc.viewModel = self.viewModel.viewModelForExistingRecipes()
            let navVC = UINavigationController(rootViewController: vc)
            self.present(navVC, animated: true, completion: nil)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(addNew)
        alert.addAction(addExisting)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    private func presentDeleteAlert() {
        let alert = UIAlertController(title: "Do you want to dismiss group?", message: "The group will be dissmissed. All recipes won't be deleted", preferredStyle: .alert)
        alert.view.tintColor = Colors.textColor
        let dismiss = UIAlertAction(title: "Dismiss group", style: .default) { (_) in
            self.viewModel.deleteGroup()
            if let nav = self.navigationController {
                nav.popToRootViewController(animated: true)
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(dismiss)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
}


//MARK:- CollectionView DataSource and Delegate methods
extension RecipeGroupViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.numberOfRows
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecipeCell", for: indexPath) as! RecipeCell
        cell.viewModel = viewModel.cellViewModel(forIndexPath: indexPath)  as? RecipeCollectionCellViewModel
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 302, height: 152)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch viewModel.recipeCollectionType {
        case .recipCollection:
            return
        case .recipeGroupCollection:
            viewModel.selectRow(atIndexPath: indexPath)
            let vc = RecipeViewController()
            vc.viewModel = viewModel.viewModelForSelectedRow() as? RecipeViewModel
            navigationController?.pushViewController(vc, animated: true)
        case .addRecipeToGroupCollection:
            viewModel.selectRecipeForGroup(atIndexPath: indexPath) {
                self.navigationItem.title = "\(self.viewModel.numberOfSelectedRecipes) Recipes selected"
                self.collectionView.reloadData()
                self.addButton.isHidden = self.viewModel.numberOfSelectedRecipes == 0
            }
        }
    }
}
