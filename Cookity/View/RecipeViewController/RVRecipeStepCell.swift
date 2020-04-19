//
//  RVRecipeStepCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 21/04/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit

class RVRecipeStepCell: UITableViewCell {
    @IBOutlet weak var recipeStepLabel: UILabel!
    
    weak var viewModel: RVRecipeStepCellViewModel? {
        willSet(viewModel) {
            guard let viewModel = viewModel else { return }
            recipeStepLabel.text = viewModel.cellText
        }
    }
}

class RVRecipeStepCellViewModel: CellViewModelType {
    private var recipeStep: RecipeStep
    private var stepPosition: Int
    
    var cellText: String {
        "\(stepPosition.description). \(recipeStep.name)"
    }
    
    init(recipeStep: RecipeStep, stepPosition: Int) {
        self.recipeStep = recipeStep
        self.stepPosition = stepPosition
    }
}
