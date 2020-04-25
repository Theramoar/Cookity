//
//  SwipeTableViewCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 10/03/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import SwipeCellKit



class ProductTableViewCell: SwipeTableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var measureLabel: UILabel!
    @IBOutlet weak var expirationDateLabel: UILabel!
    
    var attributedName: NSMutableAttributedString!
    var attributedNumber: NSMutableAttributedString!
    let strikethroughAttribute = NSAttributedString.Key.strikethroughStyle
    
    weak var viewModel: ProductTableCellViewModel? {
        willSet(viewModel) {
            guard let viewModel = viewModel else { return }
            expirationDateLabel.isHidden = !isInFridge
            
            attributedName = NSMutableAttributedString(string: viewModel.productName)
            attributedNumber = NSMutableAttributedString(string: "\(viewModel.productQuantity) \(viewModel.productMeasure)")
    
            nameLabel.attributedText = attributedName
            measureLabel.attributedText = attributedNumber
            
            nameLabel.textColor = viewModel.isChecked ? Colors.highlightColor : Colors.textColor
            measureLabel.textColor = viewModel.isChecked ? Colors.highlightColor : Colors.textColor
            
            if viewModel.isChecked, !isInFridge {
                attributedName.addAttribute(strikethroughAttribute, value: 2, range: NSMakeRange(0, attributedName.length))
                attributedNumber.addAttribute(strikethroughAttribute, value: 2, range: NSMakeRange(0, attributedNumber.length))
            }
            if isInFridge {
                expirationDateLabel.text = viewModel.expirationDate
            }
            
            nameLabel.attributedText = attributedName
            measureLabel.attributedText = attributedNumber
        }
    }
    
    var isInFridge = false
    
    override func awakeFromNib() {
        self.selectionStyle = .none
    }
}


class ProductTableCellViewModel: CellViewModelType {
    private var product: Product
    var productName: String {
        product.name
    }
    var isChecked: Bool {
        product.checked
    }
    
    var expirationDate: String {
        product.expirationDate != nil ? Configuration.createStringFromDate(product.expirationDate!) : ""
    }
    
    var productMeasure: String
    var productQuantity: String
    
    init(product: Product) {
        self.product = product
        (self.productQuantity, self.productMeasure) = Configuration.presentNumbers(quantity: product.quantity, measure: product.measure)
    }
}
