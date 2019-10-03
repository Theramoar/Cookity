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
    
    private let dataManager = RealmDataManager()
    
    var recipeList: Results<Recipe>? {
        didSet {
            guard SettingsVariables.isCloudEnabled else { return }
            var recipes = [Recipe]()
            for recipe in recipeList! {
                recipes.append(recipe)
            }
            CloudManager.syncData(ofType: .Recipe, parentObjects: recipes)
        }
    }
    
    //MARK:- SearchBar variables
    private var searchController: UISearchController!
    private var filteredRecipeList: [Recipe] = []
    private var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    private var searchBarIsEmpty: Bool {
        guard let text = searchController.searchBar.text else { return false }
        return text.isEmpty
    }
    
    //MARK:- ViewController methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recipeCollection.delegate = self
        recipeCollection.dataSource = self
        
        setupSearchBarController()
    
        //        self.navigationController?.navigationBar.backgroundColor = Colors.appColor
        
        addRecipeButton.layer.shadowOffset = CGSize(width: 0, height: 3.0)
        addRecipeButton.layer.shadowOpacity = 0.7
        addRecipeButton.layer.shadowRadius = 5.0
        
        recipeList = RealmDataManager.dataLoadedFromRealm(ofType: .Recipe)
        loadDataFromCloud()

    }
    
    private func setStandardNavBar() {
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.view.backgroundColor = Colors.appColor
        self.navigationController?.navigationBar.tintColor = Colors.textColor
        self.navigationController?.navigationBar.backgroundColor = Colors.appColor
        self.navigationController?.navigationBar.isTranslucent = false
        setupSearchBarController()
    }
    
    private func setupSearchBarController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.tintColor = Colors.textColor
        searchController.searchBar.backgroundColor = Colors.appColor
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.searchTextField.backgroundColor = .white
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    private func loadDataFromCloud() {
        let recipes = Array(recipeList!)
        CloudManager.loadDataFromCloud(ofType: .Recipe, recipes: recipes, closure: { (parentObject) in
            guard let recipe = parentObject as? Recipe else { return }
            RealmDataManager.saveToRealm(parentObject: nil, object: recipe)
            self.recipeCollection.reloadData()
            CloudManager.loadImageFromCloud(recipe: recipe, closure: { (imageData) in
                guard let data = imageData, let image = UIImage(data: data) else { return }
                let imagePath = RealmDataManager.savePicture(image: image, imageName: recipe.name)
                RealmDataManager.saveToRealm(parentObject: recipe, object: imagePath)
                self.recipeCollection.reloadData()
            })
        })
    }
    
    func updateVC() {
        recipeCollection.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setStandardNavBar()
        recipeCollection.reloadData()
        searchController.searchBar.placeholder = SettingsVariables.isIngridientSearchEnabled ? "Search for recipe or ingridient" : "Search for recipe"
    }

    
    @IBAction func addButtonPressed(_ sender: UIButton) {
      performSegue(withIdentifier: "goToCookingArea", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToRecipe" {
           let destinationVC = segue.destination as! RecipeViewController
            if let indexPath = recipeCollection.indexPathsForSelectedItems?.first{
                let recipe = isFiltering ? filteredRecipeList[indexPath.row] : recipeList?[indexPath.row]
                destinationVC.selectedRecipe = recipe
            }
        }
        else if segue.identifier == "goToCookingArea" {
            let destinationVC = segue.destination as! CookViewController
            destinationVC.updateVCDelegate = self
        }
    }
    
}

extension RecipeCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isFiltering {
            return filteredRecipeList.count
        }
        else {
            return recipeList?.count ?? 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecipeCell", for: indexPath) as! RecipeCollectionViewCell
        cell.recipe = isFiltering ? filteredRecipeList[indexPath.row] : recipeList?[indexPath.row]
        return cell
    }
    

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToRecipe", sender: self)
    }
}

extension RecipeCollectionViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        filteredRecipeList.removeAll()
        var filteredRecipeNames: [String] = [] // заменить потом на уникальный recipe ID
        
        if let filteredRecipes = recipeList?.filter("name CONTAINS[cd] %@", searchText), filteredRecipes.count > 0 {
            filteredRecipeList.append(contentsOf: filteredRecipes)
            filteredRecipes.forEach { (recipe) in
                filteredRecipeNames.append(recipe.name)
            }
        }
        //Search for recipe ingridients
        if SettingsVariables.isIngridientSearchEnabled {
            searchForRecipeIngridients(searchText: searchText, compare: filteredRecipeNames)
        }
        
        recipeCollection.reloadData()
    }
    
    
    private func searchForRecipeIngridients(searchText: String, compare filteredNames: [String]) {
        var recipesContainingProducts: [Recipe] = []
        
        recipeList?.forEach({ (recipe) in
            if recipe.products.filter("name CONTAINS[cd] %@", searchText).count > 0,
                !filteredNames.contains(recipe.name) {
                recipesContainingProducts.append(recipe)
            }
        })
        filteredRecipeList.append(contentsOf: recipesContainingProducts)
    }
}
