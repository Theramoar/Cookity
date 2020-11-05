//
//  TextFieldView.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 24/03/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit

protocol IsEditedDelegate {
    var isEdited: Bool { get set }
}

class TextFieldView: UIView {

    var delegate: IsEditedDelegate?
    var viewHeight: CGFloat!
    var heightConstraint: NSLayoutConstraint!
    var initialHeight: CGFloat!
    
    
    
    var isEdited: Bool = false {
        didSet {
            delegate?.isEdited = isEdited
        }
    }
    
    override func awakeFromNib() {
        viewHeight = self.frame.height
        
        self.layer.shadowOffset = CGSize(width: 0, height: -1)
        self.layer.shadowOpacity = 0.1
        self.layer.shadowRadius = 0.1
        self.layer.shadowColor = Colors.shadowColor?.cgColor
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    

    
    @objc func keyboardWillChangeFrame(notification: NSNotification) {
        
        guard let superview = self.superview else { return }
        let bottomMargin = superview.layoutMargins.bottom
        
        
        guard let userInfo = notification.userInfo,
              let keyboardSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else { return }
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            heightConstraint.constant = initialHeight
            UIView.animate(withDuration: 0.5) {
                superview.layoutIfNeeded()
            }
        }
        else {
            heightConstraint.constant = keyboardSize.height + initialHeight - bottomMargin
            
            //Блок используется для того, чтобы убрать анимацию текстового поля при смене клавиатуры (чтобы текстовое поле не отрывалось от клавиатуры)
            if isEdited == false {
                UIView.animate(withDuration: 2) {
                    superview.layoutIfNeeded()
                }
            }
            isEdited = true
        }
    }
    
    @objc func keyboardDidHide(notification: NSNotification) {
        isEdited = false
    }
}
