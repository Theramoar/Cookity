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
        
        let deleteAction = SwipeAction(style: .destructive, title: nil) { action, indexPath in
            self.deleteObject(at: indexPath)
        }
        
        var size: CGFloat
        if tableView.rowHeight >= 50 {
            size = 25
        } else {
            size = 20
        }
        
        deleteAction.image = UIImage.setupSFSymbol(name: "trash", size: size)
        deleteAction.backgroundColor = UIColor(red: 211/255, green: 68/255, blue: 53/255, alpha: 1)
        
        return [deleteAction]
    }
    
    
    func deleteObject(at indexPath: IndexPath) {
    }
}
