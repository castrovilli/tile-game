//
//  MyScene.m
//  senecalj_cs441a7
//
//  Created by Jeff Senecal on 3/20/14.
//  Copyright (c) 2014 Jeff Senecal. All rights reserved.
//

@import AVFoundation;

#import "MyScene.h"
#import "Tile.h"

@implementation MyScene
{
    NSMutableArray *board;
    int selectedI, selectedJ;
    CFAbsoluteTime dropTime;
    enum {INIT, INSTRUCTIONS, READY, SWAPPING, CHECKING, POPPING, WAITPOP, FILLING, WAITDROP} state;
    SKAction *sfxPop;
    SKAction *sfxDing;
    SKLabelNode *scoreLabel;
    SKSpriteNode *instructionBox;
    int score;
    SKNode *particleLayerNode;
    SKEmitterNode *sparksNode;
    AVAudioPlayer *backgroundMusicPlayer;
}

-(id)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size])
    {
        state = INIT;
        selectedI = selectedJ = -1;
        score = 0;
        
        NSURL *backgroundMusicURL = [[NSBundle mainBundle] URLForResource:@"theme.wav" withExtension:nil];
        backgroundMusicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:backgroundMusicURL error:nil];
        backgroundMusicPlayer.numberOfLoops = -1;
        backgroundMusicPlayer.volume = 0.1;
        [backgroundMusicPlayer prepareToPlay];
        [backgroundMusicPlayer play];
        
        board = [[NSMutableArray alloc] initWithCapacity:9];
        for (int i = 0; i < 9; i++)
        {
            board[i] = [[NSMutableArray alloc] initWithCapacity:7];
        }
        for (int i = 0; i < 9; i++)
        {
            for (int j = 0; j < 7; j++)
            {
                board[i][j] = [[Tile alloc] init];
            }
        }
        do
        {
            [self unmarkTiles];
            [self markTilesToRemove];
        }
        while ([self deleteConnectedTiles]);
        [self unmarkTiles];
        
        for (int i = 0; i < 9; i++)
        {
            for (int j = 0; j < 7; j++)
            {
                Tile *tile = (Tile *)board[i][j];
                SKShapeNode *tileSprite = [SKShapeNode node];
                [tileSprite setPath:CGPathCreateWithRoundedRect(CGRectMake(-20,-20,40,40), 8, 8, nil)];
                tileSprite.strokeColor = tileSprite.fillColor = [tile getUIColor];
                tileSprite.position = [self tilePosForI:i J:j];
                SKNode *shape = [tile shapeNode];
                shape.name = [NSString stringWithFormat:@"s%d%d", i, j];
                [tileSprite addChild:shape];
                tileSprite.name = [NSString stringWithFormat:@"%d%d", i, j];
                [self addChild:tileSprite];
            }
        }
        dropTime = 0;
        
        sfxPop = [SKAction playSoundFileNamed:@"pop.wav" waitForCompletion:NO];
        sfxDing = [SKAction playSoundFileNamed:@"ding.wav" waitForCompletion:NO];
        
        particleLayerNode = [SKNode node];
        particleLayerNode.zPosition = 100;
        [self addChild:particleLayerNode];
        sparksNode = [NSKeyedUnarchiver unarchiveObjectWithFile:
                      [[NSBundle mainBundle] pathForResource:@"sparks" ofType:@"sks"]];
        sparksNode.position = CGPointMake(self.size.width/2, self.size.height/2);
        
        scoreLabel = [SKLabelNode node];
        scoreLabel.position = CGPointMake(20, self.size.height/2 + 210);
        scoreLabel.fontName = @"Chalkduster";
        scoreLabel.fontSize = 18;
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        [self addChild:scoreLabel];
        
        state = INSTRUCTIONS;
        instructionBox = [SKSpriteNode spriteNodeWithImageNamed:@"instructions.png"];
        instructionBox.position = CGPointMake(self.size.width/2, self.size.height/2);
        instructionBox.zPosition = 100;
        [self addChild:instructionBox];
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (state == INSTRUCTIONS)
    {
        [instructionBox removeFromParent];
        state = READY;
        return;
    }
    
    if (state != READY)
        return;
    
    /* Called when a touch begins */
    UITouch *touch = [touches anyObject];
    CGPoint pt = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:pt];
    
    if (node.name)
    {
        NSString *tag;
        if ([node.name characterAtIndex:0] == 's')
            tag = [node.name substringFromIndex:1];
        else
            tag = node.name;
        
        if (selectedI < 0)
        {
            selectedI = [tag characterAtIndex:0] - '0';
            selectedJ = [tag characterAtIndex:1] - '0';
            
            node = [self getNodeWithI:selectedI J:selectedJ];
            node.alpha = 0.5;
        }
        else
        {
            int newI = [tag characterAtIndex:0] - '0';
            int newJ = [tag characterAtIndex:1] - '0';
            
            if (newI == selectedI && newJ == selectedJ)
            {
                node = [self getNodeWithI:selectedI J:selectedJ];
                node.alpha = 1;
            }
            else
            {
                SKNode *node1 = [self getNodeWithI:newI J:newJ];
                SKNode *node2 = [self getNodeWithI:selectedI J:selectedJ];
                if (((Tile *)board[newI][newJ]).shape == ((Tile *)board[selectedI][selectedJ]).shape)
                {                    
                    CGPoint dest1 = [self tilePosForI:selectedI J:selectedJ];
                    CGPoint dest2 = [self tilePosForI:newI J:newJ];
                
                    CGPoint mid = CGPointMake((dest1.x+dest2.x)/2, (dest1.y+dest2.y)/2);
                    CGPoint mid1;
                    CGPoint mid2;
                    if (fabs(dest1.x-dest2.x) > fabs(dest1.y-dest2.y))
                    {
                        mid1 = CGPointMake(mid.x, mid.y + 30);
                        mid2 = CGPointMake(mid.x, mid.y - 30);
                    }
                    else
                    {
                        mid1 = CGPointMake(mid.x + 30, mid.y);
                        mid2 = CGPointMake(mid.x - 30, mid.y);
                    }
                    
                    SKAction *move1mid = [SKAction moveTo:mid1 duration:0.25];
                    SKAction *move2mid = [SKAction moveTo:mid2 duration:0.25];
                    SKAction *move1end = [SKAction moveTo:dest1 duration:0.25];
                    SKAction *move2end = [SKAction moveTo:dest2 duration:0.25];
                    SKAction *move1block = [SKAction runBlock:^{node1.zPosition = 0;}];
                    SKAction *move2block = [SKAction runBlock:^{node2.zPosition = 0; state = CHECKING;}];
                    SKAction *move1 = [SKAction sequence:@[move1mid, move1end, move1block]];
                    SKAction *move2 = [SKAction sequence:@[move2mid, move2end, move2block]];
                    
                    node1.zPosition = 2;
                    node2.zPosition = 2;
                    state = SWAPPING;
                    
                    NSString *temp = node1.name;
                    node1.name = node2.name;
                    ((SKNode *)node1.children[0]).name = [@"s" stringByAppendingString:node2.name];
                    node2.name = temp;
                    ((SKNode *)node2.children[0]).name = [@"s" stringByAppendingString:temp];
                    
                    Tile *tile1 = (Tile *) board[selectedI][selectedJ];
                    Tile *tile2 = (Tile *) board[newI][newJ];
                    [Tile swap:tile1 with:tile2];
                    
                    [node1 runAction:move1];
                    [node2 runAction:move2];
                }
                node2.alpha = 1;
            }
            selectedI = selectedJ = -1;
        }
    }
}

