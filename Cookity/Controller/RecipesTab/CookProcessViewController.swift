//
//  CookProcessViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 02/05/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit

class CookProcessViewController: UIViewController {
    
    
    @IBOutlet weak var recipeStepLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    var recipeSteps: [RecipeStep]?
    var currentStep = 0
    var progress: Float = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recipeStepLabel.text = recipeSteps?[currentStep].name
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        self.view.addGestureRecognizer(tapGesture)
        progressView.progressViewStyle = UIProgressView.Style.bar
    }
    
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        recipeSteps?.removeAll()
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @objc func viewTapped() {
        guard let recipeSteps = recipeSteps else { return }
        if progress >= 1 {
            self.dismiss(animated: true, completion: nil)
        }

        let progressStep = 1 / Float(recipeSteps.count)
        progress += progressStep
        progressView.setProgress(progress, animated: true)
        
        currentStep += 1
        if recipeSteps.count > currentStep {
            recipeStepLabel.text = recipeSteps[currentStep].name
        }
        else {
            recipeStepLabel.text = "Done!"
        }
    }
}
