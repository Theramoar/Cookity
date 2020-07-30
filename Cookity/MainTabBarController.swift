//
//  MainTabBarController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 15/04/2020.
//  Copyright © 2020 Mihails Kuznecovs. All rights reserved.
//

import UIKit


class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cartVC = CartCollectionViewController()
//        let recipeVC = RecipeCollectionViewController.loadFromStoryboard()
//        let fridgeVC = FridgeViewController.loadFromStoryboard()
        
        viewControllers = [
            generateViewController(rootVC: cartVC, title: "Carts", image: UIImage(named: "shopping-cart")!)
//            generateViewController(rootVC: recipeVC, image: UIImage(named: "fridge")!),
//            generateViewController(rootVC: fridgeVC, image: UIImage(named: "fridge")!)
        ]
    }
    
    private func generateViewController(rootVC: UIViewController, title: String, image: UIImage) -> UIViewController {
        let navigationVC = UINavigationController(rootViewController: rootVC)
        navigationVC.tabBarItem.image = image
        navigationVC.tabBarItem.title = title
        rootVC.navigationItem.title = title
        navigationVC.navigationBar.prefersLargeTitles = true
        return navigationVC
    }
}


extension UIViewController {
    
    class func loadFromStoryboard<T: UIViewController>() -> T {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateInitialViewController() as? T {
            return vc
        }
        else {
            fatalError("No Initial View Controller in Main storybard")
        }
    }
}
