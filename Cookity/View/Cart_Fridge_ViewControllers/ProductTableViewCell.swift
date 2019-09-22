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
    
    var attributedName: NSMutableAttributedString!
    var attributedNumber: NSMutableAttributedString!
    let strikethroughAttribute = NSAttributedString.Key.strikethroughStyle
    
    var product: Product! {
        didSet {
            let (presentedQuantity, presentedMeasure) = Configuration.presentNumbers(quantity: product.quantity, measure: product.measure)
            attributedName = NSMutableAttributedString(string: product.name)
            attributedNumber = NSMutableAttributedString(string: "\(presentedQuantity) \(presentedMeasure)")
            nameLabel.attributedText = attributedName
            measureLabel.attributedText = attributedNumber
        }
    }
    
    var isChecked: Bool! {
        didSet {
            nameLabel.textColor = isChecked ? Colors.highlightColor : Colors.textColor
            measureLabel.textColor = isChecked ? Colors.highlightColor : Colors.textColor
            if isChecked {
                attributedName.addAttribute(strikethroughAttribute, value: 2, range: NSMakeRange(0, attributedName.length))
                attributedNumber.addAttribute(strikethroughAttribute, value: 2, range: NSMakeRange(0, attributedNumber.length))
            }
            nameLabel.attributedText = attributedName
            measureLabel.attributedText = attributedNumber
            
        }
    }
    
    override func awakeFromNib() {
        self.selectionStyle = .none
    }
}
