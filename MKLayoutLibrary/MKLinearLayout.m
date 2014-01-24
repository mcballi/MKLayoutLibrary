//
//  MKLinearLayout.m
//  MKLayout
//
//  Created by Martin Klöppner on 1/10/14.
//  Copyright (c) 2014 Martin Klöppner. All rights reserved.
//

#import "MKLinearLayout.h"

@interface MKLinearLayout ()

// Transient, outdated after layout
@property (assign, nonatomic) CGRect bounds;

@end

@implementation MKLinearLayout

- (instancetype)initWithView:(UIView *)view
{
    self = [super initWithView:view];
    if (self) {
        self.orientation = MKLinearLayoutOrientationHorizontal;
    }
    return self;
}

- (MKLinearLayoutItem *)addSubview:(UIView *)subview
{
    MKLinearLayoutItem *item = [[MKLinearLayoutItem alloc] initWithLayout:self subview:subview];
    [self addLayoutItem:item];
    return item;
}

- (MKLinearLayoutItem *)addSublayout:(MKLayout *)sublayout
{
    MKLinearLayoutItem *item = [[MKLinearLayoutItem alloc] initWithLayout:self sublayout:sublayout];
    [self addLayoutItem:item];
    return item;
}

- (void)layoutBounds:(CGRect)bounds
{
    self.bounds = bounds;
    
    float currentPos = 0.0f;
    float overallWeight = 0.0f;
    float overallLength = 0.0f;
    
    [self calculateOverallWeight:&overallWeight overallLength:&overallLength];
    
    float contentLength = [self lengthForOrientation:self.orientation];
    
    for (int i = 0; i < self.items.count; i++) {
        
        MKLinearLayoutItem *item = self.items[i];
        
        CGRect rect = CGRectMake(0.0f, 0.0f, 0.0f, 0.0f);
        
        // Apply current position]
        if (self.orientation == MKLinearLayoutOrientationHorizontal) {
            rect.origin.x = currentPos;
        } else {
            rect.origin.y = currentPos;
        }
        
        // Calculate absolute size
        rect.size.width = [self lengthForItem:item orientation:MKLinearLayoutOrientationHorizontal overallWeight:overallWeight overallLength:overallLength contentLength:contentLength];
        rect.size.height = [self lengthForItem:item orientation:MKLinearLayoutOrientationVertical overallWeight:overallWeight overallLength:overallLength contentLength:contentLength];
        
        // Apply offset for recursive layout calls in order to achieve sublayouts
        rect.origin.x += self.bounds.origin.x;
        rect.origin.y += self.bounds.origin.y;
        
        // Move the cursor in order to reserve the whole rectance for the current item view.
        currentPos += [self lengthFromRect:rect orientation:self.orientation];
        
        // Get the total reserved item frame in order to apply inner gravity without nesting subviews 
        CGRect reservedItemSpace = [self reservedTotalSpaceForRect:rect];
        
        // Apply the margin in order to achive spacings around the item view
        rect = UIEdgeInsetsInsetRect(rect, item.margin);
        reservedItemSpace = UIEdgeInsetsInsetRect(reservedItemSpace, item.margin);
        
        // Apply gravity
        rect = [self applyGravity:item.gravity withRect:rect withinRect:reservedItemSpace];
        
        if (item.subview) {
            item.subview.frame = rect;
        } else if (item.sublayout) {
            [item.sublayout layoutBounds:rect];
        }
    
    }
    
    self.bounds = CGRectMake(0.0f, 0.0f, 0.0f, 0.0f);
}

- (CGRect)reservedTotalSpaceForRect:(CGRect)rect
{
    MKLinearLayoutOrientation orientation = MKLinearLayoutOrientationVertical;
    
    if (self.orientation == MKLinearLayoutOrientationHorizontal) {
        orientation = MKLinearLayoutOrientationVertical;
    } else if (self.orientation == MKLinearLayoutOrientationVertical) {
        orientation = MKLinearLayoutOrientationHorizontal;
    } else {
        [NSException raise:@"Unknown state exception" format:@"Can't calculate the length for orientation %i", orientation];
    }
    
    if (orientation == MKLinearLayoutOrientationHorizontal) {
        rect.size.width = self.bounds.size.width;
    } else if (orientation == MKLinearLayoutOrientationVertical) {
        rect.size.height = self.bounds.size.height;
    } else {
        [NSException raise:@"Unknown state exception" format:@"Can't calculate the length for orientation %i", orientation];
    }
    
    return rect;
}

- (CGFloat)lengthForItem:(MKLinearLayoutItem *)item orientation:(MKLinearLayoutOrientation)orientation overallWeight:(CGFloat)overallWeight overallLength:(CGFloat)overallLength contentLength:(CGFloat)contentLength
{
    float itemLength = [self pointsForOrientation:orientation fromItem:item];
    
    // Weight is used to achieve the arrangement in a linear layout horizontal or vertical.
    // A linear layout is not capable to arrange items both horizontal and vertical. If its neccessary to align views, please use the corrensponding alignment properties.
    // So just calculate the size by weight if the orientation fits.
    if (orientation == self.orientation) {
        if (item.weight != kMKLinearLayoutWeightInvalid) {
            float percent = item.weight / overallWeight;
            
            float boundsWithoutAbsoluteSizes = contentLength - overallLength;
            itemLength = boundsWithoutAbsoluteSizes * percent;
        }
    }
    return itemLength;
}

/**
 * Gathers the total weights and the total points in order to achieve relative layouting
 *
 * @discussion
 *
 * Obviously, the overall weight is used to calculate the total amount of relative layout items. The percentage of the space beeing used for an item
 * is the total space minus the available space.
 *
 * Available space is all the space that is not reserved for absolute sized layout items.
 *
 * Therefore it is also neccessary to gather the total amount of space used by all layout items using the total size.
 */
- (void)calculateOverallWeight:(CGFloat *)overallWeight overallLength:(CGFloat *)overallPoints
{
    for (int i = 0; i < self.items.count; i++) {
        MKLinearLayoutItem *item = self.items[i];
        if (item.weight != kMKLinearLayoutWeightInvalid) {
            *overallWeight += item.weight;
        } else {
            *overallPoints += [self pointsForOrientation:self.orientation fromItem:item];
        }
    }
}

/**
 * Extract flags for absolute sizes and replaces them with their point pendants
 *
 * @discussion
 *
 * Extract all your flags, such as match_parent and gets the length for it.
 */
- (CGFloat)pointsForOrientation:(MKLinearLayoutOrientation)orientation fromItem:(MKLinearLayoutItem *)item
{
    CGFloat points =  orientation == MKLinearLayoutOrientationHorizontal ? item.size.width : item.size.height;
    if (points == kMKLinearLayoutSizeValueMatchParent) {
        points = [self lengthForOrientation:orientation];
    }
    return points;
}

- (CGFloat)lengthForOrientation:(MKLinearLayoutOrientation)orientation
{
    return [self lengthFromRect:self.bounds orientation:orientation];
}

- (CGFloat)lengthFromRect:(CGRect)rect orientation:(MKLinearLayoutOrientation)orientation
{
    switch (orientation) {
        case MKLinearLayoutOrientationHorizontal:
            return rect.size.width;
            break;
        case MKLinearLayoutOrientationVertical:
            return rect.size.height;
            
        default:
            break;
    }
    [NSException raise:@"Unknown state exception" format:@"Can't calculate the length for orientation %i", orientation];
}

@end
