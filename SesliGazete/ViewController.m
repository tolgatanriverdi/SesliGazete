//
//  ViewController.m
//  SesliGazete
//
//  Created by Netas MacBook Pro on 7/1/13.
//  Copyright (c) 2013 MeeApps Inc. All rights reserved.
//

#import "ViewController.h"


#import "AcapelaSetup.h"
#import "AcapelaLicense.h"
#include "./License/evaluation.lic.h"
#include "./License/evaluation.lic.password"



@interface ViewController ()<NSURLConnectionDelegate>
@property (nonatomic,strong) AcapelaLicense *MyAcaLicense;
@property (nonatomic,strong) AcapelaSpeech *MyAcaTTS;
@property (nonatomic,strong) AcapelaSetup  *SetupData;
@end

@implementation ViewController
@synthesize pdfViewer;
@synthesize MyAcaLicense;
@synthesize MyAcaTTS;
@synthesize SetupData;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    
    NSURL *pdfURL = [NSURL URLWithString:@"http://meeappsmobile.com/sesligazete/tts.pdf"];
    NSURLRequest *pdfRequest = [NSURLRequest requestWithURL:pdfURL];
    [pdfViewer loadRequest:pdfRequest];
    
    
    
    //TTS INITIALIZE
	
	// Create the default UserDico for the voice delivered in the bundle
	NSError * error;
	
	// Get the application Documents folder
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	
	// Creates heather folder if it doesn't exist already
	NSString * dirDicoPath = [documentsDirectory stringByAppendingString:[NSString stringWithFormat:@"/heather"]];
	[[NSFileManager defaultManager] createDirectoryAtPath:dirDicoPath withIntermediateDirectories: YES attributes:nil error: &error];
	
	NSString * fullDicoPath = [documentsDirectory stringByAppendingString:[NSString stringWithFormat:@"/heather/default.userdico"]];
	// Check the file doesn't already exists to avoid to erase its content
	if (![[NSFileManager defaultManager] fileExistsAtPath: fullDicoPath]) {
		
		// Create the file
		if (![@"UserDico\n" writeToFile:fullDicoPath atomically:YES encoding:NSISOLatin1StringEncoding error:&error]) {
			NSLog(@"%@",error);
			return;
		}
	}
    
    
    NSString* aLicenseString = [[NSString alloc] initWithCString:babLicense
                                                        encoding:NSASCIIStringEncoding];
    MyAcaLicense = [[AcapelaLicense alloc] initLicense:aLicenseString user:uid.userId
                                                passwd:uid.passwd];
    SetupData = [[AcapelaSetup alloc] initialize];
    MyAcaTTS = [[AcapelaSpeech alloc] initWithVoice:SetupData.CurrentVoice
                                            license:MyAcaLicense];
    
    [MyAcaTTS setDelegate:self];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)readPressed:(id)sender
{
    NSURL *txtURL = [NSURL URLWithString:@"http://meeappsmobile.com/sesligazete/tts.txt"];
    NSURLRequest *txtRequest = [NSURLRequest requestWithURL:txtURL];

    
    NSURLConnection *txtConnection = [[NSURLConnection alloc] initWithRequest:txtRequest delegate:self];
    [txtConnection start];
}

- (IBAction)listenPressed:(id)sender
{
    
}


-(void) connection:(NSURLConnection*)connection didReceiveData:(NSData *)data
{
    NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Result Of Connection IS: %@  Language: %@ Speaker: %@",result,SetupData.CurrentVoice,SetupData.CurrentVoiceName);
    //[MyAcaTTS startSpeakingString:@"This is a simple hello demo for the TTS on the iPhone. Ok OK OK Ok OK OK OK"];
    [MyAcaTTS startSpeakingString:result];
}

@end
