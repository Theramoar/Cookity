//
//  CartViewModel.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 12/04/2020.
//  Copyright © 2020 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift

enum ExportType {
    case text
    case file
}


class CartViewModel: DetailViewModelType {
    
    private var products = List<Product>()
    private var productsInFridge = Fridge.shared.products
    private var selectedCart: ShoppingCart?
    private var selectedIndexPath: IndexPath?
    
    var cartName: String {
        selectedCart?.name ?? ""
    }
    
    init(cart: ShoppingCart) {
        self.selectedCart = cart
        products = cart.products
    }
    
    func saveProductToCart(product: Product) {
        guard let cart = selectedCart else { return }
        RealmDataManager.saveToRealm(parentObject: cart, object: product)
        CloudManager.saveChildrenDataToCloud(objects: [product], to: cart)
        
    }
    
    func deleteProductFromCart(at position: Int) {
        let product = products[position]
        CloudManager.deleteRecordFromCloud(ofObject: product)
        RealmDataManager.deleteFromRealm(object: product)
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
    
    func createNewProduct(productName: String, productQuantity: String, productMeasure: String) -> Product {
        let newProduct = Product()
        
        let measure = Configuration.configMeasure(measure: productMeasure)
        let (savedQuantity, savedMeasure) = Configuration.configNumbers(quantity: productQuantity, measure: measure)
        
        newProduct.name = productName
        newProduct.quantity = savedQuantity
        newProduct.measure = savedMeasure
        
        return newProduct
    }
    
    
    func checkProduct(at position: Int) -> Bool {
        guard let products = selectedCart?.products else { return false }
        
        let product = products[position]
        RealmDataManager.changeElementIn(object: product,
                                    keyValue: "checked",
                                    objectParameter: product.checked,
                                    newParameter: !product.checked)
        //If all products are checked, App offers to add them to the Fridge
        for product in products {
            guard product.checked == true else { return false }
        }
        return true
    }
    
    func shareCart(as type: ExportType) -> UIActivityViewController? {
        let shareManager = ShareDataManager()
        guard
            let cart = selectedCart,
            let url = shareManager.exportToURL(object: cart)
            else { return nil }
        
        switch type {
        case .text:
            let exportMessage = shareManager.prepareExportMessage(for: cart)
            let activity = UIActivityViewController(
            activityItems: [exportMessage],
            applicationActivities: nil)
            return activity
        case .file:
            let activity = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil)
            return activity
        }

    }
       
       
    func moveProductsToFridge() {
        guard let cart = selectedCart else { return }
        let products = cart.products
        var copiedProducts = [Product]()
        for product in products {
            setDefaultExpirationDate(for: product)
//            Checks if the similar product is already in the fridge
            for fridgeProduct in productsInFridge{
//                 if products name and measure coincide, adds quantity and deletes product from the shopping list
                if product.name.lowercased() == fridgeProduct.name.lowercased() && product.measure == fridgeProduct.measure {
                    let newQuantity = fridgeProduct.quantity + product.quantity
                    RealmDataManager.changeElementIn(object: fridgeProduct,
                                                     keyValue: "quantity",
                                                     objectParameter: fridgeProduct.quantity,
                                                     newParameter: newQuantity)
                    RealmDataManager.deleteFromRealm(object: product)
                    CloudManager.updateChildInCloud(childObject: fridgeProduct)
                    break
                }
            }
            if product.isInvalidated == false{
                let coppiedProduct = Product(value: product)
                coppiedProduct.cloudID = nil
                coppiedProduct.checked = false
                RealmDataManager.saveToRealm(parentObject: Fridge.shared, object: coppiedProduct)
                RealmDataManager.deleteFromRealm(object: product)
                copiedProducts.append(coppiedProduct)
            }
        }
        CloudManager.saveChildrenDataToCloud(objects: copiedProducts, to: Fridge.shared)
        
//        Delete Cart from Cloud
        CloudManager.deleteRecordFromCloud(ofObject: cart)
        RealmDataManager.deleteFromRealm(object: cart)
    }
    
    
    func setDefaultExpirationDate(for product: Product) {
        guard SettingsVariables.isDefaultDateEnabled, product.expirationDate == nil else { return }
        let date = Date()
        let days = SettingsVariables.defaultExpirationDate
        let addbyUnit = Calendar.Component.day
        let endDate = Calendar.current.date(byAdding: addbyUnit, value: days, to: date)
        
        RealmDataManager.changeElementIn(object: product, keyValue: "expirationDate", objectParameter: product.expirationDate, newParameter: endDate)
    }
}

extension CartViewModel: TableViewModelType {
    var numberOfRows: Int {
        products.count
    }
    var numberOfSections: Int {
        0
    }
    
    func cellViewModel(forIndexPath indexPath: IndexPath) -> CellViewModelType? {
        ProductTableCellViewModel(product: products[indexPath.row], forTable: .cart)
    }
    
    func viewModelForSelectedRow() -> DetailViewModelType? {
        guard let row = selectedIndexPath?.row else { return nil }
        return PopupEditViewModel(product: products[row])
    }
    
    func selectRow(atIndexPath indexPath: IndexPath) {
    }
    
    func longTapRow(atIndexPath indexPath: IndexPath) {
        selectedIndexPath = indexPath
    }
}
