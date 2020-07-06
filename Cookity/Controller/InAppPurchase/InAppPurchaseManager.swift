//
//  InAppPurchaseManager.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 30/05/2020.
//  Copyright © 2020 Mihails Kuznecovs. All rights reserved.
//

import Foundation
import StoreKit


enum IAPProducts: String {
    case fullPro = "michaelk.FullCookityPro"
    case monthlyPro = "michaelk.MonthlyCookityPro"
}


class IAPManager: NSObject  {
    static let shared = IAPManager()
    private override init() {}
    private var products: [SKProduct] = []

    
    //Убеждаемся в том, что данное устройство может совершать платежи
    public func setupPurchases(callback: @escaping (Bool) -> ()) {
        if SKPaymentQueue.canMakePayments() {
            //Если устройство может делать покупки, добавляем данный класс как наблюдателя за совершением покупок
            SKPaymentQueue.default().add(self)
            callback(true)
            return
        }
        callback(false)
    }
    
    public func getProducts() {
        let identifiers: Set = [IAPProducts.fullPro.rawValue,
                                IAPProducts.monthlyPro.rawValue]
        let productRequest = SKProductsRequest(productIdentifiers: identifiers)
        productRequest.delegate = self
        productRequest.start()
    }
    
    public func purchase(productWith identifier: String) {
        guard let product = products.filter({ $0.productIdentifier == identifier }).first else { return }
        let payment = SKPayment(product: product)
        //отправляет платёж в очередь. Далее работает метод func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction])
        SKPaymentQueue.default().add(payment)
    }

    public func priceStringForProduct(withIdentifier identifier: String) -> String {
        guard let product = products.first(where: {$0.productIdentifier == identifier }) else { return "--" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price) ?? "--"
    }
    
    public func restoreCompletedTransactions() {
        SKPaymentQueue.default().restoreCompletedTransactions()        
    }
    
}

extension IAPManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased: purchased(transaction)
            case .failed: failed(transaction)
            case .restored: restored(transaction)
            case .purchasing: break
            case .deferred: break
            @unknown default: break
            }
        }
    }
    
    private func failed(_ transaction: SKPaymentTransaction) {
        if let transactionError = transaction.error as NSError? {
            if transactionError.code != SKError.paymentCancelled.rawValue {
                print("Transaction Error: \(transactionError.localizedDescription)")
            }
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    private func purchased(_ transaction: SKPaymentTransaction) {
        NotificationCenter.default.post(name: NSNotification.Name(transaction.payment.productIdentifier), object: nil)
        SKPaymentQueue.default().finishTransaction(transaction)
//        validateRecipe()
    }
    
    
    //Monthly Subscription expiration date validation
    //https://developer.apple.com/documentation/storekit/in-app_purchase/validating_receipts_with_the_app_store
    //https://savvyapps.com/blog/how-setup-test-auto-renewable-subscription-ios-app
//    private func validateRecipe() {
//        if let receiptURL = Bundle.main.appStoreReceiptURL, FileManager.default.fileExists(atPath: receiptURL.path), let receiptData = NSData(contentsOf: receiptURL) {
//            let receiptDictionary = ["receipt-data" : receiptData.base64EncodedString(options: []), "password" : "ed45ee0d7fce439488807f3b70d5c01c"]
//            let requestData = try? JSONSerialization.data(withJSONObject: receiptDictionary)
//            let storeURL = URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")!  //in production https://buy.itunes.apple.com/verifyReceipt
//            var storeRequest = URLRequest(url: storeURL)
//            storeRequest.httpMethod = "POST"
//            storeRequest.httpBody = requestData
//
//            URLSession.shared.dataTask(with: storeRequest) { (data, response, error) in
//                // Обработатть ответ тут
//                if let data = data {
//                    let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String : Any]
//                    print(self.createExpirationDate(json: json))
//
//                }
//            }.resume()
//        }
//    }
    
//    private func createExpirationDate(json: [String : Any]?) -> Date? {
//        if let json = json, let receiptInfo: Array = json["latest_receipt_info"] as? Array<Any> {
//            let lastReceipt = receiptInfo.last as! NSDictionary
//            let formatter = DateFormatter()
//            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss VV"
//            let expirationDate = formatter.date(from: lastReceipt["expires_date"] as! String)
//            return expirationDate
//        }
//        return nil
//    }
    
    private func restored(_ transaction: SKPaymentTransaction) {
        NotificationCenter.default.post(name: NSNotification.Name("restored_\(transaction.payment.productIdentifier)"), object: nil)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
}

extension IAPManager: SKProductsRequestDelegate {
    //Обработка ответа посланного func getProducts()
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.products = response.products
        products.forEach { print($0.localizedTitle) }
//        if products.count > 0 {
//            NotificationCenter.default.post(name: NSNotification.Name(NotificationNames.purchasesAreAvailable), object: nil)
//        }
    }
}
