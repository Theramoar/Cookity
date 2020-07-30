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
    var viewModel: CookProcessViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recipeStepLabel.text = viewModel.currentStepText
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        self.view.addGestureRecognizer(tapGesture)
        progressView.progressViewStyle = UIProgressView.Style.bar
    }
    
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @objc func viewTapped() {
        if viewModel.progress >= 1 {
            self.dismiss(animated: true, completion: nil)
        }
        recipeStepLabel.text = viewModel.updateProgressAndLabel()
        progressView.setProgress(viewModel.progress, animated: true)
    }
}
