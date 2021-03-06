//
//  IngridientsViewCell.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 03/08/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit

enum EnableCellTypes {
    case enableIngridient
    case enableCloud
    case enableDefaultDate
    case noType
}

class EnableOptionCell: UITableViewCell {

    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var cellLabel: UILabel!
    @IBOutlet weak var ingridientSwitch: UISwitch!
    
    var delegate: UpdateVCDelegate?
    
    var enableCellType: EnableCellTypes {
        didSet {
            switch enableCellType {
            case .enableIngridient:
                ingridientSwitch.isOn = SettingsVariables.isIngridientSearchEnabled == true ? true : false
                cellLabel.text = "Enable ingridients search"
                
                if #available(iOS 13.0, *) {
                    cellImageView.image = #imageLiteral(resourceName: "search_40").withTintColor(Colors.textColor!)
                } else {
                    cellImageView.image = #imageLiteral(resourceName: "search_40")
                }
            case .enableCloud:
                ingridientSwitch.isOn = SettingsVariables.isCloudEnabled == true ? true : false
                cellLabel.text = "Enable iCloud"
                if #available(iOS 13.0, *) {
                    cellImageView.image = #imageLiteral(resourceName: "cloud_40").withTintColor(Colors.textColor!)
                }
                else {
                    cellImageView.image = #imageLiteral(resourceName: "cloud_40")
                }
            case .enableDefaultDate:
                ingridientSwitch.isOn = SettingsVariables.isDefaultDateEnabled == true ? true : false
                cellLabel.text = "Set default expiration date"
                if #available(iOS 13.0, *) {
                    cellImageView.image = UIImage(systemName: "calendar")?.withTintColor(Colors.textColor!)
                } 
            case .noType:
                return
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.enableCellType = EnableCellTypes.noType
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.enableCellType = EnableCellTypes.noType
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
    @IBAction func switchChanged(_ sender: Any) {
        switch enableCellType {
        case .enableIngridient:
            SettingsVariables.isIngridientSearchEnabled = !SettingsVariables.isIngridientSearchEnabled
        case .enableCloud:
            SettingsVariables.isCloudEnabled = !SettingsVariables.isCloudEnabled
        case .enableDefaultDate:
            SettingsVariables.isDefaultDateEnabled = !SettingsVariables.isDefaultDateEnabled
            delegate?.updateVC()
        case .noType:
            return
        }
    }
}
