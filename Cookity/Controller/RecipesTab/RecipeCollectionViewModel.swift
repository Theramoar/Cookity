//
//  RecipeCollectionViewModel.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 12/04/2020.
//  Copyright © 2020 Mihails Kuznecovs. All rights reserved.
//

import RealmSwift
import UIKit

class RecipeCollectionViewModel {
    
    private var filteredRecipeList: [Recipe] = []
    private var recipeList: Results<Recipe>?
    var isFiltering: Bool
    var isImageInSelectedRow: Bool = false
    var isRecipeListEmpty: Bool {
        recipeList?.isEmpty ?? true
    }
    private var selectedIndexPath: IndexPath?
    
    init() {
        recipeList = RealmDataManager.dataLoadedFromRealm(ofType: Recipe.self)
        self.isFiltering = false
    }
    
    func loadDataFromCloud(completion: @escaping() -> ()) {
        let recipes = Array(recipeList!)
        CloudManager.syncData(parentObjects: recipes)
        CloudManager.loadDataFromCloud(objects: recipes, closure: { (parentObjects) in
            parentObjects.forEach { (recipe) in
                RealmDataManager.saveToRealm(parentObject: nil, object: recipe)
                completion()
                CloudManager.loadImageFromCloud(recipe: recipe, closure: { (imageData) in
                    guard let data = imageData, let image = UIImage(data: data) else { return }
                    _ = RealmDataManager.savePicture(to: recipe, image: image)
                    completion()
                })
            }
        })
    }
    
    
    //MARK:- Methods for Search Process
    func updateSearchResults(with searchText: String) {
        filteredRecipeList.removeAll()
        var filteredRecipeNames: [String] = []
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

extension RecipeCollectionViewModel: TableViewModelType {
    
    var numberOfRows: Int {
        if isFiltering {
            return filteredRecipeList.count
        }
        else {
            return recipeList?.count ?? 0
        }
    }
    
    var numberOfSections: Int {
        0
    }
    
    func cellViewModel(forIndexPath indexPath: IndexPath) -> CellViewModelType? {
        guard let recipe = isFiltering ? filteredRecipeList[indexPath.row] : recipeList?[indexPath.row] else { return nil }
        return RecipeCollectionCellViewModel(recipe: recipe)
    }
    
    func viewModelForSelectedRow() -> DetailViewModelType? {
        guard let row = selectedIndexPath?.row,
            let recipe = isFiltering ? filteredRecipeList[row] : recipeList?[row]
        else { return nil }
        isImageInSelectedRow = recipe.getImageFromFileManager() != nil ? true : false
        return RecipeViewModel(recipe: recipe)
    }
    
    func selectRow(atIndexPath indexPath: IndexPath) {
        selectedIndexPath = indexPath
        if let recipe = isFiltering ? filteredRecipeList[indexPath.row] : recipeList?[indexPath.row] {
            isImageInSelectedRow = recipe.getImageFromFileManager() != nil ? true : false
        }
        
    }
    
    func viewModelForNewRecipe() -> CookViewModel {
        CookViewModel(recipe: nil)
    }
    
    
}
