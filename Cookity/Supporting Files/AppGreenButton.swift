//
//  AppGreenButton.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 12/11/2020.
//  Copyright © 2020 Mihails Kuznecovs. All rights reserved.
//

import UIKit

class AppGreenButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAppearance()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupAppearance()
    }
    
    func setupAppearance() {
        layer.cornerRadius = frame.width / 2
        layer.shadowOffset = CGSize(width: 0, height: 3.0)
        layer.shadowOpacity = 0.7
        layer.shadowRadius = 5.0
        backgroundColor = Colors.appColor
    }
    
    func setupSFSymbol(name: String, size: CGFloat) {
        let image = UIImage(systemName: name, withConfiguration: UIImage.SymbolConfiguration(pointSize: size, weight: .regular, scale: .large))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        setImage(image, for: .normal)
    }
    
    func setupAssetImage(name: String, edgeInset: CGFloat) {
        let image = UIImage(named: name, in: nil, with: nil)?.withTintColor(.white, renderingMode: .alwaysOriginal)
        self.setImage(image, for: .normal)
        self.imageEdgeInsets = UIEdgeInsets(top: edgeInset, left: edgeInset, bottom: edgeInset, right: edgeInset)
    }
    
}
