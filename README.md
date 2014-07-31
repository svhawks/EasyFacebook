_Example project coming soon._

Purpose
--------------

EasyFacebook is aimed for iOS developers who do most of the Facebook related stuff on their servers and only really need to get the Facebook token of a user in their apps. This pod gives these developers the ability to do everything they may need with just 3 simple methods, and saves them from any headaches they may normally have from tasks like having to juggle between Social Framework and Facebook's iOS SDK, dealing with persistence, etc. It also does some really cool stuff such as knowing what permissions it previously asked for from the user, and if your new permission request doesn't introduce anything that hasn't been asked for before, it just gives you the saved token (which is, of course, checked for validity).


__Requires iOS 7 or later.__


Installation
--------------

Either simply copy the files _EasyFacebook.h_ and _EasyFacebook.m_ under _EasyFacebook/Pod Classes_ into your Xcode project or add via [CocoaPods](http://cocoapods.org) by adding this line to your Podfile:

```ruby
pod 'EasyFacebook', '~>0.1.1'
```

Configuration
--------------

You need to set your Facebook's App ID and also the read and publish permissions you require before using any EasyFacebook methods.

```objective-c
#import <EasyFacebook.h>

...

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // EasyFacebook configuration.
    [EasyFacebook sharedInstance].facebookAppID = @"YOUR_FACEBOOK_APP_ID";
    [EasyFacebook sharedInstance].facebookReadPermissions = @[@"email"];
    [EasyFacebook sharedInstance].facebookPublishPermissions = @[@"publish_actions"];

    ...
```

Usage
--------------

Writing a login method using EasyFacebook is easy.

```objective-c
- (IBAction)facebookLoginButtonTapped {

    [[EasyFacebook sharedInstance] openSession:^(NSString *token) {
        // Facebook login succeeded and we now have a valid facebook token string.
        // Send it to your servers for authentication, and then move to the next screen in the app.
    } error:^(NSError *error) {
        // Login failed, let the user know.
    }];
}
```

If you are, for example, going to call an API end-point on your server that is going to publish something on Facebook on behalf of your user, you might want to make sure your server has a token with publish permissions first.

```objective-c
- (void)postFacebookStatus:(NSString *)status {
    
    [[EasyFacebook sharedInstance] requestPublishPermissions:^(NSString *token) {
        // If we got to this line, then we have a valid token with both our read and publish permissions. This is guaranteed.
        // Send the new token to the server, so it updates the Facebook token associated with your user.
        // After the new token is sent successfully, call the end-point that you originally wanted to.
    } error:^(NSError *)error {
        // An error occured, handle it.
    }];
}
```

When your user logs out from your app you should clear any data EasyFacebook holds if you don't want the Facebook data to persist between app sessions.

```objective-c
- (IBAction)logoutButtonTapped {
    // Close EasyFacebook session.
    [[EasyFacebook sharedInstance] closeSession];

    // Clear any persistent data you stored about the currently logged in user.
}
```
