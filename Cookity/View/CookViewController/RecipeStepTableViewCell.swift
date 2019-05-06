//
//  RecipeStepTableViewCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 25/12/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit

protocol RecipeStepDelegate {
    func saveStep (step: String)
}

class RecipeStepTableViewCell: UITableViewCell {


    @IBOutlet weak var recipeStep: UITextField!
    var delegate: RecipeStepDelegate?
    
    override func awakeFromNib() {
        self.selectionStyle = .none
        recipeStep.autocapitalizationType = .sentences
    }
    
    @IBAction func addButtonPressed(_ sender: UIButton) {
        
        if let step = recipeStep?.text {
            guard step != "" else { return }
            delegate?.saveStep(step: step)
            recipeStep?.text = ""
        }
        
    }
}
