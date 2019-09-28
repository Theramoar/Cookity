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

    @IBOutlet weak var tableView: UITableView!
    let sections = ["Settings", "Contact us"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
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
        guard section != 0 else { return 0 }
        return 35
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                return 210
            }
            return 44
        }
        else {
            return 44
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
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
                cell = tableView.dequeueReusableCell(withIdentifier: "workInProgressCell", for: indexPath)
            case 1:
                let enableCell = tableView.dequeueReusableCell(withIdentifier: "enableIngridientCell", for: indexPath) as! EnableOptionCell
                enableCell.enableCellType = .enableIngridient
                return enableCell
            case 2:
                let enableCell = tableView.dequeueReusableCell(withIdentifier: "enableIngridientCell", for: indexPath) as! EnableOptionCell
                enableCell.enableCellType = .enableCloud
                return enableCell
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
