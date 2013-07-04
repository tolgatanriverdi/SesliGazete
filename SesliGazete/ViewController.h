//
//  ViewController.h
//  SesliGazete
//
//  Created by Netas MacBook Pro on 7/1/13.
//  Copyright (c) 2013 MeeApps Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIWebView *pdfViewer;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *listenButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *readButton;

@end
