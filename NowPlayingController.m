//
//  NowPlayingController.m
//  ShoutOut
//
//  Created by ME on 9/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SOApplication.h"
#import <pthread.h>

#define IPHONE_MENU_DISABLED            0
#define IPHONE_MENU_MAIN                1
#define IPHONE_MENU_SAVE_CURRENT        2
#define IPHONE_MENU_SAVE_NEW            3
#define IPHONE_MENU_TOGGLE_CHEAT_LOAD   4
#define IPHONE_MENU_QUIT_LOAD           5
#define IPHONE_MENU_TOGGLE_CHEAT        6
#define IPHONE_MENU_QUIT                7
#define IPHONE_MENU_MAIN_LOAD           8

char romfile[1024];
char ourArgsStr[16][256];
char* ourArgs[255];
int ourArgsCnt = 0;
unsigned short* screenbuffer;
int iphone_touches = 0;
int iphone_menu = IPHONE_MENU_DISABLED;
long long iphone_last_upd_ticks = 0;
int iphone_controller_opacity = 100;
int iphone_is_landscape = 0;
pthread_t sound_tid;

enum  { GP2X_UP=0x1,       GP2X_LEFT=0x4,       GP2X_DOWN=0x10,  GP2X_RIGHT=0x40,
	GP2X_START=1<<8,   GP2X_SELECT=1<<9,    GP2X_L=1<<10,    GP2X_R=1<<11,
	GP2X_A=1<<12,      GP2X_B=1<<13,        GP2X_X=1<<14,    GP2X_Y=1<<15,
GP2X_VOL_UP=1<<23, GP2X_VOL_DOWN=1<<22, GP2X_PUSH=1<<27 };

unsigned long global_enable_audio = 1;

extern float __audioVolume;
extern unsigned short BaseAddress[240*160];
extern unsigned long gp2x_pad_status;
extern int __emulation_run;
extern int __emulation_saving;
extern int __emulation_paused;
extern int tArgc;
extern char** tArgv;
extern pthread_t main_tid;
extern unsigned char gamepak_filename[512];
extern char test_print_buffer[128];
extern unsigned short* videobuffer;

extern void save_state(char *savestate_filename, unsigned short *screen_capture);
extern void set_save_state(void);
extern int iphone_main (int argc, char **argv);
extern void toggle_cheat(unsigned char cheat_num);
extern int check_cheat(unsigned char cheat_num);
extern unsigned char* name_cheat(unsigned char cheat_num);

static ScreenView *sharedInstance = nil;

void updateScreen()
{
  //usleep(100);
  sched_yield();
	//[sharedInstance performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
}

void* sound_Thread_Start(void* args)
{
  if(global_enable_audio)
  {
    app_DemuteSound();
  }
	while(__emulation_run)
	{
    usleep(1000000);
	}
}

