//
//  SettingsViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 16/06/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import MessageUI


class SettingsViewController: UIViewController {
    @IBOutlet weak var buyProButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    let sections = ["General", "Contact us"]
    private var canAnimate = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
        setupButton()
        NotificationCenter.default.addObserver(self, selector: #selector(IAPPurchased), name: .purchaseWasSuccesful, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func IAPPurchased() {
        setupButton()
    }
        
    private func setupTable() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: "DefaultDatePickerCell", bundle: nil), forCellReuseIdentifier: "DefaultDatePickerCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 300
    }
    
    private func setupButton() {
        if UserPurchases.isProEnabled() {
            buyProButton.isEnabled = false
            buyProButton.isHidden = true
        }
        else {
            buyProButton.layer.cornerRadius = buyProButton.frame.size.height / 3
            buyProButton.layer.shadowOffset = CGSize(width: 0, height: 3.0)
            buyProButton.layer.shadowOpacity = 0.7
            buyProButton.layer.shadowRadius = 5.0
        }
    }
    
    func showMailComposer() {
        guard MFMailComposeViewController.canSendMail() else {
            
            let mailURL = URL(string: "message://")!
            if UIApplication.shared.canOpenURL(mailURL) {
                UIApplication.shared.open(mailURL, options: [:], completionHandler: nil)
            }
            return
        }
        
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setToRecipients(["cookityapp@gmail.com"])
        composer.setSubject("App feedback")

        present(composer, animated: true)
    }
    
    
    @IBAction func buyProPressed(_ sender: Any) {
        let vc = InAppPurchaseViewController()
        present(vc, animated: true, completion: nil)
    }
}

//MARK: - Extension for MailComposer Methods
extension SettingsViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        
        if let _ = error {
            controller.dismiss(animated: true)
            return
        }
        
        switch result {
        case .saved:
            animateCheckmark(message: "Message is saved")
        case .sent:
            animateCheckmark(message: "Message is sent")
        case .cancelled:
            break
        case .failed:
            break
        @unknown default:
            fatalError()
        }
        
        controller.dismiss(animated: true)
    }
    
    func animateCheckmark(message: String) {
        let checkmark = CheckmarkView(frame: self.view.frame, message: message)
        self.view.addSubview(checkmark)
        checkmark.animate()
    }
}


//MARK: - Extension for TableView Methods
extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view = UIView()
        view.backgroundColor = Colors.viewColor
        
        let label = UILabel()
        label.frame = CGRect(x: 5, y: 0, width: 200, height: 35)
        label.textColor = Colors.textColor
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.text = sections[section]
        view.addSubview(label)
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if SettingsVariables.isDefaultDateEnabled { return 4 }
            return 3
        default:
            return 2
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell
        
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                let enableCell = tableView.dequeueReusableCell(withIdentifier: "enableIngridientCell", for: indexPath) as! EnableOptionCell
                enableCell.enableCellType = .enableIngridient
                return enableCell
            case 1:
                let enableCell = tableView.dequeueReusableCell(withIdentifier: "enableIngridientCell", for: indexPath) as! EnableOptionCell
                enableCell.enableCellType = .enableCloud
                return enableCell
            case 2:
                let enableCell = tableView.dequeueReusableCell(withIdentifier: "enableIngridientCell", for: indexPath) as! EnableOptionCell
                enableCell.enableCellType = .enableDefaultDate
                enableCell.delegate = self
                return enableCell
            case 3:
                let defCell = tableView.dequeueReusableCell(withIdentifier: "DefaultDatePickerCell", for: indexPath) as! DefaultDatePickerCell
                defCell.delegate = self
                defCell.animator = self
                return defCell
                
            default:
                cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            }
        }
        else {
            switch indexPath.row {
            case 0:
                let contactsCell = tableView.dequeueReusableCell(withIdentifier: "contactsCell", for: indexPath) as! ContactsCell
                contactsCell.contactsCellType = .contactUs
                cell = contactsCell
            case 1:
                let contactsCell = tableView.dequeueReusableCell(withIdentifier: "contactsCell", for: indexPath) as! ContactsCell
                contactsCell.contactsCellType = .credits
                cell = contactsCell
            default:
                cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                cell.selectionStyle = .none
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        switch indexPath.row {
        case 0:
            showMailComposer()
        case 1:
            performSegue(withIdentifier: "goToCredits", sender: self)
        default:
            break
        }
    }
}

extension SettingsViewController: UpdateVCDelegate, DatePickerAnimator {
    func updateVC() {
        tableView.reloadData()
    }
    
    func rotateArrow() {
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        guard let cell = tableView.cellForRow(at: IndexPath(row: 3, section: 0)) as? DefaultDatePickerCell else { return }
        if !cell.defaultDatePicker.isHidden {
            UIView.animate(withDuration: 0.3, animations: {
                cell.arrowImageView.transform = CGAffineTransform(rotationAngle: -.pi/2)
            })
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                cell.arrowImageView.transform = CGAffineTransform(rotationAngle: 0)
            })
        }
    }
}

