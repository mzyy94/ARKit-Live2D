/**
 *
 * Live2D-binding.mm
 * ARKit-Live2D
 * Created by Yuki MIZUNO on 2017/11/14.
 *
 * Copyright (c) 2017, Yuki MIZUNO
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "Live2D-binding.h"

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <SceneKit/SceneKit.h>
#import "Live2DModelOpenGL.h"
#import "UtSystem.h"

#pragma mark - Live2DCubism class

@implementation Live2DCubism
+ (void)initL2D {
    live2d::Live2D::init();
}

+ (void)dispose {
    live2d::Live2D::dispose();
}

+ (NSString *)live2DVersion {
    return [NSString stringWithUTF8String:live2d::Live2D::getVersionStr()];
}
@end

#pragma mark - Live2DModelOpenGL class

@interface Live2DModelOpenGL ()

@property (nonatomic, assign) live2d::Live2DModelOpenGL *live2DModel;

@end

@implementation Live2DModelOpenGL
- (instancetype)initWithModelPath:(NSString *)modelPath {
    if (self = [super init]) {
        _live2DModel = live2d::Live2DModelOpenGL::loadModel( [modelPath UTF8String] ) ;
    }
    return self;
}

- (void)setTexture:(int)textureNo to:(uint32_t)openGLTextureNo {
    self.live2DModel->setTexture( textureNo , openGLTextureNo ) ;
}

- (float)getCanvasWidth {
    return self.live2DModel->getCanvasWidth();
}

- (void)setMatrix:(SCNMatrix4)matrix {
    float fMatrix[] = {
        matrix.m11, matrix.m12, matrix.m13, matrix.m14,
        matrix.m21, matrix.m22, matrix.m23, matrix.m24,
        matrix.m31, matrix.m32, matrix.m33, matrix.m34,
        matrix.m41, matrix.m42, matrix.m43, matrix.m44
    };
    self.live2DModel->setMatrix(fMatrix);
}

- (void)setParam:(NSString *)paramId value:(CGFloat)value {
    self.live2DModel->setParamFloat([paramId UTF8String], (float)(value));
}

- (void)setPartsOpacity:(NSString *)paramId opacity:(CGFloat)value {
    self.live2DModel->setPartsOpacity([paramId UTF8String], (float)(value));
}
    
- (void)update {
    self.live2DModel->update();
}

- (void)draw {
    self.live2DModel->draw();
}
@end

#pragma mark - UtSystem class

@implementation UtSystem
+ (CGFloat)getUserTimeMSec {
    return live2d::UtSystem::getUserTimeMSec();
}
@end
