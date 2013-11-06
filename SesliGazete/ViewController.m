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
#include "MBProgressHUD.h"
#include "JSONKit.h"


#define GUNCEL_HABER_PAGE @"http://www.hurriyet.com.tr/gundem/25021285.asp"
#define EKONOMI_HABER_PAGE @"http://www.hurriyet.com.tr/ekonomi/25026764.asp"
#define SPOR_HABER_PAGE @"http://www.hurriyet.com.tr/spor/futbol/25022206.asp"

#define GUNCEL_SES_FILE @"guncel_hurriyet.txt"
#define SPOR_SES_FILE @"spor_hurriyet.txt"
#define EKONOMI_SES_FILE @"ekonomi_hurriyet.txt"

#define ACAPELA_ENABLED 0


@interface ViewController ()<NSURLConnectionDelegate,UIWebViewDelegate>
@property (nonatomic,strong) AVAudioRecorder *recorder;
@property (nonatomic,strong) NSTimer *recordTimer;
@property (nonatomic,strong) NSString *pathToSave;
@property (nonatomic,strong) NSString *outputPath;
@property (nonatomic) int networkStatus;
@property (nonatomic,strong) NSString *pageToRead;
@property (nonatomic,strong) MBProgressHUD *hud;
@property (nonatomic,strong) AVSpeechSynthesisVoice *appleTTS;
@property (nonatomic,strong) AVSpeechUtterance *utterance;
@property (nonatomic,strong) AVSpeechSynthesizer *synthesizer;
@property (nonatomic,strong) NSDictionary *phoneticDictionary;

@property (nonatomic,strong) AcapelaLicense *MyAcaLicense;
@property (nonatomic,strong) AcapelaSpeech *MyAcaTTS;
@property (nonatomic,strong) AcapelaSetup  *SetupData;
@end

@implementation ViewController
@synthesize pdfViewer;
@synthesize recorder;
@synthesize recordTimer;
@synthesize pathToSave;
@synthesize outputPath;
@synthesize networkStatus;
@synthesize pageToRead;
@synthesize hud;
@synthesize appleTTS;
@synthesize utterance;
@synthesize synthesizer;
@synthesize phoneticDictionary;

@synthesize MyAcaLicense;
@synthesize MyAcaTTS;
@synthesize SetupData;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    NSURL *pdfURL = [NSURL URLWithString:GUNCEL_HABER_PAGE];
    NSURLRequest *pdfRequest = [NSURLRequest requestWithURL:pdfURL];
    pdfViewer.scalesPageToFit = YES;
    [pdfViewer loadRequest:pdfRequest];
    
    self.pageToRead = GUNCEL_SES_FILE;
    NSString *phoneticJSONPath = [[NSBundle mainBundle] pathForResource:@"phonetics" ofType:@"json"];
    NSString *phoneticsJSON = [NSString stringWithContentsOfFile:phoneticJSONPath encoding:NSUTF8StringEncoding error:NULL];
    
    //NSLog(@"devro: %@", emotionJSON);
    phoneticDictionary = (NSDictionary*)[phoneticsJSON objectFromJSONString];
    
    
    if (ACAPELA_ENABLED) {
        //TTS INITIALIZE
        
        // Create the default UserDico for the voice delivered in the bundle
        NSError * error;
        
        // Get the application Documents folder
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        // Creates heather folder if it doesn't exist already
        NSString * dirDicoPath = [documentsDirectory stringByAppendingString:[NSString stringWithFormat:@"/heather"]];
        [[NSFileManager defaultManager] createDirectoryAtPath:dirDicoPath withIntermediateDirectories: YES attributes:nil error: &error];
        
        //NSString * fullDicoPath = [documentsDirectory stringByAppendingString:[NSString stringWithFormat:@"/heather/default.userdico"]];
        
        NSString* aLicenseString = [[NSString alloc] initWithCString:babLicense encoding:NSASCIIStringEncoding];
        MyAcaLicense = [[AcapelaLicense alloc] initLicense:aLicenseString user:uid.userId passwd:uid.passwd];
        SetupData = [[AcapelaSetup alloc] initialize];
        MyAcaTTS = [[AcapelaSpeech alloc] initWithVoice:SetupData.CurrentVoice license:MyAcaLicense];
        
        [MyAcaTTS setDelegate:self];
        // Check the file doesn't already exists to avoid to erase its content
    } else {
        appleTTS = [AVSpeechSynthesisVoice voiceWithLanguage:@"tr-TR"];
        synthesizer = [[AVSpeechSynthesizer alloc] init];
    }

    
    


    
    
    [self prepareRecording];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)readPressed:(id)sender
{
    [self readWebRequest:self.pageToRead];
}

