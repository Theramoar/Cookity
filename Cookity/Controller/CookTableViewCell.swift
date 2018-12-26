//
//  CookTableViewCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 30/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit


class CookTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        quantityForRecipe?.text = "1"
    }
    
    @IBOutlet weak var quantityForRecipe: UITextField!
}
