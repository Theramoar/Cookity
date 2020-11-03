//
//  RecipeStepCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 18/03/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import SwipeCellKit

class RecipeStepCell: UITableViewCell, UITextViewDelegate {
    

    @IBOutlet weak var recipeStepTextView: UITextView!
    var viewModel: RecipeStepCellViewModel? {
        willSet(viewModel) {
            guard let viewModel = viewModel else { return }
            recipeStepTextView.text = viewModel.recipeStepText
            recipeStepTextView.delegate = self
        }
    }
    var delegate: UpdateVCDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        recipeStepTextView.autocapitalizationType = .sentences
    }
    
//    private func setTextView() {
//        recipeStepTextView.translatesAutoresizingMaskIntoConstraints = false
//        
//        recipeStepTextView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor).isActive = true
//        recipeStepTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
//        recipeStepTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
//        recipeStepTextView.heightAnchor.constraint(equalToConstant: 50).isActive = true
//    }

    func textViewDidEndEditing(_ textView: UITextView) {
        guard let viewModel = viewModel, let text = textView.text else { return }
        viewModel.userEnteredString = text.isEmpty ? viewModel.userEnteredString : text
        textView.text = viewModel.userEnteredString
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let size = CGSize(width: contentView.frame.width, height: .infinity)
        let estimatedSize = recipeStepTextView.sizeThatFits(size)
        
        recipeStepTextView.constraints.forEach { constraint in
            if constraint.firstAttribute == .height {
                constraint.constant = estimatedSize.height
                delegate?.updateVC()
            }
        }
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
