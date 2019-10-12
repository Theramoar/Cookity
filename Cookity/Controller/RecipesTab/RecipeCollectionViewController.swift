//
//  RecipeCollectionViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 25/11/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift

class RecipeCollectionViewController: UIViewController, UpdateVCDelegate {
    
    
    @IBOutlet var recipeCollectioDM: RecipeCollectionDataManager!
    @IBOutlet weak var recipeCollection: UICollectionView!
    @IBOutlet weak var addRecipeButton: UIButton!
    
    
    //MARK:- SearchBar variables
    private var searchController: UISearchController!
    private var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    private var searchBarIsEmpty: Bool {
        guard let text = searchController.searchBar.text else { return false }
        return text.isEmpty
    }
    
    //MARK:- ViewController methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recipeCollection.delegate = self
        recipeCollection.dataSource = self
        recipeCollectioDM.updateVCDelegate = self
        
        searchController = recipeCollectioDM.setupSearchBarController()
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        addRecipeButton.layer.shadowOffset = CGSize(width: 0, height: 3.0)
        addRecipeButton.layer.shadowOpacity = 0.7
        addRecipeButton.layer.shadowRadius = 5.0
        
        recipeCollectioDM.recipeList = RealmDataManager.dataLoadedFromRealm(ofType: .Recipe)
        recipeCollectioDM.loadDataFromCloud()
    }
    
    private func setStandardNavBar() {
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.view.backgroundColor = Colors.appColor
        self.navigationController?.navigationBar.tintColor = Colors.textColor
        self.navigationController?.navigationBar.backgroundColor = Colors.appColor
        self.navigationController?.navigationBar.isTranslucent = false
        searchController = recipeCollectioDM.setupSearchBarController()
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setStandardNavBar()
        updateVC()
        searchController.searchBar.placeholder = SettingsVariables.isIngridientSearchEnabled ? "Search for recipe or ingridient" : "Search for recipe"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToRecipe" {
           let destinationVC = segue.destination as! RecipeViewController
            if let indexPath = recipeCollection.indexPathsForSelectedItems?.first{
                let recipe = isFiltering ? recipeCollectioDM.filteredRecipeList[indexPath.row] : recipeCollectioDM.recipeList?[indexPath.row]
                destinationVC.recipeDataManager.selectedRecipe = recipe
            }
        }
        else if segue.identifier == "goToCookingArea" {
            let destinationVC = segue.destination as! CookViewController
            destinationVC.updateVCDelegate = self
        }
    }
    
    //MARK:- UpdateVCDelegate Method
    func updateVC() {
        recipeCollection.reloadData()
    }

    //MARK:- Methods for Buttons
    @IBAction func addButtonPressed(_ sender: UIButton) {
      performSegue(withIdentifier: "goToCookingArea", sender: self)
    }
}

//MARK:- RecipeCollection Delegate and DataSource
extension RecipeCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isFiltering {
            return recipeCollectioDM.filteredRecipeList.count
        }
        else {
            return recipeCollectioDM.recipeList?.count ?? 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecipeCell", for: indexPath) as! RecipeCollectionViewCell
        cell.recipe = isFiltering ? recipeCollectioDM.filteredRecipeList[indexPath.row] : recipeCollectioDM.recipeList?[indexPath.row]
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToRecipe", sender: self)
    }
}
