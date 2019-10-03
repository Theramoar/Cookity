//
//  RecipeImageViewCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 14/04/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit

class RecipeImageViewCell: UITableViewCell {

    
    @IBOutlet weak var recipeName: UILabel!
    @IBOutlet weak var recipeImageView: UIImageView!
    
    
    var recipe: Recipe! {
        didSet {
            
            recipeName.text = recipe.name
            if let imageFileName = recipe.imageFileName {
                let imagePath: String = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(imageFileName)"
                let imageUrl: URL = URL(fileURLWithPath: imagePath)
                guard FileManager.default.fileExists(atPath: imagePath),
                    let imageData: Data = try? Data(contentsOf: imageUrl),
                    let image: UIImage = UIImage(data: imageData) else {
                        recipeImageView.image = nil
                        return
                }
                recipeImageView.image = image
            }
            else {
                
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }

    

}
