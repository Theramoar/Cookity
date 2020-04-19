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
    
    weak var viewModel: RecipeCollectionCellViewModel? {
        willSet(viewModel) {
            guard let viewModel = viewModel else { return }
            recipeName.text = viewModel.recipeName
            recipeName.layer.shadowOffset = CGSize(width: 0, height: 0)
            recipeName.layer.shadowOpacity = 0.6
            recipeName.layer.shadowRadius = 1
            recipeImage.image = viewModel.image
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

 
class RecipeCollectionCellViewModel: CellViewModelType {
    private var recipe: Recipe
    
    var recipeName: String {
        recipe.name
    }
    
    var image: UIImage {
        if let imageFileName = recipe.imageFileName,
            let image = Configuration.getImageFromFileManager(with: imageFileName) {
            return image
        }
        else {
            return UIImage(named: "RecipeDefaultImage.jpg")!
        }
    }
    
    init(recipe: Recipe) {
        self.recipe = recipe
    }
}
