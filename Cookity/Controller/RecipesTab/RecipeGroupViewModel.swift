//
//  RecipeGroupViewModel.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 24/05/2020.
//  Copyright © 2020 Mihails Kuznecovs. All rights reserved.
//

import RealmSwift

class RecipeGroupViewModel : DetailViewModelType, RemoveFromGroupDelegate {
    private var recipeGroup: RecipeGroup
    var recipeCollectionType: RecipeCollectionType
    
    init(recipeGroup: RecipeGroup, collectionType: RecipeCollectionType) {
        self.recipeGroup = recipeGroup
        self.recipeCollectionType = collectionType
    }
    
//MARK:- Variables to recipeGroupCollection Type
    private var selectedIndexPath: IndexPath?
    var isGroupEdited: Bool = false
    var groupName: String {
        recipeGroup.name
    }

//MARK:- Variables to addRecipeToGroupCollection Type
    private var selectedRecipesForGroup: [Recipe] = []
    var numberOfSelectedRecipes: Int {
        selectedRecipesForGroup.count
    }
    
//MARK:- Methods to recipeGroupCollection Type
    func fillRecipeGroup() {
        recipeGroup.recipes.removeAll()
        RealmDataManager.dataLoadedFromRealm(ofType: Recipe.self)?.forEach{
            if $0.recipeGroup == self.recipeGroup.name {
                recipeGroup.recipes.append($0)
            }
        }
    }
    
    func saveGroupName(_ name: String) {
        recipeGroup.name = name
        recipeGroup.recipes.forEach {
            RealmDataManager.changeElementIn(object: $0, keyValue: "recipeGroup", objectParameter: $0.recipeGroup, newParameter: name)
        }
    }
    
    func deleteGroup() {
        let recipes = recipeGroup.recipes
        recipes.forEach({
            RealmDataManager.changeElementIn(object: $0, keyValue: "recipeGroup", objectParameter: $0.recipeGroup, newParameter: "")
        })
    }
    
    func removeRecipeFromGroup(at indexPath: IndexPath) {
        let recipe =  recipeGroup.recipes[indexPath.row]
        RealmDataManager.changeElementIn(object: recipe, keyValue: "recipeGroup", objectParameter: recipe.recipeGroup, newParameter: "")
        recipeGroup.recipes.remove(at: indexPath.row)
        NotificationCenter.default.post(name: NSNotification.Name(NotificationNames.groupIsUpdated), object: nil)
    }
    
    
    func viewModelForNewRecipe() -> CookViewModel {
        CookViewModel(recipeGroup: recipeGroup)
    }
    
    func viewModelForExistingRecipes() -> RecipeGroupViewModel {
        let recipeList = RealmDataManager.dataLoadedFromRealm(ofType: Recipe.self)
        var noGroupRecipes = [Recipe]()
        recipeList?.forEach({
            if $0.recipeGroup == nil {
                noGroupRecipes.append($0)
            }
            else if $0.recipeGroup!.isEmpty {
                noGroupRecipes.append($0)
            }
        })
        let noGroupRecipesGroup = RecipeGroup(name: "\(groupName)", recipes: noGroupRecipes)
        return RecipeGroupViewModel(recipeGroup: noGroupRecipesGroup, collectionType: .addRecipeToGroupCollection)
    }
    
//MARK:- Methods to addRecipeToGroupCollection Type
    func selectRecipeForGroup(atIndexPath indexPath: IndexPath, completion: @escaping () -> ()) {
        //Добавить filtered recipe??
        let recipe = recipeGroup.recipes[indexPath.row]
        RealmDataManager.changeElementIn(object: recipe, keyValue: "checkedForGroup", objectParameter: recipe.checkedForGroup, newParameter: !recipe.checkedForGroup)
        if recipe.checkedForGroup {
            selectedRecipesForGroup.append(recipe)
        }
        else {
            selectedRecipesForGroup.removeAll(where: {$0 == recipe})
        }
        completion()
    }
    
    func appendExistingRecipesToGroup() {
        selectedRecipesForGroup.forEach{
            RealmDataManager.changeElementIn(object: $0, keyValue: "checkedForGroup", objectParameter: $0.checkedForGroup, newParameter: false)
            RealmDataManager.changeElementIn(object: $0, keyValue: "recipeGroup", objectParameter: $0.recipeGroup, newParameter: groupName)
        }
    }
}


//MARK: - TableViewModelType Methods
extension RecipeGroupViewModel: TableViewModelType {
    var numberOfRows: Int {
        recipeGroup.recipes.count
    }
    
    var numberOfSections: Int {
        0
    }
    
    func cellViewModel(forIndexPath indexPath: IndexPath) -> CellViewModelType? {
        let vm = RecipeCollectionCellViewModel(recipe: recipeGroup.recipes[indexPath.row], cellIndexPath: indexPath)
        vm.isCellEdited = isGroupEdited
        vm.removeRecipeDelegate = self
        return vm
    }
    
    func viewModelForSelectedRow() -> DetailViewModelType? {
        guard let row = selectedIndexPath?.row else { return nil }
        return RecipeViewModel(recipe: recipeGroup.recipes[row])
    }
    
    func selectRow(atIndexPath indexPath: IndexPath) {
        selectedIndexPath = indexPath
    }
}
