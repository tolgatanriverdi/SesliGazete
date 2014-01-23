//
//  MAPSDK.h
//  MAPSDK
//
//  Created by Tolga Tanriverdi on 19/12/13.
//  Copyright (c) 2013 MeeAppsMobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum
{
    MAPERROR_NOCONNECTION=0,
    MAPERROR_REQUEST_FAILED=1,
    MAPERROR_INFORM_PROVIDER = 2,
    MAPERROR_INVALID_INFORMATION = 3,
    MAPERROR_NORELATED_MEDIA = 4,
    MAPERROR_SECUREKEY = 5,
    MAPERROR_MISSING_CONFIGURATION = 6,
    MAPERROR_NOTDEFINED=7
}MAPErrorCodes;


typedef enum
{
    MAPBANNERHEIGHT_DEFAULT=0,
    MAPBANNERHEIGHT_FULL_SCREEN=1
}MAPBannerHeight;

@protocol MAPSDKDelegate <NSObject>

@optional
-(void) activateBannerDidSucceed:(NSString*)inventoryName;
-(void) activateBannerDidFailed:(NSString*)inventoryName withError:(MAPErrorCodes)errorCode;

@end

@interface MAPSDK : NSObject


+(MAPSDK*) sharedInstance:(NSString*)secureKey;

-(UIView*) getMAPSDKBanner:(NSString*)inventoryName andKeyword:(NSString*)keyword withBannerHeight:(MAPBannerHeight)height;
-(void) closeMAPSDKBanner:(NSString*)inventoryName;

-(void) addDelegate:(id<MAPSDKDelegate>)delegate;
-(void) removeDelegate:(id<MAPSDKDelegate>)delegate;


@property (nonatomic,copy) NSString* msisdn;
@property (nonatomic,assign) UIViewController *parentViewController;

@end
