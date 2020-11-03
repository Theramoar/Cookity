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

class RecipeStepTableViewCell: UITableViewCell, UITextViewDelegate {


    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var addButton: UIButton!
    
    var delegate: RecipeStepDelegate?
    var updateVCDelegate: UpdateVCDelegate?
    var isNewText = true
    
    override func awakeFromNib() {
        self.selectionStyle = .none
        textView.autocapitalizationType = .sentences
        textView.delegate = self
        let image = UIImage(systemName: "plus.circle")?.withTintColor(Colors.appColor!, renderingMode: .alwaysOriginal)
        addButton.setImage(image, for: .normal)
        textView.text = "Enter recipe step"
        textView.textColor = .placeholderText
    }
    
    @IBAction func addButtonPressed(_ sender: UIButton) {
        print("addButtonPressed")
        if let step = textView?.text {
            guard step != "" else { return }
            delegate?.saveStep(step: step)
            updateVCDelegate?.updateVC()
            textView?.text = ""
            updateTextViewHeight()
            setPlaceholder()
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if isNewText {
            textView.text = ""
            textView.textColor = .darkText
            isNewText = false
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            setPlaceholder()
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        updateTextViewHeight()
    }
    
    private func updateTextViewHeight() {
        let size = CGSize(width: contentView.frame.width, height: .infinity)
        let estimatedSize = textView.sizeThatFits(size)
        textView.constraints.forEach { constraint in
            if constraint.firstAttribute == .height {
                constraint.constant = estimatedSize.height
                updateVCDelegate?.updateVC()
            }
        }
    }
    
    private func setPlaceholder() {
        textView.text = "Enter recipe step"
        textView.textColor = .placeholderText
        isNewText = true
    }
}
