//
//  AddCartViewModel.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 12/04/2020.
//  Copyright © 2020 Mihails Kuznecovs. All rights reserved.
//

import RealmSwift

class AddCartViewModel: DetailViewModelType {
    
    var products = List<Product>()
    
    
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
    
    func saveCart(name: String) {
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
    
    func deleteProductFromCart(at position: Int) {
        products.remove(at: position)
    }
}

extension AddCartViewModel: TableViewModelType {
    var numberOfRows: Int {
        products.count
    }
    
    var numberOfSections: Int {
        0
    }
    
    func cellViewModel(forIndexPath indexPath: IndexPath) -> CellViewModelType? {
        ProductTableCellViewModel(product: products[indexPath.row], forTable: .addCart)
    }
    
    func viewModelForSelectedRow() -> DetailViewModelType? { nil }
    
    func selectRow(atIndexPath indexPath: IndexPath) {}
    
    
}
