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
    
    var viewModel: RecipeGroupViewModel!
    
//MARK:- View Setup Methods
    override func viewDidLoad() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "RecipeCell", bundle: nil), forCellWithReuseIdentifier: "RecipeCell")
        collectionView.register(UINib(nibName: "ChangeGroupNameCell", bundle: nil), forCellWithReuseIdentifier: "ChangeGroupNameCell")
        
        switch viewModel.recipeCollectionType {
        case .recipCollection:
            return
        case .recipeGroupCollection:
            NotificationCenter.default.addObserver(self, selector: #selector(reload), name: .groupIsUpdated, object: nil)
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
        switch viewModel.recipeCollectionType {
        case .recipCollection:
            return
        case .recipeGroupCollection:
            title = viewModel.groupName
            navigationController?.navigationBar.tintColor = Colors.appColor
            self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
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
    
    private func setupNavigationViewForChangeName() {
        navigationItem.rightBarButtonItem?.image = viewModel.isGroupEdited ? nil : UIImage(named: "edit")
        navigationItem.rightBarButtonItem?.title = viewModel.isGroupEdited ? "Done" : nil
        title = viewModel.isGroupEdited ? "Edit group" : viewModel.groupName
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
        collectionView.performBatchUpdates(nil) { _ in 
            self.collectionView.reloadData()
        }
        let cell = collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? ChangeGroupNameCell
        if !viewModel.isGroupEdited, let name = cell?.nameTextField.text, !name.isEmpty {
            viewModel.saveGroupName(name)
        }
        setupNavigationViewForChangeName()
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
            NotificationCenter.default.post(name: .groupIsUpdated, object: nil)
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
        if indexPath.row == 0 {
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "ChangeGroupNameCell", for: indexPath) as! ChangeGroupNameCell
            cell.nameTextField.text = viewModel.groupName
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecipeCell", for: indexPath) as! RecipeCell
            cell.viewModel = viewModel.cellViewModel(forIndexPath: indexPath)  as? RecipeCollectionCellViewModel
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.row == 0 {
            return viewModel.isGroupEdited ? CGSize(width: 302, height: 52) : CGSize(width: 302, height: 0)
        }
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
