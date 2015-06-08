//
//  KPBackgroundRunner.m
//  PrettyTunnel
//
//  Created by zhang fan on 14-8-12.
//
//

#import "KPBackgroundRunner.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "NSOperationQueue+GlobalQueue.h"
#import "ErrorCheck.h"

@interface KPBackgroundRunner()
{
	UIBackgroundTaskIdentifier	_bkgTaskId;
	
	dispatch_semaphore_t		_sem;
	__weak NSOperation*			_opt;
}

- (void)_onApplicationDidEnterBackground: (NSNotification*)notification;
- (void)_onApplicationWillEnterForeground: (NSNotification*)notification;

- (void)_start;
- (void)_stop;

@end

@implementation KPBackgroundRunner

- (instancetype)init
{
	self = [super init];
	
	_sem = dispatch_semaphore_create(0);
		
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_onApplicationDidEnterBackground:)
												 name:UIApplicationDidEnterBackgroundNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_onApplicationWillEnterForeground:)
												 name:UIApplicationWillEnterForegroundNotification
											   object:nil];
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	_sem = 0;
}

- (void)_onApplicationDidEnterBackground: (NSNotification*)notification
{
    if (_enable)
        [self _start];
}

- (void)_onApplicationWillEnterForeground: (NSNotification*)notification
{
	if (_opt)
		[self _stop];
}

- (void)_start
{
	// perform background task
	_bkgTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^
	{
		if (UIBackgroundTaskInvalid != _bkgTaskId)
		{
			[[UIApplication sharedApplication] endBackgroundTask:_bkgTaskId];
			_bkgTaskId = UIBackgroundTaskInvalid;
		}
	}];
	
	// play mute music
	NSError* error;
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
	X_ASSERT(!error);
		
	error = nil;
	[[AVAudioSession sharedInstance] setActive:YES error:&error];
	X_ASSERT(!error);
	
	NSURL* muteSoundURL = [[NSBundle mainBundle] URLForResource:@"mute" withExtension:@"mp3"];
	
	error = nil;
	AVAudioPlayer* player = [[AVAudioPlayer alloc] initWithContentsOfURL:muteSoundURL error:&error];
	X_ASSERT(!error);
	
	player.numberOfLoops = -1;
	BOOL ret = [player play];
	X_ASSERT(ret);

	// check stop
	NSBlockOperation* opt = [NSBlockOperation new];
	[opt addExecutionBlock:^
	{
		while (true)
		{
			if (!dispatch_semaphore_wait(_sem, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC))	||
				!_enable)
			{
				[[NSOperationQueue mainQueue] addOperationWithBlock:^
				{
					[player stop];
					[[AVAudioSession sharedInstance] setActive:NO error:nil];
					
					[[UIApplication sharedApplication] endBackgroundTask:_bkgTaskId];
					_bkgTaskId = UIBackgroundTaskInvalid;
				}];
				
				break;
			}
		}
	}];
	
	[[NSOperationQueue globalQueue] addOperation:opt];
	_opt = opt;
}

- (void)_stop
{
	dispatch_semaphore_signal(_sem);
	[_opt waitUntilFinished];
	_opt = nil;
}

@end
