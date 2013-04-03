//
//  CRTableViewCell.m
//  CRMultiRowSelector
//
//  Created by Christian Roman on 6/17/12.
//  Copyright (c) 2012 chroman. All rights reserved.
//

#import "CRTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

/* Macro for background colors */
#define colorWithRGBHex(hex)[UIColor colorWithRed:((float)((hex&0xFF0000)>>16))/255.0 green:((float)((hex&0xFF00)>>8))/255.0 blue:((float)(hex&0xFF))/255.0 alpha:1.0]
#define clearColorWithRGBHex(hex)[UIColor colorWithRed:MIN((((int)(hex>>16)&0xFF)/255.0)+.1,1.0)green:MIN((((int)(hex>>8)&0xFF)/255.0)+.1,1.0)blue:MIN((((int)(hex)&0xFF)/255.0)+.1,1.0)alpha:1.0]

/* Unselected mark constants */
#define kCircleRect                 CGRectMake(3.5, 2.5, 22.0, 22.0)
#define kCircleRectUnselected       CGRectMake(3.5, 2.5, 23.0, 23.0)
#define kCircleOverlayRect          CGRectMake(1.5, 12.5, 26.0, 23.0)

/* Mark constants */
#define kStrokeWidth                2.0
#define kShadowRadius               4.0
#define kMarkDegrees                70.0
#define kMarkWidth                  3.0
#define kMarkHeight                 6.0
#define kShadowOffset               CGSizeMake(.0, 2.0)
#define kMarkShadowOffset           CGSizeMake(.0, -1.0)
#define kMarkImageSize              CGSizeMake(30.0, 30.0)
#define kMarkBase                   CGPointMake(9.0, 13.5)
#define kMarkDrawPoint              CGPointMake(20.0, 9.5)
#define kShadowColor                [UIColor colorWithWhite:.0 alpha:0.7]
#define kMarkShadowColor            [UIColor colorWithWhite:.0 alpha:0.3]
#define kBlueColor                  0x236ed8
#define kGreenColor                 0x179714
#define kRedColor                   0xa4091c

/* Colums and cell constants */
#define kAnimationDuration			1.0
#define kColumnPosition             44.0

/* Macro for float comparison */
#ifndef float_epsilon
	#define float_epsilon 0.01
#endif
#ifndef float_equal
	#define float_equal(a,b) (fabs((a) - (b)) < float_epsilon)
#endif

@interface CRTableViewCell () {
	NSUInteger markColor;
	
	CALayer *_borderLayer;
	UIView *_backgroundMarkView;
	UIImage *_backgroundDefault;
	UIImage *_backgroundHighlighted;
	UIImage *_selectedImage;
	UIImage *_unselectedImage;
}

@end

@implementation CRTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {		
        _markView = [[UIImageView alloc] init];
		[_markView setContentMode:UIViewContentModeCenter];
		[_markView setOpaque:YES];
		[_markView setUserInteractionEnabled:YES];
		[_markView setBackgroundColor:[UIColor clearColor]];
		
		_borderLayer = [CALayer layer];
		[_borderLayer setBackgroundColor:[[UIColor colorWithRed:224/255.0 green:224/255.0 blue:224/255.0 alpha:1.0] CGColor]];
		[[_markView layer] addSublayer:_borderLayer];
		
		_backgroundMarkView = [[UIView alloc] init];
		[_backgroundMarkView setUserInteractionEnabled:YES];
		[_backgroundMarkView setOpaque:YES];
		
		markColor = kBlueColor;
		
		_backgroundDefault = nil;
		_backgroundHighlighted = nil;
		
		_selectedImage = nil;
		_unselectedImage = nil;
		
		[self setMarked:NO];
		[self setAlwaysShowMark:YES];
    }
	
    return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if (!_alwaysShowMark) {
		[_backgroundMarkView setFrame:CGRectMake(-27.0, 0.0, 32.0, self.contentView.frame.size.height)];
		[_markView setFrame:[_backgroundMarkView frame]];
	} else {
		[_markView setFrame:CGRectMake(0.0, 0.0, kColumnPosition, self.contentView.frame.size.height)];
	}
	
	[_borderLayer setFrame:CGRectMake(_markView.frame.size.width-1.0, _markView.frame.origin.y, 1.0, _markView.frame.size.height)];
	
	[self updateMarkViewIfNeeded];
}

