//
//  SwipeTableViewCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 10/03/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import SwipeCellKit

let green = UIColor(red: 54 / 255, green: 98 / 255, blue: 43 / 255, alpha: 1)
let lightGreen = UIColor(red: 198 / 255, green: 227 / 255, blue: 119 / 255, alpha: 1)

class ProductTableViewCell: SwipeTableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var measureLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    
    var product: Product! {
        didSet {
            let (presentedQuantity, presentedMeasure) = Configuration.presentNumbers(quantity: product.quantity, measure: product.measure)
            nameLabel.text = product.name
            quantityLabel.text = presentedQuantity
            measureLabel.text = presentedMeasure
        }
    }
    
    var isChecked: Bool! {
        didSet {
            nameLabel.textColor = isChecked ? lightGreen : green
            quantityLabel.textColor = isChecked ? lightGreen : green
            measureLabel.textColor = isChecked ? lightGreen : green
        }
    }
    
    override func awakeFromNib() {
        self.selectionStyle = .none
    }
}
