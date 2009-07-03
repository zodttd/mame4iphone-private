//
//  NowPlayingController.m
//  ShoutOut
//
//  Created by ME on 9/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SOApplication.h"
#import <pthread.h>

char romfile[1024];
char *ourArgs[255];
char ourArgsStr[8][64];
int ourArgsCnt = 0;

enum  { GP2X_UP=0x1,       GP2X_LEFT=0x4,       GP2X_DOWN=0x10,  GP2X_RIGHT=0x40,
	GP2X_START=1<<8,   GP2X_SELECT=1<<9,    GP2X_L=1<<10,    GP2X_R=1<<11,
	GP2X_A=1<<12,      GP2X_B=1<<13,        GP2X_X=1<<14,    GP2X_Y=1<<15,
GP2X_VOL_UP=1<<23, GP2X_VOL_DOWN=1<<22, GP2X_PUSH=1<<27, GP2X_ESC=1<<28 };

extern float __audioVolume;
extern unsigned short *BaseAddress;
extern unsigned long gp2x_pad_status;
extern int __emulation_run;
extern int tArgc;
extern char** tArgv;
extern pthread_t main_tid;

extern void set_save_state(void);
extern int iphone_main (int argc, char **argv);

void *app_Thread_Start(void *args)
{
	__emulation_run = 1;
	iphone_main(ourArgsCnt, ourArgs);
/*	if(tArgv)
	{
		int i;
		for(i = 0; i < tArgc; i++)
		{
			if(tArgv[i] != NULL) free(tArgv[i]);
		}
		free(tArgv);
		tArgv = NULL;
	}
*/
	__emulation_run = 0;
	return NULL;
}

@implementation ScreenView
- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])!=nil) {
		CFMutableDictionaryRef dict;
		int w = 320; //rect.size.width;
		int h = 240; //rect.size.height;
		
    	int pitch = w * 2, allocSize = 2 * w * h;
    	char *pixelFormat = "565L";
		
		dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
										 &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFDictionarySetValue(dict, kCoreSurfaceBufferGlobal, kCFBooleanTrue);
		CFDictionarySetValue(dict, kCoreSurfaceBufferMemoryRegion,
							 @"PurpleGFXMem");
		CFDictionarySetValue(dict, kCoreSurfaceBufferPitch,
							 CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &pitch));
		CFDictionarySetValue(dict, kCoreSurfaceBufferWidth,
							 CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &w));
		CFDictionarySetValue(dict, kCoreSurfaceBufferHeight,
							 CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &h));
		CFDictionarySetValue(dict, kCoreSurfaceBufferPixelFormat,
							 CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, pixelFormat));
		CFDictionarySetValue(dict, kCoreSurfaceBufferAllocSize,
							 CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &allocSize));
		
		_screenSurface = CoreSurfaceBufferCreate(dict);
		CoreSurfaceBufferLock(_screenSurface, 3);
		
    	//CALayer* screenLayer = [CALayer layer];  
		screenLayer = [[CALayer layer] retain];
		/*
		CGAffineTransform affineTransform = CGAffineTransformIdentity;
		affineTransform = CGAffineTransformConcat( affineTransform, CGAffineTransformMakeRotation(90));
		self.transform = affineTransform;
		*/
		screenLayer.frame = CGRectMake(0.0f, 0.0f, 320.0f, 238.0f);
		[screenLayer setMagnificationFilter: 0];
		screenLayer.contents = (id)_screenSurface;
		[ screenLayer setOpaque: YES ];
		[[self layer] addSublayer:screenLayer];
		
		/*
		 screenLayer = [CALayer layer];
		 screenLayer.doubleSided = NO;
		 screenLayer.bounds = rect;
		 screenLayer.contents = (id)_screenSurface;
		 screenLayer.anchorPoint = CGPointMake(0, 0); // set anchor point to top-left
		 [self.layer addSublayer: screenLayer];
		 */
    	CoreSurfaceBufferUnlock(_screenSurface);
		
		BaseAddress = CoreSurfaceBufferGetBaseAddress(_screenSurface);
		
		timer = [NSTimer scheduledTimerWithTimeInterval:0.0275f
												 target:self
											   selector:@selector(updateScreen)
											   userInfo:nil
												repeats:YES];
	}
    
	return self;
}

- (void)dealloc
{
	[timer invalidate];
	[ screenLayer release ];
	[ super dealloc ];
}

- (CoreSurfaceBufferRef)getSurface
{
	return _screenSurface;
}

- (void)drawRect:(CGRect)rect
{
}