-(void)update:(CFTimeInterval)currentTime
{
    static int nextJ;
    static int nextI;
    
    scoreLabel.text = [NSString stringWithFormat:@"SCORE: %d", score];
    
    if (state == CHECKING)
    {
        [self unmarkTiles];
        if([self markTilesToRemove])
        {
            nextI = nextJ = 0;
            state = POPPING;
        }
        else
        {
            state = READY;
        }
    }
    
    else if (state == POPPING)
    {
        for (int j = nextJ; j < 7; j++)
        {
            for (int i = nextI; i < 9; i++)
            {
                Tile *tile = (Tile *) board[i][j];
                if (tile.connected)
                {
                    nextJ = j;
                    nextI = i + 1;
#if !(TARGET_IPHONE_SIMULATOR)
                    state = WAITPOP;
#endif
                    SKNode *node = [self getNodeWithI:i J:j];
                    SKAction *pop = [SKAction scaleTo:0 duration:0.05];
                    SKAction *block = [SKAction runBlock:^{state = POPPING;}];
                    SKAction *remove = [SKAction removeFromParent];
                    SKAction *seq = [SKAction sequence:@[pop, sfxPop, block, remove]];
                    [node runAction:seq];
                    return;
                }
            }
            nextI = 0;
        }
        
        [self enumerateChildNodesWithName:@"border" usingBlock:^(SKNode *node, BOOL *stop){[node removeFromParent];}];
        
        for (int j = 0; j < 7; j++)
            [self dropColumn:j];
        
        state = WAITDROP;
    }
    else if (state == WAITDROP)
    {
        if (CFAbsoluteTimeGetCurrent() > dropTime)
            state = FILLING;
    }
    else if (state == FILLING)
    {
        for (int i = 0; i < 9; i++)
        {
            for (int j = 0; j < 7; j++)
            {
                Tile *tile = board[i][j];
                
                if (tile.connected)
                {
                    tile = [Tile new];
                    board[i][j] = tile;
                    SKShapeNode *tileSprite = [SKShapeNode node];
                    [tileSprite setPath:CGPathCreateWithRoundedRect(CGRectMake(-20,-20,40,40), 8, 8, nil)];
                    tileSprite.strokeColor = tileSprite.fillColor = [tile getUIColor];
                    tileSprite.position = [self tilePosForI:i J:j];
                    SKNode *shape = [tile shapeNode];
                    shape.name = [NSString stringWithFormat:@"s%d%d", i, j];
                    [tileSprite addChild:shape];
                    tileSprite.name = [NSString stringWithFormat:@"%d%d", i, j];
                    tileSprite.xScale = 0;
                    tileSprite.yScale = 0;
                    [self addChild:tileSprite];
                    SKAction *grow = [SKAction scaleTo:1 duration:0.5];
                    SKAction *block = [SKAction runBlock:^{state = CHECKING;}];
                    [tileSprite runAction:[SKAction sequence:@[grow, block]]];
                }
            }
        }
    }
}

