//
//  CartCollectionViewModel.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 12/04/2020.
//  Copyright © 2020 Mihails Kuznecovs. All rights reserved.
//

import Foundation
import RealmSwift

protocol TableViewModelType {
    var numberOfRows: Int { get }
    var numberOfSections: Int { get }
    func cellViewModel(forIndexPath indexPath: IndexPath) -> CellViewModelType?
    func viewModelForSelectedRow() -> DetailViewModelType?
    func selectRow(atIndexPath indexPath: IndexPath)
}

protocol DetailViewModelType { }

protocol CellViewModelType { }




class CartCollectionViewModel {
    
    private var products = List<Product>()
    private var productsInFridge = Fridge.shared.products
    private var selectedIndexPath: IndexPath?
    
    private var shoppingCarts: Results<ShoppingCart>?
    
    var cartCollectionIsEmpty: Bool {
        shoppingCarts?.isEmpty ?? true
    }
    
    init() {
        shoppingCarts = RealmDataManager.dataLoadedFromRealm(ofType: ShoppingCart.self)
        productsInFridge = Fridge.shared.products
    }
    
    func deleteCart(at position: Int) {
        guard let cart = shoppingCarts?[position] else { return }
        for product in cart.products {
            RealmDataManager.deleteFromRealm(object: product)
        }
        CloudManager.deleteRecordFromCloud(ofObject: cart)
        RealmDataManager.deleteFromRealm(object: cart)
    }
    
    
    func moveProductsToFridge(fromCartAtIndexPath indexPath: IndexPath) {
        guard let cart = shoppingCarts?[indexPath.row] else { return }
        let products = cart.products
        var copiedProducts = [Product]()
        for product in products {
            setDefaultExpirationDate(for: product)
            //Checks if the similar product is already in the fridge
            for fridgeProduct in productsInFridge{
                // if products name and measure coincide, adds quantity and deletes product from the shopping list
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
        
        //Delete Cart from Cloud
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
    
    func loadCartsFromCloud(completion: @escaping () -> ()) {
        guard let carts = shoppingCarts else { return }
        let objects = Array(carts)
        CloudManager.syncData(parentObjects: objects)
        CloudManager.loadDataFromCloud(objects: objects) { (parentObjects) in
            parentObjects.forEach { (cart) in
                RealmDataManager.saveToRealm(parentObject: nil, object: cart)
            }
            
        }
    }
}

extension CartCollectionViewModel: TableViewModelType {
    var numberOfRows: Int {
        shoppingCarts?.count ?? 0
    }
    
    var numberOfSections: Int {
        0
    }
    
    func cellViewModel(forIndexPath indexPath: IndexPath) -> CellViewModelType? {
        guard let cart = shoppingCarts?[indexPath.row] else { return nil }
        return CartCellViewModel(cart: cart)
    }
    
    func viewModelForSelectedRow() -> DetailViewModelType? {
        guard let row = selectedIndexPath?.row, let cart = shoppingCarts?[row] else { return nil }
        return CartViewModel(cart: cart)
    }
    
    func selectRow(atIndexPath indexPath: IndexPath) {
        selectedIndexPath = indexPath
    }
    
    func viewModelForNewCart() -> AddCartViewModel  {
        AddCartViewModel()
    }
}
