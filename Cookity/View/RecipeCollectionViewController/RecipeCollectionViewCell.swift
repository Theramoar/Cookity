//
//  RecipeCollectionViewCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 25/11/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
//import SwipeCellKit

class RecipeCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var recipeName: UILabel!
    @IBOutlet weak var recipeImage: UIImageView!
    
    
    var recipe: Recipe! {
        didSet {
            recipeName.text = recipe.name
            recipeName.layer.shadowOffset = CGSize(width: 0, height: 0)
            recipeName.layer.shadowOpacity = 0.6
            recipeName.layer.shadowRadius = 1
            
            if let imageFileName = recipe.imageFileName,
                let image = Configuration.getImageFromFileManager(with: imageFileName) {
                recipeImage.image = image
            }
            else {
                recipeImage.image = UIImage(named: "RecipeDefaultImage.jpg")
            }
        }
    }
    

    override func awakeFromNib() {
        self.layer.cornerRadius = self.frame.size.height / 14
        recipeImage.layer.cornerRadius = self.frame.size.height / 14
        
        
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.shadowOpacity = 0.4
        self.layer.shadowRadius = 3
        self.layer.masksToBounds = false
    }
    
}
