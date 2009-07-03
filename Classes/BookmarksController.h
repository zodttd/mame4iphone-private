//
//  BookmarksController.h
//  ShoutOut
//
//  Created by ME on 9/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BookmarksController : UIViewController < UITableViewDataSource, UITableViewDelegate, AdMobDelegate > {
	IBOutlet UITableView		* tableview;
	IBOutlet UITabBar			* tabBar;
	IBOutlet UITextField		* textBookmark;
	IBOutlet UIWindow			* window;
	NSMutableArray				* bookmarksArray;
	AdMobView					* adMobView;
	NSUInteger					  adNotReceived;
}

- (void)getBookmarks;
- (void)addBookmark:(NSString*)thisServer withId:(NSString*)thisId withTunein:(NSString*)thisTunein withBookmark:(NSString*)thisBookmark withPath:(NSString*)thisPath withFile:(NSString*)thisFile withDir:(NSString*)thisDir;
- (NSString*)getDocumentsDirectory;

@end
