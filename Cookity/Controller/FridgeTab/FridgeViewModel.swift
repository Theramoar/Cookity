//
//  FridgeViewModel.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 12/04/2020.
//  Copyright © 2020 Mihails Kuznecovs. All rights reserved.
//

import RealmSwift


class FridgeViewModel {
    
    private var productsInFridge: List<Product> {
        Fridge.shared.products
    }
    var checkedProducts = 0
    private var selectedIndexPath: IndexPath?
    
    var fridgeIsEmpty: Bool {
        productsInFridge.isEmpty
    }
        
    func deleteProductFromFridge(at position: Int) {
        let product = productsInFridge[position]
        CloudManager.deleteRecordFromCloud(ofObject: product)
        RealmDataManager.deleteFromRealm(object: product)
    }
    
    
    func moveProductsToCookArea() -> List<Product> {
        let copiedProducts = List<Product>()
        for product in productsInFridge {
            if product.checked {
                //creates the separate product in the Realm which can be used and edited in the recipe, not touching the existing product in the fridge
                let copiedProduct = Product()
                copiedProduct.name = product.name
                copiedProduct.quantity = product.quantity
                copiedProduct.measure = product.measure
                copiedProducts.append(copiedProduct)
            }
        }
        return copiedProducts
    }
    
    func uncheckProducts() {
        for product in productsInFridge {
            RealmDataManager.changeElementIn(object: product,
                                        keyValue: "checked",
                                        objectParameter: product.checked,
                                        newParameter: false)
        }
        checkedProducts = 0
    }
    
    func checkProduct(at position: Int) {
        let product = productsInFridge[position]
            RealmDataManager.changeElementIn(object: product,
                                             keyValue: "checked",
                                             objectParameter: product.checked,
                                             newParameter: !product.checked)
            checkedProducts = product.checked ? checkedProducts + 1  : checkedProducts - 1
        
    }
    
}

extension FridgeViewModel: TableViewModelType {
    var numberOfRows: Int {
        productsInFridge.count
    }
    
    var numberOfSections: Int {
        0
    }
    
    func cellViewModel(forIndexPath indexPath: IndexPath) -> CellViewModelType? {
        ProductTableCellViewModel(product: productsInFridge[indexPath.row])
    }
    
    func viewModelForSelectedRow() -> DetailViewModelType? {
        guard let row = selectedIndexPath?.row else { return nil }
        return PopupEditViewModel(product: productsInFridge[row])
    }
    
    func selectRow(atIndexPath indexPath: IndexPath) {
        
    }
    
    func longTapRow(atIndexPath indexPath: IndexPath) {
        selectedIndexPath = indexPath
    }
    
    func viewModelForCookdArea() -> CookViewModel {
        CookViewModel(products: moveProductsToCookArea())
    }
    
}
