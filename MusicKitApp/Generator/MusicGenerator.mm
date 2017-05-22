//
//  MusicGenerator.m
//  MusicKit
//
//  Created by Thanh-Dung Nguyen on 5/18/17.
//  Copyright © 2017 Venture Media Labs. All rights reserved.
//

#import "MusicGenerator.h"
#import <MusicKit/MusicKit.h>
#import <SSZipArchive/SSZipArchive.h>

#include <mxml/parsing/ScoreHandler.h>
#include <mxml/SpanFactory.h>
#include <lxml/lxml.h>

#include <iostream>
#include <fstream>
#include "VMKScoreRendererIOS.h"

//#include "VMKScoreRenderer.h"

@implementation MusicGenerator

std::unique_ptr<mxml::dom::Score> loadXML(NSString* filePath) {
    mxml::parsing::ScoreHandler handler;
    std::ifstream is([filePath UTF8String]);
    lxml::parse(is, [filePath UTF8String], handler);
    return handler.result();
}

std::unique_ptr<mxml::dom::Score> loadMXL(NSString* filePath) {
    NSArray* cachePathArray = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* cachePath = [cachePathArray firstObject];
    NSString* filename = [[filePath lastPathComponent] stringByDeletingPathExtension];
    NSString* destPath = [cachePath stringByAppendingPathComponent:filename];
    
    NSError* error;
    BOOL success = [SSZipArchive unzipFileAtPath:filePath
                                   toDestination:destPath
                                       overwrite:YES
                                        password:nil
                                           error:&error
                                        delegate:nil];
    if (error)
        NSLog(@"Error unzipping: %@", error);
    if (!success) {
        NSLog(@"Failed to unzip %@", filePath);
        return std::unique_ptr<mxml::dom::Score>();
    }
    
    NSFileManager* fileManager = [[NSFileManager alloc] init];
    NSArray* paths = [fileManager contentsOfDirectoryAtPath:destPath error:NULL];
    NSString* xmlFile = nil;
    for (NSString* file in paths) {
        if ([file hasSuffix:@".xml"]) {
            xmlFile = file;
            break;
        }
    }
    if (xmlFile == nil) {
        NSLog(@"Archive does not contain an xml file: %@", filePath);
        return std::unique_ptr<mxml::dom::Score>();
    }
    
    try {
        NSString* xmlPath = [destPath stringByAppendingPathComponent:xmlFile];
        std::ifstream is([xmlPath UTF8String]);
        
        mxml::parsing::ScoreHandler handler;
        lxml::parse(is, [filename UTF8String], handler);
        return handler.result();
    } catch (mxml::dom::InvalidDataError& error) {
        NSLog(@"Error loading score '%@': %s", filePath, error.what());
        return std::unique_ptr<mxml::dom::Score>();
    }
}

- (CGImageRef)renderWithInput:(NSString*)input {
    // Parse input file
    std::unique_ptr<mxml::dom::Score> score;
    if ([input hasSuffix:@".xml"]) {
        score = loadXML(input);
    } else if ([input hasSuffix:@".mxl"]) {
        score = loadMXL(input);
    } else {
        std::cerr << "File extension not recognized, assuming compressed MusicXML (.mxl).\n";
        score = loadMXL(input);
    }
    
    if (!score || score->parts().empty() || score->parts().front()->measures().empty())
        return nil;
    
    // Generate geometry
    std::unique_ptr<mxml::ScrollScoreGeometry> scoreGeometry(new mxml::ScrollScoreGeometry(*score));
    
    VMKScoreRendererIOS renderer(*scoreGeometry);
    CGImageRef rep = renderer.render();
    
    return rep;
}

@end
