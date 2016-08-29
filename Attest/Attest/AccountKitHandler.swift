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

///A closure that will be triggered at the response of any Account Kit activity.
typealias AccountKitHandlerCompletion = (AccountKitHandler.AccountKitHandlerResponseState) -> ()

///A wrapper written on `AKFAccountKit`. This class translates the delegate patterns used by `AKFAccountKit` into closure callbacks with an `enum` parameter being passed to indicate the state of the response. This makes the usage cleaner and more readable.
class AccountKitHandler: NSObject {
    
    ///The `AKFAccountKit` property that can be accessed if required.
    var accountKit: AKFAccountKit
    
    ///This property gives the `AKFResponseType` using which this class was instantiated.
    var responseType: AKFResponseType
    
    ///This property just passes the `currentAccessToken` from the class's `accountKit` object.
    var currentAccessToken: AKFAccessToken? {
        return accountKit.currentAccessToken
    }
    
    ///This property gives the last obtained authorizationCode.
    var currentAuthorizationCode: String?
    
    ///Specifies if the app supports sending codes to Facebook (as an SMS alternative)
    var enableSendToFacebook = true
    
    ///An optional boolean to determine if the user is logged in. This property will have a value if the account was logged in using access token. Else, it will be a `nil`. If the user was logged in with access token, the boolean value will give away the state of the log in.
    var isUserLoggedIn: Bool? {
        return (responseType == .AccessToken) ? (currentAccessToken != nil ? true : false) : (nil)
    }
    
    ///This will hold the view controller from the previous session whose flow was not completed.
    weak var resumeViewController: UIViewController?
    
    //This property holds the last completion block for every log in call being made. This is cleaned up in the `cleanUp()` method.
    private var loginCompletion: AccountKitHandlerCompletion?
    
    //This property will hold the latest state string for every log in call being made.
    private var state = ""
    
    
    //MARK: - Initializer
    
    ///The only initializer for this class.
    /// - parameter responseType: An `AKFResponseType` `enum` to be passed to specify the kind of log in to be done.
    init(responseType: AKFResponseType) {
        self.responseType = responseType
        accountKit = AKFAccountKit(responseType: responseType)
        super.init()
    }
    
    ///This method will pass the view controller from the previous session whose flow was not completed. It will also store this in `resumeViewController` property.
    func viewControllerForLoginResume() -> UIViewController? {
        resumeViewController = accountKit.viewControllerForLoginResume()
        return resumeViewController
    }
    
    ///This method will present the log in VC which accepts email as the unique identifier.
    /// - parameter email: An optional `String` value that will be pre-filled in the email field.
    /// - parameter viewController: The `UIViewController` instance from which the log in VC needs to be presented.
    /// - parameter completion: This block will get executed when the a response is obtained from `accountKit`
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
    
    ///This method will present the log in VC which accepts phone number as the unique identifier.
    /// - parameter phoneNumber: An optional `String` value that will be pre-filled in the phone number field.
    /// - parameter viewController: The `UIViewController` instance from which the log in VC needs to be presented.
    /// - parameter completion: This block will get executed when the a response is obtained from `accountKit`
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
    
    ///This method will resume the log-in flow from any previously terminated log-in flow.
    /// - parameter viewController: The `UIViewController` instance from which the log in VC needs to be presented.
    /// - parameter completion: This block will get executed when the a response is obtained from `accountKit`
    func resumePreviousLogIn(viewController: UIViewController?, completion: AccountKitHandlerCompletion?) {
        loginCompletion = completion
        if let resumeViewController = resumeViewController as? AKFViewController {
            resumeViewController.delegate = self
            if let resumeViewController = resumeViewController as? UIViewController {
                viewController?.presentViewController(resumeViewController, animated: true, completion: nil)
            }
        }
    }
    
    ///This method will log the user out and clean up any data.
    func logOut() {
        cleanUp()
        accountKit.logOut()
    }
    
}

extension AccountKitDelegate: AKFViewControllerDelegate {
    
    func viewController(viewController: UIViewController?, didCompleteLoginWithAuthorizationCode code: String?, state: String?) {
        if state == self.state {
            loginCompletion?(AccountKitHandler.AccountKitHandlerResponseState.Success(accessToken: nil, authorizationCode: code))
            if let code = code {
                currentAuthorizationCode = code
            }
        } else {
            loginCompletion?(AccountKitHandler.AccountKitHandlerResponseState.Failure(description: Constants.stateMismatchError))
        }
        cleanUp()
        currentAuthorizationCode = code
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
        currentAuthorizationCode = nil
        loginCompletion = nil
        resumeViewController = nil
    }
    
}