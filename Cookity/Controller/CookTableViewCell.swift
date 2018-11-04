//
//  CookTableViewCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 30/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit


//protocol CookCellDelegate {
//    func cookProduct (productQuantity: String)
//}

class CookTableViewCell: UITableViewCell {

//    var delegate: CookCellDelegate?
    override func awakeFromNib() {
        super.awakeFromNib()
        quantityForRecipe?.text = "1"
    }
    
    
    @IBOutlet weak var quantityForRecipe: UITextField!
    
    //написано криво - улучшить
    @IBAction func increasedByOne(_ sender: UIButton) {
        var enteredValue = Int(quantityForRecipe?.text ?? "0")
        enteredValue! += 1
        quantityForRecipe?.text = String(enteredValue!)
    }
    
    
    @IBAction func decreasedByOne(_ sender: UIButton) {
        var enteredValue = Int(quantityForRecipe?.text ?? "0")
        enteredValue! -= 1
        quantityForRecipe?.text = String(enteredValue!)
    }
    
}
