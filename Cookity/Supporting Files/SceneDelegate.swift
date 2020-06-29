//
//  SceneDelegate.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 15/04/2020.
//  Copyright © 2020 Mihails Kuznecovs. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
//        print("HERE")
//        guard let windowScene = (scene as? UIWindowScene) else { return }
//        window = UIWindow(windowScene: windowScene)
//        window?.makeKeyAndVisible()
//        window?.rootViewController = MainTabBarController()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {        
        guard
            let url = URLContexts.first?.url,
            url.pathExtension == "ckty",
            let object = ShareDataManager.importData(from: url)
        else { return }
        
        if let cart = object as? ShoppingCart {
            CloudManager.saveParentDataToCloud(object: cart, objectImageName: nil) { (recordID) in
                DispatchQueue.main.async {
                    RealmDataManager.changeElementIn(object: cart,
                                                     keyValue: "cloudID",
                                                     objectParameter: cart.cloudID,
                                                     newParameter: recordID)
                }
            }
            guard
                let tabBarViewController = window?.rootViewController as? UITabBarController,
                let navigationController  = tabBarViewController.viewControllers?.first as? UINavigationController,
                let vc1 = navigationController.viewControllers.first as? CartCollectionViewController
                else { return }
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: CartViewController.self))
            guard let vc2 = vc as? CartViewController else { return }
            vc2.viewModel = CartViewModel(cart: cart)
            navigationController.viewControllers = [vc1,vc2]
        }
        else if let recipe = object as? Recipe {
            CloudManager.saveParentDataToCloud(object: recipe, objectImageName: recipe.imageFileName) { (recordID) in
                DispatchQueue.main.async {
                    RealmDataManager.changeElementIn(object: recipe,
                                                     keyValue: "cloudID",
                                                     objectParameter: recipe.cloudID,
                                                     newParameter: recordID)
                }
            }
            guard
                let tabBarViewController = window?.rootViewController as? UITabBarController
                else { return }
            tabBarViewController.selectedIndex = 1
            
            guard
                let navigationController = tabBarViewController.selectedViewController as? UINavigationController,
                let vc1 = navigationController.viewControllers.first as? RecipeCollectionViewController
                else { return }
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: String(describing: RecipeViewController.self))
            guard let vc2 = vc as? RecipeViewController else { return }
            vc2.viewModel = RecipeViewModel(recipe: recipe)
            navigationController.viewControllers = [vc1,vc2]
        }
    }
}
