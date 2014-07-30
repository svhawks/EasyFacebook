//
//  EasyFacebook.h
//
//  Version 0.9.0
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
