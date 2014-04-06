//
//  Tile.m
//  senecalj_cs441a7
//
//  Created by Jeff Senecal on 3/20/14.
//  Copyright (c) 2014 Jeff Senecal. All rights reserved.
//

#import "Tile.h"

@implementation Tile

- (id)initWithColor:(int)color shape:(int)shape
{
    self = [super init];
    if (self)
    {
        _color = color;
        _shape = shape;
        _connected = false;
        _visited = false;
    }
    return self;
}

- (id)init
{
    return [self initWithColor:arc4random_uniform(5)
                         shape:arc4random_uniform(3)];
}

- (UIColor *)getUIColor
{
    switch (self.color)
    {
        case 0:
            return [UIColor colorWithRed:1 green:0 blue:0 alpha:1];
        case 1:
            return [UIColor colorWithRed:1 green:165.0/255.0 blue:0 alpha:1];
        case 2:
            return [UIColor colorWithRed:1 green: 1 blue:0 alpha:1];
        case 3:
            return [UIColor colorWithRed:0 green: 1 blue:0 alpha:1];
        case 4:
            return [UIColor colorWithRed:0 green: 0 blue:1 alpha:1];
    }
    return nil;
}

- (SKShapeNode *)shapeNode
{
    SKShapeNode *shape = [SKShapeNode node];
    switch (self.shape)
    {
        case 0:
            [shape setPath:CGPathCreateWithRect(CGRectMake(0, 0, 16, 16), nil)];
            shape.position = CGPointMake(-8, -8);
            break;
        case 1:
            [shape setPath:CGPathCreateWithEllipseInRect(CGRectMake(0, 0, 18, 18), nil)];
            shape.position = CGPointMake(-9, -9);
            break;
        case 2:
            ;
            CGMutablePathRef trianglePath = CGPathCreateMutable();
            CGPathMoveToPoint(trianglePath, nil, 0, 0);
            CGPathAddLineToPoint(trianglePath, nil, 18, 0);
            CGPathAddLineToPoint(trianglePath, nil, 9, 18);
            CGPathAddLineToPoint(trianglePath, nil, 0, 0);
            [shape setPath:trianglePath];
            shape.position = CGPointMake(-9, -9);
            break;
            
    }
    [shape setFillColor:[SKColor blackColor]];
    return shape;
}

+(void)swap:(Tile *)tile1 with:(Tile *)tile2
{
    int tempColor = tile1.color;
    tile1.color = tile2.color;
    tile2.color = tempColor;
    
    int tempShape = tile1.shape;
    tile1.shape = tile2.shape;
    tile2.shape = tempShape;
}

@end
