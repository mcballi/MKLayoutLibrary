//
//  MKLinearLayout.h
//  MKLayout
//
//  Created by Martin Klöppner on 1/10/14.
//  Copyright (c) 2014 Martin Klöppner. All rights reserved.
//

#import "MKLayout.h"
#import "MKLinearLayoutItem.h"
#import "MKLinearLayoutSeparatorDelegate.h"

/**
 *  A linear layout places all its children view side by side in a specified direction.
 */
@interface MKLinearLayout : MKLayout

DECLARE_LAYOUT_ITEM_ACCESSORS_WITH_CLASS_NAME(MKLinearLayoutItem)

/**
 * Inserts spacing between the outer border and the different layout items.
 *
 * Reduces the total available space which affects the calculation of relative sizes calculated by weight.
 */
@property (assign, nonatomic) CGFloat spacing;

/**
 * Specifies in which direction the linear layout should place its childs.
 */
@property (assign, nonatomic) MKLayoutOrientation orientation;

/**
 * Separator delegate allows delegate to insert separator images.
 */
@property (assign, nonatomic) id<MKLinearLayoutSeparatorDelegate> separatorDelegate;

@end
