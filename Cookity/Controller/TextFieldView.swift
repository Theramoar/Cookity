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
    var tableView: UITableView?
    
    var isEdited: Bool = false {
        didSet {
            delegate?.isEdited = isEdited
        }
    }
    
    
    override func awakeFromNib() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    

    
    @objc func keyboardWillChangeFrame(notification: NSNotification) {
        guard let superViewSize = self.superview?.frame.size else { return }
        guard let userInfo = notification.userInfo else { return }
        guard let keyboardSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        if keyboardSize.origin.y == 667.0 {
            UIView.setAnimationsEnabled(true)
            self.frame.origin.y = superViewSize.height - self.frame.height
            isEdited = false
        }
        else {
            //Блок используется для того, чтобы убрать анимацию текстового поля при смене клавиатуры (чтобы текстовое поле не отрывалось от клавиатуры)
            if isEdited == true {
                UIView.setAnimationsEnabled(false)
            }
            self.frame.origin.y = superViewSize.height - keyboardSize.height - self.frame.height
            isEdited = true
        }
    }
}