- (void)willTransitionToState:(UITableViewCellStateMask)state {
	[super willTransitionToState:state];
	
	if (!_alwaysShowMark && state & UITableViewCellStateShowingEditControlMask && !(state & UITableViewCellStateShowingDeleteConfirmationMask)) {
		[self.contentView addSubview:_backgroundMarkView];
		[self.contentView insertSubview:_markView aboveSubview:_backgroundMarkView];
	} else if (_alwaysShowMark && state & UITableViewCellStateShowingEditControlMask && !(state & UITableViewCellStateShowingDeleteConfirmationMask)) {
		[UIView animateWithDuration:kAnimationDuration
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseOut
						 animations:^{
							 [_markView setAlpha:0.0];
							 [self setIndentationLevel:0];
							 [self setIndentationWidth:kColumnPosition];}
						 completion:nil];
	} else if (_alwaysShowMark && state == UITableViewCellStateDefaultMask) {
		[UIView animateWithDuration:kAnimationDuration
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseOut
						 animations:^{
							 [_markView setAlpha:1.0];
							 [self setIndentationLevel:1];
							 [self setIndentationWidth:kColumnPosition];}
						 completion:nil];
	}
}

- (void)didTransitionToState:(UITableViewCellStateMask)state {
	[super didTransitionToState:state];
	
	if (!_alwaysShowMark && state == UITableViewCellStateDefaultMask) {
		[_backgroundMarkView removeFromSuperview];
		[_markView removeFromSuperview];
	}
}


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	if (!_alwaysShowMark && _backgroundMarkView.superview && CGRectContainsPoint(CGRectOffset(_backgroundMarkView.frame, _backgroundMarkView.frame.size.width, 0.0), point)) {
		return _backgroundMarkView;
	}
	
	return [super hitTest:point withEvent:event];
}

#pragma mark - Properties

- (void)setMarkColor:(UIColor *)markColor_ {
	CGFloat red;
	CGFloat green;
	CGFloat blue;
	
	[markColor_ getRed:&red green:&green blue:&blue alpha:NULL];
	
	NSUInteger color = (int)(red * 255) << 16 | (int)(green * 255) << 8 | (int)(blue * 255) << 0;
	if (color != markColor) {
		markColor = color;
		_selectedImage = nil;
		_unselectedImage = nil;
	}
}

- (UIColor *)markColor {
	return colorWithRGBHex(markColor);
}

- (void)setAlwaysShowMark:(BOOL)alwaysShowMark {
	if (alwaysShowMark && !_alwaysShowMark) {
		[_backgroundMarkView removeFromSuperview];
		[self.contentView addSubview:_markView];
		[self setIndentationLevel:1];
		[self setIndentationWidth:kColumnPosition];
	} else if (!alwaysShowMark && _alwaysShowMark) {
		[_markView setAlpha:1.0];
		[self setIndentationLevel:0];
		[self setIndentationWidth:kColumnPosition];
	}
	
	_alwaysShowMark = alwaysShowMark;
}

- (void)setMarked:(BOOL)marked {
	_marked = marked;
	
	[_markView setImage:(_marked ? self.markedImage : self.unmarkedImage)];
}

- (UIImage *)unmarkedImage {
    if(_unselectedImage) {
		return _unselectedImage;
	}
	    
    UIGraphicsBeginImageContextWithOptions(kMarkImageSize, NO, [[UIScreen mainScreen] scale]);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    UIBezierPath *markCircle = [UIBezierPath bezierPathWithOvalInRect:kCircleRectUnselected];
    
    /* Background */
    CGContextSaveGState(ctx);
    {
        CGContextAddPath(ctx, markCircle.CGPath);
        CGContextSetLineWidth(ctx, kStrokeWidth);
        CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 0.0);
        CGContextSetRGBStrokeColor(ctx, 229/255.0, 229/255.0, 229/255.0, 1.0);
        CGContextDrawPath(ctx, kCGPathFillStroke);
    }
    CGContextRestoreGState(ctx);
	
    UIImage *unselectedMark = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
	_unselectedImage = unselectedMark;
	
    return unselectedMark;
}

