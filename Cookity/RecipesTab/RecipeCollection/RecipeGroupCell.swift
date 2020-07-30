//
//  RecipeCollectionGroupViewCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 29/04/2020.
//  Copyright © 2020 Mihails Kuznecovs. All rights reserved.
//

import UIKit

class RecipeGroupCell: UICollectionViewCell {
    
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var recipeCollection: RecipeGroupCollectionView!
    
    var presentatioDelegate: PresentationDelegate?
    
    var viewModel: RecipeGroupCellViewModel? {
        willSet(viewModel) {
            guard let viewModel = viewModel else { return }
            groupNameLabel.text = viewModel.recipeGroupName
            recipeCollection.viewModel = viewModel.viewModelForCollection()
            recipeCollection.presentationDelegate = presentatioDelegate
            recipeCollection.reloadData()
        }
    }
    
    @IBAction func seeAllButtonPressed(_ sender: Any) {
        let vc = RecipeGroupViewController()
        vc.viewModel = viewModel?.viewModelForPresentedGroup()
        presentatioDelegate?.present(vc: vc)
    }
}


class RecipeGroupCellViewModel: CellViewModelType {
    private var recipeGroup: RecipeGroup
    
    
    var recipeGroupName: String {
        recipeGroup.name
    }
    
    private var recipes: [Recipe] {
        recipeGroup.recipes
    }
    
    func viewModelForPresentedGroup() -> RecipeGroupViewModel {
        RecipeGroupViewModel(recipeGroup: recipeGroup, collectionType: .recipeGroupCollection)
    }
    
    func viewModelForCollection() -> RecipeGroupCollectionViewModel {
        RecipeGroupCollectionViewModel(recipes: recipes)
    }
    
    init(recipeGroup: RecipeGroup) {
        self.recipeGroup = recipeGroup
    }
}
