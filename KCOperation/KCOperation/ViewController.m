//
//  ViewController.m
//  KCOperation
//
//  Created by Chiang ML on 2018/7/19.
//  Copyright © 2018 Chiang ML. All rights reserved.
//

#import "ViewController.h"
#import "KCOperation.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [self demo];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - demo

- (void)demo {
    NSOperationQueue *jobQueue = [[NSOperationQueue alloc] init];
    jobQueue.suspended = YES;

    // set qualityOfService and maxConcurrentOperationCount
//    jobQueue.qualityOfService = NSQualityOfServiceUserInteractive;
//    jobQueue.maxConcurrentOperationCount = 1;

    KCOperation *lastJob = [[KCOperation alloc] initWithJobHandler:^(KCOperation *operation) {
        [operation nextStep];
        NSLog(@"lastJob finish");
    } cancelHandler:nil];

    KCOperation *firstJob = [[KCOperation alloc] initWithJobHandler:^(KCOperation *operation) {
        // do something async job
        NSLog(@"firstJob start");
        [NSThread sleepForTimeInterval:2];

        NSLog(@"firstJob finish");
        // when async job finish, must call method nextStep to increment the counting semaphore!
        [operation nextStep];
    } cancelHandler:nil];

    KCOperation *secodeJob = [[KCOperation alloc] initWithJobHandler:^(KCOperation *operation) {
        NSLog(@"secodeJob start");
        [NSThread sleepForTimeInterval:2];
        NSLog(@"secodeJob finish");
        [operation nextStep];
    } cancelHandler:nil];

    KCOperation *thirdJob = [[KCOperation alloc] initWithJobHandler:^(KCOperation *operation) {
        NSLog(@"thirdJob start");
        [NSThread sleepForTimeInterval:2];
        [operation cancel];
    } cancelHandler:^(KCOperation *operation) {
        // handle cancel, throw exception or callback error or just pass and do next.
        NSLog(@"thirdJob cancel");

        // when job cancel, must call method nextStep to increment the counting semaphore!
        [operation nextStep];
    }];

    // set operation dependency
    [lastJob addDependency:firstJob];
    [lastJob addDependency:secodeJob];
    [lastJob addDependency:thirdJob];
    [secodeJob addDependency:thirdJob];
    [thirdJob addDependency:firstJob];

    // add operation to queue
    [jobQueue addOperation:lastJob];
    [jobQueue addOperation:firstJob];
    [jobQueue addOperation:secodeJob];
    [jobQueue addOperation:thirdJob];

    // start queue
    jobQueue.suspended = NO;

    /*
     print:

     firstJob start
     firstJob finish
     thirdJob start
     thirdJob cancel
     secodeJob start
     secodeJob finish
     lastJob finish
     */
}

@end
