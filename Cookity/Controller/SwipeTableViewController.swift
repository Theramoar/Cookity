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
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        
        guard orientation == .right else { return nil }
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            self.deleteObject(at: indexPath)
        }
        
        return [deleteAction]
    }
    
    
    func deleteObject(at indexPath: IndexPath) {
        
    }
    
}
