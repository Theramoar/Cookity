//
//  RecipeCollectionViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 25/11/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift


enum RecipeCollectionType {
    case recipCollection
    case recipeGroupCollection
    case addRecipeToGroupCollection
}


class RecipeCollectionViewController: UIViewController, UpdateVCDelegate, PresentationDelegate {
    func present(vc: UIViewController) {
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    @IBOutlet weak var recipeCollection: UICollectionView!
    @IBOutlet weak var addRecipeButton: UIButton!
    
    @IBOutlet weak var bookImageView: UIImageView!
    @IBOutlet weak var bookMainLabel: UILabel!
    @IBOutlet weak var bookSecondaryLabel: UILabel!
    
    var viewModel = RecipeCollectionViewModel()
    private var recipeGroupCreating: Bool = false
    private var barButton: UIBarButtonItem?
    
    //MARK:- SearchBar variables
    private var searchController: UISearchController!

    private var searchBarIsEmpty: Bool {
        guard let text = searchController.searchBar.text else { return false }
        return text.isEmpty
    }
    
    //MARK:- ViewController methods
    override func viewDidLoad() {
        super.viewDidLoad()
        recipeCollection.delegate = self
        recipeCollection.dataSource = self
        recipeCollection.register(UINib(nibName: "RecipeCell", bundle: nil), forCellWithReuseIdentifier: "RecipeCell")
        
        addRecipeButton.layer.shadowOffset = CGSize(width: 0, height: 3.0)
        addRecipeButton.layer.shadowOpacity = 0.7
        addRecipeButton.layer.shadowRadius = 5.0
        
        switch viewModel.recipeCollectionType {
            
        case .recipCollection:
            recipeCollection.register(UINib(nibName: "RecipeGroupCell", bundle: nil), forCellWithReuseIdentifier: "RecipeGroupCell")
            viewModel.loadDataFromCloud {
                self.recipeCollection.reloadData()
            }
        case .recipeGroupCollection:
            return
        case .addRecipeToGroupCollection:
            return
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setStandardNavBar()
        updateVC()
    }
    
    
    private func setStandardNavBar() {
        switch viewModel.recipeCollectionType {
        case .recipCollection:
            navigationController?.navigationBar.prefersLargeTitles = true
            searchController = setupSearchBarController()
            navigationItem.searchController = searchController
            searchController.searchBar.placeholder = SettingsVariables.isIngridientSearchEnabled ? "Search for recipe or ingridient" : "Search for recipe"
            navigationItem.hidesSearchBarWhenScrolling = false
            let image = UIImage(systemName: "text.badge.plus")?.withTintColor(Colors.textColor!, renderingMode: .alwaysOriginal)
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(addGroupPressed))
            barButton = navigationItem.rightBarButtonItem
        case .recipeGroupCollection:
            navigationController?.navigationBar.tintColor = Colors.textColor
            navigationController?.navigationBar.prefersLargeTitles = true
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "edit"), style: .plain, target: self, action: #selector(editGroup))
        case .addRecipeToGroupCollection:
            return
        }

    }
    
    private func setupSearchBarController() -> UISearchController {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        return searchController
    }
    

    
    //MARK:- UpdateVCDelegate Method
    func updateVC() {
        viewModel.updateviewModel()
        recipeCollection.reloadData()
    }

    //MARK:- Methods for Buttons
    @IBAction func addButtonPressed(_ sender: UIButton) {
        if recipeGroupCreating {
            let alert = UIAlertController(title: "What is the group name?", message: nil, preferredStyle: .alert)
            alert.view.tintColor = Colors.textColor
            let create = UIAlertAction(title: "Create group", style: .default) { _ in
                //Create group Here
                guard let textField = alert.textFields?.first,
                    let name = textField.text,
                    !name.isEmpty
                else { return }
                
                if self.viewModel.createGroupWith(name: name)  {
                    self.recipeCollection.reloadData()
                    self.addGroupPressed()
                }
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                self.addGroupPressed()
            }
            alert.addAction(cancel)
            alert.addAction(create)
            alert.addTextField()
                        
            present(alert, animated: true, completion: nil)
        }
        else {
            let vc = CookViewController()
            vc.viewModel = viewModel.viewModelForNewRecipe()
            vc.updateVCDelegate = self
            present(vc, animated: true, completion: nil)
        }
    }
    
