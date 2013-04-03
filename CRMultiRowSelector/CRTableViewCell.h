//
//  CRTableViewCell.h
//  CRMultiRowSelector
//
//  Created by Christian Roman on 6/17/12.
//  Copyright (c) 2012 chroman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CRTableViewCell : UITableViewCell

@property (nonatomic, assign) BOOL alwaysShowMark;
@property (nonatomic, assign, getter = isBorderHidden) BOOL borderHidden;
@property (nonatomic, assign, getter = isMarked) BOOL marked;
@property (nonatomic, readonly, strong) UIImageView *markView;
@property (nonatomic, readonly, strong) UIImage *markedImage;
@property (nonatomic, readonly, strong) UIImage *unmarkedImage;
@property (nonatomic, strong) UIColor *markColor;
@property (nonatomic, strong) UIColor *borderColor;

@end