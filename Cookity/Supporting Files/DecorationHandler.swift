//
//  DecorationHandler.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 05/05/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit

public var shadow: UIView!

struct Colors {
    static let appColor = UIColor(named: "AppColor")
    static let textColor =  UIColor(named: "TextColor")
    static let viewColor = UIColor(named: "ViewColor")
    static let highlightColor = UIColor(named: "HighlightColor")
    static let cellColor = UIColor(named: "CellColor")
    static let shadowColor = UIColor(named: "ShadowColor")
    static let popupColor = UIColor(named: "PopupColor")
    static let darkGreen = UIColor(red: 54 / 255, green: 98 / 255, blue: 43 / 255, alpha: 1)
//    static let buttonColor: UIColor = #colorLiteral(red: 1, green: 0.3607843137, blue: 0, alpha: 1)
}

class DecorationHandler {
    
    static func putShadowOnView(vc: UIViewController) {
        shadow = UIView()
        shadow.frame = UIScreen.main.bounds
        shadow.backgroundColor = .black
        shadow.alpha = 0.0
        if let navController = vc.navigationController {
            navController.view.addSubview(shadow)
        }
        else {
            vc.view.addSubview(shadow)
        }
        UIView.animate(withDuration: 0.5) {
            shadow.alpha = 0.7
        }
    }
    
    
}
