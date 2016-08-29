# attest
A POC on Facebook Account Kit written in Swift 2.2.1.

### Facebook Account Kit

Using Account Kit is an easy and secure way of moving away from passwords for authentication.

Account Kit helps people quickly and easily register and log into the app using their phone number or email address as a passwordless credential. Account Kit is powered by Facebook's email and SMS sending infrastructure for reliable scalable performance with global reach. Using email and phone number authentication doesn't require a Facebook account, and is the ideal alternative to a social login.

### POC
This App contains a basic log in and log out flow. The users can log in using either their email address or phone number.

1. If the user picks and enters their email addresses, Facebook will send an email to the address with an authorization link. Clicking on this link will automatically log the user in to the app.
2. If the user picks and enteres their mobile numbers, Facebook will send an SMS with an OTP to the user's number. Entering this OTP in the following screen will log the user in.

If `enableSendToFacebook` option is enabled, Facebook sends a push notification to the user's Facebook App if the mobile number is connected to Facebook. Interacting with this notification will authorize the log in.

This app also takes care of the situation where in an authorization flow is triggered and the user quits the app. During the next launch, If log in was due from previous session, the same screen is opened and the user can continue logging in from the previous state.

###Wrapper on Account Kit

This wrapper class is called `AccountKitHandler`

####Features
1. Provides property to check log in state.
2. Provides method to check response state
3. Translates delegate pattern to block pattern for cleaner and readable code.
4. Exposes all the relevant methods from the Account Kit.
5. Checks the state of delegate callbacks and prevents false completion block callbacks if multiple log-ins are triggered.
6. Provides the success, error or cancelled states in a clean enum type with required parameters passed along with each.
7. Designed to be a short-lived class, where it's in memory only for as long as the authentication flow is required.


###Note
1. `isUserLoggedIn` is an optional boolean. This wrapper can determine the log-in state only if the authorization was done using access tokens. If authorization code was used, only the app's backend infrastructure can determine the state of log in. Hence, this property is an optional boolean.