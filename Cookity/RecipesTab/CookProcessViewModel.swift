//
//  CookProcessViewModel.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 13/04/2020.
//  Copyright © 2020 Mihails Kuznecovs. All rights reserved.
//

import RealmSwift

class CookProcessViewModel: DetailViewModelType {
    
    private var recipeSteps: List<RecipeStep>
    private var currentStep = 0
    
    var currentStepText: String {
        recipeSteps[currentStep].name
    }
    var progress: Float = 0
    
    init(recipeSteps: List<RecipeStep>) {
        self.recipeSteps = recipeSteps
    }
    
    func updateProgressAndLabel() -> String {
        let progressStep = 1 / Float(recipeSteps.count)
        progress += progressStep
        currentStep += 1
        if recipeSteps.count > currentStep {
            return currentStepText
        }
        else {
            return "Done!"
        }
    }
}