- (UIImage *)markedImage {
    if(_selectedImage) {
        return _selectedImage;
	}
	    
    UIGraphicsBeginImageContextWithOptions(kMarkImageSize, NO, [[UIScreen mainScreen] scale]);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    UIBezierPath *markCircle = [UIBezierPath bezierPathWithOvalInRect:kCircleRect];
    
    /* Background */
    CGContextSaveGState(ctx);
    {
        CGContextAddPath(ctx, markCircle.CGPath);
        CGContextSetFillColorWithColor(ctx, clearColorWithRGBHex(markColor).CGColor);
        CGContextSetShadowWithColor(ctx, kShadowOffset, kShadowRadius, kShadowColor.CGColor );
        CGContextDrawPath(ctx, kCGPathFill);
    }
    CGContextRestoreGState(ctx);
    
    /* Overlay */
    CGContextSaveGState(ctx);
    {
        CGContextAddPath(ctx, markCircle.CGPath);
        CGContextClip(ctx);
        CGContextAddEllipseInRect(ctx, kCircleOverlayRect);
        CGContextSetFillColorWithColor(ctx, colorWithRGBHex(markColor).CGColor);
        CGContextDrawPath(ctx, kCGPathFill);
    }
    CGContextRestoreGState(ctx);
    
    /* Stroke */
    CGContextSaveGState(ctx);
    {
        CGContextAddPath(ctx, markCircle.CGPath);
        CGContextSetLineWidth(ctx, kStrokeWidth);
        CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
        CGContextDrawPath(ctx, kCGPathStroke);
    }
    CGContextRestoreGState(ctx);
    
    /* Mark */
    CGContextSaveGState(ctx);
    {
        CGContextSetShadowWithColor(ctx, kMarkShadowOffset, 0.0, kMarkShadowColor.CGColor );
        CGContextMoveToPoint(ctx, kMarkBase.x, kMarkBase.y);
        CGContextAddLineToPoint(ctx, kMarkBase.x + kMarkHeight * sin(kMarkDegrees), kMarkBase.y + kMarkHeight * cos(kMarkDegrees));
        CGContextAddLineToPoint(ctx, kMarkDrawPoint.x, kMarkDrawPoint.y);
        CGContextSetLineWidth(ctx, kMarkWidth);
        CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
        CGContextStrokePath(ctx);
    }
    CGContextRestoreGState(ctx);
    
    UIImage *selectedMark = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	
	_selectedImage = selectedMark;
    
    return selectedMark;
}

#pragma mark - Private

- (void)updateMarkViewIfNeeded {
	if ([_backgroundMarkView superview]) {
		[self bringSubviewToFront:self.contentView];
		
		if (![self isHighlighted] && ![self isSelected]) {
			if (!_backgroundDefault || (_backgroundDefault && !float_equal(_backgroundDefault.size.height, self.contentView.frame.size.height))) {
				if (self.backgroundView) {
					_backgroundDefault = [self takeScreenshot:self.backgroundView frame:[self.backgroundView convertRect:_backgroundMarkView.frame fromView:_backgroundMarkView.superview]];
				} else {
					CGSize imageSize = _backgroundMarkView.frame.size;
					UIGraphicsBeginImageContextWithOptions(imageSize, YES, [[UIScreen mainScreen] scale]);
					CGContextRef ctx = UIGraphicsGetCurrentContext();
					
					CGContextSaveGState(ctx);
					{
						CGContextSetFillColorWithColor(ctx, [[self backgroundColor] CGColor]);
						CGContextFillRect(ctx, CGRectMake(0.0, 0.0, imageSize.width, imageSize.height));
					}
					CGContextRestoreGState(ctx);
					
					UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
					UIGraphicsEndImageContext();
					
					_backgroundDefault = image;
				}
			}
		} else if (!_backgroundHighlighted || (_backgroundHighlighted && !float_equal(_backgroundHighlighted.size.height, self.contentView.frame.size.height))) {
			if (self.selectedBackgroundView) {
				_backgroundHighlighted = [self takeScreenshot:self.selectedBackgroundView frame:[self.selectedBackgroundView convertRect:_backgroundMarkView.frame fromView:_backgroundMarkView.superview]];
			} else {
				_backgroundHighlighted = [self takeScreenshot:self frame:CGRectMake(0.0, 0.0, 1.0, self.contentView.frame.size.height)];
			}
		}
		
		CGImageRef backgroundImage;
		if ([self isHighlighted] || [self isSelected]) {
			backgroundImage = [_backgroundHighlighted CGImage];
		} else {
			backgroundImage = [_backgroundDefault CGImage];
		}
		
		if (_backgroundMarkView.layer.contents != (__bridge id)(backgroundImage)) {
			[_backgroundMarkView.layer setContents:(__bridge id)backgroundImage];
			[_backgroundMarkView setNeedsDisplay];
		}
	}
}

- (UIImage *)takeScreenshot:(UIView *)view frame:(CGRect)frame {
	UIGraphicsBeginImageContextWithOptions(frame.size, YES, [[UIScreen mainScreen] scale]);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	CGContextSaveGState(ctx);
	{
		CGContextTranslateCTM(ctx, -frame.origin.x, -frame.origin.y);
		[view.layer renderInContext:UIGraphicsGetCurrentContext()];
	}
	CGContextRestoreGState(ctx);
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}

@end
