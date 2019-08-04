//
//  IngridientsViewCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 03/08/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit

class EnableIngridientCell: UITableViewCell {

    @IBOutlet weak var ingridientSwitch: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        ingridientSwitch.isOn = SettingsVariables.isIngridientSearchEnabled == true ? true : false
    }
    
    @IBAction func switchChanged(_ sender: Any) {
        SettingsVariables.isIngridientSearchEnabled = !SettingsVariables.isIngridientSearchEnabled
    }


}
