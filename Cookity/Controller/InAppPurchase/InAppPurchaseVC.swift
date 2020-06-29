//
//  TestVC.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 28/05/2020.
//  Copyright © 2020 Mihails Kuznecovs. All rights reserved.
//

import UIKit

class InAppPurchaseViewController: UIViewController {

    @IBOutlet weak var visibleView: UIView!
    @IBOutlet weak var subscribeButton: UIButton!
    @IBOutlet weak var buyButton: UIButton!
    
    override func viewDidLoad() {
        setupButton(buyButton, title: "\(IAPManager.shared.priceStringForProduct(withIdentifier: IAPProducts.fullPro.rawValue))\nForever")
        setupButton(subscribeButton, title: "\(IAPManager.shared.priceStringForProduct(withIdentifier: IAPProducts.monthlyPro.rawValue))\nMonthly")
        
        NotificationCenter.default.addObserver(self, selector: #selector(completeFullPro), name: NSNotification.Name(IAPProducts.fullPro.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(completeMonthlyPro), name: NSNotification.Name(IAPProducts.monthlyPro.rawValue), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(restoreFullPro), name: NSNotification.Name("restored_\(IAPProducts.fullPro.rawValue)"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(restoreMonthlyPro), name: NSNotification.Name("restored_\(IAPProducts.monthlyPro.rawValue)"), object: nil)
    }
    
    @objc private func completeFullPro() {
        UserPurchases.fullPro = true
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func completeMonthlyPro() {
        UserPurchases.monthlyPro = true
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func restoreFullPro() {
        UserPurchases.fullPro = true
        showRestoreAlert()
    }
    
    @objc private func restoreMonthlyPro() {
        UserPurchases.monthlyPro = true
        showRestoreAlert()
    }
    
    private func showRestoreAlert() {
        let alert = UIAlertController(title: "All purchases are restored!", message: nil, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default) { _ in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    private func setupButton(_ button: UIButton, title: String) {
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center
        button.setTitle(title, for: .normal)
        button.layer.cornerRadius = buyButton.frame.size.height / 3
        button.layer.shadowOffset = CGSize(width: 0, height: 3.0)
        button.layer.shadowOpacity = 0.7
        button.layer.shadowRadius = 5.0
    }
    
    @IBAction func buyButtonPressed(_ sender: Any) {
        IAPManager.shared.purchase(productWith: IAPProducts.fullPro.rawValue)
    }
    
    
    @IBAction func subscribeButtonPressed(_ sender: Any) {
        IAPManager.shared.purchase(productWith: IAPProducts.monthlyPro.rawValue)
    }
    
    @IBAction func restoreButtonPressed(_ sender: Any) {
        IAPManager.shared.restoreCompletedTransactions()
    }
    
    override func viewDidLayoutSubviews() {
        let size = CGSize(width: 20, height: 20)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = UIBezierPath(roundedRect: visibleView.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: size).cgPath
        visibleView.layer.mask = shapeLayer
    }
}
