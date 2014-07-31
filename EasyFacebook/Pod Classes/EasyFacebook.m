//
//  EasyFacebook.h
//
//  Version 0.1.0
//
//  Created by Baris Sencan on 27/05/2014.
//  Copyright 2014 Baris Sencan
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/isair/EasyFacebook
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import <FacebookSDK/FacebookSDK.h>
#import <FXKeychain/FXKeychain.h>
#import "EasyFacebook.h"

@import Social;
@import Accounts;

@implementation EasyFacebook {
    ACAccountStore *_accountStore;
    ACAccountType *_FBAccountType;
    ACAccount *_account;
}

+ (EasyFacebook *)sharedInstance {
    static EasyFacebook *instance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        instance = [[EasyFacebook alloc] init];
    });

    return instance;
}

- (void)openSession:(void(^)(NSString *))successCallback error:(void(^)(NSError *))errorCallback {

    // Check if we already have a Facebook account at hand.
    if (_account) {

        if (successCallback) {
            successCallback([[_account credential] oauthToken]);
        }

        return;
    }

    // If not, request access to one.
    _accountStore = [[ACAccountStore alloc] init];
    _FBAccountType = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];

    [_accountStore
     requestAccessToAccountsWithType:_FBAccountType
     options:@{ACFacebookAppIdKey: _facebookAppID,
               ACFacebookPermissionsKey: _facebookReadPermissions,
               ACFacebookAudienceKey: ACFacebookAudienceEveryone}
     completion:^(BOOL granted, NSError *error) {

         if (error) {

             // If there are no accounts or the user denied permission, fall back to Facebook SDK.
             // Else, pass the error to the error callback.
             if (error.code == 6 || error.code == 7) {

                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self openSessionWithFacebookSDK:successCallback error:errorCallback];
                 });
             } else if (errorCallback) {

                 dispatch_async(dispatch_get_main_queue(), ^{
                     errorCallback(error);
                 });
             }

             return;
         }

         if (granted) { // Log in using the Facebook account.
             // Get the Facebook account.
             NSArray *accounts = [_accountStore accountsWithAccountType:_FBAccountType];
             _account = [accounts lastObject];

             // Renew account credentials to ensure that we get an up-to-date token.
             [_accountStore
              renewCredentialsForAccount:_account
              completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {

                  switch (renewResult) {
                      case ACAccountCredentialRenewResultRenewed: {
                          NSString *token = [[_account credential] oauthToken];

                          if (token) {

                              if (successCallback) {

                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      successCallback(token);
                                  });
                              }
                          } else {

                              if (errorCallback) {
                                  
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      // TODO: Custom error.
                                      errorCallback([[NSError alloc] init]);
                                  });
                              }
                          }
                          break;
                      }

                      case ACAccountCredentialRenewResultFailed:
                      case ACAccountCredentialRenewResultRejected:
                          // Fall back to Facebook SDK.
                          dispatch_async(dispatch_get_main_queue(), ^{
                              [self openSessionWithFacebookSDK:successCallback error:errorCallback];
                          });
                          break;
                  }
             }];
         } else { // Fall back to Facebook SDK.

             dispatch_async(dispatch_get_main_queue(), ^{
                 [self openSessionWithFacebookSDK:successCallback error:errorCallback];
             });
         }
     }];
}

- (void)requestPublishPermissions:(void(^)(NSString *))successCallback error:(void(^)(NSError *))errorCallback {

    // If we don't have a Facebook account at hand, try to get access to one first.
    if (!_account) {

        [self openSession:^(NSString *token) {

            if (_account) { // Try to get publish permissions using Social Framework.
                [self requestPublishPermissionsWithSocialFramework:successCallback error:errorCallback];
            } else { // Try to get publish permissions using Facebook SDK.

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self requestPublishPermissionsWithFacebookSDK:successCallback error:errorCallback];
                });
            }
        } error:^(NSError *error) {

            if (errorCallback) {

                dispatch_async(dispatch_get_main_queue(), ^{
                    errorCallback(error);
                });
            }
        }];

        return;
    }

    // Try to get publish permissions for the account.
    [self requestPublishPermissionsWithSocialFramework:successCallback error:errorCallback];
}

- (void)closeSession {

    if (_account) {
        _account = nil;
        _FBAccountType = nil;
        _accountStore = nil;
    }

    if (FBSession.activeSession) {
        [FBSession.activeSession closeAndClearTokenInformation];
        [[FXKeychain defaultKeychain] removeObjectForKey:@"BSFacebookToken"];
    }
}

#pragma mark - Private methods

- (void)openSessionWithFacebookSDK:(void (^)(NSString *))successCallback error:(void (^)(NSError *))errorCallback {
    // Get current Facebook session state.
    FBSessionState currentState = FBSession.activeSession.state;

    // Check if there is already an open session.
    if (currentState == FBSessionStateOpen || currentState == FBSessionStateOpenTokenExtended) {

        if (successCallback) {

            dispatch_async(dispatch_get_main_queue(), ^{
                successCallback(FBSession.activeSession.accessTokenData.accessToken);
            });
        }

        return;
    }

    // If not, try to open one.
    FBSession *session = [[FBSession alloc] initWithAppID:_facebookAppID
                                              permissions:_facebookReadPermissions
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:nil];

    [FBSession setActiveSession:session];

    // Check if there is a cached token.
    NSDictionary *tokenDataDictionary = [FXKeychain defaultKeychain][@"BSFacebookToken"];

    if (tokenDataDictionary) {
        NSDate *expirationDate = [tokenDataDictionary objectForKey:FBTokenInformationExpirationDateKey];

        // Check if the cached token is expired.
        if ([expirationDate timeIntervalSinceNow] > 0) {
            __block BOOL executedBlock = NO;

            // Restore session from cached token.
            [session openFromAccessTokenData:[FBAccessTokenData createTokenFromDictionary:tokenDataDictionary] completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                // Check if the completion handler has already been called.
                if (executedBlock) {

                    return;
                } else {
                    executedBlock = YES;
                }

                [self openSessionWithFacebookSDKSubroutine:session FBStatus:status FBError:error success:successCallback error:errorCallback];
            }];

            return;
        }
    }

    // Open a new session.
    __block BOOL executedBlock = NO;

    [session
     openWithCompletionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
         // Check if the completion handler has already been called.
         if (executedBlock) {

             return;
         } else {
             executedBlock = YES;
         }

         [self openSessionWithFacebookSDKSubroutine:session FBStatus:status FBError:error success:successCallback error:errorCallback];
     }];
}

