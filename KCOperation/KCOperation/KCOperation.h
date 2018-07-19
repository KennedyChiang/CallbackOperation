//
//  KCOperation.h
//  KCOperation
//
//  Created by Chiang ML on 2018/7/19.
//  Copyright © 2018 Chiang ML. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCOperation : NSOperation

- (instancetype)initWithJobHandler:(void (^)(KCOperation *operation))jobHandler
                     cancelHandler:(void (^)(KCOperation *operation))cancelHandler;
- (void)nextStep;

@end
