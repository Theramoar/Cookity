//
//  SwipeTableViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 12/03/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import SwipeCellKit

class SwipeTableViewController: UIViewController, SwipeTableViewCellDelegate {
    
    let dataManager = RealmDataManager()
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        
        guard orientation == .right else { return nil }
        
        let deleteAction = SwipeAction(style: .destructive, title: nil) { action, indexPath in
            self.deleteObject(at: indexPath)
        }
        deleteAction.backgroundColor = UIColor(red: 211/255, green: 68/255, blue: 53/255, alpha: 1)
        deleteAction.image = UIImage(named: "delete")
        
        return [deleteAction]
    }
    
    
    func deleteObject(at indexPath: IndexPath) {
    }
    
}
