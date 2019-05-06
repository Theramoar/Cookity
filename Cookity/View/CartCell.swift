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
    
    
    override func awakeFromNib() {
        cellContentView.layer.cornerRadius = self.frame.size.height / 14
        self.selectionStyle = .none
    }
}
