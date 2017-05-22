// Copyright © 2016 Venture Media Labs.
//
// This file is part of MusicKit. The full MusicKit copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

#import "AppDelegate.h"
#import "MusicGenerator.h"

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(UIApplication *)application {
    MusicGenerator *generator = [[MusicGenerator alloc] init];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"kiss_the_rain" ofType:@"xml"];
    
    CGImageRef cgImage = [generator renderWithInput:filePath];
    
    
    CGImageRef imageRef = CGImageRotated(cgImage, -M_PI);
    
    
}

- (double)radiansFromUIImageOrientation:(UIImageOrientation)orientation
{
    double radians;
    
    switch (orientation) {
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            radians = M_PI_2;
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            radians = 0.f;
            break;
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            radians = M_PI;
            break;
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            radians = -M_PI_2;
            break;
    }
    
    return radians;
}

CGImageRef CGImageRotated(CGImageRef originalCGImage, double radians)
{
    CGSize imageSize = CGSizeMake(CGImageGetWidth(originalCGImage), CGImageGetHeight(originalCGImage));
    CGSize rotatedSize;
    if (radians == M_PI_2 || radians == -M_PI_2) {
        rotatedSize = CGSizeMake(imageSize.height, imageSize.width);
    } else {
        rotatedSize = imageSize;
    }
    
    double rotatedCenterX = rotatedSize.width / 2.f;
    double rotatedCenterY = rotatedSize.height / 2.f;
    
    UIGraphicsBeginImageContextWithOptions(rotatedSize, NO, 1.f);
    CGContextRef rotatedContext = UIGraphicsGetCurrentContext();
    if (radians == 0.f || radians == M_PI) { // 0 or 180 degrees
        CGContextTranslateCTM(rotatedContext, rotatedCenterX, rotatedCenterY);
        if (radians == 0.0f) {
            CGContextScaleCTM(rotatedContext, 1.f, -1.f);
        } else {
            CGContextScaleCTM(rotatedContext, -1.f, 1.f);
        }
        CGContextTranslateCTM(rotatedContext, -rotatedCenterX, -rotatedCenterY);
    } else if (radians == M_PI_2 || radians == -M_PI_2) { // +/- 90 degrees
        CGContextTranslateCTM(rotatedContext, rotatedCenterX, rotatedCenterY);
        CGContextRotateCTM(rotatedContext, radians);
        CGContextScaleCTM(rotatedContext, 1.f, -1.f);
        CGContextTranslateCTM(rotatedContext, -rotatedCenterY, -rotatedCenterX);
    }
    
    CGRect drawingRect = CGRectMake(0.f, 0.f, imageSize.width, imageSize.height);
    CGContextDrawImage(rotatedContext, drawingRect, originalCGImage);
    CGImageRef rotatedCGImage = CGBitmapContextCreateImage(rotatedContext);
    
    UIGraphicsEndImageContext();
    CFAutorelease((CFTypeRef)rotatedCGImage);
    
    return rotatedCGImage;
}

@end
