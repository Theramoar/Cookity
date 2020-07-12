//
//  CartCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 01/05/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import SwipeCellKit

class CartCell: SwipeTableViewCell {

    @IBOutlet weak var cartName: UILabel!
    @IBOutlet weak var cellContentView: UIView!
    
    weak var viewModel: CartCellViewModel? {
        willSet(viewModel) {
            guard let viewModel = viewModel else { return }
            cartName.text = viewModel.cartName
        }
    }
    
    override func awakeFromNib() {
        cellContentView.layer.cornerRadius = self.frame.size.height / 14
        self.selectionStyle = .none
        self.backgroundColor = .clear
        cellContentView.layer.shadowOffset = CGSize(width: 0, height: 3)
        cellContentView.layer.shadowOpacity = 0.2
        cellContentView.layer.shadowRadius = 3.0
    }
}

class CartCellViewModel: CellViewModelType {
    private var cart: ShoppingCart
    
    var cartName: String {
        cart.name
    }
    
    init(cart: ShoppingCart) {
        self.cart = cart
    }
}
