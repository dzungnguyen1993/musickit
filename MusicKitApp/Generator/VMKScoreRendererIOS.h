//
//  VMKScoreRendererIOS.h
//  MusicKit
//
//  Created by Thanh-Dung Nguyen on 5/18/17.
//  Copyright © 2017 Venture Media Labs. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <MusicKit/MusicKit.h>

#include <mxml/geometry/ScrollScoreGeometry.h>
#include <mxml/geometry/PartGeometry.h>


class VMKScoreRendererIOS {
public:
    /**
     The scale used to render the score.
     */
    static const CGFloat scale;
    
    /**
     The number of measures to include in the rendering.
     */
    static const CGFloat maxWidth;
    
public:
    /**
     Construct a score renderer for the score geometry.
     */
    VMKScoreRendererIOS(const mxml::ScrollScoreGeometry& scoreGeometry);
    
    /**
     Render the first `numberOfMeasures` measures of the last part of the score.
     
     @return An NSBitmatImageRep of the rendered score.
     */
    CGImageRef render();
    
protected:
    static CGSize partSize(const mxml::PartGeometry& partGeometry);
    static CGFloat calculatePartHeight(const mxml::PartGeometry& partGeometry);
    
    void renderMeasures(CGContextRef ctx);
    void renderWords(CGContextRef ctx);
    void renderTies(CGContextRef ctx);
    
    CGRect getFrame(const mxml::Geometry& geometry);
    void renderLayer(CGContextRef ctx, VMKScoreElementLayer* layer, CGRect frame);
    
private:
    const mxml::ScrollScoreGeometry& _scoreGeometry;
    const mxml::PartGeometry* _lastPartGeometry;
    
    CGRect _renderBounds;
};
