//
//  VBAppDelegate.h
//  VideoBooth
//
//  Created by Jason Frame on 28/12/2011.
//

#import <Cocoa/Cocoa.h>

#import <QTKit/QTKit.h>

#import "AMSerialPort.h"
#import "AMSerialPortAdditions.h"
#import "AMSerialPortList.h"

@interface VBAppDelegate : NSObject <NSApplicationDelegate>
{
    BOOL                            busy_;
    
    QTCaptureDevice                 *videoCaptureDevice_;
    QTCaptureDevice                 *audioCaptureDevice_;
    AMSerialPort                    *serialPort_;
    
    IBOutlet QTCaptureView          *captureView_;
    IBOutlet NSTextFieldCell        *label_;
    
    QTCaptureSession                *captureSession_;
    QTCaptureVideoPreviewOutput     *captureVideoPreview_;
    
    NSDateFormatter                 *dateFormatter_;
    
    int                             nextIndex_;
    
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction)takePhoto:(id)sender;
- (IBAction)recordVideo:(id)sender;
- (IBAction)stop:(id)sender;

- (int)nextIndex;

@end
