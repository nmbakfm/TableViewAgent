//
// Created by P.I.akura on 2013/08/18.
// Copyright (c) 2013 P.I.akura. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "AgentViewObjectProtocol.h"

@interface SSAgentViewObject : NSObject <AgentViewObjectProtocol>
@property(nonatomic, strong) NSMutableArray *array;

- (id)initWithArray:(NSArray *)array;
@end