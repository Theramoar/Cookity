//
//  ContactsCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 23/09/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit

enum ContactsCellTypes {
    case contactUs
    case credits
    case noType
}

class ContactsCell: UITableViewCell {

    
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    
    var contactsCellType: ContactsCellTypes {
        didSet {
            switch contactsCellType {
                
            case .contactUs:
                label.text = "Leave us feedback"
                if #available(iOS 13.0, *) {
                    iconImageView.image = #imageLiteral(resourceName: "envelope_40").withTintColor(Colors.textColor!)
                } else {
                    iconImageView.image = #imageLiteral(resourceName: "envelope_40")
                }
            case .credits:
                label.text = "Credits"
                if #available(iOS 13.0, *) {
                    iconImageView.image = #imageLiteral(resourceName: "copyright_40").withTintColor(Colors.textColor!)
                } else {
                    iconImageView.image = #imageLiteral(resourceName: "copyright_40")
                }
            case .noType:
                return
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.contactsCellType = ContactsCellTypes.noType
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.contactsCellType = ContactsCellTypes.noType
        super.init(coder: aDecoder)
    }
}
