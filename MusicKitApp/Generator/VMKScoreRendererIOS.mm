//
//  VMKScoreRendererIOS.m
//  MusicKit
//
//  Created by Thanh-Dung Nguyen on 5/18/17.
//  Copyright © 2017 Venture Media Labs. All rights reserved.
//

#import "VMKScoreRendererIOS.h"

#include <algorithm>

const CGFloat VMKScoreRendererIOS::scale = 2;
const CGFloat VMKScoreRendererIOS::maxWidth = 2048;


VMKScoreRendererIOS::VMKScoreRendererIOS(const mxml::ScrollScoreGeometry& scoreGeometry) : _scoreGeometry(scoreGeometry), _lastPartGeometry() {
    // Find last part
    for (auto& geometry : scoreGeometry.geometries())
        _lastPartGeometry = static_cast<mxml::PartGeometry*>(geometry.get());
}

CGImageRef VMKScoreRendererIOS::render() {
    if (!_lastPartGeometry)
        return nil;
    
    CGSize size = partSize(*_lastPartGeometry);
    
    _renderBounds.origin = CGPointZero;
    _renderBounds.size = size;
    
    // Create image
    UIGraphicsBeginImageContext(size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(ctx, 0, size.height);
    CGContextScaleCTM(ctx, 1.f, -1.f);
    
    renderMeasures(ctx);
    renderWords(ctx);
    renderTies(ctx);

    CGImageRef imageRefWithAlpha = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);

    return imageRefWithAlpha;
}

CGFloat VMKScoreRendererIOS::calculatePartHeight(const mxml::PartGeometry& partGeometry) {
    mxml::coord_t minY = 0.0f;
    mxml::coord_t maxY = 0.0f;
    
    for (auto& geometry : partGeometry.geometries()){
        auto frame = geometry->frame();
        if (frame.origin.x < maxWidth) {
            minY = std::min(minY, frame.min().y);
            maxY = std::max(maxY, frame.max().y);
        }
    }
    
    return maxY - minY;
}

CGSize VMKScoreRendererIOS::partSize(const mxml::PartGeometry& partGeometry) {
    CGFloat measuresWidth = 0.0;
    for (auto& measureGeometry : partGeometry.geometries()) {
        measuresWidth += measureGeometry->size().width;
        if (measuresWidth >= maxWidth)
            break;
    }
    
    CGSize size;
    size.width = std::min(measuresWidth, maxWidth);
    size.height = calculatePartHeight(partGeometry);
    
    // Round to nearest pixel
    CGSize scaledSize = CGSizeMake(std::ceil(size.width * scale), std::ceil(size.height * scale));
    size.width = scaledSize.width / scale;
    size.height = scaledSize.height / scale;
    
    return size;
}

void VMKScoreRendererIOS::renderMeasures(CGContextRef ctx) {
    CGFloat measuresWidth = 0.0;
    for (auto& measureGeometry : _lastPartGeometry->measureGeometries()) {
        CGRect frame = getFrame(*measureGeometry);
        if (!CGRectIntersectsRect(frame, _renderBounds))
            continue;
        
        VMKMeasureLayer* layer = [[VMKMeasureLayer alloc] initWithGeometry:measureGeometry];
        [layer layoutIfNeeded];
        
        renderLayer(ctx, layer, frame);
        
        measuresWidth += layer.bounds.size.width;
        if (measuresWidth >= maxWidth)
            break;
    }
}

void VMKScoreRendererIOS::renderWords(CGContextRef ctx) {
    for (auto& directionGeometry : _lastPartGeometry->directionGeometries()) {
        CGRect frame = getFrame(*directionGeometry);
        if (!CGRectContainsRect(_renderBounds, frame))
            continue;
        
        if (const mxml::WordsGeometry* geom = dynamic_cast<const mxml::WordsGeometry*>(directionGeometry)) {
            VMKScoreElementLayer *layer = [[VMKWordsLayer alloc] initWithGeometry:geom];
            renderLayer(ctx, layer, frame);
        }
    }
}

void VMKScoreRendererIOS::renderTies(CGContextRef ctx) {
    for (auto& tieGeometry : _lastPartGeometry->tieGeometries()) {
        CGRect frame = getFrame(*tieGeometry);
        if (!CGRectIntersectsRect(frame, _renderBounds))
            continue;
        
        VMKTieLayer* layer = [[VMKTieLayer alloc] initWithTieGeometry:tieGeometry];
        [layer layoutIfNeeded];
        
        renderLayer(ctx, layer, frame);
    }
}

CGRect VMKScoreRendererIOS::getFrame(const mxml::Geometry& geometry) {
    CGRect frame = CGRectFromRect(geometry.frame());
    frame.origin.y -= _lastPartGeometry->contentOffset().y;
    return VMKRoundRect(frame);
}

void VMKScoreRendererIOS::renderLayer(CGContextRef ctx, VMKScoreElementLayer* layer, CGRect frame) {
    CGFloat dx = frame.origin.x - layer.bounds.origin.x;
    CGFloat dy = frame.origin.y - layer.bounds.origin.y;
    
    [layer layoutIfNeeded];
    CGContextTranslateCTM(ctx, dx, dy);
    [layer renderInContext:ctx];
    CGContextTranslateCTM(ctx, -dx, -dy);
}