- (void)updateScreen
{
	static unsigned long long last_upd_ticks = 0;
	//NSLog(@"CoreSurfaceBufferGetBaseAddress(screenSurface): 0x%x", CoreSurfaceBufferGetBaseAddress(_screenSurface));
	if(last_upd_ticks != 0)
	{
		struct timeval current_time;
		gettimeofday(&current_time, NULL);
		unsigned long long current_ticks = 
		((unsigned long long)current_time.tv_sec * 1000000ll) + current_time.tv_usec;
		
		if((current_ticks - last_upd_ticks) > 19667)
		{
			[self setNeedsDisplay];
			struct timeval new_time;
			gettimeofday(&new_time, NULL);
			last_upd_ticks = ((unsigned long long)new_time.tv_sec * 1000000ll) + new_time.tv_usec;
		}
	}
	else
	{
		[self setNeedsDisplay];
		struct timeval new_time;
		gettimeofday(&new_time, NULL);
		last_upd_ticks = ((unsigned long long)new_time.tv_sec * 1000000ll) + new_time.tv_usec;
	}
	
	//[ self setNeedsDisplay ];
	//if(iphone_can_draw)
	//{
	//  [ self setNeedsDisplay ];
	//  iphone_can_draw = 0;
	//}
}

@end

@implementation NowPlayingController

- (void)startEmu:(char*)path {
	int i=0;
	
	ourArgsCnt = 0;
	/* faked executable path */
	ourArgs[ourArgsCnt]="/var/mobile/Media/ROMs/MAME/mame"; ourArgsCnt++;
	
	/* playgame */
	sprintf(romfile, "%s", strrchr(path, '/') + 1);
	char* trimrom = strrchr(romfile, '.');
	if(trimrom)
		trimrom[0] = '\0';
	
	ourArgs[ourArgsCnt]=romfile; ourArgsCnt++;
		
	/* gp2x_video_depth */
	/*
	if (gp2x_video_depth==8)
	{
		ourArgs[ourArgsCnt]="-depth"; ourArgsCnt++;
		ourArgs[ourArgsCnt]="8"; ourArgsCnt++;
	}
	if (gp2x_video_depth==16)
	{
		ourArgs[ourArgsCnt]="-depth"; ourArgsCnt++;
		ourArgs[ourArgsCnt]="16"; ourArgsCnt++;
	}
	*/
	/*
	if ((gp2x_video_aspect>=8) && (gp2x_video_aspect<=15))
	{
		ourArgs[ourArgsCnt]="-rotatecontrols"; ourArgsCnt++;
	}
	*/
	
	//ourArgs[ourArgsCnt]="-nothrottle"; ourArgsCnt++;

	if(__audioVolume == 0.0)
	{
		ourArgs[ourArgsCnt]="-soundcard"; ourArgsCnt++;
		ourArgs[ourArgsCnt]="0"; ourArgsCnt++;
	}
	
	ourArgs[ourArgsCnt]="-depth"; ourArgsCnt++;
	ourArgs[ourArgsCnt]="16"; ourArgsCnt++;

	/* gp2x_frameskip */
	//ourArgs[ourArgsCnt]="-frameskip"; ourArgsCnt++;
	//sprintf(ourArgsStr[i],"%d",5);
	//ourArgs[ourArgsCnt]=ourArgsStr[i]; i++; ourArgsCnt++;
	
	ourArgs[ourArgsCnt]="-samplerate"; ourArgsCnt++;
	ourArgs[ourArgsCnt]="44100"; ourArgsCnt++;
	//ourArgs[ourArgsCnt]="-fastsound"; ourArgsCnt++;
	
	/* gp2x_clock_cpu */
	ourArgs[ourArgsCnt]="-uclock"; ourArgsCnt++;
	sprintf(ourArgsStr[i],"%d",100-(80));
	ourArgs[ourArgsCnt]=ourArgsStr[i]; i++; ourArgsCnt++;
	
	/* gp2x_clock_sound */
	ourArgs[ourArgsCnt]="-uclocks"; ourArgsCnt++;
	sprintf(ourArgsStr[i],"%d",100-(80));
	ourArgs[ourArgsCnt]=ourArgsStr[i]; i++; ourArgsCnt++;
	
	ourArgs[ourArgsCnt]="-cheat"; ourArgsCnt++;
	ourArgs[ourArgsCnt]=NULL;
	
	
	ourArgs[ourArgsCnt]="-romdir"; ourArgsCnt++;
	ourArgs[ourArgsCnt]="/var/mobile/Media/ROMs/MAME/roms"; ourArgsCnt++;
	
	for (i=0; i<ourArgsCnt; i++)
	{
		fprintf(stderr, "%s ",ourArgs[i]);
	}
	fprintf(stderr, "\n");
	
	pthread_create(&main_tid, NULL, app_Thread_Start, NULL);	
/*
	char romfile[1024];
	tArgc = 4;
	tArgv = (char**) malloc (sizeof(*tArgv) * (tArgc+1));
	
	if (tArgv == NULL) 
	{
		return;
	}
	
	tArgv[0] = (char*)malloc(strlen("/Applications/mame4iphone.app/mame4iphone") + 1);
	sprintf(tArgv[0], "/Applications/mame4iphone.app/mame4iphone");
	
	sprintf(romfile, "%s", strrchr(path, '/') + 1);
	char* trimrom = strrchr(romfile, '.');
	if(trimrom)
		trimrom[0] = '\0';
	
	tArgv[1] = (char*)malloc(strlen(romfile) + 1);
	sprintf(tArgv[1], "%s",romfile);
	
	tArgv[2] = (char*)malloc(strlen("-romdir") + 1);
	sprintf(tArgv[2], "-romdir");
	tArgv[3] = (char*)malloc(strlen("/var/mobile/Media/ROMs/MAME") + 1);
	sprintf(tArgv[3], "/var/mobile/Media/ROMs/MAME");
		
	fprintf(stderr, "Loading %s\n", romfile);
	tArgv[tArgc] = NULL;
	
	pthread_create(&main_tid, NULL, app_Thread_Start, NULL);	
*/
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
	}
	return self;
}

