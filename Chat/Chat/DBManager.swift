//
//  DBManager.swift
//  Chat
//
//  Created by Maor Shams on 09/04/2017.
//  Copyright © 2017 Maor Shams. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher

protocol FetchedData : class{
    func dataReceived(contacts : [Contact])
    // func errorOccurred(description : String)
}
protocol DBManagerDelegate : class{
    func dataUpdated(info : String, error : String?)
}

class DBManager{
    
    // Initialization
    
    fileprivate init(){}
    
    fileprivate static let instance = DBManager()
    
    static var manager : DBManager{
        get{
            return instance
        }
    }
    
    weak var fetchedDelegate : FetchedData?
    weak var DBDelegate : DBManagerDelegate?
    
    
    // functionality
    
    var dbRef : FIRDatabaseReference{
        return FIRDatabase.database().reference()
    }
    
    var contactsRef : FIRDatabaseReference{
        return dbRef.child(Constants.CONTACTS)
    }
    
    var messagesRef : FIRDatabaseReference{
        return dbRef.child(Constants.MESSAGES)
    }
    
    var storageRef : FIRStorageReference{
        return FIRStorage.storage().reference(forURL: "gs://ios-chat-c92a3.appspot.com/")
    }
    
    var imageStorageRef : FIRStorageReference{
        return storageRef.child(Constants.IMAGE_STORAGE)
    }
    
    var videoStorageRef : FIRStorageReference{
        return storageRef.child(Constants.VIDEO_STORAGE)
    }
    
    // MARK: - Save User
    func saveUser(withID : String, email : String, password : String ){
        
        // split the name of from the email
        let userDisplayName = email.components(separatedBy: "@")[0]
        
        // store user data in Dictionary
        let data : Dictionary<String,Any> = [
            Constants.EMAIL: email,
            Constants.PASSWORD : password,
            Constants.USER_NAME : userDisplayName
        ]
        
        // save data in DB
        contactsRef.child(withID).setValue(data)
        
        updateDisplayName(with: userDisplayName)
    }
    
    // MARK: - Update user display name
    func updateDisplayName(with name : String){
        
        // store user data in Dictionary
        let data : Dictionary<String,Any> = [
            Constants.USER_NAME : name
        ]
        
        // save data in DB
        contactsRef.child(AuthManager.User.id.value).updateChildValues(data)
        
        //authentication
        let usr = FIRAuth.auth()?.currentUser?.profileChangeRequest()
        usr?.displayName = name
        usr?.commitChanges(completion: { (err_) in
            if err_ != nil{
                self.DBDelegate?.dataUpdated(info: "", error: err_!.localizedDescription)
            }
        })
        
    }
    
    // MARK: - Update user status
    func updateUserStatus(with status : String){
        // store user data in Dictionary
        let data : Dictionary<String,Any> = [
            Constants.USER_STATUS : status
        ]
        
        // save data in DB
        contactsRef.child(AuthManager.User.id.value).updateChildValues(data)
    }
    
    // MARK: -  Update user profile image
    func updateImage(image : UIImage){
        // image to data (0.5) is the compression Quality..
        let data : Data = UIImageJPEGRepresentation(image, 0.5)!
        let currentUser = AuthManager.User.self
        
        // store the image is path :
        // storage/files/Image_Storage/profile_images/**USER-ID**/ profile_image.jpg
        imageStorageRef.child(Constants.PROFILE_IMAGES).child(currentUser.id.value)
            .child("\(Constants.PROFILE_IMAGE).jpg")
            .put(data, metadata: nil){ [weak self] (metadata : FIRStorageMetadata?, err : Error?) in
                
                if err != nil{ // problem with upload image
                    // Error occurred, infrom the user
                    self?.DBDelegate?.dataUpdated(info: "", error: err!.localizedDescription)
                }else{  // send link to photo in user messages
                    
                    let link = metadata!.downloadURL()!
                    let usr = FIRAuth.auth()?.currentUser?.profileChangeRequest()
                    usr?.photoURL = link
                    usr?.commitChanges(completion: { (err) in
                        if err != nil{
                            self?.DBDelegate?.dataUpdated(info: "", error: err!.localizedDescription)
                        }else{
                            self?.DBDelegate?.dataUpdated(info: "", error: nil)
                        }
                        
                    })
                    
                    // store user data in Dictionary
                    let data : Dictionary<String,Any> = [
                        Constants.PROFILE_IMAGE : String(describing: link)
                    ]
                    
                    // save data in DB
                    self?.contactsRef.child(AuthManager.User.id.value).updateChildValues(data)
                }
        }
    }
    
    // MARK: - Get current user profile image
    func getProfileImage(fromCache : Bool, completion:((UIImage)->())?){
        
        // Profile image url, may be empty
        let imgURL : String = AuthManager.User.imageURL.value
        
        // Download from DB only if not exist in cache / updating image
        func downloadImage(){
            guard !imgURL.isEmpty ,imgURL != "nil"  else {
                return
            }
            
            let url = URL(string: imgURL)!
            
            ImageDownloader.default.downloadImage(with: url, options: [], progressBlock: nil){
                (image, error, url, data) in
                
                guard let img = image else{
                    return
                }
                
                if completion != nil {completion!(img)}
                
                // Store in cache
                ImageCache.default.store(img, forKey: Constants.PROFILE_IMAGE)
            }
        }
        
        // Check if image is Exist in cache
        // In case user changed his profile image pass FALSE..
        if fromCache{
            ImageCache.default.retrieveImage(forKey: Constants.PROFILE_IMAGE, options: nil) {
                image, cacheType in
                
                if let image = image, completion != nil {   // There is image in cache.
                    completion!(image)
                } else {                 // Not exist in cache.
                    downloadImage()
                }
            }
            return
        }//else
        downloadImage()
    }
    
    // MARK: - Get current user status
    func getUserStatus(completion : @escaping (_ : String) -> Void) {
        let userID = AuthManager.User.id.value
        
        contactsRef.child(userID).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            
            if let str = value?[Constants.USER_STATUS] as? String {
                completion(str)
            }else{
                completion("No status")
            }
            
        })
        
    }
    
    // new array of contacts, loop append each contact into
    fileprivate var _contacts = [Contact]()
    
    var contacts : [Contact]{
        return _contacts
    }
    
    // MARK: - Get all contacts
    func getContacts(){
        
        // event listener for any data changes at a location or, recursively, at any child node.
        contactsRef.observeSingleEvent(of: .value){ [weak self] (snapshot : FIRDataSnapshot) in
            
            // if contacts list is Dictionary
            guard let myContacts = snapshot.value as? NSDictionary else{
                return
            }
            
            self?._contacts.removeAll()
            
            // iterate over each contact
            for(key,value) in myContacts{
                
                // if the contact is
                guard let contactData = value as? NSDictionary else{
                    break
                }
                
                // if the contact have email, create new object, append
                guard let email = contactData[Constants.EMAIL] as? String,
                    email.lowercased() != (AuthManager.User.email.value),
                    let name = contactData[Constants.USER_NAME] as? String ,
                    let imageURL = contactData[Constants.PROFILE_IMAGE] as? String?,
                    let status = contactData[Constants.USER_STATUS] as? String?
                    else{
                        continue // next user
                }
                
                let id = key as! String
                let newContact = Contact(id: id,
                                         email: email,
                                         name: name,
                                         imageURL: imageURL ?? "",
                                         status : status ?? "Available")
                
                self?._contacts.append(newContact)
                
            }
            self?.fetchedDelegate?.dataReceived(contacts: (self?.contacts)!)
        }
    }
}//class
