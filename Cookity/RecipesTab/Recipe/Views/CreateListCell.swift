//
//  CreateListCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 17/03/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit

protocol CreateButtonDelegate {
    func createCart()
}

 class CreateListCell: UITableViewCell {
    
    var delegate: CreateButtonDelegate?
    @IBOutlet weak var createListButton: UIButton! {
        didSet {
            createListButton.layer.cornerRadius = createListButton.frame.size.height / 1.5
            createListButton.layer.borderColor = Colors.appColor?.cgColor
            createListButton.layer.borderWidth = 2
        }
    }
    
    @IBAction func createButtonPressed(_ sender: Any) {
        delegate?.createCart()
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }
}
