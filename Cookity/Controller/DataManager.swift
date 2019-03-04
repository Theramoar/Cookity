//
//  DataManager.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 04/03/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import Foundation
import RealmSwift


class DataManager {
    
    let realm = try! Realm()
    
    func delete(object: Object){
        do{
            try self.realm.write {
                self.realm.delete(object)
            }
        }catch
        {
            print("Error while deleting items \(error)")
        }
    }
    
    
}