- (void)awakeFromNib {
	//[ self setTapDelegate: self ];
	//[ self setGestureDelegate: self ];
	//[ self setMultipleTouchEnabled: YES ];
	[ self getControllerCoords ];
	[ self fixRects ];
	numFingers = 0;
	self.navigationItem.hidesBackButton = YES;
	screenView = [ [ScreenView alloc] initWithFrame: CGRectMake(0, 0, 320, 238) ];
	[self.view addSubview: screenView];
}

- (void)fixRects {
/*
    UpLeft    	= [ self convertRect: UpLeft toView: self ];
    DownLeft  	= [ self convertRect: DownLeft toView: self ];
    UpRight   	= [ self convertRect: UpRight toView: self ];
    DownRight  	= [ self convertRect: DownRight toView: self ];
    Up     = [ self convertRect: Up toView: self ];
    Down   = [ self convertRect: Down toView: self ];
    Left   = [ self convertRect: Left toView: self ];
    Right  = [ self convertRect: Right toView: self ];
    Select = [ self convertRect: Select toView: self ];
    Start  = [ self convertRect: Start toView: self ];
	
    ButtonUpLeft    	= [ self convertRect: ButtonUpLeft toView: self ];
    ButtonDownLeft  	= [ self convertRect: ButtonDownLeft toView: self ];
    ButtonUpRight   	= [ self convertRect: ButtonUpRight toView: self ];
    ButtonDownRight  	= [ self convertRect: ButtonDownRight toView: self ];
    ButtonUp     = [ self convertRect: ButtonUp toView: self ];
    ButtonDown   = [ self convertRect: ButtonDown toView: self ];
    ButtonLeft   = [ self convertRect: ButtonLeft toView: self ];
    ButtonRight  = [ self convertRect: ButtonRight toView: self ];
	
    LPad   = [ self convertRect: LPad toView: self ];
    RPad   = [ self convertRect: RPad toView: self ];
	
    LPad2   = [ self convertRect: LPad2 toView: self ];
    RPad2   = [ self convertRect: RPad2 toView: self ];
	
    Menu   = [ self convertRect: Menu toView: self ];
*/
}

