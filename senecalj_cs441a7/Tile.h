//
//  Tile.h
//  senecalj_cs441a7
//
//  Created by Jeff Senecal on 3/20/14.
//  Copyright (c) 2014 Jeff Senecal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

@interface Tile : NSObject

@property (nonatomic) int color;
@property (nonatomic) int shape;
@property (nonatomic) bool connected;
@property (nonatomic) bool visited;

- (id)init;
- (id)initWithColor:(int)color shape:(int)shape;
- (UIColor *)getUIColor;
- (SKShapeNode *)shapeNode;
+(void)swap:(Tile *)tile1 with:(Tile *)tile2;

@end
