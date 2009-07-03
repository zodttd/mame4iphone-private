//
//  main.m
//  ShoutOut
//
//  Created by Spookysoft on 9/6/08.
//  Copyright Spookysoft 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <iControlpad.h>

pthread_t controller_tid;

void* controller_Thread_Start(void *args) 
{
    THREAD_Init_iControlPad();
    return NULL;
}

int main(int argc, char *argv[]) {
	
	pthread_create(&controller_tid, NULL, controller_Thread_Start, NULL);
	Cmd_iControlPad(CMD_SERIALINIT);
	usleep(1000000);
	Cmd_iControlPad(CMD_INIT);
	usleep(1500000);
	Cmd_iControlPad(CMD_TX);
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	UIApplicationUseLegacyEvents(1);
	int retVal = UIApplicationMain(argc, argv, @"SOApplication", nil);
	[pool release];
	
	Cmd_iControlPad(CMD_IDLE);
	Cmd_iControlPad(CMD_DEINIT);  
	pthread_join(controller_tid, NULL);
	
	return retVal;
}
