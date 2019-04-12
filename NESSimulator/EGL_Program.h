//
//  EGL_Program.h
//  OpenGL ES Test
//
//  Created by work_lenovo on 2017/7/9.
//  Copyright © 2017年 work_lenovo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES3/gl.h>

@interface EGL_Program : NSObject

+ (instancetype)eglProgram;

- (void)resetProgram;
- (BOOL)loadShader:(GLenum)shaderType shaderPath:(NSString*)path;
- (BOOL)linkProgram;
- (void)useProgram;

- (GLint)attribLocationOfName:(NSString*)name;
- (GLint)uniformLocationOfName:(NSString*)name;
- (void)clear;

@end
