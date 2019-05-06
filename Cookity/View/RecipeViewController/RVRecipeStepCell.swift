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
    
    
    var position: Int!
    
    var recipeStep: RecipeStep! {
        didSet {
            recipeStepLabel.text = "\(position.description). \(recipeStep.name)"
        }
    }
}