    @objc private func addGroupPressed() {
        guard UserPurchases.isProEnabled() else {
            let vc = InAppPurchaseViewController()
            present(vc, animated: true, completion: nil)
            return
        }
        recipeGroupCreating = !recipeGroupCreating
        navigationItem.rightBarButtonItem?.image = recipeGroupCreating ? nil : UIImage(systemName: "text.badge.plus")?.withTintColor(Colors.textColor!, renderingMode: .alwaysOriginal)
        navigationItem.rightBarButtonItem?.title = recipeGroupCreating ? "Cancel" : nil
        navigationItem.title = recipeGroupCreating ? " \(viewModel.numberOfSelectedRecipes) Recipes selected" : "Recipes"
        let buttonImage = recipeGroupCreating ? UIImage(named: "addGroupButton") : UIImage(named: "addButton")
        addRecipeButton.setImage(buttonImage, for: .normal)
    }
    
    @objc private func editGroup() {
        if let nav = self.navigationController {
            nav.popToRootViewController(animated: true)
        }
    }
}

//MARK:- RecipeCollection Delegate and DataSource
extension RecipeCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        viewModel.numberOfSections
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        bookImageView.isHidden = !viewModel.isRecipeListEmpty
        bookMainLabel.isHidden = !viewModel.isRecipeListEmpty
        bookSecondaryLabel.isHidden = !viewModel.isRecipeListEmpty
        return viewModel.numberOfRowsForCurrentSection(section)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if viewModel.isFiltering {
            return CGSize(width: 302, height: 152)
        }
        else if viewModel.numberOfGroups == 0 {
            return CGSize(width: 302, height: 152)
        }
        if indexPath.section == 0 {
            return CGSize(width: UIScreen.main.bounds.width, height: 187)
        }
            return CGSize(width: 302, height: 152)
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if viewModel.isFiltering {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecipeCell", for: indexPath) as! RecipeCell
            cell.viewModel = viewModel.cellViewModel(forIndexPath: indexPath)  as? RecipeCollectionCellViewModel
            return cell
        }
        else if viewModel.numberOfGroups == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecipeCell", for: indexPath) as! RecipeCell
            cell.viewModel = viewModel.cellViewModel(forIndexPath: indexPath)  as? RecipeCollectionCellViewModel
            return cell
        }
        else if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecipeGroupCell", for: indexPath) as! RecipeGroupCell
            cell.presentatioDelegate = self
            cell.viewModel = viewModel.cellViewModel(forIndexPath: indexPath) as? RecipeGroupCellViewModel
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecipeCell", for: indexPath) as! RecipeCell
            cell.viewModel = viewModel.cellViewModel(forIndexPath: indexPath)  as? RecipeCollectionCellViewModel
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 && viewModel.numberOfGroups != 0 && !viewModel.isFiltering {
            return
        }
        if !recipeGroupCreating {
            viewModel.selectRow(atIndexPath: indexPath)
            let vc = RecipeViewController()
            vc.viewModel = viewModel.viewModelForSelectedRow() as? RecipeViewModel
            vc.navigationController?.navigationBar.prefersLargeTitles = false
            navigationController?.pushViewController(vc, animated: true)
        }
        else {
            viewModel.selectRecipeForGroup(atIndexPath: indexPath) {
                self.navigationItem.title = "\(self.viewModel.numberOfSelectedRecipes) Recipes selected"
                self.recipeCollection.reloadData()
            }
        }
    }
}

extension RecipeCollectionViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        viewModel.isFiltering = searchController.isActive && !searchBarIsEmpty
        viewModel.updateSearchResults(with: searchText)
        recipeCollection.reloadData()
    }
}
