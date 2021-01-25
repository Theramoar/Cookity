//
//  UIImage Extension.swift
//  Cookity
//
//  Created by MihailsKuznecovs on 19/01/2021.
//  Copyright © 2021 Mihails Kuznecovs. All rights reserved.
//

import UIKit

extension UIImage {
    #warning("Remove this function from AppGreenButton Class")
    static func setupSFSymbol(name: String, size: CGFloat, color: UIColor = .white) -> UIImage? {
        UIImage(systemName: name, withConfiguration: UIImage.SymbolConfiguration(pointSize: size, weight: .regular, scale: .large))?.withTintColor(color, renderingMode: .alwaysOriginal)
    }
}
