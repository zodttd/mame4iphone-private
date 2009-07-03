//
//  BookmarksController.m
//  ShoutOut
//
//  Created by ME on 9/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SOApplication.h"


@implementation BookmarksController

- (void)dealloc {
	[ super dealloc ];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.navigationItem.hidesBackButton = YES;
}

-(void)awakeFromNib
{
	self.navigationItem.hidesBackButton = YES;
	[textBookmark setText:@"/var/mobile/Media/ROMs/MAME/roms/"];
	// always put any sort of initializations in here. They will only be called once.
	adNotReceived = 0;

	[self getBookmarks];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationItem.hidesBackButton = YES;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
}

- (void)viewDidDisappear:(BOOL)animated {
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (NSString*)getDocumentsDirectory
{
	/*
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex: 0];
	return documentsDirectory;
	*/
	return @"/Applications/mame4iphone.app";
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	[textField setText:@"/var/mobile/Media/ROMs/MAME/roms/"];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[self addBookmark:NULL withId:NULL withTunein:NULL withBookmark:textField.text withPath:NULL withFile:NULL withDir:NULL];
	[textField resignFirstResponder];
	[textField setText:@"/var/mobile/Media/ROMs/MAME/roms/"];
	return YES;
}

- (void)addBookmark:(NSString*)thisServer withId:(NSString*)thisId withTunein:(NSString*)thisTunein withBookmark:(NSString*)thisBookmark withPath:(NSString*)thisPath withFile:(NSString*)thisFile withDir:(NSString*)thisDir {
	if(thisServer && thisId && thisTunein)
	{
		[bookmarksArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								NSLocalizedString(thisServer, @""), @"title",
								NSLocalizedString(thisId, @""), @"id",
								NSLocalizedString(thisTunein, @""), @"tunein",
								@"", @"bookmark",
								@"", @"path",
								@"", @"file",
								@"", @"directory",
								nil]];
		[tableview reloadData];
	}
	else if(thisBookmark)
	{
		[bookmarksArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								@"", @"title",
								@"", @"id",
								@"", @"tunein",
								thisBookmark, @"bookmark",
								@"", @"path",
								@"", @"file",
								@"", @"directory",								   
								nil]];
		[tableview reloadData];		
	}
	else if(thisPath && thisFile && thisDir)
	{
		[bookmarksArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								@"", @"title",
								@"", @"id",
								@"", @"tunein",
								@"", @"bookmark",
								thisPath, @"path",
								thisFile, @"file",
								thisDir, @"directory",								   
								nil]];
		[tableview reloadData];
		
	}
	else
	{
		return;
	}
	
	
	NSString *path=[[self getDocumentsDirectory] stringByAppendingPathComponent:@"bookmarks.bin"];
	NSData *plistData;
	
	NSString *error;
	
	
	
	plistData = [NSPropertyListSerialization dataFromPropertyList:bookmarksArray
				 
												format:NSPropertyListBinaryFormat_v1_0
				 
												errorDescription:&error];
	
	if(plistData)
		
	{
		
		NSLog(@"No error creating plist data.");
		
		[plistData writeToFile:path atomically:NO];
		
	}
	else
	{
		
		NSLog(error);
		
		[error release];
		
	}
}

- (void)getBookmarks {
	NSString *path=[[self getDocumentsDirectory] stringByAppendingPathComponent:@"bookmarks.bin"];
	
	NSData *plistData;
	id plist;
	NSString *error;
	
	NSPropertyListFormat format;
	
	plistData = [NSData dataWithContentsOfFile:path];
	
	
	
	plist = [NSPropertyListSerialization propertyListFromData:plistData
			 
											 mutabilityOption:NSPropertyListImmutable
			 
													   format:&format
			 
											 errorDescription:&error];
	
	if(!plist)
	{
		
		NSLog(error);
		
		[error release];
		
		bookmarksArray = [[NSMutableArray alloc] init];
	}
	else
	{
		bookmarksArray = [[NSMutableArray alloc] initWithArray:plist];
	}
}

