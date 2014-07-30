_Example project coming soon._

Purpose
--------------

FacebookHelper is aimed for iOS developers who do most of the Facebook related stuff on their servers and only really need to get the Facebook token of a user in their apps. This pod gives these developers the ability to do everything they may need with just 3 simple methods, and saves them any headache they may normally face such as having to juggle between Social Framework and Facebook's iOS SDK, dealing with persistence, etc. It also does really cool stuff such as knowing what permissions it previously asked for from the user, and if your new permission request doesn't introduce anything that hasn't been asked for before, it just gives you the saved token (which is, of course, checked for validity).


__Requires iOS 7 or later.__


Installation
--------------

Either simply copy the files _EasyFacebook.h_ and _EasyFacebook.m_ under _EasyFacebook/Pod Classes_ into your Xcode project or add via [CocoaPods](http://cocoapods.org) by adding this line to your Podfile:

```ruby
pod 'EasyFacebook', '~>0.1.0'
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

Coming soon.
