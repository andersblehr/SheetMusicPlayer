//
//  SobelAnalyser.h
//  SheetMusicPlayer
//
//  Created by Anders Blehr on 20.02.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SobelAnalyserDelegate <NSObject>
@required
- (void)plotImagePoint:(CGPoint)imagePoint;
- (void)plotImagePoint:(CGPoint)imagePoint withColour:(UIColor *)colour;
@end

@interface SobelAnalyser : NSObject {
@private    
    id <SobelAnalyserDelegate> delegate;
    
    size_t imageWidth;
    size_t imageHeight;
    unsigned char *sobelArray;
    float sobelThreshold;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) size_t imageWidth;
@property (nonatomic, assign) size_t imageHeight;
@property (nonatomic, assign) float sobelThreshold;

- (BOOL)didEnterInkFromTopAtPoint:(CGPoint)point;
- (BOOL)didEnterInkFromLeftAtPoint:(CGPoint)point;
- (id)initWithSobelArray:(unsigned char *)array ofSize:(CGSize)size;

@end