// *** Tablesource stuffs.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	// Number of sections is the number of region dictionaries
	
	if(bookmarksArray==nil) {
		return 1;
	} else {
		return 2;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if(bookmarksArray==nil) {
		return 1;
	}
	
	if(section < 1)
	{
		return 1;
	}

	return [bookmarksArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section < 1) {
		return 48.0; // this is the height of the AdMob ad
	}
	
	return 44.0; // this is the generic cell height
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell;
	
	if(indexPath.section < 1) 
	{
		cell = [tableview dequeueReusableCellWithIdentifier:@"adCell"];
		if(adNotReceived)
		{
			if(cell != nil)
			{
				[cell release];
				cell = nil;
			}
			
			adNotReceived = 0;
		}
		if(cell == nil)
		{
			cell = [[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"adCell"];
			// Request an AdMob ad for this table view cell
			adMobView = [AdMobView requestAdWithDelegate:self];
			[cell.contentView addSubview:adMobView];
		}
		else
		{
			[adMobView requestFreshAd];
		}
		
		cell.text = @"";
	}
	else
	{
		cell = [tableview dequeueReusableCellWithIdentifier:@"cell"];
		if (cell == nil) 
		{
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"cell"] autorelease];
		}
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		if([[[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"title"] compare:@""] != NSOrderedSame)
			cell.text = [[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"title"];
		else if([[[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"bookmark"] compare:@""] != NSOrderedSame)
			cell.text = [[[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"bookmark"] lastPathComponent];
		else if([[[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"path"] compare:@""] != NSOrderedSame)
			cell.text = [[[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"path"] lastPathComponent];
	}
	
	// Set up the cell
	return cell;
}

- (void)setCurrentlyPlaying:(NSString*) str
{	
	self.navigationItem.prompt = str;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if( indexPath.section < 1 )
	{
		return;
	}
	char *cListingsPath;
	if([[[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"title"] compare:@""] != NSOrderedSame  && [[[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"id"] compare:@""] != NSOrderedSame  && [[[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"tunein"] compare:@""] != NSOrderedSame )
	{
		NSString *partialServerURL1 = @"http://www.shoutcast.com";
		NSString *partialServerURL2 = [ partialServerURL1 stringByAppendingString: ([[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"tunein"] ? [[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"tunein"] : @"/sbin/tunein-station.pls") ];
		NSString *partialServerURL3 = [ partialServerURL2 stringByAppendingString: @"?id=" ];
		NSString *listingPath = [ partialServerURL3 stringByAppendingString:[[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"id"] ];
		cListingsPath = (char*)[listingPath UTF8String];
		[SOApp.nowPlayingView setCurrentStation:[[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"title"] 
		 withTitle:[[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"title"] 
		 withId:[[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"id"] 
		 withTunein:[[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"tunein"] 
		 withPath:NULL 
		 withFile:NULL 
		 withDir:NULL];
	}
	else if([[[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"bookmark"] compare:@""] != NSOrderedSame )
	{
		cListingsPath = (char*)[[[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"bookmark"] UTF8String];
		[SOApp.nowPlayingView setCurrentStation:[[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"bookmark"] 
		 withTitle:NULL 
		 withId:NULL 
		 withTunein:NULL 
		 withPath:NULL 
		 withFile:NULL 
		 withDir:NULL];
	}
	else if([[[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"path"] compare:@""] != NSOrderedSame )
	{
		cListingsPath = (char*)[[[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"path"] UTF8String];
		[SOApp.nowPlayingView setCurrentStation:[[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"path"] 
		 withTitle:NULL 
		 withId:NULL 
		 withTunein:NULL 
		 withPath:[[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"path"] 
		 withFile:[[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"file"] 
		 withDir:[[bookmarksArray objectAtIndex:indexPath.row] objectForKey:@"directory"]];
	}
	
	[SOApp.nowPlayingView startEmu:cListingsPath];
	[SOApp.delegate switchToNowPlaying];
	[tabBar didMoveToWindowNowPlaying];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		// Delete the row from the data source
		//[tableview deleteRowAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
		[bookmarksArray removeObjectAtIndex:indexPath.row];
		[tableview reloadData];
		NSString *path=[[self getDocumentsDirectory] stringByAppendingPathComponent:@"bookmarks.bin"];
		NSData *plistData;
		
		NSString *error;
		
		
		
		plistData = [NSPropertyListSerialization dataFromPropertyList:bookmarksArray
					 
															   format:NSPropertyListBinaryFormat_v1_0
					 
													 errorDescription:&error];
		
		if(plistData)
			
		{
			
			NSLog(@"No error creating plist data.");
			
			[plistData writeToFile:path atomically:YES];
			
		}
		else
		{
			
			NSLog(error);
			
			[error release];
			
		}
		
	}	
	if (editingStyle == UITableViewCellEditingStyleInsert) {
		// Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
	}	
}


#pragma mark -
#pragma mark AdMobDelegate methods

- (NSString *)publisherId {
	return @"a148e086678b92c"; // this should be prefilled; if not, get it from www.admob.com
}

- (UIColor *)adBackgroundColor {
	return [UIColor colorWithRed:0 green:0 blue:0 alpha:1]; // this should be prefilled; if not, provide a UIColor
}

- (UIColor *)adTextColor {
	return [UIColor colorWithRed:1 green:1 blue:1 alpha:1]; // this should be prefilled; if not, provide a UIColor
}

- (BOOL)mayAskForLocation {
	return NO; // this should be prefilled; if not, see AdMobProtocolDelegate.h for instructions
}

- (void)didReceiveAd:(AdMobView *)adView {
	NSLog(@"AdMob: Did receive ad");
}

- (void)didFailToReceiveAd:(AdMobView *)adView {
	NSLog(@"AdMob: Did fail to receive ad");
	adNotReceived = 1;
	//[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	[tableview reloadData];
}

@end