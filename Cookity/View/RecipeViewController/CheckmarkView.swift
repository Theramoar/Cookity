//
//  CheckmarkView.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 03/05/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit

class CheckmarkView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let frame = UIScreen.main.bounds
        let side = frame.width / 3
        let xPosition = (frame.width / 2) - (side / 2)
        let yPosition = (frame.height / 2) - (side / 2)

        
        self.frame = CGRect(x: xPosition, y: yPosition, width: side, height: side)
        self.layer.cornerRadius = self.frame.size.height / 14
        self.backgroundColor = .gray
        self.alpha = 0.0
        
        let image = UIImageView()
        image.image = UIImage(named: "whiteTick.png")
        image.frame.size = CGSize(width: 50, height: 50)
        image.frame.origin = CGPoint(x: (side / 2) - (image.frame.size.width / 2), y: (side / 2) - (image.frame.size.height / 2))
        self.addSubview(image)

        let label = UILabel()
        label.frame.size = CGSize(width: 50, height: 30)
        label.frame.origin = CGPoint(x: (side / 2) - (label.frame.size.width / 2), y: side - (side / 4))
        label.textColor = .white
        label.alpha = 1
        label.text = "Done!"
        label.textAlignment = .center
        self.addSubview(label)
    }
    
    func animate() {
       
        UIView.animate(withDuration: 0.15) {
                self.alpha = 0.7
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            UIView.animate(withDuration: 0.2) {
                self.alpha = 0.0
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
