//
//  AvAdsBannerView.h
//  SesliGazete
//
//  Created by Tolga MacBook Pro on 11/12/13.
//  Copyright (c) 2013 MeeApps Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AVAdsBannerDelegate<NSObject>

/** Delegate method for informing activation(showing) of a banner is succeeded.
 
 Activation of a Banner is succesfull in cases.
 
 - There is no problem in network connections
 - Publisher id and inventory id/ids that you provided is valid
 
 @param inventoryID show which banner activation succeeded.
 */
-(void) activateBannerDidSucceed:(NSString*)inventoryID;


/** Delegate method for informing activation(showing) of a banner is failed.
 
 Activation of a Banner is failed in cases:
 
 - There is a possible problem in network connections
 - Publisher id and inventory id/ids that you provided is not valid
 
 @param inventoryID show which banner activation succeeded.
 */
-(void) activateBannerDidFailed:(NSString*)inventoryID;


/** Delegate method for informing deactivation(stopping) of a banner is succeeded.
 
 DeActivation of a Banner is succesfull in cases.
 
 - There is no problem in network connections
 - Publisher id and inventory id/ids that you provided is valid
 
 @param inventoryID show which banner activation succeeded.
 */
-(void) deActivateBannerDidSucceed:(NSString*)inventoryID;

/** Delegate method for informing deactivation(stopping) of a banner is failed.
 
 DeActivation of a Banner is failed in cases.
 
 - There is a possible problem in network connections
 - Publisher id and inventory id/ids that you provided is not valid
 
 @param inventoryID show which banner activation succeeded.
 */
-(void) deActivateBannerDidFailed:(NSString*)inventoryID;
@end

@interface AvAdsBanner : NSObject

/**---------------------------------------------------------------------------------------
 * @name AVADSBanner METHODS
 *  ---------------------------------------------------------------------------------------
 */


/** Creates shared instance(singleton) of Avea Ads Banner FrameWork.
 
 You have to get the shared Instance by providing publisherID.
 
 - You can get publisher ID From Avea Adds Platform
 - You can only set publisherID while you are creating shared Instance
 - Its a private information and please do not share it with anyone
 - Location information(if permitted by user) and your application's bundle id will be detected by Avea ADDS SDK automaticly.You dont need to give any other information
 
 @param publisherID PublisherID string is mandatory and will be provided to you with framework.
 @return shared instance of AvAdsBanner Class(Only interface of Avea Ads Framework).
 */
+ (AvAdsBanner*) sharedInstance:(NSString*) publisherID;



/** Gets Banner View By providing related inventoryID.
 
 You have to use different inventoryIDs for getting more than one advertisment
 
 - InventoryID is provided to you by Avea Ads Platform
 - If you want to use more than 1 advertisment within your application , please ask for more inventoryID from Avea Ads Platform
 
 @param inventoryID inventoryID string is unique to each banner you want to show within your application.
 @return UIView represantation of selected advertisment.
 */
-(UIView*) getAVAdsBannerView:(NSString*)inventoryID;

/** Activate and Shows The Advirtisment  By providing related inventoryID.
 
 You have to use different inventoryIDs for activating different advertisments
 
 - InventoryID is provided to you by Avea Ads Platform
 - If you want to use more than 1 advertisment within your application , please ask for more inventoryID from Avea Ads Platform
 
 @param inventoryID inventoryID string is unique to each banner you want to show within your application.
 */
-(void) activateAVAdsBanner:(NSString*)inventoryID;


/** DeActivate and Hides The Advirtisment  By providing related inventoryID.
 
 You have to use different inventoryIDs for deactivating different advertisments.
 If you closed the advertisment banner by clicking the X in the top right corner.You don't need to call this method
 
 - InventoryID is provided to you by Avea Ads Platform
 - If you want to use more than 1 advertisment within your application , please ask for more inventoryID from Avea Ads Platform
 
 @param inventoryID inventoryID string is unique to each banner you want to show within your application.
 */
-(void) deActivateAVAdsBanner:(NSString*)inventoryID;


/** Delegate object for AvADSBanner operations.
 
 */
@property (nonatomic, assign) id<AVAdsBannerDelegate> delegate;


/** A unique identifier for specific user.
 
 If you are defining each or some of your customers with a unique id such as
 
 - Mobile Phone Number
 - Username
 - Email Address
 
 you can provide that information with blindID parameter for getting targeted advertisments
 
 */
@property (nonatomic, copy) NSString *blindID;


/** Contextual information for providing targeted advertisments.
 
 If you want to show specific kind of advertisments you can provide keyword with such strings :
 
 - Spor
 - Teknoloji
 - Borsa
 
 list of strings that you can use as keyword will be provided to you by Avea ADS Platform.
 If you want to use more than one string as a keyWord, you should create your string with , delimeter like
 NSString *keywords = @"Spor,Borsa,Teknoloji";
 
 */
@property (nonatomic,copy) NSString *keyWord;


@end
