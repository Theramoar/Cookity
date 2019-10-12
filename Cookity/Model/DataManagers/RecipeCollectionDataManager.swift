//
//  RecipeCollectionDataManager.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 12/10/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import RealmSwift


class RecipeCollectionDataManager: DataManager {
    
    var filteredRecipeList: [Recipe] = []
    var updateVCDelegate: UpdateVCDelegate?
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

    func setupSearchBarController() -> UISearchController {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.tintColor = Colors.textColor
        searchController.searchBar.backgroundColor = Colors.appColor
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.searchTextField.backgroundColor = .white
        return searchController
    }
    
    func loadDataFromCloud() {
        let recipes = Array(recipeList!)
        CloudManager.loadDataFromCloud(ofType: .Recipe, recipes: recipes, closure: { (parentObject) in
            guard let recipe = parentObject as? Recipe else { return }
            RealmDataManager.saveToRealm(parentObject: nil, object: recipe)
            self.updateVCDelegate?.updateVC()
            CloudManager.loadImageFromCloud(recipe: recipe, closure: { (imageData) in
                guard let data = imageData, let image = UIImage(data: data) else { return }
                let imagePath = RealmDataManager.savePicture(image: image, imageName: recipe.name)
                RealmDataManager.saveToRealm(parentObject: recipe, object: imagePath)
                self.updateVCDelegate?.updateVC()
            })
        })
    }
}

extension RecipeCollectionDataManager: UISearchResultsUpdating {
    
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
        updateVCDelegate?.updateVC()
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
