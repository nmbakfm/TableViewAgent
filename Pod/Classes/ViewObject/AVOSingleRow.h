//
// Created by P.I.akura on 2013/08/18.
// Copyright (c) 2013 P.I.akura. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "AgentViewObjectProtocol.h"

@interface AVOSingleRow : NSObject <AgentViewObjectProtocol>
@property(strong, nonatomic) id viewObject;
@property(weak, nonatomic) TableViewAgent *agent;
@property(copy, nonatomic) id(^convert)(id);

- (id)initWithViewObject:(id)viewObject;
@end