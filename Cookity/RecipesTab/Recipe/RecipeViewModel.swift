//
//  RecipeViewModel.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 12/04/2020.
//  Copyright © 2020 Mihails Kuznecovs. All rights reserved.
//

import RealmSwift


class RecipeViewModel: DetailViewModelType {
    
    let sections = ["Name", "Ingridients:", "Cooking steps:"]
    var currentSection: Int!
    private var selectedRecipe: Recipe
    
    var recipeName: String {
        selectedRecipe.name
    }
    var isRecipeInvalidated: Bool {
        selectedRecipe.isInvalidated
    }
    var recipeStepsCount: Int {
        selectedRecipe.recipeSteps.count
    }
    var productsCount: Int {
        selectedRecipe.products.count
    }
    var recipeImage: UIImage? {
        guard let imageFileName = selectedRecipe.imageFileName else  { return nil }
        return Configuration.getImageFromFileManager(with: imageFileName)
    }
    
    
    init(recipe: Recipe) {
        self.selectedRecipe = recipe
    }
    
    
    func compareFridgeToRecipe(selectedProduct: Product) -> [String : Product] {
        var chosenProducts = [String : Product]()
        for product in Fridge.shared.products {
            if selectedProduct.name == product.name{
                chosenProducts[selectedProduct.name] = product
            }
        }
        return chosenProducts
    }
    
    func editFridgeProducts() {
        // The loop compares if there is a similar product in the fridge. If Yes - edits this product in the fridge
        for recipeProduct in selectedRecipe.products {
            let chosenProducts = compareFridgeToRecipe(selectedProduct: recipeProduct)
                if let selectedProduct = chosenProducts[recipeProduct.name] {
                    //If the quantity of the product in Recipe is less than in the Fridge substracts it, else deletes it from the fridge
                    if recipeProduct.quantity >= selectedProduct.quantity {
                        CloudManager.deleteRecordFromCloud(ofObject: selectedProduct)
                        RealmDataManager.deleteFromRealm(object: selectedProduct)
                    }
                    else{
                        let newQuantity = selectedProduct.quantity - recipeProduct.quantity
                        RealmDataManager.changeElementIn(object: selectedProduct, keyValue: "quantity", objectParameter: selectedProduct.quantity, newParameter: newQuantity)
                        CloudManager.updateChildInCloud(childObject: selectedProduct)
                    }
                }
        }
    }
    
    func shareRecipet(as type: ExportType) -> UIActivityViewController? {
        let shareManager = ShareDataManager()
        
        switch type {
        case .text:
            let exportMessage = shareManager.prepareExportMessage(for: selectedRecipe)
            let activity = UIActivityViewController(
            activityItems: [exportMessage],
            applicationActivities: nil)
            return activity
        case .file:
            guard let url = shareManager.exportToURL(object: selectedRecipe)
            else { return nil }
            let activity = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil)
            return activity
        }
    }
    
    func createCartFromRecipe() {
        let products = List<Product>()
        for product in selectedRecipe.products {
            let coppiedProduct = Product(value: product)
            products.append(coppiedProduct)
        }
        saveCart(name: selectedRecipe.name, products: products)
    }
    
    private func saveCart(name: String, products: List<Product>) {
        let cart = ShoppingCart()
        cart.name = name
        for product in products {
            cart.products.append(product)
        }
        RealmDataManager.saveToRealm(parentObject: nil, object: cart)
        CloudManager.saveParentDataToCloud(object: cart, objectImageName: nil) { (recordID) in
            DispatchQueue.main.async {
                RealmDataManager.changeElementIn(object: cart,
                                                 keyValue: "cloudID",
                                                 objectParameter: cart.cloudID,
                                                 newParameter: recordID)
            }
        }
    }
}

extension RecipeViewModel: TableViewModelType {
    var numberOfRows: Int {
        if currentSection == 1 {
            return selectedRecipe.products.count.advanced(by: 1)
        }
        else if currentSection == 2 {
            return selectedRecipe.recipeSteps.count
        }
        else {
            return 0
        }
    }
    
    var numberOfSections: Int {
        if selectedRecipe.recipeSteps.count == 0 { return 2 }
        return sections.count
    }
    
    func cellViewModel(forIndexPath indexPath: IndexPath) -> CellViewModelType? {
        if indexPath.section == 1 {
            return RecipeProductCellViewModel(product: selectedRecipe.products[indexPath.row])
        }
        else {
            return RVRecipeStepCellViewModel(recipeStep: selectedRecipe.recipeSteps[indexPath.row], stepPosition: indexPath.row + 1)
        }
    }
    
    func viewModelForCookProcess() -> CookProcessViewModel {
        CookProcessViewModel(recipeSteps: selectedRecipe.recipeSteps)
    }
    
    func viewModelForCookVC() -> CookViewModel {
        CookViewModel(recipe: selectedRecipe)
    }
    
    func viewModelForSelectedRow() -> DetailViewModelType? { nil }
    func selectRow(atIndexPath indexPath: IndexPath) { }
    func currentSection(_ section: Int) {
        currentSection = section
    }
}
