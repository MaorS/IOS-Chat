//
//  ContactsVC.swift
//  Chat
//
//  Created by Maor Shams on 09/04/2017.
//  Copyright © 2017 Maor Shams. All rights reserved.
//

import UIKit
import Firebase

class ContactsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, FetchedData {
    
    @IBOutlet weak var tableView: UITableView!
    weak var refreshControl : UIRefreshControl?
    
    private var contacts = [Contact](){
        didSet{
            tableView.reloadData()
        }
    }
    
    var getContacts : [Contact]{
        return contacts
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add UIRefreshControl
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(fetchData), for: .valueChanged)
        tableView.addSubview(control)
        refreshControl = control
        
        // delegation
        DBManager.manager.fetchedDelegate = self
        
        fetchData()
        
        // get & set user profile image
        DBManager.manager.getProfileImage(fromCache: true, completion: nil)
    }
    
    //  setup cell
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.CHAT_SEGUE ,
            let destination = segue.destination as? ChatVC ,
            let indexPath = self.tableView.indexPathForSelectedRow {
            let contact = contacts[indexPath.row]
            destination.setup(receiver: contact)
        }
    }
    
    // Get contacts
    func fetchData(){
        DBManager.manager.getContacts()
        if (refreshControl?.isRefreshing)!{
            self.refreshControl?.endRefreshing()
        }
    }
    
    // Delegation
    func dataReceived(contacts: [Contact]) {
        self.contacts = contacts
    }
    
    // MARK: -  TableView Data Source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.CONTACT_CELL, for: indexPath) as! ContactCell
        
        let contact = contacts[indexPath.row]
        cell.configure(with: contact)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: Constants.CHAT_SEGUE, sender: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
