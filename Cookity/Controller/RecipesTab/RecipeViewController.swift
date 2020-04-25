//
//  RecipeViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 25/11/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift

enum ParentViewForLabel {
    case image
    case view
}

class RecipeViewController: UIViewController, UpdateVCDelegate {
    
    @IBOutlet weak var productTable: UITableView!
    @IBOutlet weak var cookButton: UIButton!
    
    var viewModel: RecipeViewModel!
    let imageView = UIImageView()

    
    var navBarHeight: CGFloat {
        guard let navBarHeight = self.navigationController?.navigationBar.frame.height,
            let statBarHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height
        else { return 0 }
        return statBarHeight + navBarHeight
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        productTable.delegate = self
        productTable.dataSource = self
        productTable.separatorStyle = .none
        productTable.rowHeight = UITableView.automaticDimension
        productTable.estimatedRowHeight = 100
        
        cookButton.layer.shadowOffset = CGSize(width: 0, height: 3.0)
        cookButton.layer.shadowOpacity = 0.7
        cookButton.layer.shadowRadius = 5.0
    }

    override func viewWillAppear(_ animated: Bool) {
        updateVC()
    }
    
    func updateVC() {
        if viewModel.isRecipeInvalidated {
            navigationController?.popViewController(animated: true)
        }
        else {
            if let image = viewModel.recipeImage {
                addImageView(image: image)
                productTable.reloadData()
            }
            else {
                setStandardNavBar()
            }
        }
    }
    
    private func addImageView(image: UIImage) {
        productTable.contentInset = UIEdgeInsets(top: 300, left: 0, bottom: 0, right: 0)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.backgroundColor = .clear
        
        imageView.image = image
        let imageHeight = 300 + navBarHeight
        imageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: imageHeight)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        view.addSubview(imageView)
    }
    
    private func setStandardNavBar() {
        imageView.removeFromSuperview()
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.tintColor = Colors.textColor
        self.navigationController?.navigationBar.barTintColor = Colors.viewColor
        self.navigationController?.navigationBar.backgroundColor = Colors.viewColor
        productTable.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y = 300 - (scrollView.contentOffset.y + 300)
        let height = min(max(y, navBarHeight), 600)
        imageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: height)
    }
    

    
    
    @IBAction func shareButtonPressed(_ sender: UIBarButtonItem) {
        var activityController: UIActivityViewController?
        
        
        let alert = UIAlertController(title: "How would you like to share this recipe?", message: nil, preferredStyle: .actionSheet)
        alert.view.tintColor = Colors.textColor
        let textAction = UIAlertAction(title: "Send as text", style: .default) { (_) in
            activityController = self.viewModel.shareRecipet(as: .text)
            guard let activity = activityController else { return }
            activity.popoverPresentationController?.barButtonItem = sender
            self.present(activity, animated: true, completion: nil)
        }
        let fileAction = UIAlertAction(title: "Send as Cookity file", style: .default) { (_) in
            activityController = self.viewModel.shareRecipet(as: .file)
            guard let activity = activityController else { return }
            activity.popoverPresentationController?.barButtonItem = sender
            self.present(activity, animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(textAction)
        alert.addAction(fileAction)
        alert.addAction(cancelAction)
        present(alert, animated: true) {}
    }
    
    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "EditCookingArea", sender: self)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "EditCookingArea" {
            let destinationVC = segue.destination as! CookViewController
            destinationVC.viewModel = viewModel.viewModelForCookVC()
            destinationVC.updateVCDelegate = self
        }
        else if segue.identifier == "goToCookProcess" {
            let destinationVC = segue.destination as! CookProcessViewController
            destinationVC.viewModel = viewModel.viewModelForCookProcess()
        }
    }
        
    
    //Creates a new shopping list the adds the products from recipe to it
    @IBAction func createButtonPressed(_ sender: UIButton) {
        let checkmark = CheckmarkView(frame: self.view.frame, message: "Done!")
        self.view.addSubview(checkmark)
        checkmark.animate()
        viewModel.createCartFromRecipe()
    }
    
    
    @IBAction func cookButtonPressed(_ sender: UIButton) {
        if viewModel.recipeStepsCount != 0 {
            performSegue(withIdentifier: "goToCookProcess", sender: self)
        }
        else {
            let checkmark = CheckmarkView(frame: self.view.frame, message: "Fridge was edited")
            self.view.addSubview(checkmark)
            checkmark.animate()
        }
        viewModel.editFridgeProducts()
        productTable.reloadData()
    }
}


//MARK:- UITableView Methods
extension RecipeViewController: UITableViewDelegate, UITableViewDataSource{
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0 else { return nil }
//        if viewModel.recipeImage == nil { return nil }
        let backgroundView = RecipeSectionView()
        backgroundView.configureView(.Header, with: viewModel.recipeName)
        return backgroundView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section != 2 else { return nil }
        if section == 1, viewModel.recipeStepsCount == 0 { return nil }
        
        let backgroundView = RecipeSectionView()
        backgroundView.configureView(.Footer, with: viewModel.sections[section + 1])
        return backgroundView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard section != 2 else { return 0 }
        if section == 1, viewModel.recipeStepsCount == 0 { return 0 }
        return 30
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section == 0 else { return 0 }
//        if viewModel.recipeImage == nil { return 0 }
        return 38
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.currentSection(section)
        return viewModel.numberOfRows
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            if indexPath.row < viewModel.productsCount {
                let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeProductCell", for: indexPath) as! RecipeProductCell
                cell.viewModel = viewModel.cellViewModel(forIndexPath: indexPath) as? RecipeProductCellViewModel
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "createShoppingListCell", for: indexPath) as! CreateListCell
                return cell
            }
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RVRecipeStepCell", for: indexPath) as! RVRecipeStepCell
            cell.viewModel = viewModel.cellViewModel(forIndexPath: indexPath) as? RVRecipeStepCellViewModel
            cell.selectionStyle = .none
            return cell
        }
    }
}
