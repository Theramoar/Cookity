//
//  DecorationHandler.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 05/05/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit

public var shadow: UIView!

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
