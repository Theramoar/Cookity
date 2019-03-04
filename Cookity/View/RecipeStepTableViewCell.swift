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
    
    @IBAction func addButtonPressed(_ sender: UIButton) {
        
        if let step = recipeStep?.text {
            guard step != "" else { return }
            delegate?.saveStep(step: step)
            recipeStep?.text = ""
        }
    }
    //Попробовать передать строку через completion handler
    func saveRecipeStep(step: String, completion: (String) -> ()) {
        guard step != "" else { return }
        completion(step)
    }
}
