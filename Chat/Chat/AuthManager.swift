//
//  AuthManager.swift
//  Chat
//
//  Created by Maor Shams on 09/04/2017.
//  Copyright © 2017 Maor Shams. All rights reserved.
//

import UIKit
import Firebase
class AuthManager{
    
    // Initialization
    typealias Response = (isValid : Bool,description : String)
    typealias LoginHandler = (_ msg: String?) -> Void;
    
    fileprivate init(){}
    
    fileprivate static let instance = AuthManager()
    
    static var manager : AuthManager{
        get{
            return instance
        }
    }
    
    // Get info about current user
    enum User {
        case email
        case name
        case id
        case imageURL
        
        var value : String{
            switch self {
            case .email: return (FIRAuth.auth()?.currentUser?.email ?? "")
            case .name:   return (FIRAuth.auth()?.currentUser?.displayName ?? "")
            case .id:   return (FIRAuth.auth()?.currentUser?.uid ?? "")
            case .imageURL:
                if let url = FIRAuth.auth()?.currentUser?.photoURL{
                    return String(describing: url)
                }
                return ""
            }
        }
        
    }
    
    // functionality
    
    // MARK: - Logout
    func logOut() -> Response{
        if FIRAuth.auth()?.currentUser != nil{
            do{
                try FIRAuth.auth()?.signOut()
                return (true,"")
            }catch{
                return (false,error.localizedDescription)
            }
        }
        return (true,"")
    }

    // MARK: - Sign In
    func signIn(with email: String, password: String,loginHandler: LoginHandler?){
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
            if error != nil {// if error is occurred
                loginHandler?(error?.localizedDescription)
            }else{
                loginHandler?(nil)
            }
        })
    }
    
    // MARK: - Sign Up
    func signUp(with email: String, password: String, loginHandler: LoginHandler?){
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
            if error != nil { // if error is occurred
                loginHandler?(error?.localizedDescription)
            }else{
                // store the user in database
                DBManager.manager.saveUser(withID: user!.uid, email: email, password: password)
                
                // login the user
                self.signIn(with: email, password: password, loginHandler: loginHandler)
            }
        })
    }
    
    // Check if the user is already logged in
    var isLoggedIn : Bool{
        return FIRAuth.auth()?.currentUser != nil ? true : false
    }
}
