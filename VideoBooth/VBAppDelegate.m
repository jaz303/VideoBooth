//
//  VBAppDelegate.m
//  VideoBooth
//
//  Created by Jason Frame on 28/12/2011.
//

#import "VBAppDelegate.h"

static NSString *kAudioDeviceLocalizedName  = @"VF0700 Live! Cam Chat HD";
static NSString *kVideoDeviceLocalizedName  = @"VF0700 Live! Cam Chat HD";
static NSString *kTargetFolder              = @"~/Captures";
static CGFloat kMaxVideoWidth               = 640;
static CGFloat kMaxVideoHeight              = 480;
static NSString *kSerialPort                = @"/dev/cu.usbserial-A9007UOD";
static CGFloat recordTime                   = 15.0f;
static NSString *message                    = @"Press the Green Button to record a %d second message";

@interface VBAppDelegate ()
- (NSString *)uniqeFilenameWithExtension:(NSString *)ext;
- (void)disableButtons;
- (void)enableButtons;
@end

@implementation VBAppDelegate

@synthesize window = _window;

- (void)awakeFromNib
{
    busy_ = NO;
    captureSession_ = nil;
    videoCaptureDevice_ = nil;
    audioCaptureDevice_ = nil;
    nextIndex_ = 0;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSDictionary *fsOpts = [NSDictionary
                            dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:NSApplicationPresentationDefault |
                                                          NSApplicationPresentationHideDock |
                                                          NSApplicationPresentationHideMenuBar |
                                                          NSApplicationPresentationDisableAppleMenu],
                            NSFullScreenModeApplicationPresentationOptions, nil];
    
    //
    // Serial ports
    
    NSArray *ports = [[AMSerialPortList sharedPortList] serialPorts];
    for (AMSerialPort *p in ports) {
        if ([kSerialPort isEqualToString:[p bsdPath]]) {
            serialPort_ = [p retain];
            [serialPort_ open];
            [serialPort_ setDataBits:8];
            [serialPort_ setSpeed:9600];
            [serialPort_ setLocalMode:YES];
            [serialPort_ setParity:kAMSerialParityNone];
            [serialPort_ setCanonicalMode:NO];
            
            [serialPort_ setDelegate:self];
            
            [serialPort_ clearError];
            if (![serialPort_ commitChanges]) {
                NSLog(@"Serial config error: %d", [serialPort_ errorCode]);
            } else {
                NSLog(@"Serial port configured");
                [serialPort_ readDataInBackground];
                [self enableButtons];
            }
        }
    }
    
    for (QTCaptureDevice *device in [QTCaptureDevice inputDevices]) {
        if (!videoCaptureDevice_) {
            if ([device.localizedDisplayName isEqualToString:kVideoDeviceLocalizedName] && [device hasMediaType:QTMediaTypeVideo]) {
                NSLog(@"Found video capture device!");
                videoCaptureDevice_ = [device retain];
            }
        }
        if (!audioCaptureDevice_) {
            if ([device.localizedDisplayName isEqualToString:kAudioDeviceLocalizedName] && [device hasMediaType:QTMediaTypeSound]) {
                NSLog(@"Found audio capture device!");
                audioCaptureDevice_ = [device retain];
            }            
        }
    }
    
    if (!(videoCaptureDevice_ && audioCaptureDevice_)) {
        NSLog(@"Error: couldn't find audio and/or video capture devices");
        [[NSApplication sharedApplication] terminate:nil];
    }
    
    NSError *error = nil;
    
    [videoCaptureDevice_ open:&error];
    if (error) {
        [self.window presentError:error];
    }
    
    [audioCaptureDevice_ open:&error];
    if (error) {
        [self.window presentError:error];
    }
    
    //
    // Date formatter
    
    dateFormatter_ = [[NSDateFormatter alloc] init];
    [dateFormatter_ setDateFormat:@"yyyyMMddHHmmss"];
    
    //
    //
    
    [label_ setTitle:[NSString stringWithFormat:message, (int)recordTime]];
    
    //
    //
    
    [[self.window contentView] enterFullScreenMode:[NSScreen mainScreen] withOptions:fsOpts];
    
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    
    [self stop:nil];
    
    [serialPort_ close];
    [videoCaptureDevice_ close];
    [audioCaptureDevice_ close];
}

- (IBAction)takePhoto:(id)sender {
    
}

- (IBAction)recordVideo:(id)sender {
    
    if (busy_) return;
    
    busy_ = YES;
    [self disableButtons];
    
    captureSession_ = [[QTCaptureSession alloc] init];
    
    // Inputs
    
    QTCaptureDeviceInput *audioInput = [[QTCaptureDeviceInput alloc] initWithDevice:audioCaptureDevice_];
    QTCaptureDeviceInput *videoInput = [[QTCaptureDeviceInput alloc] initWithDevice:videoCaptureDevice_];
    
    [captureSession_ addInput:audioInput error:NULL];
    [captureSession_ addInput:videoInput error:NULL];
    
    [audioInput release];
    [videoInput release];
    
    [captureView_ setCaptureSession:captureSession_];
    
    //
    // Outputs
    
    QTCaptureFileOutput *fileOutput = [[QTCaptureMovieFileOutput alloc] init];
    [fileOutput setMaximumVideoSize:NSMakeSize(kMaxVideoWidth, kMaxVideoHeight)];
    [fileOutput recordToOutputFileURL:[NSURL fileURLWithPath:[self uniqeFilenameWithExtension:@"avi"]]];
    
    [captureSession_ addOutput:fileOutput error:NULL];
    
    [fileOutput release];
    
    //
    // Go go go
    
    [captureSession_ startRunning];
    
    //
    
    [self performSelector:@selector(stop:) withObject:nil afterDelay:20.0f];
    
}

- (void)stop:(id)sender {
    
    if (captureSession_) {
        [captureSession_ stopRunning];
        [captureView_ setCaptureSession:nil];
        [captureSession_ release];
    }
    
    [self enableButtons];
    busy_ = NO;

}

- (NSString *)uniqeFilenameWithExtension:(NSString *)ext {
    
    NSString *date = [dateFormatter_ stringFromDate:[NSDate date]];
    NSString *fileName = [NSString stringWithFormat:@"%@_%d.%@", date, [self nextIndex], ext];
    
    return [[kTargetFolder stringByExpandingTildeInPath] stringByAppendingPathComponent:fileName];
}

- (void)serialPortReadData:(NSDictionary *)dataDictionary {
//    NSData *data = [dataDictionary objectForKey:@"data"];
//    char *bytes = [data bytes];
//    for (int i = 0; i < [data length]; i++) {
        [self recordVideo:nil];
//    }
    [serialPort_ readDataInBackground];
}

- (int)nextIndex {
    nextIndex_++;
    return nextIndex_;
}

- (void)disableButtons {
    char *disable = "ab";
    [serialPort_ writeBytes:disable length:2 error:NULL];
}

- (void)enableButtons {
    char *enable = "AB";
    [serialPort_ writeBytes:enable length:2 error:NULL];
}

@end
