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
    case filteredRecipeSearch
}


class RecipeCollectionViewController: UIViewController, UpdateVCDelegate, PresentationDelegate {
    func present(vc: UIViewController) {
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    @IBOutlet weak var recipeCollection: UICollectionView!
    @IBOutlet weak var addRecipeButton: AppGreenButton!
    
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
        addRecipeButton.setupSFSymbol(name: "plus", size: 30)
        
        
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
        case .filteredRecipeSearch:
            return
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        setStandardNavBar()
        updateVC()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        navigationController?.navigationBar.backgroundColor = Colors.viewColor
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        recipeGroupCreating = false
        setupGroupSettings()
        changeNavigationTitle()
        animateAddButtonChange()
    }
    
    
    
    private func setStandardNavBar() {
        switch viewModel.recipeCollectionType {
        case .recipCollection:
            self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
            navigationController?.navigationBar.tintColor = Colors.appColor
            navigationController?.navigationBar.prefersLargeTitles = true
            
            searchController = setupSearchBarController()
            navigationItem.searchController = searchController
            searchController.searchBar.placeholder = SettingsVariables.isIngridientSearchEnabled ? "Search for recipe or ingridient" : "Search for recipe"
            
            navigationItem.hidesSearchBarWhenScrolling = false
            let image = UIImage(systemName: "text.badge.plus")?.withTintColor(Colors.appColor!, renderingMode: .alwaysOriginal)
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(addGroupPressed))
            barButton = navigationItem.rightBarButtonItem
        case .recipeGroupCollection:
            self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController?.navigationBar.tintColor = Colors.appColor
            navigationController?.navigationBar.prefersLargeTitles = true
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "edit"), style: .plain, target: self, action: #selector(editGroup))
        case .addRecipeToGroupCollection:
            return
        case .filteredRecipeSearch:
            return
        }
    }
    
    private func setupSearchBarController() -> UISearchController {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        return searchController
    }
    
    private func setupGroupSettings() {
        if !recipeGroupCreating {
            viewModel.uncheckRecipes()
            recipeCollection.reloadData()
        }
        navigationItem.rightBarButtonItem?.image = recipeGroupCreating ? nil : UIImage(systemName: "text.badge.plus")?.withTintColor(Colors.appColor!, renderingMode: .alwaysOriginal)
        navigationItem.rightBarButtonItem?.title = recipeGroupCreating ? "Cancel" : nil
    }

    
//MARK:- Animations
    private func animateAddButtonChange() {
        let imageName = recipeGroupCreating ? "text.badge.plus" : "plus"
        let imageSize: CGFloat = recipeGroupCreating ? 25 : 30
        let originButtonY = addRecipeButton.frame.origin.y

        UIView.animate(withDuration: 0.2, animations: {
            self.addRecipeButton.frame.origin.y = UIScreen.main.bounds.maxY
        }) { (completed) in
            self.addRecipeButton.setupSFSymbol(name: imageName, size: imageSize)
        }
        
        UIView.animate(withDuration: 0.2, delay: 0.2, animations: {
            self.addRecipeButton.frame.origin.y = originButtonY
        }, completion: nil)
    }
    
    private func animateNavigationTitileChange() {
        let fadeTextAnimation = CATransition()
        fadeTextAnimation.duration = 0.4
        fadeTextAnimation.type = CATransitionType.fade
        navigationController?.navigationBar.layer.add(fadeTextAnimation, forKey: "fadeText")
        changeNavigationTitle()
    }
    
    private func changeNavigationTitle() {
        navigationItem.title = self.recipeGroupCreating ? " \(self.viewModel.numberOfSelectedRecipes) Recipes selected" : "Recipes"
    }
    
    //MARK:- UpdateVCDelegate Method
    func updateVC() {
        viewModel.updateviewModel()
        recipeCollection.reloadData()
    }

    //MARK:- Methods for Buttons
    @IBAction func addButtonPressed(_ sender: UIButton) {
        if recipeGroupCreating {
            if viewModel.numberOfSelectedRecipes == 0 {
                presentNoRecipesSelectedAlert()
            } else {
                presentEnterNameAlert()
            }
        }
        else {
            let vc = CookViewController()
            vc.viewModel = viewModel.viewModelForNewRecipe()
            vc.updateVCDelegate = self
            present(vc, animated: true, completion: nil)
        }
    }
    
    @objc private func addGroupPressed() {
        #if !DEBUG
        guard UserPurchases.isProEnabled() else {
            let vc = InAppPurchaseViewController()
            present(vc, animated: true, completion: nil)
            return
        }
        #endif
        
        recipeGroupCreating = !recipeGroupCreating
        setupGroupSettings()
        animateNavigationTitileChange()
        animateAddButtonChange()
    }
    
    @objc private func editGroup() {
        if let nav = self.navigationController {
            nav.popToRootViewController(animated: true)
        }
    }

    // MARK: - Private Methods
    private func presentEnterNameAlert() {
        let alert = UIAlertController(title: "What is the group name?", message: nil, preferredStyle: .alert)
        alert.view.tintColor = Colors.appColor
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
                    
        present(alert, animated: true)
    }
    
    private func presentNoRecipesSelectedAlert() {
        let alert = UIAlertController(title: "No recipes selected", message: "Select at least one recipe for the group", preferredStyle: .alert)
        alert.view.tintColor = Colors.appColor
        let cancel = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(cancel)
        present(alert, animated: true)
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
