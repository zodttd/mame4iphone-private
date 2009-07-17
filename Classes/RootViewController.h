//
//  RootViewController.h
//  ShoutOut
//
//  Created by Spookysoft on 9/6/08.
//  Copyright Spookysoft 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

extern void *app_Thread_Start(void *args);

@interface RootViewController : UITableViewController {
	NSMutableArray			*browseArray;
	NSMutableArray			*indexedLetters;
	NSMutableArray			*displayList;
	IBOutlet UITableView	*tableView;
	IBOutlet UIWindow		*window;
	IBOutlet UITabBar		*tabBar;
#ifdef WITH_ADS
	AltAds*	 altAds;
#endif
	NSUInteger				adNotReceived;
	NSString*				currentPath;
}

- (void)backClicked:(id)sender;
- (void)refreshData:(NSString*)path;
- (void)setupIndexedData;
- (NSMutableArray*)getDisplayList;
- (void)setCurrentlyPlaying:(NSString*) str;
- (void)initRootData;

@end
