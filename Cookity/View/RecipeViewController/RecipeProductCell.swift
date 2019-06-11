//
//  RecipeProductCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 16/04/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit

class RecipeProductCell: UITableViewCell {

    
    @IBOutlet weak var productName: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var fridgeDetailsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        self.separatorInset = .zero
    }
    
    var fridgeDetails = "(You don't have any)"
    
    var productsInFridge: [Product]?
    
    var product: Product! {
        didSet {
            let (quantity, measure) = Configuration.presentNumbers(quantity: product.quantity, measure: product.measure)
            if let productsInFridge = productsInFridge {
                let (productsMatch, productInFridge) = Configuration.compareFridgeToRecipe(selectedProduct: product, compareTo: productsInFridge)
                if productsMatch, let productInFridge = productInFridge {
                    let (fridgeQuantity, fridgeMeasure) = Configuration.presentNumbers(quantity: productInFridge.quantity, measure: productInFridge.measure)
                    fridgeDetails = "(You have \(fridgeQuantity) \(fridgeMeasure))"
                    fridgeDetailsLabel.isHidden = false
                }
                else {
                    fridgeDetailsLabel.isHidden = true
                }
            }
            
            productName.text = product.name
            detailsLabel.text = "\(quantity) \(measure)"
            fridgeDetailsLabel.text = fridgeDetails
        }
    }

}
