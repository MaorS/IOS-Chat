//
//  Utils.swift
//  Chat
//
//  Created by Maor Shams on 09/04/2017.
//  Copyright © 2017 Maor Shams. All rights reserved.
//

import UIKit
import PopupDialog
import JSQMessagesViewController

// Show alert
extension UIViewController{
    func alert(title: String = "Oops!", message: String = ""){
        let alert = PopupDialog(title: title, message: message)
        alert.addButton(DefaultButton(title: "Ok", action: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

// HEX to rbg
extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

//  Button mode
extension UIButton{
    func toDisable(_ choise : Bool){
        self.isUserInteractionEnabled = choise
        self.setTitleColor(choise ? .black : .gray, for: .normal)
    }
}