- (IBAction)listenPressed:(id)sender
{
    [self showHUD:@"Dinliyor"];
    if (ACAPELA_ENABLED) {
        [MyAcaTTS stopSpeaking];
    } else {
        [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
    self.listenButton.enabled = NO;
    [recorder record];
    self.recordTimer = [NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(stopRecording) userInfo:nil repeats:NO];
}

-(void) showHUD:(NSString*)hudText
{
    if (!hud) {
        hud = [[MBProgressHUD alloc] initWithView:self.view];
        hud.dimBackground = YES;
    }
    hud.labelText = hudText;
    [hud show:YES];
    [self.view addSubview:hud];
}

-(void) hideHUD
{
    if (hud) {
        [hud show:NO];
        [hud removeFromSuperview];
    }
}

-(void) stopRecording
{
    hud.labelText = @"Ses İnceleniyor";
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
        __block NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        if (phoneticDictionary) {
            [phoneticDictionary enumerateKeysAndObjectsUsingBlock:^(id key,id obj,BOOL *stop) {
                NSString *phoneticKey = (NSString* ) key;
                NSString *phoneticVal = (NSString* ) obj;
                result = [result stringByReplacingOccurrencesOfString:phoneticKey withString:phoneticVal];
            }];
        }
        
        if (ACAPELA_ENABLED) {
            [MyAcaTTS startSpeakingString:result];
        } else {
            utterance = [AVSpeechUtterance speechUtteranceWithString:result];
            utterance.voice = appleTTS;
            utterance.rate = 0.25;
            [synthesizer speakUtterance:utterance];
        }

        
        self.readButton.enabled = NO;
    } else if (networkStatus == 1) {
        
        self.listenButton.enabled = YES;
        [self deleteExistingFiles];
        [self hideHUD];
        
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
                    [self checkSpeechResult:resultText];
                }
            }

        }
    }

}

-(void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.listenButton.enabled = YES;
    if (networkStatus == 1) {
      [self hideHUD];
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


-(void) loadWebRequest:(NSString*)requestPage
{
    //NSString *requestStr = [NSString stringWithFormat:@"http://meeappsmobile.com/sesligazete/%@",requestPage];
    NSURL *pdfURL = [NSURL URLWithString:requestPage];
    NSURLRequest *pdfRequest = [NSURLRequest requestWithURL:pdfURL];
    pdfViewer.delegate = self;
    pdfViewer.scalesPageToFit = YES;
    [pdfViewer loadRequest:pdfRequest];
}


-(void) readWebRequest:(NSString*)requestPage
{
    networkStatus = 0;
    NSString *requestStr = [NSString stringWithFormat:@"http://meeappsmobile.com/sesligazete/%@",requestPage];
    NSURL *txtURL = [NSURL URLWithString:requestStr];
    NSURLRequest *txtRequest = [NSURLRequest requestWithURL:txtURL];
    
    
    NSURLConnection *txtConnection = [[NSURLConnection alloc] initWithRequest:txtRequest delegate:self];
    [txtConnection start];
}

-(void) checkSpeechResult:(NSString*)resultText
{
    
    if (ACAPELA_ENABLED) {
        [MyAcaTTS stopSpeaking];
    } else {
        [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
    
    if ([resultText rangeOfString:@"ekonomi"].length > 0) {
        //[self showHUD:@"Ekonomi Haberleri"];
        hud.labelText = @"Ekonomi Haberleri";
        self.pageToRead = EKONOMI_SES_FILE;
        [self loadWebRequest:EKONOMI_HABER_PAGE];
        [self readWebRequest:self.pageToRead];
    } else if ([resultText rangeOfString:@"spor"].length > 0) {
        //[self showHUD:@"Spor Haberleri"];
         hud.labelText = @"Spor Haberleri";
        self.pageToRead = SPOR_SES_FILE;
        [self loadWebRequest:SPOR_HABER_PAGE];
        [self readWebRequest:self.pageToRead];
    } else  if ([resultText rangeOfString:@"güncel"].length > 0) {
        //[self showHUD:@"Güncel Haberler"];
         hud.labelText = @"Ekonomi Haberleri";
        self.pageToRead = GUNCEL_SES_FILE;
        [self loadWebRequest:GUNCEL_HABER_PAGE];
        [self readWebRequest:self.pageToRead];
    }
}


-(void) webViewDidFinishLoad:(UIWebView *)webView
{
    [self hideHUD];

}

-(void) webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self hideHUD];        
}


-(void) speechSynthesizer:(AcapelaSpeech *)sender didFinishSpeaking:(BOOL)finishedSpeaking
{
    self.readButton.enabled = YES;
}

@end
