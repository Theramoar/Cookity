//
//  RecipeDataManager.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 08/10/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift


class RecipeDataManager: DataManager {
    
    var selectedRecipe: Recipe? {
        didSet{
            configDataManager()
        }
    }
    var recipeImage: UIImage?
    var recipeSteps = List<RecipeStep>()
    var chosenProducts = [String : Product]() // The variable is used to store the products chosen from the Fridge list. The Key - name of the Recipe Product
    
    
    func configDataManager() {
        guard let recipe = selectedRecipe else { return }
        for product in recipe.products {
            let product = Product(value: product)
            products.append(product)
        }
        for recipeStep in recipe.recipeSteps {
            let recipeStep = RecipeStep(value: recipeStep)
            recipeSteps.append(recipeStep)
        }
        if let imageFileName = recipe.imageFileName,
            let image = Configuration.getImageFromFileManager(with: imageFileName) {
            recipeImage = image
        }
    }
    
    func compareFridgeToRecipe(selectedProduct: Product) -> Bool{
        for product in productsInFridge {
            if selectedProduct.name == product.name{
                chosenProducts[selectedProduct.name] = product
                return true
            }
        }
        return false
    }
    
    func editFridgeProducts() {
        // The loop compares if there is a similar product in the fridge. If Yes - edits this product in the fridge
        for recipeProduct in products {
            if compareFridgeToRecipe(selectedProduct: recipeProduct) == true {
                if let selectedProduct = chosenProducts[recipeProduct.name] {
                    //If the quantity of the product in Recipe is less than in the Fridge substracts it, else deletes it from the fridge
                    if recipeProduct.quantity >= selectedProduct.quantity {
                        RealmDataManager.deleteFromRealm(object: selectedProduct)
                    }
                    else{
                        let newQuantity = selectedProduct.quantity - recipeProduct.quantity
                        RealmDataManager.changeElementIn(object: selectedProduct, keyValue: "quantity", objectParameter: selectedProduct.quantity, newParameter: newQuantity)
                    }
                }
            }
        }
    }
    
    func createCartFromRecipe() {
        guard let cartName = selectedRecipe?.name, let recipe = selectedRecipe else { return }
        let products = List<Product>()
        for product in recipe.products {
            let coppiedProduct = Product(value: product)
            products.append(coppiedProduct)
        }
        saveCart(name: cartName, products: products)
    }
}
