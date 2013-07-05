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

#include <AVFoundation/AVFoundation.h>
#include "wav_to_flac.h"


@interface ViewController ()<NSURLConnectionDelegate>
@property (nonatomic,strong) AcapelaLicense *MyAcaLicense;
@property (nonatomic,strong) AcapelaSpeech *MyAcaTTS;
@property (nonatomic,strong) AcapelaSetup  *SetupData;
@property (nonatomic,strong) AVAudioRecorder *recorder;
@property (nonatomic,strong) NSTimer *recordTimer;
@property (nonatomic,strong) NSString *pathToSave;
@property (nonatomic,strong) NSString *outputPath;
@property (nonatomic) int networkStatus;
@end

@implementation ViewController
@synthesize pdfViewer;
@synthesize MyAcaLicense;
@synthesize MyAcaTTS;
@synthesize SetupData;
@synthesize recorder;
@synthesize recordTimer;
@synthesize pathToSave;
@synthesize outputPath;
@synthesize networkStatus;

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
    
    
    [self prepareRecording];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)readPressed:(id)sender
{
    networkStatus = 0;
    NSURL *txtURL = [NSURL URLWithString:@"http://meeappsmobile.com/sesligazete/tts.txt"];
    NSURLRequest *txtRequest = [NSURLRequest requestWithURL:txtURL];

    
    NSURLConnection *txtConnection = [[NSURLConnection alloc] initWithRequest:txtRequest delegate:self];
    [txtConnection start];
}

- (IBAction)listenPressed:(id)sender
{
    [recorder record];
    self.recordTimer = [NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(stopRecording) userInfo:nil repeats:NO];
}

-(void) stopRecording
{
    NSLog(@"Stoping Record");
    [recorder stop];
    int interval_seconds = 0;
    char** flac_files = (char**) malloc(sizeof(char*) * 1024);
    int status = convertWavToFlac([pathToSave UTF8String], [outputPath UTF8String], interval_seconds, flac_files);
    NSLog(@"Status Of Conversion : %d",status);
    outputPath = [outputPath stringByAppendingString:@".flac"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath]) {
        NSLog(@"Dosya Yazildi: %@",outputPath);
        [self sendRecordToGoogleSpeech];
    }
}

-(void) deleteExistingFiles
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToSave]) {
        [[NSFileManager defaultManager] removeItemAtPath:pathToSave error:nil];
    }
    
    //NSString *outputWithExt = [NSString stringWithFormat:@"%@.flac",self.outputPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.outputPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.outputPath error:nil];
        self.outputPath = [self.outputPath stringByDeletingPathExtension];
        NSLog(@"Proccesed Output File: %@",self.outputPath);
    }
}

-(void) prepareRecording
{
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    
    [settings setValue: [NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [settings setValue: [NSNumber numberWithFloat:44000.0] forKey:AVSampleRateKey];
    [settings setValue: [NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
    [settings setValue:  [NSNumber numberWithInt: AVAudioQualityMax] forKey:AVEncoderAudioQualityKey];
    
    NSArray *searchPaths =NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath_ = [searchPaths objectAtIndex: 0];
    
    NSString *fileName = @"recognize.wav";
    NSString *outputFileName = @"recognize";
    self.pathToSave = [documentPath_ stringByAppendingPathComponent:fileName];
    self.outputPath = [documentPath_ stringByAppendingPathComponent:outputFileName];
    
    [self deleteExistingFiles];


    NSLog(@"Record Audio File To: %@ OutputPath: %@",pathToSave,outputPath);
    
    // File URL
    NSURL *url = [NSURL fileURLWithPath:pathToSave];//FILEPATH];
    
    
    // Create recorder
    recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:nil];
    
    [recorder prepareToRecord];
}


-(void) connection:(NSURLConnection*)connection didReceiveData:(NSData *)data
{
    if (networkStatus == 0) {
        NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        //NSLog(@"Result Of Connection IS: %@  Language: %@ Speaker: %@",result,SetupData.CurrentVoice,SetupData.CurrentVoiceName);
        [MyAcaTTS startSpeakingString:result];
    } else if (networkStatus == 1) {
        
        [self deleteExistingFiles];
        
        NSLog(@"Google Speech Response Geldi");
        NSDictionary * result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        NSLog(@"Result of Google Speech : %@",result);
        if (result) {
            int status = [[result objectForKey:@"status"] intValue];
            if (status == 0) {
                NSArray *hypotesis = [result objectForKey:@"hypotheses"];
                if ([hypotesis count]) {
                    NSDictionary *utteranceDict = [hypotesis objectAtIndex:0];
                    NSString *resultText = [utteranceDict objectForKey:@"utterance"];
                    NSLog(@"RESULT TEXT : %@",resultText);
                }
            }

        }
    }

}


-(void) sendRecordToGoogleSpeech
{
    networkStatus = 1;
    NSLog(@"Sending Record To Google Speech Api");
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[NSURL
                                                 URLWithString:@"https://www.google.com/speech-api/v1/recognize?xjerr=1&client=chromium&lang=tr-TR"]];
    
    
    NSData *myData = [NSData dataWithContentsOfFile:outputPath];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:myData];
    [request addValue:@"audio/x-flac; rate=44000" forHTTPHeaderField:@"Content-Type"];
    [request setTimeoutInterval:15];
    
    
    NSURLConnection *speechConnection = [NSURLConnection connectionWithRequest:request delegate:self];
    [speechConnection start];

}

@end
