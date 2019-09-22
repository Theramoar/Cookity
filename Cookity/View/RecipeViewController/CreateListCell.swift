//
//  CreateListCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 17/03/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit


 class CreateListCell: UITableViewCell {
    
    @IBOutlet weak var createListButton: UIButton! {
        didSet {
            createListButton.layer.cornerRadius = createListButton.frame.size.height / 2.5
            createListButton.layer.borderColor = Colors.textColor?.cgColor
            createListButton.layer.borderWidth = 2
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }
}
