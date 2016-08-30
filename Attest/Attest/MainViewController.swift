//
//  MainViewController.swift
//  Attest
//
//  Created by Vishal on 29/08/16.
//  Copyright © 2016 Vishal. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, StoryboardIdentity {
    
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var middleLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    
    var accountKitHandler: AccountKitHandler?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let accountKitHandler = accountKitHandler {
            topLabel.text = "Access Token: \(accountKitHandler.currentAccessToken?.tokenString ?? "")"
            middleLabel.text = "Account ID: \(accountKitHandler.currentAccessToken?.accountID ?? "")"
        }
    }
    
    @IBAction func logOut(sender: AnyObject) {
        accountKitHandler?.logOut()
        self.navigationController?.popViewControllerAnimated(true)
    }
    
}
