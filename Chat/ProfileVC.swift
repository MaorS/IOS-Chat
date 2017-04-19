//
//  ProfileVC.swift
//  Chat
//
//  Created by Maor Shams on 12/04/2017.
//  Copyright © 2017 Maor Shams. All rights reserved.
//

import UIKit
import Kingfisher
import Firebase

class ProfileVC: UITableViewController, UITextFieldDelegate,DBManagerDelegate{
    
    @IBOutlet weak var userNameField: UITextField!
    @IBOutlet weak var statusField: UITextField!
    @IBOutlet weak var profileImage: UIButton!
    
    @IBAction func changeImageAction(_ sender: UIButton) {
        // Create actionsheet using MSActionSheet -> https://github.com/MaorS/MSActionSheet
        let sheet = MSActionSheet.instance.create()
        sheet.addLibrary().addRearCamera().addCancelButton().show(on: self)
        sheet.onFinishPicking {
            if let image = sheet.getResizedImage(toSize: CGSize(width: 150, height: 150)){
                DBManager.manager.updateImage(image: image)
            }
        }
    }
    
    @IBAction func logoutAction(_ sender: UIButton) {
        sender.toDisable(true)  // toggle disable clicking logout
        let response = AuthManager.manager.logOut()
        sender.toDisable(false)
        if response.isValid{   // valid logout
            clearUserCache()
            dismiss(animated: true, completion: nil)
        }else{ // error with logout, notify user
            self.alert(message: response.description)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DBManager.manager.DBDelegate = self
        
        // corner radius
        profileImage.layer.cornerRadius = (profileImage.frame.width) / 2
        profileImage.clipsToBounds = true
        
        // get data
        fetchData(profileCache : true)
    }
    
    func fetchData(profileCache : Bool){
        // get & set user profile image
        DBManager.manager.getProfileImage(fromCache: profileCache ? true : false){
            [weak self] (image : UIImage) in
            self?.profileImage.setImage(image , for: .normal)
            
        }
        
        // get & set user name
        self.userNameField.text = AuthManager.User.name.value
        
        // get & set user status
        DBManager.manager.getUserStatus(){ [weak self] (status : String) in
            self?.statusField.text = status
        }
    }
    
    // Delegation
    func dataUpdated(info: String, error: String?) {
        if error != nil {
            self.alert(message: error!)
            return
        }
        fetchData(profileCache : false)
    }
    
    // MARK: - Return button clicked
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField.tag {
        case 100: updateDisplayName()
        case 101: updateStatus()
        default : break
        }
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - Update user status
    func updateStatus(){
        if let status = statusField.text, !status.isEmpty{
            DBManager.manager.updateUserStatus(with: status)
        }
    }
    
    // MARK: - Update display name
    func updateDisplayName() {
        if let name = userNameField.text, !name.isEmpty{
            DBManager.manager.updateDisplayName(with: name)
        }
    }
    
    
    func clearUserCache(){
        
        func cleanUser(key : String){
            ImageCache.default.removeImage(forKey: key)
        }
        
        // clean current user image
        cleanUser(key: Constants.PROFILE_IMAGE)
        
        // get all contacts
        for contact in DBManager.manager.contacts{
            cleanUser(key: contact.id)
        }
    }
}