/* Big thanks to iPhysics author nop144666 for the initial multitouch code! */
- (void)dumpEvent:(myGSEvent*)event {
	int i;

	gp2x_pad_status = 0;
	//NSLog(@"MouseEvent: %d, fingerCount: %hd, numPoints: %hhd, pos: %f, %f", event->mouseEvent, event->fingerCount, event->numPoints, event->x, event->y);
	
	for (i = 0; i < event->fingerCount; i++) {
		//NSLog(@"  Point %d: %f, %f", i, event->points[i].x, event->points[i].y);
		struct CGPoint point;
		point.x = event->points[i].x;
		point.y = event->points[i].y;
		
		if (CGRectContainsPoint(UpLeft, point)) {
            gp2x_pad_status |= GP2X_UP | GP2X_LEFT;
		} 
		else if (CGRectContainsPoint(DownLeft, point)) {
            gp2x_pad_status |= GP2X_DOWN | GP2X_LEFT;
		}
		else if (CGRectContainsPoint(UpRight, point)) {
            gp2x_pad_status |= GP2X_UP | GP2X_RIGHT;
		}
		else if (CGRectContainsPoint(DownRight, point)) {
            gp2x_pad_status |= GP2X_DOWN | GP2X_RIGHT;
		}
		else if (CGRectContainsPoint(Up, point)) {
            gp2x_pad_status |= GP2X_UP;
		}
		else if (CGRectContainsPoint(Down, point)) {
            gp2x_pad_status |= GP2X_DOWN;
		}
		else if (CGRectContainsPoint(Left, point)) {
            gp2x_pad_status |= GP2X_LEFT;
		}
		else if (CGRectContainsPoint(Right, point)) {
            gp2x_pad_status |= GP2X_RIGHT;
		}
		else if (CGRectContainsPoint(Select, point)) {
            gp2x_pad_status |= GP2X_SELECT;
		}
		else if (CGRectContainsPoint(Start, point)) {
            gp2x_pad_status |= GP2X_START;
		}
		else if (CGRectContainsPoint(ButtonUpLeft, point)) {
            gp2x_pad_status |= GP2X_A | GP2X_Y;
		}
		else if (CGRectContainsPoint(ButtonDownLeft, point)) {
            gp2x_pad_status |= GP2X_A | GP2X_X;
		}
		else if (CGRectContainsPoint(ButtonUpRight, point)) {
            gp2x_pad_status |= GP2X_Y | GP2X_B;
		}
		else if (CGRectContainsPoint(ButtonDownRight, point)) {
            gp2x_pad_status |= GP2X_X | GP2X_B;
		}
		else if (CGRectContainsPoint(ButtonUp, point)) {
            gp2x_pad_status |= GP2X_Y;
		}
		else if (CGRectContainsPoint(ButtonDown, point)) {
            gp2x_pad_status |= GP2X_X;
		}
		else if (CGRectContainsPoint(ButtonLeft, point)) {
            gp2x_pad_status |= GP2X_A;
		}
		else if (CGRectContainsPoint(ButtonRight, point)) {
            gp2x_pad_status |= GP2X_B;
		}
		else if (CGRectContainsPoint(LPad, point)) {
            gp2x_pad_status |= GP2X_L;
		}
		else if (CGRectContainsPoint(RPad, point)) {
            gp2x_pad_status |= GP2X_R;
		}
		else if (CGRectContainsPoint(LPad2, point)) {
            gp2x_pad_status |= GP2X_VOL_DOWN;
		}
		else if (CGRectContainsPoint(RPad2, point)) {
            gp2x_pad_status |= GP2X_VOL_UP;
		}
		else if (CGRectContainsPoint(Menu, point)) {
			__emulation_run = 0;
			gp2x_pad_status |= GP2X_ESC;
			[SOApp.delegate switchToBrowse];
			[tabBar didMoveToWindow];
		}
	}
}

- (void)gestureChanged:(myGSEvent*)event {
	//NSLog(@"gestureChanged:");
	[self dumpEvent: event];
}

- (void)gestureEnded:(myGSEvent*)event {
	//NSLog(@"gestureEnded:");
	[self dumpEvent: event];
}

- (void)gestureStarted:(myGSEvent*)event {
	//NSLog(@"gestureStarted:");
	[self dumpEvent: event];
}

- (void)mouseDown:(myGSEvent*)event {
	//NSLog(@"mouseDown:");
	[self dumpEvent: event];
}

- (void)mouseDragged:(myGSEvent*)event {
	//NSLog(@"mouseDragged:");
	[self dumpEvent: event];
}

- (void)mouseEntered:(myGSEvent*)event {		
	//NSLog(@"mouseEntered:");
	[self dumpEvent: event];
}

- (void)mouseExited:(myGSEvent*)event {		
	//NSLog(@"mouseExited:");
	[self dumpEvent: event];
}

- (void)mouseMoved:(myGSEvent*)event {
	//NSLog(@"mouseMoved:");
	[self dumpEvent: event];
}

- (void)mouseUp:(myGSEvent*)event {
	//NSLog(@"mouseUp:");
	[self dumpEvent: event];
}

- (void)view:(UIView *)view handleTapWithCount:(int)count event:(myGSEvent *)event {
	//NSLog(@"handleTapWithCount: %d", count);
	[self dumpEvent: event];
}

- (double)viewTouchPauseThreshold:(UIView *)view {
	return 0.5;
}

- (BOOL)isFirstResponder {
	return YES;
}

