//
//  MRSubmitButton.m
//  parkinator
//
//  Created by Mikhail Zinov on 07.11.15.
//  Copyright © 2015 Anton Zlotnikov. All rights reserved.
//

#import "MRSubmitButton.h"
#import "MRConsts.h"
#import <QuartzCore/QuartzCore.h>

@implementation MRSubmitButton

- (instancetype)init
{
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    [self setStyle];
    
    return self;
}

- (void)setStyle {
    [self setBackgroundColor:orangeColor];
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.titleLabel setFont:[UIFont systemFontOfSize:18]];
    [self.layer setCornerRadius:2.0f];
    [self setClipsToBounds:YES];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    [self setStyle];

    return self;
}

@end
