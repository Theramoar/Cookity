//
//  CookViewModel.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 13/04/2020.
//  Copyright © 2020 Mihails Kuznecovs. All rights reserved.
//

import RealmSwift

enum CookSections: String, CaseIterable {
    case productSection = "Choose ingridients for the recipe:"
    case stepSection = "Describe cooking process:"
}

class CookViewModel: DetailViewModelType {
    
    private var selectedRecipe: Recipe?
    private var recipeSteps = List<RecipeStep>()
    private var products = List<Product>()
    private var recipeGroup: RecipeGroup?
    let sections = CookSections.allCases
    var currentSection: Int!
    var recipeImage: UIImage?
    
    var recipeName: String {
        selectedRecipe?.name ?? ""
    }
    var isNewRecipe: Bool {
        selectedRecipe == nil
    }
    
    init(recipe: Recipe?) {
        self.selectedRecipe = recipe
        if let recipe = selectedRecipe {
            for product in recipe.products {
                let product = Product(value: product)
                self.products.append(product)
            }
            for recipeStep in recipe.recipeSteps {
                let recipeStep = RecipeStep(value: recipeStep)
                self.recipeSteps.append(recipeStep)
            }
        }
        if let imageFileName = recipe?.imageFileName,
            let image = Configuration.getImageFromFileManager(with: imageFileName) {
            self.recipeImage = image
        }
    }
    
    init(recipeGroup: RecipeGroup) {
        self.recipeGroup = recipeGroup
    }
    
    init(products: List<Product>) {
        self.products = products
    }
    
    
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
        
        if isNewRecipe {
            recipe = Recipe()
            recipe.name = name
            RealmDataManager.saveToRealm(parentObject: nil, object: recipe)
        }
        else {
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
        for product in products {
            RealmDataManager.saveToRealm(parentObject: recipe, object: product)
        }
        
        
        for (index, recipeStep) in recipeSteps.enumerated() {
            recipeStep.position = index
            RealmDataManager.saveToRealm(parentObject: recipe, object: recipeStep)
        }
        
        
        if !RealmDataManager.savePicture(to: recipe, image: recipeImage), let imageFileName = recipe.imageFileName {
            RealmDataManager.deletePicture(withName: imageFileName)
        }
        updateRecipeGroup(with: recipe)
        saveRecipeToCloud(recipe: recipe)
    }
    
    private func saveRecipeToCloud(recipe: Recipe) {
        if isNewRecipe {
            CloudManager.saveParentDataToCloud(object: recipe, objectImageName: recipe.imageFileName) { (recordID) in
                DispatchQueue.main.async {
                    RealmDataManager.changeElementIn(object: recipe,
                                                     keyValue: "cloudID",
                                                     objectParameter: recipe.cloudID,
                                                     newParameter: recordID)
                }
            }
        }
        else {
            CloudManager.updateRecipeInCloud(recipe: recipe)
        }
    }
    
    func checkDataFromTextFields(productName: String, productQuantity: String, productMeasure: String) -> UIAlertController? {
        let alert = UIAlertController(title: "title", message: "message", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { (_) in return }
        alert.addAction(action)
        
        guard alert.check(data: productName, dataName: AlertMessage.name),
        alert.check(data: productQuantity, dataName: AlertMessage.quantity)
        else {
            return (alert)
        }
        return nil
    }
    
    func createNewProduct(productName: String, productQuantity: String, productMeasure: String) {
        let newProduct = Product()
        
        let measure = Configuration.configMeasure(measure: productMeasure)
        let (savedQuantity, savedMeasure) = Configuration.configNumbers(quantity: productQuantity, measure: measure)
        
        newProduct.name = productName
        newProduct.quantity = savedQuantity
        newProduct.measure = savedMeasure
        products.append(newProduct)
    }
    
    func deleteRecipe() {
        if let recipe = selectedRecipe {
            deleteRecipeFromGroup(recipe)
            CloudManager.deleteRecordFromCloud(ofObject: recipe)
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
    
    private func updateRecipeGroup(with recipe: Recipe) {
        guard let name = recipeGroup?.name else { return }
        RealmDataManager.changeElementIn(object: recipe, keyValue: "recipeGroup", objectParameter: recipe.recipeGroup, newParameter: name)
        NotificationCenter.default.post(name: NSNotification.Name(NotificationNames.groupIsUpdated), object: nil)
    }
    private func deleteRecipeFromGroup(_ recipe: Recipe) {
        RealmDataManager.changeElementIn(object: recipe, keyValue: "recipeGroup", objectParameter: recipe.recipeGroup, newParameter: "")
        NotificationCenter.default.post(name: NSNotification.Name(NotificationNames.groupIsUpdated), object: nil)
    }
    
    private func configureNumbers() {
            for product in products {
                let quantityString = String(product.quantity)
                (product.quantity, product.measure) = Configuration.configNumbers(quantity: quantityString, measure: product.measure)
            }
        }
}

extension CookViewModel: TableViewModelType {
    var numberOfRows: Int {
        if currentSection == 0 {
              return (products.count) + 1
        }
        else {
              return (recipeSteps.count) + 1
        }
    }
    
    var numberOfSections: Int {
        sections.count
    }
    
    func cellViewModel(forIndexPath indexPath: IndexPath) -> CellViewModelType? {
        if indexPath.section == 0, indexPath.row != 0 {
            return CookCellViewModel(product: products[indexPath.row - 1])
        }
        else if indexPath.row != 0 {
            return RecipeStepCellViewModel(step: recipeSteps[indexPath.row - 1])
        }
        return nil
    }
    
    func viewModelForSelectedRow() -> DetailViewModelType? { nil }
    func selectRow(atIndexPath indexPath: IndexPath) { }
    func currentSection(_ section: Int) {
        currentSection = section
    }
    
    func moveObjects(from sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath.section == 0, destinationIndexPath.section == 0 {
            let movedObject = products[sourceIndexPath.row - 1]
            products.remove(at: sourceIndexPath.row - 1)
            products.insert(movedObject, at: destinationIndexPath.row - 1)
        }
        else if sourceIndexPath.section == 1, destinationIndexPath.section == 1 {
            let movedObject = recipeSteps[sourceIndexPath.row - 1]
            recipeSteps.remove(at: sourceIndexPath.row - 1)
            recipeSteps.insert(movedObject, at: destinationIndexPath.row - 1)
        }
    }
}
