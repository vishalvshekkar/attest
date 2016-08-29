//
//  AttestViewController.swift
//  Attest
//
//  Created by Vishal on 29/08/16.
//  Copyright © 2016 Vishal. All rights reserved.
//

import UIKit
import AccountKit

private typealias Utilities = AttestViewController

class AttestViewController: UIViewController, AKFViewControllerDelegate {

    let accountKitHandler = AccountKitHandler(responseType: .AccessToken)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let isUserLoggedIn = accountKitHandler.isUserLoggedIn where isUserLoggedIn {
            showMainVC(accountKitHandler.currentAccessToken)
        } else if accountKitHandler.viewControllerForLoginResume() != nil {
            accountKitHandler.resumePreviousLogIn(self, completion: { (response) in
                self.handleResponse(response)
            })
        }
    }
    
    @IBAction func loginWithEmail(sender: AnyObject) {
        accountKitHandler.logInWithEmail(nil, viewController: self) { (response) in
            self.handleResponse(response)
        }
    }
    
    @IBAction func loginWithPhone(sender: AnyObject) {
        accountKitHandler.logInWithPhoneNumber(nil, viewController: self) { (response) in
            self.handleResponse(response)
        }
    }
    
    func handleResponse(responseStatus: AccountKitHandler.AccountKitHandlerResponseState) {
        switch responseStatus {
        case let .Success(accessToken, _):
            showMainVC(accessToken)
        case let .Failure(description):
            showError(description)
        case .Cancellation:
            break
        }
    }
    
    private func showMainVC(accessToken: AKFAccessToken?) {
        if let mainVC = UIStoryboard.StoryboardType.Main.instantiateViewController(MainViewController) {
            mainVC.accountKitHandler = accountKitHandler
            self.navigationController?.pushViewController(mainVC, animated: true)
        }
    }
    
    private func showError(description: String?) {
        showAlert(description ?? Constants.somethingWentWrong)
    }
    
    
}

extension Utilities {
    
    private struct Constants {
        static let somethingWentWrong = "Something Went Wrong"
        static let okay = "Okay"
        static let attest = "Attest"
    }
    
    func showAlert(message : String)
    {
        let alert = UIAlertController(title: Constants.attest, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: Constants.okay, style: UIAlertActionStyle.Default, handler: { (alert) -> Void in
            
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
}
