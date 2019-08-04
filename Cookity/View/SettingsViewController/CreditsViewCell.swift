//
//  CreditsViewCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 03/07/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit



class CreditsViewCell: UITableViewCell {

    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var linkLabel: UILabel!
    

    
    var authorName: String? {
        didSet {
            guard let authorName = authorName else { return }
            nameLabel.text = authorName
        }
    }
    
    var url: URL? {
        didSet {
            guard let url = url else { return }
            linkLabel.text = url.absoluteString
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }
    

}
