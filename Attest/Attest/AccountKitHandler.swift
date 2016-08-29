//
//  AccountKitHandler.swift
//  Attest
//
//  Created by Vishal on 29/08/16.
//  Copyright © 2016 Vishal. All rights reserved.
//

import UIKit
import AccountKit

private typealias AccountKitDelegate = AccountKitHandler
private typealias Utility = AccountKitHandler

typealias AccountKitHandlerCompletion = (AccountKitHandler.AccountKitHandlerResponseState) -> ()

class AccountKitHandler: NSObject {
    
    var accountKit: AKFAccountKit
    var responseType: AKFResponseType
    var currentAccessToken: AKFAccessToken? {
        return accountKit.currentAccessToken
    }
    var currentAuthorizationCode: String?
    var enableSendToFacebook = true
    var isUserLoggedIn: Bool? {
        return (responseType == .AccessToken) ? (currentAccessToken != nil ? true : false) : (nil)
    }
    
    private var loginCompletion: AccountKitHandlerCompletion?
    private var state = ""
    weak var resumeViewController: UIViewController?

    init(responseType: AKFResponseType) {
        self.responseType = responseType
        accountKit = AKFAccountKit(responseType: responseType)
        super.init()
    }
    
    func viewControllerForLoginResume() -> UIViewController? {
        resumeViewController = accountKit.viewControllerForLoginResume()
        return resumeViewController
    }
    
    func logInWithEmail(email: String?, viewController: UIViewController?, completion: AccountKitHandlerCompletion?) {
        loginCompletion = completion
        state = generateState()
        if let emailLoginViewController = accountKit.viewControllerForEmailLoginWithEmail(email, state: state) as? AKFViewController {
            emailLoginViewController.enableSendToFacebook = enableSendToFacebook
            emailLoginViewController.delegate = self
            if let emailLoginViewController = emailLoginViewController as? UIViewController {
                viewController?.presentViewController(emailLoginViewController, animated: true, completion: nil)
            }
        }
    }
    
    func logInWithPhoneNumber(phoneNumber: String?, viewController: UIViewController?, completion: AccountKitHandlerCompletion?) {
        loginCompletion = completion
        state = generateState()
        if let phoneLoginViewController = accountKit.viewControllerForPhoneLoginWithPhoneNumber(nil, state: state) as? AKFViewController {
            phoneLoginViewController.enableSendToFacebook = true
            phoneLoginViewController.delegate = self
            if let phoneLoginViewController = phoneLoginViewController as? UIViewController {
                viewController?.presentViewController(phoneLoginViewController, animated: true, completion: nil)
            }
        }
    }
    
    func resumePreviousLogIn(viewController: UIViewController?, completion: AccountKitHandlerCompletion?) {
        loginCompletion = completion
        if let resumeViewController = resumeViewController as? AKFViewController {
            resumeViewController.delegate = self
            if let resumeViewController = resumeViewController as? UIViewController {
                viewController?.presentViewController(resumeViewController, animated: true, completion: nil)
            }
        }
    }
    
    func logOut() {
        accountKit.logOut()
    }
    
}

extension AccountKitDelegate: AKFViewControllerDelegate {
    
    func viewController(viewController: UIViewController?, didCompleteLoginWithAuthorizationCode code: String?, state: String?) {
        if state == self.state {
            loginCompletion?(AccountKitHandler.AccountKitHandlerResponseState.Success(accessToken: nil, authorizationCode: code))
        } else {
            loginCompletion?(AccountKitHandler.AccountKitHandlerResponseState.Failure(description: Constants.stateMismatchError))
        }
        cleanUp()
    }
    
    func viewController(viewController: UIViewController?, didCompleteLoginWithAccessToken accessToken: AKFAccessToken?, state: String?) {
        if state == self.state {
            loginCompletion?(AccountKitHandler.AccountKitHandlerResponseState.Success(accessToken: accessToken, authorizationCode: nil))
        } else {
            loginCompletion?(AccountKitHandler.AccountKitHandlerResponseState.Failure(description: Constants.stateMismatchError))
        }
        cleanUp()
    }
    
    func viewController(viewController: UIViewController?, didFailWithError error: NSError?) {
        loginCompletion?(AccountKitHandler.AccountKitHandlerResponseState.Failure(description: error?.localizedDescription))
        cleanUp()
    }
    
    func viewControllerDidCancel(viewController: UIViewController?) {
        loginCompletion?(AccountKitHandler.AccountKitHandlerResponseState.Cancellation)
        cleanUp()
    }
    
}

extension Utility {
    
    private struct Constants {
        static let stateMismatchError = "Use only one log in method at a time."
    }
    
    enum AccountKitHandlerResponseState {
        case Success(accessToken: AKFAccessToken?, authorizationCode: String?)
        case Failure(description: String?)
        case Cancellation
    }
    
    private func generateState() -> String {
        var state = NSUUID().UUIDString
        if let indexOfDash = state.rangeOfString("-")?.startIndex {
            state = state.substringToIndex(indexOfDash)
        }
        return state
    }
    
    private func cleanUp() {
        loginCompletion = nil
        resumeViewController = nil
    }
    
}