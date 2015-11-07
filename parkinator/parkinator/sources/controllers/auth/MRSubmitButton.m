//
//  MRSubmitButton.m
//  parkinator
//
//  Created by Mikhail Zinov on 07.11.15.
//  Copyright © 2015 Anton Zlotnikov. All rights reserved.
//

#import "MRSubmitButton.h"
#import "MRConsts.h"

@implementation MRSubmitButton

- (instancetype)init
{
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    [self setBackgroundColor:orangeColor];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.titleLabel setFont:[UIFont systemFontOfSize:18]];
    
    return self;
}

@end