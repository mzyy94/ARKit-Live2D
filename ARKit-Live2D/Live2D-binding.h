/**
 *
 * Live2D-binding.h
 * ARKit-Live2D
 * Created by Yuki MIZUNO on 2017/11/14.
 *
 * Copyright (c) 2017, Yuki MIZUNO
 * All rights reserved.
 *
 * See LICENSE for license information
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#ifndef Live2D_binding_h
#define Live2D_binding_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <SceneKit/SceneKit.h>

@interface Live2DCubism : NSObject
+ (void)initL2D;
+ (void)dispose;
+ (NSString *)live2DVersion;
@end

@interface Live2DModelOpenGL : NSObject

- (instancetype)initWithJsonPath:(NSString *)jsonPath;
- (int)getNumberOfTextures;
- (NSString *)getFileNameOfTexture:(int)number;
- (void)setTexture:(int)textureNo to:(uint32_t)openGLTextureNo;
- (void)setPremultipliedAlpha:(bool)enable;
- (float)getCanvasWidth;
- (void)setMatrix:(SCNMatrix4)matrix;
- (void)setParam:(NSString *)paramId value:(Float32)value;
- (void)setPartsOpacity:(NSString *)paramId opacity:(Float32)value;
- (void)updatePhysics:(Float32)delta;
- (void)update;
- (void)draw;

@property (nonatomic, copy) NSString *modelPath;
@property (nonatomic, strong) NSArray<NSString *> *texturePaths;
@property (nonatomic, strong) NSArray<NSString *> *parts;

@end

#endif /* Live2D_binding_h */