- (void)openSessionWithFacebookSDKSubroutine:(FBSession *)session FBStatus:(FBSessionState)status FBError:(NSError *)error success:(void(^)(NSString *))successCallback error:(void(^)(NSError *))errorCallback {

    // Check if there were any errros.
    if (error) {

        if (errorCallback) {

            dispatch_async(dispatch_get_main_queue(), ^{
                errorCallback(error);
            });
        }

        return;
    }

    // Try to retrieve Facebook access token.
    NSString *token = session.accessTokenData.accessToken;

    if (token) {
        [FXKeychain defaultKeychain][@"BSFacebookToken"] = [session.accessTokenData dictionary];

        if (successCallback) {

            dispatch_async(dispatch_get_main_queue(), ^{
                successCallback(token);
            });
        }
    } else {

        if (errorCallback) {

            dispatch_async(dispatch_get_main_queue(), ^{
                // TODO: Custom error.
                errorCallback([[NSError alloc] init]);
            });
        }
    }
}

- (void)requestPublishPermissionsWithSocialFramework:(void(^)(NSString *token))successCallback error:(void(^)(NSError *))errorCallback {

    // Request access to account with publish permissions.
    [_accountStore
     requestAccessToAccountsWithType:_FBAccountType
     options:@{ACFacebookAppIdKey: _facebookAppID,
               ACFacebookPermissionsKey: _facebookPublishPermissions,
               ACFacebookAudienceKey: ACFacebookAudienceEveryone}
     completion:^(BOOL granted, NSError *error) {

         if (error) {

             if (errorCallback) {

                 dispatch_async(dispatch_get_main_queue(), ^{
                     errorCallback(error);
                 });
             }

             return;
         }

         if (granted) {
             // Get the new account object.
             NSArray *accounts = [_accountStore accountsWithAccountType:_FBAccountType];
             _account = [accounts lastObject];

             // Fetch Facebook token.
             NSString *token = [[_account credential] oauthToken];

             if (successCallback) {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     successCallback(token);
                 });
             }
         } else {

             if (errorCallback) {

                 dispatch_async(dispatch_get_main_queue(), ^{
                     // TODO: Custom error.
                     errorCallback([[NSError alloc] init]);
                 });
             }
         }

     }];
}

- (void)requestPublishPermissionsWithFacebookSDK:(void(^)(NSString *))successCallback error:(void(^)(NSError *))errorCallback {
    // Get current Facebook session state.
    FBSessionState currentState = [FBSession activeSession].state;

    if (currentState == FBSessionStateOpen || currentState == FBSessionStateOpenTokenExtended) {
        // Get access token data.
        FBAccessTokenData *accessTokenData = [FBSession activeSession].accessTokenData;

        // Check if our current access token already has required permissions (denied or not).
        NSArray *askedPermissions = [accessTokenData.permissions arrayByAddingObjectsFromArray:accessTokenData.declinedPermissions];
        BOOL unaskedPermissionsExist = NO;

        for (NSString *permission in _facebookPublishPermissions) {

            if ([askedPermissions indexOfObject:permission] == NSNotFound) {
                unaskedPermissionsExist = YES;
                break;
            }
        }

        // If there are no unasked permissions, call success callback and return.
        if (!unaskedPermissionsExist) {

            if (successCallback) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    successCallback(accessTokenData.accessToken);
                });
            }

            return;
        }

        // If not, request publish permissions.
        [[FBSession activeSession]
         requestNewPublishPermissions:_facebookPublishPermissions
         defaultAudience:FBSessionDefaultAudienceEveryone
         completionHandler:^(FBSession *session, NSError *error) {

             if (error) {

                 if (errorCallback) {

                     dispatch_async(dispatch_get_main_queue(), ^{
                         errorCallback(error);
                     });
                 }

                 return;
             }

             // Get Facebook token.
             NSString *token = session.accessTokenData.accessToken;

             if (token) {
                 [FXKeychain defaultKeychain][@"BSFacebookToken"] = [session.accessTokenData dictionary];

                 if (successCallback) {

                     dispatch_async(dispatch_get_main_queue(), ^{
                         successCallback(token);
                     });
                 }
             } else {

                 if (errorCallback) {

                     dispatch_async(dispatch_get_main_queue(), ^{
                         // TODO: Custom error.
                         errorCallback([[NSError alloc] init]);
                     });
                 }
             }
         }];
    } else {

        if (errorCallback) {

            dispatch_async(dispatch_get_main_queue(), ^{
                // TODO: Custom error.
                errorCallback([[NSError alloc] init]);
            });
        }
    }
}

@end
