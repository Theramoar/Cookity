//
//  CookDataManager.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 08/10/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit


class CookDataManager: RecipeDataManager {
    
    
    func saveStep(step: String) {
        let newStep = RecipeStep()
        newStep.name = step
        recipeSteps.append(newStep)
    }
    
    
    func deleteObject(at indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            products.remove(at: indexPath.row - 1)
        case 1:
            recipeSteps.remove(at: indexPath.row - 1)
        default:
            return
        }
    }
    
    
    func saveRecipe(withName name: String) {
        configureNumbers()
        var recipe: Recipe
        
        if selectedRecipe != nil {
            recipe = selectedRecipe!
            let newName = name
            RealmDataManager.changeElementIn(object: recipe, keyValue: "name", objectParameter: recipe.name, newParameter: newName)
            for product in recipe.products {
                RealmDataManager.deleteFromRealm(object: product)
            }
            for recipeStep in recipe.recipeSteps {
                RealmDataManager.deleteFromRealm(object: recipeStep)
            }
        }
        else {
            recipe = Recipe()
            recipe.name = name
            RealmDataManager.saveToRealm(parentObject: nil, object: recipe)
        }

        for product in products {
            RealmDataManager.saveToRealm(parentObject: recipe, object: product)
        }
        
        
        for recipeStep in recipeSteps {
            RealmDataManager.saveToRealm(parentObject: recipe, object: recipeStep)
        }
        
        
        if let imageFileName = RealmDataManager.savePicture(image: recipeImage, imageName: recipe.name) {
            RealmDataManager.saveToRealm(parentObject: recipe, object: imageFileName)
        }
        else if let imageFileName = recipe.imageFileName {
            RealmDataManager.deletePicture(withName: imageFileName)
        }
        
        saveRecipeToCloud(recipe: recipe)
    }
    
    
    private func saveRecipeToCloud(recipe: Recipe) {
        if selectedRecipe != nil {
            CloudManager.updateRecipeInCloud(recipe: recipe)
        }
        else {
            CloudManager.saveDataToCloud(ofType: .Recipe, object: recipe) { (recordID) in
                DispatchQueue.main.async {
                    RealmDataManager.changeElementIn(object: recipe,
                                                     keyValue: "cloudID",
                                                     objectParameter: recipe.cloudID,
                                                     newParameter: recordID)
                }
            }
        }
    }
    
    func deleteRecipe() {
        if let recipe = selectedRecipe {
            if let cloudID = recipe.cloudID {
                CloudManager.deleteRecordFromCloud(ofType: .Recipe, recordID: cloudID)
            }
            for product in recipe.products {
                RealmDataManager.deleteFromRealm(object: product)
            }
            for step in recipe.recipeSteps {
                RealmDataManager.deleteFromRealm(object: step)
            }
            if let imageFileName = recipe.imageFileName {
               RealmDataManager.deletePicture(withName: imageFileName)
            }
            RealmDataManager.deleteFromRealm(object: recipe)
            
        }
        products.removeAll()
    }
    
    
    private func configureNumbers() {
          for product in products {
              let quantityString = String(product.quantity)
              (product.quantity, product.measure) = Configuration.configNumbers(quantity: quantityString,
                                                                                measure: product.measure)
          }
      }
}
