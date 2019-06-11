//
//  RecipeCollectionViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 25/11/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift

class RecipeCollectionViewController: UIViewController {

    
    @IBOutlet weak var recipeCollection: UICollectionView!
    @IBOutlet weak var addRecipeButton: UIButton!
    
    var recipeList: Results<Recipe>?
    private let dataManager = RealmDataManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recipeCollection.delegate = self
        recipeCollection.dataSource = self
        
        addRecipeButton.layer.shadowOffset = CGSize(width: 0, height: 3.0)
        addRecipeButton.layer.shadowOpacity = 0.7
        addRecipeButton.layer.shadowRadius = 5.0
        
        dataManager.loadFromRealm(vc: self, parentObject: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        recipeCollection.reloadData()
    }

    
    @IBAction func addButtonPressed(_ sender: UIButton) {
      performSegue(withIdentifier: "goToCookingArea", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToRecipe" {
           let destinationVC = segue.destination as! RecipeViewController
            if let indexPath = recipeCollection.indexPathsForSelectedItems?.first{
                destinationVC.selectedRecipe = recipeList?[indexPath.row]
            }
        }
    }
    
}

extension RecipeCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recipeList?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecipeCell", for: indexPath) as! RecipeCollectionViewCell
        cell.recipe = recipeList?[indexPath.row]
        return cell
    }
    

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToRecipe", sender: self)
    }
}
