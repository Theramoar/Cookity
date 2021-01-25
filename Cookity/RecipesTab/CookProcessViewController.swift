//
//  CookProcessViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 02/05/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit

class CookProcessViewController: UIViewController {
    
    
    @IBOutlet private var recipeStepLabel: UILabel!
    @IBOutlet private var progressView: UIProgressView!
    @IBOutlet private var cancelButton: UIButton!
    
    var viewModel: CookProcessViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recipeStepLabel.text = viewModel.currentStepText
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        self.view.addGestureRecognizer(tapGesture)
        
        progressView.progressViewStyle = UIProgressView.Style.bar
        let cancelImage = UIImage.setupSFSymbol(name: "multiply.circle", size: 20, color: Colors.appColor!)
        cancelButton.setImage(cancelImage, for: .normal)
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
