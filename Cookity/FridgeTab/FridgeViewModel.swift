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
    
    private var productsExpired: [Product] {
        productsInFridge.filter({ self.setExpirationFrame(for: $0) == .expired })
    }
    private var productsIn3Days: [Product] {
        productsInFridge.filter({ self.setExpirationFrame(for: $0) == .in3Days })
    }
    private var productsIn1Week: [Product] {
        productsInFridge.filter({ self.setExpirationFrame(for: $0) == .in1Week })
    }
    private var productsIn1Month: [Product] {
        productsInFridge.filter({ self.setExpirationFrame(for: $0) == .in1Month })
    }
    private var productsOther: [Product] {
        productsInFridge.filter({ self.setExpirationFrame(for: $0) == .other })
    }
    
    private func productAtIndexPath(_ indexPath: IndexPath) -> Product {
        switch indexPath.section {
        case 0: return productsExpired[indexPath.row]
        case 1: return productsIn3Days[indexPath.row]
        case 2: return productsIn1Week[indexPath.row]
        case 3: return productsIn1Month[indexPath.row]
        case 4: return productsOther[indexPath.row]
        default:
            return Fridge.shared.products[indexPath.row]
        }
    }
    
    var checkedProducts = 0
    private var selectedIndexPath: IndexPath?
    private var currentSection: Int?
    
    var fridgeIsEmpty: Bool {
        productsInFridge.isEmpty
    }
        
    func deleteProductFromFridge(at indexPath: IndexPath) {
        let product = productAtIndexPath(indexPath)
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
    
    func checkProduct(at indexPath: IndexPath) {
        let product = productAtIndexPath(indexPath)
            RealmDataManager.changeElementIn(object: product,
                                             keyValue: "checked",
                                             objectParameter: product.checked,
                                             newParameter: !product.checked)
            checkedProducts = product.checked ? checkedProducts + 1  : checkedProducts - 1
        
    }
    
}

extension FridgeViewModel: TableViewModelType {
    var numberOfRows: Int {
        switch currentSection {
        case 0: return productsExpired.count
        case 1: return productsIn3Days.count
        case 2: return productsIn1Week.count
        case 3: return productsIn1Month.count
        case 4: return productsOther.count
        default:
            return 0
        }
    }
    
    var numberOfSections: Int {
        5
    }
    
    func numberOfRowsForCurrentSection(_ section: Int) -> Int {
        currentSection = section
        return numberOfRows
    }
    
    func cellViewModel(forIndexPath indexPath: IndexPath) -> CellViewModelType? {
        ProductTableCellViewModel(product: productAtIndexPath(indexPath))
    }
    
    func viewModelForSelectedRow() -> DetailViewModelType? {
        guard let indexPath = selectedIndexPath else { return nil }
        return PopupEditViewModel(product: productAtIndexPath(indexPath))
    }
    
    func selectRow(atIndexPath indexPath: IndexPath) {}
    
    func longTapRow(atIndexPath indexPath: IndexPath) {
        selectedIndexPath = indexPath
    }
    
    func viewModelForCookdArea() -> CookViewModel {
        CookViewModel(products: moveProductsToCookArea())
    }
    
    
    private func setExpirationFrame(for product: Product) -> ExpirationFrame {
        guard let date = product.expirationDate else { return .other }
        
        let calendar = Calendar.current
        let expirationDate = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())
        guard let days = calendar.dateComponents([.day], from: today, to: expirationDate).day else { return .other }
        
        switch days {
        case ..<0:
            return .expired
        case ..<4:
            return .in3Days
        case ..<8:
            return .in1Week
        case ..<31:
            return .in1Month
        default:
            return .other
        }
    }
}
