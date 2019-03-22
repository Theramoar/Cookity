//
//  RecipeStepCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 18/03/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import SwipeCellKit

class RecipeStepCell: SwipeTableViewCell {

    var recipeStep: RecipeStep! {
        didSet {
            recipeStepCell.text = recipeStep.name
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }
    @IBOutlet weak var recipeStepCell: UITextField!
    
}
