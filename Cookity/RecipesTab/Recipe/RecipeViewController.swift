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

class RecipeViewController: UIViewController, UpdateVCDelegate, CreateButtonDelegate {
    
    var tableView = UITableView()
    
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
        setTableView()
        setCookButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationItem.largeTitleDisplayMode = .never
        updateVC()
    }
    
    func updateVC() {
        let editButton = UIBarButtonItem(image: UIImage(named: "edit"), style: .plain, target: self, action: #selector(editButtonPressed))
        let shareButton = UIBarButtonItem(image: UIImage(named: "share"), style: .plain, target: self, action: #selector(shareButtonPressed))
        navigationItem.setRightBarButtonItems([editButton, shareButton], animated: true)
        
        if viewModel.isRecipeInvalidated {
            navigationController?.popViewController(animated: true)
        }
        else {
            if let image = viewModel.recipeImage {
                addImageView(image: image)
                tableView.reloadData()
            }
            else {
                setStandardNavBar()
            }
        }
    }
    
    private func setTableView() {
        tableView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        view.addSubview(tableView)
        tableView.backgroundColor = Colors.viewColor
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        
        tableView.register(UINib(nibName: "RecipeProductCell", bundle: nil), forCellReuseIdentifier: "RecipeProductCell")
        tableView.register(UINib(nibName: "CreateListCell", bundle: nil), forCellReuseIdentifier: "CreateListCell")
        tableView.register(UINib(nibName: "RVRecipeStepCell", bundle: nil), forCellReuseIdentifier: "RVRecipeStepCell")
    }
    
    private func setCookButton() {
        let cookButton = AppGreenButton()

        
    
        cookButton.addTarget(self, action: #selector(cookButtonPressed), for: .touchUpInside)
        view.addSubview(cookButton)
        cookButton.translatesAutoresizingMaskIntoConstraints = false
        cookButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        cookButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        cookButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100).isActive = true
        cookButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25).isActive = true
        cookButton.frame.size = CGSize(width: 60, height: 60)
        cookButton.setupAppearance()
        print(cookButton.frame.size.width)
        cookButton.setupAssetImage(name: "chef", edgeInset: 13)
        
    }
    
    private func addImageView(image: UIImage) {
        tableView.contentInset = UIEdgeInsets(top: 300, left: 0, bottom: 0, right: 0)
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.backgroundColor = .clear
        
        imageView.image = image
        let imageHeight = CGFloat(300) + navBarHeight
        imageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: imageHeight)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        view.addSubview(imageView)
    }
    
    private func setStandardNavBar() {
        imageView.removeFromSuperview()
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.tintColor = Colors.appColor
        self.navigationController?.navigationBar.barTintColor = Colors.viewColor
        self.navigationController?.navigationBar.backgroundColor = Colors.viewColor
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y = 300 - (scrollView.contentOffset.y + 300)
        let height = min(max(y, navBarHeight), 600)
        imageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: height)
    }
    

    
    
    @objc func shareButtonPressed(_ sender: UIBarButtonItem) {
        var activityController: UIActivityViewController?
        
        
        let alert = UIAlertController(title: "How would you like to share this recipe?", message: nil, preferredStyle: .actionSheet)
        alert.view.tintColor = Colors.appColor
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
    
    @objc func editButtonPressed(_ sender: UIBarButtonItem) {
        let vc = CookViewController()
        vc.viewModel = viewModel.viewModelForCookVC()
        vc.updateVCDelegate = self
        present(vc, animated: true, completion: nil)
    }
    
        
    
    //Creates a new shopping list the adds the products from recipe to it
    func createCart() {
        let checkmark = CheckmarkView(frame: self.view.frame, message: "Done!")
        self.view.addSubview(checkmark)
        checkmark.animate()
        viewModel.createCartFromRecipe()
    }
    
    @objc func cookButtonPressed(_ sender: UIButton) {
        if viewModel.recipeStepsCount != 0 {
            let vc = CookProcessViewController()
            vc.viewModel = viewModel.viewModelForCookProcess()
            present(vc, animated: true, completion: nil)
        }
        else {
            let checkmark = CheckmarkView(frame: self.view.frame, message: "Fridge was edited")
            self.view.addSubview(checkmark)
            checkmark.animate()
        }
        viewModel.editFridgeProducts()
        tableView.reloadData()
    }
}


//MARK:- UITableView Methods
extension RecipeViewController: UITableViewDelegate, UITableViewDataSource{
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0 else { return nil }
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
                let cell = tableView.dequeueReusableCell(withIdentifier: "CreateListCell", for: indexPath) as! CreateListCell
                cell.delegate = self
                return cell
            }
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RVRecipeStepCell", for: indexPath) as! RVRecipeStepCell
            cell.viewModel = viewModel.cellViewModel(forIndexPath: indexPath) as? RVRecipeStepCellViewModel
            cell.backgroundColor = indexPath.row % 2 == 0 ? Colors.cellColor : Colors.viewColor
            cell.selectionStyle = .none
            return cell
        }
    }
}
