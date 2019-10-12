//
//  RecipeNameView.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 10/10/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit

enum SectionViews {
    case Header
    case Footer
}

class RecipeSectionView: UIView {
        
    func configureView(_ view: SectionViews, with name: String) {
        backgroundColor = Colors.viewColor
        let nameLabel = UILabel()
        nameLabel.textColor = Colors.textColor
        nameLabel.text = name
    
        var height: CGFloat = 0.0
        var width: CGFloat = 0.0
        
        switch view {
            case .Header:
                nameLabel.font = UIFont.systemFont(ofSize: 30, weight: .black)
                nameLabel.numberOfLines = 2
                nameLabel.adjustsFontSizeToFitWidth = true
                nameLabel.minimumScaleFactor = 1/3
                nameLabel.backgroundColor = Colors.viewColor
                width = (UIScreen.main.bounds.size.width / 4) * 3
                height = 38
            case .Footer:
                nameLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
                width = UIScreen.main.bounds.size.width
                height = 30
        }
        
        nameLabel.frame = CGRect(x: 8, y: 0, width: width, height: height)
        addSubview(nameLabel)
    }
    
}
