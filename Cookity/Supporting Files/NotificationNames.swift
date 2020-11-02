//
//  NotificationNames.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 24/05/2020.
//  Copyright © 2020 Mihails Kuznecovs. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let recipeIsAdded = NSNotification.Name("RecipeIsAdded")
    static let groupIsUpdated = NSNotification.Name("GroupIsUpdated")
    static let purchasesAreAvailable = NSNotification.Name("PurchasesAreAvailable")
    static let purchaseWasSuccesful = NSNotification.Name("PurchaseWasSuccesful")
    static let datePickerWasToggled = NSNotification.Name("DatePickerWasToggled")
}
