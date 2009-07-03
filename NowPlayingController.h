//
//  NowPlayingController.h
//  ShoutOut
//
//  Created by ME on 9/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import <UIKit/UIView-Geometry.h>
//#import <GraphicsServices/GraphicsServices.h>
#import <Foundation/Foundation.h>
#import <CoreSurface/CoreSurface.h>
#import <QuartzCore/CALayer.h>

#import <unistd.h>
#import <sys/time.h>

struct myGSPathPoint {
	char unk0;
	char unk1;
	short int status;
	int unk2;
	int unk3;
	int unk4;
	float x;
	float y;
};

typedef struct {
	int unk0;
	int unk1;
	int type;
	int subtype;
	float unk2;
	float unk3;
	float x;
	float y;
	int timestamp1;
	int timestamp2;
	int unk4;
	int modifierFlags;
	int unk5;
	int unk6;
	int mouseEvent;
	short int dx;
	short int fingerCount;	
	int unk7;
	int unk8;
	char unk9;
	char numPoints;
	short int unk10;
	int unk11;
	int unk12;
	int unk13;
	struct myGSPathPoint points[10];
} myGSEvent;

@interface ScreenView : UIView
{
	CoreSurfaceBufferRef			_screenSurface;
	CALayer						*	screenLayer;
	NSTimer						*	timer;
}

- (id)initWithFrame:(struct CGRect)rect;
- (void)drawRect:(CGRect)rect;
- (CoreSurfaceBufferRef)getSurface;

@end

@interface NowPlayingController : UIViewController {
	IBOutlet	UISlider		* volumeSlider;
	IBOutlet	UITabBar		* tabBar;
	IBOutlet	UIWindow		* window;
	IBOutlet	UIButton			* ButtonL1;
	IBOutlet	UIButton			* ButtonL2;
	IBOutlet	UIButton			* ButtonR1;
	IBOutlet	UIButton			* ButtonR2;
	IBOutlet	UIButton			* ButtonUP;
	IBOutlet	UIButton			* ButtonDOWN;
	IBOutlet	UIButton			* ButtonLEFT;
	IBOutlet	UIButton			* ButtonRIGHT;
	IBOutlet	UIButton			* ButtonSTART;
	IBOutlet	UIButton			* ButtonSELECT;
	IBOutlet	UIButton			* ButtonUPLEFT;
	IBOutlet	UIButton			* ButtonUPRIGHT;
	IBOutlet	UIButton			* ButtonDOWNLEFT;
	IBOutlet	UIButton			* ButtonDOWNRIGHT;
	IBOutlet	UIButton			* ButtonSAVE;
	IBOutlet	UIButton			* ButtonBOOKMARK;
	IBOutlet	UIButton			* ButtonTRIANGLE;
	IBOutlet	UIButton			* ButtonSQUARE;
	IBOutlet	UIButton			* ButtonCIRCLE;
	IBOutlet	UIButton			* ButtonCROSS;
	IBOutlet	UIButton			* ButtonEXIT;
	NSString					* currentId;
	NSString					* currentTunein;
	NSString					* currentTitle;
	NSString					* currentPath;
	NSString					* currentFile;
	NSString					* currentDir;
	ScreenView					* screenView;
	
    CGRect ButtonUp;
    CGRect ButtonLeft;
    CGRect ButtonDown;
    CGRect ButtonRight;
    CGRect ButtonUpLeft;
    CGRect ButtonDownLeft;
    CGRect ButtonUpRight;
    CGRect ButtonDownRight;
    CGRect Up;
    CGRect Left;
    CGRect Down;
    CGRect Right;
    CGRect UpLeft;
    CGRect DownLeft;
    CGRect UpRight;
    CGRect DownRight;
    CGRect Select;
    CGRect Start;
    CGRect LPad;
    CGRect RPad;
    CGRect LPad2;
    CGRect RPad2;
    CGRect Menu;
	
	CGPoint fingers[5];
    int numFingers;
}

- (void)getControllerCoords;
- (void)fixRects;
- (void)dumpEvent:(myGSEvent*)event;
- (void)volumeChanged:(id)sender;
- (void)setBookmark:(id)sender;
- (void)setCurrentlyPlaying:(NSString*) str;
- (void)setCurrentStation:(NSString*)theStation withTitle:(NSString*)theTitle withId:(NSString*)theId withTunein:(NSString*)theTunein withPath:(NSString*)thePath withFile:(NSString*)theFile withDir:(NSString*)theDir;
- (void)startEmu:(char*)path;

@end
