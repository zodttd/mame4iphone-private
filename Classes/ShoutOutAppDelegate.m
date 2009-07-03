//
//  ShoutOutAppDelegate.m
//  ShoutOut
//
//  Created by Spookysoft on 9/6/08.
//  Copyright Spookysoft 2008. All rights reserved.
//

#import "SOApplication.h"

extern unsigned long gp2x_pad_status;

@implementation ShoutOutAppDelegate

@synthesize window;
@synthesize navigationController;

- (id)init {
	if (self = [super init]) {
		// 
	}
	return self;
}


- (void)applicationDidFinishLaunching:(UIApplication *)application {
	[[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
	application.idleTimerDisabled = YES;
	application.delegate = self;
	CGRect frame = window.frame;
	frame.origin.y = window.frame.origin.y+window.frame.size.height-49;
	frame.size.height = 49;
	tabBar.frame = frame;
	[window addSubview:tabBar];
	CGRect navFrame = [navigationController view].frame;
	navFrame.origin.y = 20;
	navFrame.size.height = 460 - 49;
	[navigationController view].frame = navFrame;
	
//	tabBar.selectedItem = 0;
	// Configure and show the window
	[window addSubview:[navigationController view]];
	[window makeKeyAndVisible];	
}

#pragma mark TabBar Actions
- (void)switchToBrowse {
	[[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
	CGRect frame = window.frame;
	frame.origin.y = window.frame.origin.y+window.frame.size.height-49;
	frame.size.height = 49;
	tabBar.frame = frame;
	CGRect navFrame = [navigationController view].frame;
	navFrame.origin.y = 20;
	navFrame.size.height = 460 - 49;
	[navigationController view].frame = navFrame;
	navigationController.navigationBarHidden = FALSE;
	navigationController.navigationBar.hidden = FALSE;
	
	[[self navigationController] popToRootViewControllerAnimated:NO];
}
- (void)switchToSaveStates {
	[[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
	CGRect frame = window.frame;
	frame.origin.y = window.frame.origin.y+window.frame.size.height-49;
	frame.size.height = 49;
	tabBar.frame = frame;
	CGRect navFrame = [navigationController view].frame;
	navFrame.origin.y = 20;
	navFrame.size.height = 460 - 49;
	[navigationController view].frame = navFrame;
	navigationController.navigationBarHidden = FALSE;
	navigationController.navigationBar.hidden = FALSE;
	
	[SOApp.saveStatesView refreshData:@"/var/mobile/Media/ROMs/PSX/"];
	if ([[[self navigationController] viewControllers] containsObject:SOApp.saveStatesView]) {
		[[self navigationController] popToViewController:SOApp.saveStatesView animated:NO];
	} else {
		[[self navigationController] pushViewController:SOApp.saveStatesView animated:NO];
	}
}
- (void)switchToBookmarks {
	[[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
	CGRect frame = window.frame;
	frame.origin.y = window.frame.origin.y+window.frame.size.height-49;
	frame.size.height = 49;
	tabBar.frame = frame;
	CGRect navFrame = [navigationController view].frame;
	navFrame.origin.y = 20;
	navFrame.size.height = 460 - 49;
	[navigationController view].frame = navFrame;
	navigationController.navigationBarHidden = FALSE;
	navigationController.navigationBar.hidden = FALSE;
	
	if ([[[self navigationController] viewControllers] containsObject:SOApp.bookmarksView]) {
		[[self navigationController] popToViewController:SOApp.bookmarksView animated:NO];
	} else {
		[[self navigationController] pushViewController:SOApp.bookmarksView animated:NO];
	}
}
- (void)switchToNowPlaying {
	[[UIApplication sharedApplication] setStatusBarHidden:YES animated:NO];
	CGRect frame = window.frame;
	frame.origin.y = window.frame.origin.y+window.frame.size.height-1;
	frame.size.height = 1;
	tabBar.frame = frame;
	CGRect navFrame = [navigationController view].frame;
	navFrame.origin.y = 0;
	navFrame.size.height = 480;
	[navigationController view].frame = navFrame;
	navigationController.navigationBarHidden = TRUE;
	navigationController.navigationBar.hidden = TRUE;

	gp2x_pad_status = 0;
	
	if ([[[self navigationController] viewControllers] containsObject:SOApp.nowPlayingView]) {
		[[self navigationController] popToViewController:SOApp.nowPlayingView animated:NO];
	} else {
		[[self navigationController] pushViewController:SOApp.nowPlayingView animated:NO];
	}
}
- (void)switchToRecent {
	[[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
	CGRect frame = window.frame;
	frame.origin.y = window.frame.origin.y+window.frame.size.height-49;
	frame.size.height = 49;
	tabBar.frame = frame;
	CGRect navFrame = [navigationController view].frame;
	navFrame.origin.y = 20;
	navFrame.size.height = 460 - 49;
	[navigationController view].frame = navFrame;
	navigationController.navigationBarHidden = FALSE;
	navigationController.navigationBar.hidden = FALSE;
	
	if ([[[self navigationController] viewControllers] containsObject:SOApp.recentView]) {
		[[self navigationController] popToViewController:SOApp.recentView animated:NO];
	} else {
		[[self navigationController] pushViewController:SOApp.recentView animated:NO];
	}
}
- (void)applicationWillTerminate:(UIApplication *)application {
	// Save data if appropriate
}

- (void)dealloc {
	[ navigationController release ];
	[ window release ];
	[ super dealloc ];
}

@end
