//
//  KCOperation.m
//  KCOperation
//
//  Created by Chiang ML on 2018/7/19.
//  Copyright © 2018 Chiang ML. All rights reserved.
//

#import "KCOperation.h"

@interface KCOperation () {
    BOOL executing;
    BOOL finished;
}
- (void)completeOperation;

@property (nonatomic) dispatch_semaphore_t semaphore;
@property (copy) void (^jobHandler)(KCOperation *operation);
@property (copy) void (^cancelHandler)(KCOperation *operation);

@end

@implementation KCOperation

- (instancetype)initWithJobHandler:(void (^)(KCOperation *operation))jobHandler
                     cancelHandler:(void (^)(KCOperation *operation))cancelHandler {
    self = [super init];
    if (self) {
        executing = NO;
        finished = NO;
        self.jobHandler = jobHandler;
        self.cancelHandler = cancelHandler;
    }

    return self;
}

- (void)start {
    // Always check for cancellation before launching the task.
    if ([self isCancelled]) {
        // Must move the operation to the finished state if it is canceled.
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];

        return;
    }

    // If the operation is not canceled, begin executing the task.
    [self willChangeValueForKey:@"isExecuting"];
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)main {
    @try {
        if (NO == self.isReady) {
            [NSException raise:NSInternalInconsistencyException format:@"Attempt to start %@ before it was ready", NSStringFromClass(self.class)];
        }
        // Do the main work of the operation here.
        if (self.jobHandler) {
            self.jobHandler(self);
            dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        } else {
            [self completeOperation];
        }
    } @catch (NSException *exception) {
        // Do not rethrow exceptions.
        NSLog(@"operation exception: %@", exception);
    }
}

- (BOOL)isAsynchronous {
    return YES;
}

- (void)cancel {
    [super cancel];
    if (self.jobHandler) {
        [self nextStep];
    }
    if (self.cancelHandler) {
        self.cancelHandler(self);
    }
}

#pragma mark - public method

- (void)nextStep {
    dispatch_semaphore_signal(self.semaphore);
    [self completeOperation];
}

- (void)completeOperation {
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];

    executing = NO;
    finished = YES;

    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

#pragma mark - getter

- (dispatch_semaphore_t)semaphore {
    if (nil == _semaphore) {
        _semaphore = dispatch_semaphore_create(0);
    }

    return _semaphore;
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isExecuting {
    return executing;
}

- (BOOL)isFinished {
    return finished;
}

@end