-(void)dropColumn:(int) j
{
    int next = 0;
    
    for (int i = 0; i < 9; i++)
    {
        Tile *tile = (Tile *)board[i][j];
        
        if (tile.connected)
        {
            next = MAX(next + 1, i + 1);
            
            while (next < 9 && ((Tile*)board[next][j]).connected)
                next++;
            
            if (next >= 9)
                break;
            
            Tile *nextTile = (Tile *)board[next][j];
            nextTile.connected = true;
            tile.connected = false;

            SKNode *node = [self getNodeWithI:next J:j];
            
            [Tile swap:tile with:nextTile];
            node.name = [NSString stringWithFormat:@"%d%d", i, j];;
            ((SKNode *)node.children[0]).name = [NSString stringWithFormat:@"s%d%d", i, j];
            SKAction *drop = [SKAction moveTo:[self tilePosForI:i J:j] duration:0.1*(next-i)];
            [node runAction:drop];
            dropTime = MAX(dropTime, CFAbsoluteTimeGetCurrent() + 0.1*(next-i));
        }
    }
}

-(bool)markTilesToRemove
{
    bool match = false;
    int numBlocks = 0;
    int points = 0;
    
    for (int i = 0; i < 9; i++)
    {
        for (int j = 0; j < 7; j++)
        {
            int count = [self connectCountForI: i J: j Color:((Tile *)board[i][j]).color];
            if (count >= 4)
            {
                numBlocks++;
                points += pow(count, 3) * 10;
                [self markConnectedTilesForI: i J: j Color:((Tile *)board[i][j]).color];
                match = true;
            }
        }
    }
    points *= numBlocks;

    if (state != INIT && numBlocks > 0)
    {
        score += points;
        [self runAction:[SKAction repeatAction:[SKAction sequence:@[sfxDing, [SKAction waitForDuration:0.1]]] count:numBlocks]];
        
        if (!sparksNode.parent)
            [particleLayerNode addChild:sparksNode];
        [sparksNode resetSimulation];
        
    }
    
    return match;
}

