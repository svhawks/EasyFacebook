//
//  EasyFacebook.h
//  Baris Sencan
//
//  Created by Baris Sencan on 27/05/14.
//  Copyright (c) 2014 Baris Sencan. All rights reserved.
//

@import Foundation;

@interface EasyFacebook : NSObject

@property (copy, nonatomic) NSString *facebookAppID;
@property (copy, nonatomic) NSArray *facebookReadPermissions;
@property (copy, nonatomic) NSArray *facebookPublishPermissions;

+ (instancetype)sharedInstance;

- (void)openSession:(void(^)(NSString *))successCallback error:(void(^)(NSError *))errorCallback;

- (void)requestPublishPermissions:(void(^)(NSString *))successCallback error:(void(^)(NSError *))errorCallback;

- (void)closeSession;

@end
