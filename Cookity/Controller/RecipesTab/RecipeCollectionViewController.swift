//
//  RecipeCollectionViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 25/11/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift

class RecipeCollectionViewController: UIViewController, UpdateVCDelegate {
    
    @IBOutlet weak var recipeCollection: UICollectionView!
    @IBOutlet weak var addRecipeButton: UIButton!
    
    @IBOutlet weak var bookImageView: UIImageView!
    @IBOutlet weak var bookMainLabel: UILabel!
    @IBOutlet weak var bookSecondaryLabel: UILabel!
    
    var viewModel = RecipeCollectionViewModel()
    
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

        addRecipeButton.layer.shadowOffset = CGSize(width: 0, height: 3.0)
        addRecipeButton.layer.shadowOpacity = 0.7
        addRecipeButton.layer.shadowRadius = 5.0
        
        viewModel.loadDataFromCloud {
            self.recipeCollection.reloadData()
        }
    }
    
    private func setStandardNavBar() {
        searchController = setupSearchBarController()
        navigationItem.searchController = searchController
        self.navigationController?.definesPresentationContext = true
    }
    
    private func setupSearchBarController() -> UISearchController {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        return searchController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setStandardNavBar()
        updateVC()
        searchController.searchBar.placeholder = SettingsVariables.isIngridientSearchEnabled ? "Search for recipe or ingridient" : "Search for recipe"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToRecipe" {
           let destinationVC = segue.destination as! RecipeViewController
            destinationVC.viewModel = viewModel.viewModelForSelectedRow() as? RecipeViewModel
        }
        else if segue.identifier == "goToCookingArea" {
            let destinationVC = segue.destination as! CookViewController
            destinationVC.viewModel = viewModel.viewModelForNewRecipe()
            destinationVC.updateVCDelegate = self
        }
    }
    
    //MARK:- UpdateVCDelegate Method
    func updateVC() {
        recipeCollection.reloadData()
    }

    //MARK:- Methods for Buttons
    @IBAction func addButtonPressed(_ sender: UIButton) {
      performSegue(withIdentifier: "goToCookingArea", sender: self)
    }
}

//MARK:- RecipeCollection Delegate and DataSource
extension RecipeCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        bookImageView.isHidden = !viewModel.isRecipeListEmpty
        bookMainLabel.isHidden = !viewModel.isRecipeListEmpty
        bookSecondaryLabel.isHidden = !viewModel.isRecipeListEmpty
        return viewModel.numberOfRows
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecipeCell", for: indexPath) as! RecipeCollectionViewCell
        cell.viewModel = viewModel.cellViewModel(forIndexPath: indexPath)  as? RecipeCollectionCellViewModel
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectRow(atIndexPath: indexPath)
        performSegue(withIdentifier: "goToRecipe", sender: self)
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
