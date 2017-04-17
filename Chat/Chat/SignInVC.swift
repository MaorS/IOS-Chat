//
//  SignInVC.swift
//  Chat
//
//  Created by Maor Shams on 09/04/2017.
//  Copyright © 2017 Maor Shams. All rights reserved.
//

import UIKit
import PopupDialog

class SignInVC: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInBtn: UIButton!
    @IBOutlet weak var signUpBtn: UIButton!
    
    override func viewDidAppear(_ animated: Bool) {
        // if user is already logged in
        if AuthManager.manager.isLoggedIn{
            self.performSegue(withIdentifier: Constants.CONTACTS_SEGUE, sender: nil)
        }
    }
    
    @IBAction func signInAction() {
        
        let email : String = emailTextField.text ?? ""
        let pass : String = passwordTextField.text ?? ""
        
        if email.isEmpty || pass.isEmpty {
            alert(message: "Email and Password are required")
            return
        }
        
        self.isButtonsEnabled(false)
        
        AuthManager.manager.signIn(with : email, password: pass) { (error) in
            self.isButtonsEnabled(true)
            if error != nil{ // if there is an error
                self.alert(message: error!)
            }else if AuthManager.manager.isLoggedIn{
                self.performSegue(withIdentifier: Constants.CONTACTS_SEGUE, sender: nil)
            }
        }
    }
    
    
    @IBAction func signUpAction() {
        
        let email : String = emailTextField.text ?? ""
        let pass : String = passwordTextField.text ?? ""
        
        if email.isEmpty || pass.isEmpty {
            alert(message: "Email and Password are required")
            return
        }
        
        self.isButtonsEnabled(false)
        
        AuthManager.manager.signUp(with: email, password: pass) { (error) in
            self.isButtonsEnabled(true)
            if error != nil{ // if there is an error
                self.alert(message: error!)
            }else if AuthManager.manager.isLoggedIn{
                self.performSegue(withIdentifier: Constants.CONTACTS_SEGUE, sender: nil)
            }
        }
    }
    
    // Toggle login / logout buttons
    func isButtonsEnabled(_ choise : Bool){
        signInBtn.toDisable(choise)
        signUpBtn.toDisable(choise)
    }
}





