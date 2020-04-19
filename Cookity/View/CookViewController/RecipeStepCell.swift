//
//  RecipeStepCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 18/03/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import SwipeCellKit

class RecipeStepCell: UITableViewCell, UITextFieldDelegate {
    

    @IBOutlet weak var recipeStepCell: UITextField!
    var viewModel: RecipeStepCellViewModel? {
        willSet(viewModel) {
            guard let viewModel = viewModel else { return }
            recipeStepCell.text = viewModel.recipeStepText
            recipeStepCell.delegate = self
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        recipeStepCell.autocapitalizationType = .sentences
    }
        
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let viewModel = viewModel, let text = textField.text else { return }
        viewModel.userEnteredString = text.isEmpty ? viewModel.userEnteredString : text
        textField.text = viewModel.userEnteredString
    }
}

class RecipeStepCellViewModel: CellViewModelType {
    private let recipeStep: RecipeStep
    
    var recipeStepText: String {
        recipeStep.name
    }
    
    var userEnteredString: String {
        didSet {
            self.recipeStep.name = userEnteredString
        }
    }
    
    init(step: RecipeStep) {
        self.recipeStep = step
        self.userEnteredString = step.name
    }
}
