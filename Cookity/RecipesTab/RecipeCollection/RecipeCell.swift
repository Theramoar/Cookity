//
//  RecipeCollectionViewCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 25/11/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import SwipeCellKit

protocol RemoveFromGroupDelegate {
    func removeRecipeFromGroup(at indexPath: IndexPath)
}

class RecipeCell: UICollectionViewCell {
    
    @IBOutlet weak var recipeName: UILabel!
    @IBOutlet weak var recipeImage: UIImageView!
    @IBOutlet weak var checkImageView: UIImageView!
    @IBOutlet weak var removeFromGroupButton: UIButton!
    
    var viewModel: RecipeCollectionCellViewModel? {
        willSet(viewModel) {
            guard let viewModel = viewModel else { return }
            setImages()
            recipeName.text = viewModel.recipeName
            recipeName.layer.shadowOffset = CGSize(width: 0, height: 0)
            recipeName.layer.shadowOpacity = 0.6
            recipeName.layer.shadowRadius = 1
            recipeImage.image = viewModel.image
            checkImageView.isHidden = !viewModel.checkedForGroup
            removeFromGroupButton.isHidden = !viewModel.isCellEdited
        }
    }
    
    private func setImages() {
        checkImageView.image = UIImage(systemName: "checkmark.circle.fill")?.withTintColor(Colors.appColor!, renderingMode: .alwaysOriginal)
        removeFromGroupButton.setImage(UIImage(systemName: "minus.circle.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal), for: .normal)
    }
    
    @IBAction func removeFromGroupPressed(_ sender: Any) {
        viewModel?.removeRecipeFromGroup()
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
    private var cellIndexPath: IndexPath?
    var removeRecipeDelegate: RemoveFromGroupDelegate?
    
    var recipeName: String {
        recipe.name
    }
    var checkedForGroup: Bool {
        return recipe.checkedForGroup
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
    
    var isCellEdited: Bool = false
    
    func removeRecipeFromGroup() {
        guard let indexPath = cellIndexPath else { return }
        removeRecipeDelegate?.removeRecipeFromGroup(at: indexPath)
    }
    
    init(recipe: Recipe) {
        self.recipe = recipe
    }
    
    init(recipe: Recipe, cellIndexPath: IndexPath) {
        self.recipe = recipe
        self.cellIndexPath = cellIndexPath
    }
}