- (void)getControllerCoords {
    char string[256];
    FILE *fp;	
    fp = fopen("/Applications/mame4iphone.app/controller_hs1.txt", "r");
    if (fp) 
	{
		int i = 0;
        while(fgets(string, 256, fp) != NULL && i < 23) {
			char* result = strtok(string, ",");
			int coords[4];
			int i2 = 1;
			while( result != NULL && i2 < 5 )
			{
				coords[i2 - 1] = atoi(result);
				if(i2 - 1 == 1)
				{
					coords[1] += 240;
				}
				result = strtok(NULL, ",");
				i2++;
			}
			
			switch(i)
			{
				case 0:    DownLeft   	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
				case 1:    Down   	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
				case 2:    DownRight    = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
				case 3:    Left  	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
				case 4:    Right  	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
				case 5:    UpLeft     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
				case 6:    Up     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
				case 7:    UpRight  	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
				case 8:    Select = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
				case 9:    Start  = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
				case 10:   LPad   = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
				case 11:   RPad   = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
				case 12:   Menu   = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
				case 13:   ButtonDownLeft   	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
				case 14:   ButtonDown   	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
				case 15:   ButtonDownRight    	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
				case 16:   ButtonLeft  		= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
				case 17:   ButtonRight  	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
				case 18:   ButtonUpLeft     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
				case 19:   ButtonUp     	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
				case 20:   ButtonUpRight  	= CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
				case 21:   LPad2   = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
				case 22:   RPad2   = CGRectMake( coords[0], coords[1], coords[2], coords[3] ); break;
			}
           	i++;
        }
        fclose(fp);
    }
}

/*
 Implement loadView if you want to create a view hierarchy programmatically
- (void)loadView {
}
 */

/*
 If you need to do additional setup after loading the view, override viewDidLoad.
- (void)viewDidLoad {
}
 */


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {
	if(currentTitle)
		[ currentTitle release ];
	if(currentId)
		[ currentId release ];
	if(currentTunein)
		[ currentTunein release ];
	if(currentPath)
		[ currentPath release ];
	if(currentFile)
		[ currentFile release ];
	if(currentDir)
		[ currentDir release ];

	[super dealloc];
}

- (void)volumeChanged:(id)sender
{
	__audioVolume = volumeSlider.value;
}

- (void)setCurrentlyPlaying:(NSString*) str
{
}

- (void)setCurrentStation:(NSString*)theStation withTitle:(NSString*)theTitle withId:(NSString*)theId withTunein:(NSString*)theTunein withPath:(NSString*)thePath withFile:(NSString*)theFile withDir:(NSString*)theDir {
	if(currentTitle)
	{	[ currentTitle release ]; currentTitle = NULL; }
	if(currentId)
	{	[ currentId release ]; currentId = NULL; }
	if(currentTunein)
	{	[ currentTunein release ]; currentTunein = NULL; }
	if(currentPath)
	{	[ currentPath release ]; currentPath = NULL; }
	if(currentFile)
	{	[ currentFile release ]; currentFile = NULL; }
	if(currentDir)
	{	[ currentDir release ]; currentDir = NULL; }
	
	if(theTitle)
	{
		currentTitle = [[NSString alloc] initWithString: theTitle];	
	}
	if(theId)
	{
		currentId = [[NSString alloc] initWithString: theId];	
	}
	if(theTunein)
	{
		currentTunein = [[NSString alloc] initWithString: theTunein];	
	}
	if(thePath)
	{
		currentPath = [[NSString alloc] initWithString: thePath];	
	}
	if(theFile)
	{
		currentFile = [[NSString alloc] initWithString: theFile];	
	}
	if(theDir)
	{
		currentDir = [[NSString alloc] initWithString: theDir];	
	}
}

- (void)setBookmark:(id)sender 
{
	if(currentTunein && currentId && currentTitle)
	{
		[SOApp.bookmarksView addBookmark:currentTitle withId:currentId withTunein:currentTunein withBookmark:NULL withPath:NULL withFile:NULL withDir:NULL];
		[SOApp.delegate switchToBookmarks];
		[tabBar didMoveToWindowBookmarks];
	}
	else if(currentPath && currentFile && currentDir)
	{
		[SOApp.bookmarksView addBookmark:NULL withId:NULL withTunein:NULL withBookmark:NULL withPath:currentPath withFile:currentFile withDir:currentDir];
		[SOApp.delegate switchToBookmarks];
		[tabBar didMoveToWindowBookmarks];		
	}
	else
	{
		[SOApp.delegate switchToBookmarks];
		[tabBar didMoveToWindowBookmarks];
	}
}

@end