-(int)connectCountForI:(int) i J:(int) j Color:(int) c
{
    if (i < 0 || i >= 9 || j < 0 || j >= 7 || ((Tile *)board[i][j]).visited || ((Tile *)board[i][j]).color != c)
        return 0;
    else
    {
        ((Tile *)board[i][j]).visited = true;
        return 1 +
            [self connectCountForI:i-1 J:j Color:c] +
            [self connectCountForI:i+1 J:j Color:c] +
            [self connectCountForI:i J:j-1 Color:c] +
            [self connectCountForI:i J:j+1 Color:c];
    }
}

-(void)markConnectedTilesForI:(int) i J:(int) j Color:(int) c
{
    if (i < 0 || i >= 9 || j < 0 || j >= 7 || ((Tile *)board[i][j]).connected || ((Tile *)board[i][j]).color != c)
        return;
    else
    {
        if (state != INIT)
        {
            if (i == 0 || ((Tile *)board[i-1][j]).color != c)
            {
                SKShapeNode *line = [SKShapeNode node];
                CGMutablePathRef path = CGPathCreateMutable();
                CGPathMoveToPoint(path, nil, -22, -22);
                CGPathAddLineToPoint(path, nil, 22, -22);
                [line setPath:path];
                line.name = @"border";
                line.position = [self tilePosForI:i J:j];
                [self addChild:line];
            }
            if (i == 8 || ((Tile *)board[i+1][j]).color != c)
            {
                SKShapeNode *line = [SKShapeNode node];
                CGMutablePathRef path = CGPathCreateMutable();
                CGPathMoveToPoint(path, nil, -22, 22);
                CGPathAddLineToPoint(path, nil, 22, 22);
                [line setPath:path];
                line.name = @"border";
                line.position = [self tilePosForI:i J:j];
                [self addChild:line];
            }
            if (j == 0 || ((Tile *)board[i][j-1]).color != c)
            {
                SKShapeNode *line = [SKShapeNode node];
                CGMutablePathRef path = CGPathCreateMutable();
                CGPathMoveToPoint(path, nil, -22, -22);
                CGPathAddLineToPoint(path, nil, -22, 22);
                [line setPath:path];
                line.name = @"border";
                line.position = [self tilePosForI:i J:j];
                [self addChild:line];
            }
            if (j == 6 || ((Tile *)board[i][j+1]).color != c)
            {
                SKShapeNode *line = [SKShapeNode node];
                CGMutablePathRef path = CGPathCreateMutable();
                CGPathMoveToPoint(path, nil, 22, -22);
                CGPathAddLineToPoint(path, nil, 22, 22);
                [line setPath:path];
                line.name = @"border";
                line.position = [self tilePosForI:i J:j];
                [self addChild:line];
            }
        }
        
        ((Tile *)board[i][j]).connected = true;
        [self markConnectedTilesForI:i-1 J:j Color:c];
        [self markConnectedTilesForI:i+1 J:j Color:c];
        [self markConnectedTilesForI:i J:j-1 Color:c];
        [self markConnectedTilesForI:i J:j+1 Color:c];
    }
}

-(bool)deleteConnectedTiles
{
    bool deleted = false;
    
    for (int i = 0; i < 9; i++)
    {
        for (int j = 0; j < 7; j++)
        {
            if (((Tile *)board[i][j]).connected)
            {
                board[i][j] = [[Tile alloc] init];
                deleted = true;
            }
        }
    }
    return deleted;
}

-(void)unmarkTiles
{
    for (int i = 0; i < 9; i++)
    {
        for (int j = 0; j < 7; j++)
        {
            Tile *tile = (Tile *) board[i][j];
            
            tile.connected = false;
            tile.visited = false;
        }
    }
}

-(CGPoint)tilePosForI:(int) i J:(int) j
{
    return CGPointMake(27 + 44*j, (self.size.height - 44*9)/2 + 21 + 44*i);
}

-(SKNode *)getNodeWithI:(int) i J:(int) j
{
    NSString *tag = [NSString stringWithFormat:@"%d%d", i, j];
    return [self childNodeWithName:tag];
}

@end
