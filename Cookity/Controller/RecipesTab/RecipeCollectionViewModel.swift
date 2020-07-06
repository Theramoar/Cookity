//
//  RecipeCollectionViewModel.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 12/04/2020.
//  Copyright © 2020 Mihails Kuznecovs. All rights reserved.
//

import RealmSwift
import UIKit

class RecipeGroup {
    var name: String
    var recipes = [Recipe]()
    
    init(name: String, recipes: [Recipe]) {
        self.name = name
        self.recipes = recipes
    }
}

class RecipeCollectionViewModel {
    
    
    private var filteredRecipeList: [Recipe] = []
    private var recipeList: Results<Recipe>?
    private var recipeGroups = [RecipeGroup]()
    private var noGroupRecipes = [Recipe]()
    var recipeCollectionType: RecipeCollectionType

    

    
    private var selectedRecipesForGroup: [Recipe] = []
    var isFiltering: Bool
    
    var isRecipeListEmpty: Bool {
        recipeList?.isEmpty ?? true
    }
    var numberOfSelectedRecipes: Int {
        selectedRecipesForGroup.count
    }
    var numberOfGroups: Int {
        recipeGroups.count
    }
    
    private var selectedIndexPath: IndexPath?
    private var currentSection: Int?
    
    init() {
        self.recipeCollectionType = .recipCollection
        recipeList = RealmDataManager.dataLoadedFromRealm(ofType: Recipe.self)
        self.isFiltering = false
        self.fillRecipeGroups()
    }
    
    private func fillRecipeGroups() {
        recipeGroups.removeAll()
        noGroupRecipes.removeAll()
        recipeList?.forEach({
            if !$0.recipeGroup.isEmpty {
                let groupName = $0.recipeGroup
                if let recipeGroup = recipeGroups.first(where: {$0.name == groupName}) {
                    recipeGroup.recipes.append($0)
                }
                else {
                    recipeGroups.append(RecipeGroup(name: groupName, recipes: [$0]))
                }
            }
            else {
                noGroupRecipes.append($0)
            }
        })
    }
    
    func updateviewModel() {
        fillRecipeGroups()
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
    
    
    
    func createGroupWith(name: String) -> Bool {
        guard !selectedRecipesForGroup.isEmpty else { return false }
        selectedRecipesForGroup.forEach({
            RealmDataManager.changeElementIn(object: $0, keyValue: "recipeGroup", objectParameter: $0.recipeGroup, newParameter: name)
//            CloudManager.updateRecipeGroupInCloud(for: $0)
            CloudManager.updateRecipeInCloud(recipe: $0)
        })
        uncheckRecipes()
        fillRecipeGroups()
        return true
    }
    
    func uncheckRecipes() {
        selectedRecipesForGroup.forEach({
            RealmDataManager.changeElementIn(object: $0, keyValue: "checkedForGroup", objectParameter: $0.checkedForGroup, newParameter: false)
        })
        selectedRecipesForGroup.removeAll()
    }
    
}

extension RecipeCollectionViewModel: TableViewModelType {
    
    var numberOfRows: Int {
        if isFiltering {
            return filteredRecipeList.count
        }
        else if numberOfGroups == 0 {
            return noGroupRecipes.count
        }
        else {
            switch currentSection {
            case 0: return recipeGroups.count
            case 1: return noGroupRecipes.count
            default:
                return 0
            }
        }
    }
    
    var numberOfSections: Int {
        if isFiltering {
            return 1
        }
        else if numberOfGroups == 0 {
            return 1
        }
        else {
            return 2
        }
            
    }
    
    func numberOfRowsForCurrentSection(_ section: Int) -> Int {
        currentSection = section
        return numberOfRows
    }
    
    func cellViewModel(forIndexPath indexPath: IndexPath) -> CellViewModelType? {
        if isFiltering {
            let recipe = filteredRecipeList[indexPath.row]
            return RecipeCollectionCellViewModel(recipe: recipe)
        }
        else if numberOfGroups == 0 {
            let recipe = noGroupRecipes[indexPath.row]
            return RecipeCollectionCellViewModel(recipe: recipe)
        }
        
        if indexPath.section == 0 {
            let vm = RecipeGroupCellViewModel(recipeGroup: recipeGroups[indexPath.row])
            return vm
        }
        else {
            let recipe = noGroupRecipes[indexPath.row]
            return RecipeCollectionCellViewModel(recipe: recipe)
        }
        
        
        
    }
    
    func viewModelForSelectedRow() -> DetailViewModelType? {
        guard let row = selectedIndexPath?.row else { return nil }
        let recipe = isFiltering ? filteredRecipeList[row] : noGroupRecipes[row]
        return RecipeViewModel(recipe: recipe)
    }
    
    func selectRow(atIndexPath indexPath: IndexPath) {
        selectedIndexPath = indexPath
    }
    
    func selectRecipeForGroup(atIndexPath indexPath: IndexPath, completion: @escaping () -> ()) {
        //Добавить filtered recipe??
        let recipe = noGroupRecipes[indexPath.row]
        RealmDataManager.changeElementIn(object: recipe, keyValue: "checkedForGroup", objectParameter: recipe.checkedForGroup, newParameter: !recipe.checkedForGroup)
        if recipe.checkedForGroup {
            selectedRecipesForGroup.append(recipe)
        }
        else {
            selectedRecipesForGroup.removeAll(where: {$0 == recipe})
        }
        completion()
    }
    
    func viewModelForNewRecipe() -> CookViewModel {
        CookViewModel(recipe: nil)
    }
}