void* app_Thread_Start(void* args)
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
	__emulation_saving = 0;
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
		
  		self.opaque = YES;
  		self.clearsContextBeforeDrawing = NO;
  		self.userInteractionEnabled = NO;
  		self.multipleTouchEnabled = NO;
  		self.contentMode = UIViewContentModeTopLeft;

  		[[self layer] setMagnificationFilter:kCAFilterNearest];
  		[[self layer] setMinificationFilter:kCAFilterNearest];
		
		dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
										 &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFDictionarySetValue(dict, kCoreSurfaceBufferGlobal, kCFBooleanTrue);
		CFDictionarySetValue(dict, kCoreSurfaceBufferMemoryRegion,
							 @"IOSurfaceMemoryRegion");
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
		if(!iphone_is_landscape)
		{
			if([SOApp.optionsView getCurrentScaling])
			{
				screenLayer.frame = CGRectMake(0.0f, 0.0f, 318.0f, 238.0f);
				[ screenLayer setOpaque: YES ];
			}
			else
			{
				screenLayer.frame = CGRectMake(0.0f, 0.0f, 318.0f, 238.0f);
				[ screenLayer setOpaque: YES ];				
			}
		}
		else
		{
			if([SOApp.optionsView getCurrentScaling])
			{
				CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI / 2.0f); // = CGAffineTransformMakeTranslation(1.0, 1.0);
				[screenLayer setAffineTransform:transform];
				screenLayer.frame = CGRectMake(0.0f, 0.0f, 320.0f, 480.0f);
				//[screenLayer setCenter:CGPointMake(240.0f,160.0f)];
				[ screenLayer setOpaque:YES ];
			}
			else
			{
				CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI / 2.0f); // = CGAffineTransformMakeTranslation(1.0, 1.0);
				[screenLayer setAffineTransform:transform];
				screenLayer.frame = CGRectMake(40.0f, 80.0f, 320.0f, 480.0f);
				//[screenLayer setCenter:CGPointMake(240.0f,160.0f)];
				[ screenLayer setOpaque:YES ];				
			}
		}
		[screenLayer setMinificationFilter:kCAFilterNearest];
		[screenLayer setMagnificationFilter:kCAFilterNearest];
		screenLayer.contents = (id)_screenSurface;
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

		screenbuffer = CoreSurfaceBufferGetBaseAddress(_screenSurface);
		//[NSThread setThreadPriority:0.0];
		[NSThread detachNewThreadSelector:@selector(updateScreen) toTarget:self withObject:nil];
		
    iphone_last_upd_ticks = 0;
		/*
		timer = [NSTimer scheduledTimerWithTimeInterval:(1.0f / 10.0f)
												 target:self
											   selector:@selector(updateScreen)
											   userInfo:nil
												repeats:YES];
		*/
	}
    
	sharedInstance = self;
	
	return self;
}

- (void)dealloc
{
	//[timer invalidate];
	[ screenLayer release ];
	[ super dealloc ];
}

- (CoreSurfaceBufferRef)getSurface
{
	return _screenSurface;
}


- (void)drawRect:(CGRect)rect
{
	//memcpy(screenbuffer, BaseAddress, 240*160*2);
	//memcpy(screenbuffer, BaseAddress, 240*160*2);
}

- (void)dummy
{
	
}

