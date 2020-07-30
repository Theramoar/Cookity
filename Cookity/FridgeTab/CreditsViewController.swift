//
//  CreditsViewController.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 02/07/2019.
//  Copyright © 2019 Mihails Kuznecovs. All rights reserved.
//

import UIKit

final class CreditsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let sections = ["Icons are made by:", "from http://www.flaticon.com"]
    
    let authorNames = ["Egor Rumyantsev", "Gregor Cresnar","Kiranshastry", "Those Icons", "Roundicons", "Cole Bemis", "Freepik"]
    let authorInfos = ["Egor Rumyantsev" : "https://www.flaticon.com/authors/egor-rumyantsev",
        "Gregor Cresnar" : "https://www.flaticon.com/authors/gregor-cresnar",
        "Kiranshastry" : "https://www.flaticon.com/authors/kiranshastry",
        "Cole Bemis" : "https://www.flaticon.com/authors/cole-bemis",
        "Those Icons" : "https://www.flaticon.com/authors/those-icons",
        "Roundicons" : "https://www.flaticon.com/authors/roundicons",
        "Freepik" : "https://www.freepik.com/home"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = 30
    }
}

extension CreditsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return authorInfos.count
        default:
            return 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "creditCell", for: indexPath) as! CreditsViewCell
        let authorName = authorNames[indexPath.row]
        guard let authorLink = authorInfos[authorName] else { return cell }
        cell.authorName = authorName
        cell.url = URL(string: authorLink)
   
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! CreditsViewCell
        guard let url = cell.url else { return }
        UIApplication.shared.open(url)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view = UIView()
        view.backgroundColor = Colors.viewColor
        
        let label = UILabel()
        label.frame = CGRect(x: 5, y: 0, width: 300, height: 35)
        label.textColor = Colors.textColor
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.text = sections[section]
        view.addSubview(label)
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }
    
}
