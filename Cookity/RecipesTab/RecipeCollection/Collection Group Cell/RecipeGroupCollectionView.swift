//
//  RecipeGroupCollectionView.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 29/04/2020.
//  Copyright © 2020 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import SwipeCellKit

protocol PresentationDelegate {
    func present(vc: UIViewController)
}

class RecipeGroupCollectionView: UICollectionView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var viewModel: RecipeGroupCollectionViewModel!
    var presentationDelegate: PresentationDelegate?
    
    init() {
        super.init(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        self.register(UINib(nibName: "RecipeCell", bundle: nil), forCellWithReuseIdentifier: "RecipeCell")
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.register(UINib(nibName: "RecipeCell", bundle: nil), forCellWithReuseIdentifier: "RecipeCell")
        dataSource = self
        delegate = self
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.numberOfRows
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 151, height: 152)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecipeCell", for: indexPath) as! RecipeCell
        cell.viewModel = viewModel.cellViewModel(forIndexPath: indexPath) as? RecipeCollectionCellViewModel
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectRow(atIndexPath: indexPath)
        let vc = RecipeViewController()
        vc.viewModel = viewModel.viewModelForSelectedRow() as? RecipeViewModel
        presentationDelegate?.present(vc: vc)
    }

}


class RecipeGroupCollectionViewModel: TableViewModelType {
    
    
    private var recipes: [Recipe]
    var numberOfSections: Int {
        0
    }
    
    var numberOfRows: Int {
        recipes.count
    }
    
    private var selectedIndexPath: IndexPath?
    
    func cellViewModel(forIndexPath indexPath: IndexPath) -> CellViewModelType? {
        return RecipeCollectionCellViewModel(recipe: recipes[indexPath.row])
    }
    
    func viewModelForSelectedRow() -> DetailViewModelType? {
        guard let row = selectedIndexPath?.row else { return nil }
        
        return RecipeViewModel(recipe: recipes[row])
    }
    
    func selectRow(atIndexPath indexPath: IndexPath) {
        selectedIndexPath = indexPath
    }
    
    init(recipes: [Recipe]) {
        self.recipes = recipes
    }
}