- (void)updateScreen
{
  [NSThread setThreadPriority:1.0];
#if 1
/*  if(iphone_touches == 1)
  {
		[self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
		[self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
		[self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
  }
  else if(iphone_touches >= 2)
  {
		[self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
  }
  else*/
  {
		//[self setNeedsDisplay];
		  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		while(__emulation_run)
		{
		  [self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
      usleep(16666);
      sched_yield();
		}
    [pool release];
		/*[self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
		[self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
		[self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
		[self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
		[self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
  */
  }
#else
	struct timeval current_time;
  long long current_ticks;
	gettimeofday(&current_time, NULL);
	current_ticks = ((long long)current_time.tv_sec * 1000ll) + ((long long)current_time.tv_usec / 1000ll);
	
	if(iphone_last_upd_ticks > 0)
	{		
		if((current_ticks - iphone_last_upd_ticks) >= (iphone_touches > 1 ? 40 : 33))
		{
			[self setNeedsDisplay];
			iphone_last_upd_ticks = current_ticks;
		}
	}
	else
	{
		[self setNeedsDisplay];
		iphone_last_upd_ticks = current_ticks;
	}
#endif
}

@end

@implementation NowPlayingController

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// the user clicked one of the OK/Cancel buttons
	if(__emulation_run)
	{
	  if(iphone_menu == IPHONE_MENU_MAIN)
	  {
      if(buttonIndex == 0)
	    {
        iphone_menu = IPHONE_MENU_QUIT_LOAD;
	    }
	    else
	    {
        iphone_menu = IPHONE_MENU_DISABLED;
	    }
	  }
	  
	  if(iphone_menu == IPHONE_MENU_QUIT_LOAD)
	  {
      iphone_menu = IPHONE_MENU_QUIT;
			UIActionSheet *alert = [[UIActionSheet alloc] initWithTitle:@"Are you sure?" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Yes",@"No", nil];
			[alert showInView:screenView];
			[alert release];
      return;
	  }

	  if(iphone_menu == IPHONE_MENU_QUIT)
	  {			
  		if (buttonIndex == 0)
  		{
  		  [SOApp.delegate switchToBrowse];
  			[tabBar didMoveToWindow];
  	    
  			__emulation_saving = 0;
  			__emulation_run = 0;
  			//pthread_join(main_tid, NULL);
  			[screenView removeFromSuperview];
  			[screenView release];
  			[controllerImageView removeFromSuperview];
  			[controllerImageView release];
  			__emulation_run = 0;
  			__emulation_saving = 0;
    		if(global_enable_audio)
        {
          app_MuteSound();
        }
#ifdef WITH_ADS
  			[SOApp.delegate unpauseAdViews];
#endif
  		}
  		iphone_menu = IPHONE_MENU_DISABLED;
	  }
	  else
	  {
      iphone_menu = IPHONE_MENU_DISABLED;
	  }
	}
	else
	{
		if (buttonIndex == 0)
		{
      iphone_is_landscape = 0;
			global_enable_audio = 1;
			[ self getControllerCoords:0 ];
			[ self fixRects ];
			numFingers = 0;
			__emulation_run = 1;
			screenView = [ [ScreenView alloc] initWithFrame: CGRectMake(0, 0, 320, 480)];
			[self.view addSubview: screenView];
			controllerImageView = [ [ UIImageView alloc ] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"controller_hs%d.png", [SOApp.optionsView getCurrentSkin]]]];
			controllerImageView.frame = CGRectMake(0.0f, 240.0f, 320.0f, 240.0f); // Set the frame in which the UIImage should be drawn in.
			controllerImageView.userInteractionEnabled = NO;
			controllerImageView.multipleTouchEnabled = NO;
			controllerImageView.clearsContextBeforeDrawing = NO;
			[controllerImageView setOpaque:YES];
			[controllerImageView setAlpha:((float)iphone_controller_opacity / 100.0f)];
			[self.view addSubview: controllerImageView]; // Draw the image in self.view.
		}
		else if (buttonIndex == 1)
		{
		  iphone_is_landscape = 0;
			global_enable_audio = 0;
			[ self getControllerCoords:0 ];
			[ self fixRects ];
			numFingers = 0;
			__emulation_run = 1;
			screenView = [ [ScreenView alloc] initWithFrame: CGRectMake(0, 0, 320, 480)];
			[self.view addSubview: screenView];
			controllerImageView = [ [ UIImageView alloc ] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"controller_hs%d.png", [SOApp.optionsView getCurrentSkin]]]];
			controllerImageView.frame = CGRectMake(0.0f, 240.0f, 320.0f, 240.0f); // Set the frame in which the UIImage should be drawn in.
			controllerImageView.userInteractionEnabled = NO;
			controllerImageView.multipleTouchEnabled = NO;
			controllerImageView.clearsContextBeforeDrawing = NO;
			[controllerImageView setOpaque:YES];
			[controllerImageView setAlpha:((float)iphone_controller_opacity / 100.0f)];
			[self.view addSubview: controllerImageView]; // Draw the image in self.view.
		}
		else if (buttonIndex == 2)
		{
		  iphone_is_landscape = 1;
			global_enable_audio = 1;
			[ self getControllerCoords:1 ];
			[ self fixRects ];
			numFingers = 0;
			__emulation_run = 1;
			screenView = [ [ScreenView alloc] initWithFrame: CGRectMake(0, 0, 320, 480)];
			[self.view addSubview: screenView];
			controllerImageView = [ [ UIImageView alloc ] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"controller_fs%d.png", [SOApp.optionsView getCurrentSkin]]]];
			controllerImageView.frame = CGRectMake(0.0f, 0.0f, 320.0f, 480.0f); // Set the frame in which the UIImage should be drawn in.
			controllerImageView.userInteractionEnabled = NO;
			controllerImageView.multipleTouchEnabled = NO;
			controllerImageView.clearsContextBeforeDrawing = NO;
			[controllerImageView setOpaque:YES];
			[controllerImageView setAlpha:((float)iphone_controller_opacity / 100.0f)];
			[self.view addSubview: controllerImageView]; // Draw the image in self.view.
		}
		else
		{
		  iphone_is_landscape = 1;
			global_enable_audio = 0;
			[ self getControllerCoords:1 ];
			[ self fixRects ];
			numFingers = 0;
			__emulation_run = 1;
			screenView = [ [ScreenView alloc] initWithFrame: CGRectMake(0, 0, 320, 480)];
			[self.view addSubview: screenView];
			controllerImageView = [ [ UIImageView alloc ] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"controller_fs%d.png", [SOApp.optionsView getCurrentSkin]]]];
			controllerImageView.frame = CGRectMake(0.0f, 0.0f, 320.0f, 480.0f); // Set the frame in which the UIImage should be drawn in.
			[controllerImageView setOpaque:YES];
			[controllerImageView setAlpha:((float)iphone_controller_opacity / 100.0f)];
			controllerImageView.userInteractionEnabled = NO;
			controllerImageView.multipleTouchEnabled = NO;
			controllerImageView.clearsContextBeforeDrawing = NO;
			[self.view addSubview: controllerImageView]; // Draw the image in self.view.				
		}
