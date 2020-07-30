//
//  FridgeViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 24/10/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift
import SwipeCellKit

enum ExpirationFrame: String, CaseIterable {
    case expired = "Expired"
    case in3Days = "Expire in 3 days"
    case in1Week = "Expire in 1 week"
    case in1Month = "Expire in 1 month"
    case other = "Other"
}

class FridgeViewController: SwipeTableViewController, UpdateVCDelegate {
    
    var viewModel = FridgeViewModel()
    @IBOutlet weak var fridgeTableView: UITableView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var emptyFridgeImageView: UIImageView!
    @IBOutlet weak var emptyFridgeLabel: UILabel!
    @IBOutlet weak var emptyFridgeDescriptionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isTranslucent = true
        
        fridgeTableView.delegate = self
        fridgeTableView.dataSource = self
        fridgeTableView.separatorStyle = .none
        fridgeTableView.register(UINib(nibName: "ProductCell", bundle: nil), forCellReuseIdentifier: "ProductCell")
        fridgeTableView.rowHeight = 50
        
        addButton.layer.shadowOffset = CGSize(width: 0, height: 3.0)
        addButton.layer.shadowOpacity = 0.7
        addButton.layer.shadowRadius = 5.0
        
        //add long gesture recognizer
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressed))
        self.view.addGestureRecognizer(longPressRecognizer)
        
        guard SettingsVariables.isCloudEnabled else { return }
        CloudManager.syncData(parentObjects: [Fridge.shared])
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        updateVC()
    }
    
    func updateVC() {
        fridgeTableView.reloadData()
        uncheck()
    }
    
    //MARK:- Methods for Buttons
    @objc func longPressed(longPressRecognizer: UILongPressGestureRecognizer) {

        // find the IndexPath of the cell which was "longtouched"
        let touchPoint = longPressRecognizer.location(in: self.fridgeTableView)
        let selectedIndexPath = fridgeTableView.indexPathForRow(at: touchPoint)
        guard selectedIndexPath != nil else { return }
        viewModel.longTapRow(atIndexPath: selectedIndexPath!)
        if self.presentedViewController == nil {
            let vc = PopupEditViewController()
            vc.viewModel = viewModel.viewModelForSelectedRow() as? PopupEditViewModel
            vc.parentVC = self
            present(vc, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func addButtonPressed(_ sender: UIButton) {
        let vc = CookViewController()
        vc.viewModel = viewModel.viewModelForCookdArea()
        vc.updateVCDelegate = self
        present(vc, animated: true, completion: nil)
    }

    //MARK:- Data Manipulation Methods
    
    override func deleteObject(at indexPath: IndexPath) {
        viewModel.deleteProductFromFridge(at: indexPath)
        fridgeTableView.reloadData()
    }
    
    func uncheck() {
        viewModel.uncheckProducts()
        configButton()
    }
    
    func configButton() {
        if viewModel.checkedProducts > 0 {
            addButton.isEnabled = true
            addButton.isHidden = false
        }
        else {
            addButton.isEnabled = false
            addButton.isHidden = true
        }
    }
}


//MARK: - Extension for TableView Methods
extension FridgeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewModel.fridgeIsEmpty {
            emptyFridgeImageView.isHidden = false
            emptyFridgeLabel.isHidden = false
            emptyFridgeDescriptionLabel.isHidden = false
        } else {
            emptyFridgeImageView.isHidden = true
            emptyFridgeLabel.isHidden = true
            emptyFridgeDescriptionLabel.isHidden = true
        }
        return viewModel.numberOfRowsForCurrentSection(section)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        ExpirationFrame.allCases[section].rawValue
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        viewModel.numberOfRowsForCurrentSection(section) == 0  ? 0 : 20
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath) as! ProductTableViewCell
        cell.delegate = self as SwipeTableViewCellDelegate
        cell.isInFridge = true
        cell.viewModel = viewModel.cellViewModel(forIndexPath: indexPath) as? ProductTableCellViewModel
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.checkProduct(at: indexPath)
        configButton()
        tableView.reloadData()
    }
}
