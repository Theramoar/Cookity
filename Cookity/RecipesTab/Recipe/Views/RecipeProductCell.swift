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
    
    weak var viewModel: RecipeProductCellViewModel? {
        willSet(viewModel) {
            guard let viewModel = viewModel else { return }
            productName.text = viewModel.productName
            detailsLabel.text = viewModel.productDetails
            fridgeDetailsLabel.text = viewModel.fridgeDetails
            fridgeDetailsLabel.isHidden = viewModel.fridgeDetails.isEmpty
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        self.separatorInset = .zero
    }
}


class RecipeProductCellViewModel: CellViewModelType {
    private var product: Product
    
    var productName: String {
        product.name
    }
    var productDetails: String {
        let (quantity, measure) = Configuration.presentNumbers(quantity: product.quantity, measure: product.measure)
        return "\(quantity) \(measure)"
    }
    var fridgeDetails: String {
        let (productsMatch, productInFridge) = Configuration.compareFridgeToRecipe(selectedProduct: product, compareTo: Array(Fridge.shared.products))
        if productsMatch, let productInFridge = productInFridge {
            let (fridgeQuantity, fridgeMeasure) = Configuration.presentNumbers(quantity: productInFridge.quantity, measure: productInFridge.measure)
            return "(You have \(fridgeQuantity) \(fridgeMeasure))"
        }
        else {
            return ""
        }
    }
    
    init(product: Product) {
        self.product = product
    }
}