#ifdef WITH_ADS		
    [SOApp.delegate pauseAdViews];
#endif
		pthread_create(&main_tid, NULL, app_Thread_Start, NULL);
		
		struct sched_param    param;
    param.sched_priority = 63;
    if(pthread_setschedparam(main_tid, SCHED_RR, &param) != 0)
    {
      fprintf(stderr, "Error setting pthread priority\n");
    }
    
    if(global_enable_audio)
    {
      app_DemuteSound();
    }
    //[NSThread detachNewThreadSelector:@selector(runSound) toTarget:self withObject:nil];  
	}
}

- (void)runSound
{
  //[NSThread setThreadPriority:1.0];
  sound_Thread_Start(NULL);
}

- (void)runProgram
{
	__emulation_run = 1;
	iphone_main(ourArgsCnt, ourArgs);
	__emulation_run = 0;
	__emulation_saving = 0;	
}

- (void)startEmu:(char*)path {
	int i = 0;
	
  iphone_menu = IPHONE_MENU_DISABLED;
	
	ourArgsCnt = 0;
	/* faked executable path */
	ourArgs[ourArgsCnt]=get_documents_path("mame4iphone"); ourArgsCnt++;
	
	sprintf(romfile, "%s", strrchr(path, '/') + 1);
	char* trimrom = strrchr(romfile, '.');
	if(trimrom)
		trimrom[0] = '\0';
	
	ourArgs[ourArgsCnt]=romfile; ourArgsCnt++;
	
	ourArgs[ourArgsCnt]="-soundcard"; ourArgsCnt++;
	ourArgs[ourArgsCnt]="0"; ourArgsCnt++;
	
	ourArgs[ourArgsCnt]="-depth"; ourArgsCnt++;
	ourArgs[ourArgsCnt]="16"; ourArgsCnt++;

	/* gp2x_frameskip */
	ourArgs[ourArgsCnt]="-frameskip"; ourArgsCnt++;
	sprintf(ourArgsStr[i],"auto");
	ourArgs[ourArgsCnt]=ourArgsStr[i]; i++; ourArgsCnt++;
	
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
	
	ourArgs[ourArgsCnt]="-romdir"; ourArgsCnt++;
	ourArgs[ourArgsCnt]="/var/mobile/Media/ROMs/MAME/roms"; ourArgsCnt++;
	
	ourArgs[ourArgsCnt]=NULL;
	
	for (i=0; i<ourArgsCnt; i++)
	{
		fprintf(stderr, "%s ",ourArgs[i]);
	}
	fprintf(stderr, "\n");
	
	self.view.frame = CGRectMake(0.0f, 0.0f, 320.0f, 480.0f);
	
	UIActionSheet *alert = [[UIActionSheet alloc] initWithTitle:@"Choose Your Screen Orientation & Sound Options" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Portrait & Sound", @"Portrait & No Sound", @"Landscape & Sound", @"Landscape & No Sound", nil];
	[alert showInView:self.view];
	[alert release];
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
	[ self getControllerCoords:0 ];
	[ self fixRects ];
	numFingers = 0;
	iphone_touches = 0;
	self.navigationItem.hidesBackButton = YES;
	
  self.view.opaque = YES;
	self.view.clearsContextBeforeDrawing = NO;
	self.view.userInteractionEnabled = YES;
	self.view.multipleTouchEnabled = YES;
	self.view.contentMode = UIViewContentModeTopLeft;
	
	[[self.view layer] setMagnificationFilter:kCAFilterNearest];
	[[self.view layer] setMinificationFilter:kCAFilterNearest];
	[NSThread setThreadPriority:1.0];
}

- (void)drawRect:(CGRect)rect
{
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

- (void)runMenu
{
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  __emulation_paused = 1;
  iphone_menu = IPHONE_MENU_MAIN_LOAD;
  while(iphone_menu != IPHONE_MENU_DISABLED)
  {
    if(iphone_menu == IPHONE_MENU_MAIN_LOAD)
    {
      iphone_menu = IPHONE_MENU_MAIN;
      [NSThread detachNewThreadSelector:@selector(runMainMenu) toTarget:self withObject:nil];
		}
		else
		{
      usleep(1000000);
		}
	}
	__emulation_paused = 0;
  [pool release];
}

- (void)runMainMenu
{
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	UIActionSheet *alert = [[UIActionSheet alloc] initWithTitle:@"Choose an option from the menu. Press cancel to go back." delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Quit To Menu",@"Cancel", nil];
	[alert showInView:screenView];
	[alert release];
  [pool release];
}

#define MyCGRectContainsPoint(rect, point)						\
	(((point.x >= rect.origin.x) &&								\
		(point.y >= rect.origin.y) &&							\
		(point.x <= rect.origin.x + rect.size.width) &&			\
		(point.y <= rect.origin.y + rect.size.height)) ? 1 : 0)

#if 1
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {	
	int i;
	//Get all the touches.
	NSSet *allTouches = [event allTouches];
	int touchcount = [allTouches count];
	
	gp2x_pad_status = 0;
	
  iphone_touches = touchcount;
			
	for (i = 0; i < touchcount; i++) 
	{
		UITouch *touch = [[allTouches allObjects] objectAtIndex:i];
		
		if(touch == nil)
		{
			return;
		}
		
		/*if(touch.phase == UITouchPhaseBegan)
		{
			NSLog([NSString stringWithFormat:@"%s", test_print_buffer]);
		}*/
		if( touch.phase == UITouchPhaseBegan		||
			touch.phase == UITouchPhaseMoved		||
			touch.phase == UITouchPhaseStationary	)
		{
			struct CGPoint point;
			point = [touch locationInView:self.view];
			
			if (MyCGRectContainsPoint(ButtonUp, point)) {
				gp2x_pad_status |= GP2X_Y;
			}
			else if (MyCGRectContainsPoint(ButtonDown, point)) {
				gp2x_pad_status |= GP2X_X;
			}
			else if (MyCGRectContainsPoint(ButtonLeft, point)) {
				gp2x_pad_status |= GP2X_A;
			}
			else if (MyCGRectContainsPoint(ButtonRight, point)) {
				gp2x_pad_status |= GP2X_B;
			}
			else if (MyCGRectContainsPoint(ButtonUpLeft, point)) {
				gp2x_pad_status |= GP2X_Y | GP2X_A;
			}
			else if (MyCGRectContainsPoint(ButtonDownLeft, point)) {
				gp2x_pad_status |= GP2X_X | GP2X_A;
			}
			else if (MyCGRectContainsPoint(ButtonUpRight, point)) {
				gp2x_pad_status |= GP2X_Y | GP2X_B;
			}			
			else if (MyCGRectContainsPoint(ButtonDownRight, point)) {
				gp2x_pad_status |= GP2X_X | GP2X_B;
			} 
			else if (MyCGRectContainsPoint(Select, point)) {
				gp2x_pad_status |= GP2X_SELECT;
			}
			else if (MyCGRectContainsPoint(Start, point)) {
				gp2x_pad_status |= GP2X_START;
			}
			else if (MyCGRectContainsPoint(Up, point)) {
				gp2x_pad_status |= GP2X_UP;
			}			
			else if (MyCGRectContainsPoint(Down, point)) {
				gp2x_pad_status |= GP2X_DOWN;
			}			
			else if (MyCGRectContainsPoint(Left, point)) {
				gp2x_pad_status |= GP2X_LEFT;
			}			
			else if (MyCGRectContainsPoint(Right, point)) {
				gp2x_pad_status |= GP2X_RIGHT;
			}			
			else if (MyCGRectContainsPoint(UpLeft, point)) {
				gp2x_pad_status |= GP2X_UP | GP2X_LEFT;
			}			
			else if (MyCGRectContainsPoint(UpRight, point)) {
				gp2x_pad_status |= GP2X_UP | GP2X_RIGHT;
			}			
			else if (MyCGRectContainsPoint(DownLeft, point)) {
				gp2x_pad_status |= GP2X_DOWN | GP2X_LEFT;
			}			
			else if (MyCGRectContainsPoint(DownRight, point)) {
				gp2x_pad_status |= GP2X_DOWN | GP2X_RIGHT;
			}
			else if (MyCGRectContainsPoint(LPad, point)) {
				gp2x_pad_status |= GP2X_L;
			}
			else if (MyCGRectContainsPoint(RPad, point)) {
				gp2x_pad_status |= GP2X_R;
			}			
			else if (MyCGRectContainsPoint(LPad2, point)) {
				gp2x_pad_status |= GP2X_VOL_DOWN;
			}
			else if (MyCGRectContainsPoint(RPad2, point)) {
				gp2x_pad_status |= GP2X_VOL_UP;
			}			
			else if (MyCGRectContainsPoint(Menu, point)) {
				if(touch.phase == UITouchPhaseBegan || touch.phase == UITouchPhaseStationary)
				{
					if(__emulation_run)
					{
            [NSThread detachNewThreadSelector:@selector(runMenu) toTarget:self withObject:nil];
					}
					else
					{
  					[SOApp.delegate switchToBrowse];
  					[tabBar didMoveToWindow];
					}
				}
			}
		}
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchesBegan:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchesBegan:touches withEvent:event];
  iphone_touches = 0;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchesBegan:touches withEvent:event];
  iphone_touches = 0;
}
#endif
/*
- (void)view:(UIView *)view handleTapWithCount:(int)count event:(myGSEvent *)event {
	//NSLog(@"handleTapWithCount: %d", count);
	[self dumpEvent: event];
}
*/
/*
- (double)viewTouchPauseThreshold:(UIView *)view {
	NSLog(@"TouchPause!");
	return 0.0;
}
*/

#if 0
- (void)mouseEvent:(myGSEvent*)event {
	int i;
	int touchcount = event->fingerCount;
	
	gp2x_pad_status = 0;
	
	for (i = 0; i < touchcount; i++) 
	{
		struct CGPoint point = CGPointMake(event->points[i].x, event->points[i].y);
		
		if (MyCGRectContainsPoint(Left, point)) {
			gp2x_pad_status |= GP2X_LEFT;
		}
		else if (MyCGRectContainsPoint(Right, point)) {
			gp2x_pad_status |= GP2X_RIGHT;
		}
		else if (MyCGRectContainsPoint(Up, point)) {
			gp2x_pad_status |= GP2X_UP;
		}
		else if (MyCGRectContainsPoint(Down, point)) {
			gp2x_pad_status |= GP2X_DOWN;
		}
		else if (MyCGRectContainsPoint(A, point)) {
			gp2x_pad_status |= GP2X_B;
		}
		else if (MyCGRectContainsPoint(B, point)) {
			gp2x_pad_status |= GP2X_X;
		}
		else if (MyCGRectContainsPoint(AB, point)) {
			gp2x_pad_status |= GP2X_B | GP2X_X;
		}			
		else if (MyCGRectContainsPoint(UpLeft, point)) {
			gp2x_pad_status |= GP2X_UP | GP2X_LEFT;
		} 
		else if (MyCGRectContainsPoint(DownLeft, point)) {
			gp2x_pad_status |= GP2X_DOWN | GP2X_LEFT;
		}
		else if (MyCGRectContainsPoint(UpRight, point)) {
			gp2x_pad_status |= GP2X_UP | GP2X_RIGHT;
		}
		else if (MyCGRectContainsPoint(DownRight, point)) {
			gp2x_pad_status |= GP2X_DOWN | GP2X_RIGHT;
		}			
		else if (MyCGRectContainsPoint(LPad, point)) {
			gp2x_pad_status |= GP2X_L;
		}
		else if (MyCGRectContainsPoint(RPad, point)) {
			gp2x_pad_status |= GP2X_R;
		}			
		else if (MyCGRectContainsPoint(Select, point)) {
			gp2x_pad_status |= GP2X_SELECT;
		}
		else if (MyCGRectContainsPoint(Start, point)) {
			gp2x_pad_status |= GP2X_START;
		}
		else if (MyCGRectContainsPoint(Menu, point)) {
			//if(touch.phase == UITouchPhaseBegan || touch.phase == UITouchPhaseStationary)
			{
				[SOApp.delegate switchToBrowse];
				[tabBar didMoveToWindow];
				if(__emulation_run)
				{
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save Game State" message:@"Save Game State?" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Save Game!",@"Don't Save?", nil];
					[alert show];
					[alert release];
				}
			}
		}
	}
}

- (void)mouseDown:(myGSEvent*)event {
	//NSLog(@"mouseDown:");
	[self mouseEvent: event];
}

- (void)mouseDragged:(myGSEvent*)event {
	//NSLog(@"mouseDragged:");
	[self mouseEvent: event];
}

- (void)mouseEntered:(myGSEvent*)event {		
	//NSLog(@"mouseEntered:");
	[self mouseEvent: event];
}

- (void)mouseExited:(myGSEvent*)event {		
	//NSLog(@"mouseExited:");
	[self mouseEvent: event];
}

- (void)mouseMoved:(myGSEvent*)event {
	//NSLog(@"mouseMoved:");
	[self mouseEvent: event];
}

- (void)mouseUp:(myGSEvent*)event {
	[self mouseEvent: event];
}
#endif

/*
- (BOOL)isFirstResponder {
	return YES;
}
*/

- (void)getControllerCoords:(int)orientation {
    char string[256];
    FILE *fp;
	
	if(!orientation)
	{
		fp = fopen([[NSString stringWithFormat:@"%scontroller_hs%d.txt", get_resource_path("/"), [SOApp.optionsView getCurrentSkin]] UTF8String], "r");
  }
	else
	{
		fp = fopen([[NSString stringWithFormat:@"%scontroller_fs%d.txt", get_resource_path("/"), [SOApp.optionsView getCurrentSkin]] UTF8String], "r");
	}
	
	if (fp) 
	{
		int i = 0;
    while(fgets(string, 256, fp) != NULL && i < 24) 
    {
			char* result = strtok(string, ",");
			int coords[4];
			int i2 = 1;
			while( result != NULL && i2 < 5 )
			{
				coords[i2 - 1] = atoi(result);
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
        case 23:   iphone_controller_opacity = coords[0]; break;
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
#if 0
	__audioVolume = volumeSlider.value;
#endif
}

- (void)setCurrentStation:(NSString*)thePath withFile:(NSString*)theFile withDir:(NSString*)theDir {
	if(currentPath)
	{	[ currentPath release ]; currentPath = NULL; }
	if(currentFile)
	{	[ currentFile release ]; currentFile = NULL; }
	if(currentDir)
	{	[ currentDir release ]; currentDir = NULL; }
	
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

#if 0
- (void)setBookmark:(id)sender 
{
	if(__emulation_run)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save Game State" message:@"Save Game State?" delegate:self cancelButtonTitle:@"Dont Save?" otherButtonTitles:@"Save Game!", nil];
		[alert show];
		[alert release];
		__emulation_saving = 1;
		__emulation_run = 0;
		pthread_join(main_tid, NULL);
		[screenView release];
	}	
	if(currentPath && currentFile && currentDir)
	{
		[SOApp.bookmarksView addBookmark:currentPath withFile:currentFile withDir:currentDir];
		[SOApp.delegate switchToBookmarks];
		[tabBar didMoveToWindowBookmarks];		
	}
	else
	{
		[SOApp.delegate switchToBookmarks];
		[tabBar didMoveToWindowBookmarks];
	}
}
#endif

- (void)setSaveState:(id)sender 
{
#if 0
	if(__emulation_run)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save Game State" message:@"Save Game State?" delegate:self cancelButtonTitle:@"Dont Save?" otherButtonTitles:@"Save Game!", nil];
		[alert show];
		[alert release];
		__emulation_saving = 1;
		__emulation_run = 0;
		pthread_join(main_tid, NULL);
		[screenView release];
	}	
	[SOApp.delegate switchToBrowse];
	[tabBar didMoveToWindow];	
#endif
}

@end
