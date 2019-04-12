//
//  EGL_Program.m
//  OpenGL ES Test
//
//  Created by work_lenovo on 2017/7/9.
//  Copyright © 2017年 work_lenovo. All rights reserved.
//

#import "EGL_Program.h"
#import <OpenGLES/ES3/gl.h>

@interface EGL_Program()

@property(nonatomic, assign)BOOL bLinkFlag;

@end

@implementation EGL_Program
{
    GLuint gl_program;
}

- (void)dealloc
{
    [self clear];
}

+ (instancetype)eglProgram
{
    EGL_Program* program = [[self alloc] init];
    return program;
}

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        gl_program = glCreateProgram();
    }
    
    return self;
}

- (void)clear
{
    glDeleteProgram(gl_program);
}

- (void)resetProgram
{
    glDeleteProgram(gl_program);
    gl_program = glCreateProgram();
}

- (BOOL)loadShader:(GLenum)shaderType shaderPath:(NSString *)path
{
    NSError* error = nil;
    NSString* strShaderCode = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if(error)
    {
        NSLog(@"shader file error: %@", error);
        return NO;
    }
    
    GLuint shader = glCreateShader(shaderType);
    if(0 == shader)
    {
        NSLog(@"create shader failed");
        
        return NO;
    }
    
    const GLchar* src = (GLchar*)[strShaderCode UTF8String];
    glShaderSource(shader, 1, &src, NULL);
    glCompileShader(shader);
    
    GLint ret;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &ret);
    if(!ret)
    {
        GLint infoLen = 0;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);
        if(infoLen > 0)
        {
            GLsizei actualLen;
            GLchar* buffer = (GLchar*)malloc(infoLen);
            glGetShaderInfoLog(shader, infoLen, &actualLen, buffer);
            NSLog(@"shader compile error: %@", [NSString stringWithUTF8String:(char*)buffer]);
            free(buffer);
        }
        glDeleteShader(shader);
        
        return NO;
    }
    
    glAttachShader(gl_program, shader);
    return YES;
}

- (BOOL)linkProgram
{
    if(self.bLinkFlag)
        return YES;
    
    glLinkProgram(gl_program);
    
    GLint linkStatus;
    glGetProgramiv(gl_program, GL_LINK_STATUS, &linkStatus);
    if(!linkStatus)
    {
        GLint infoLen = 0;
        glGetProgramiv(gl_program, GL_INFO_LOG_LENGTH, &infoLen);
        if(infoLen > 0)
        {
            GLsizei actualLen;
            GLchar* buffer = (GLchar*)malloc(infoLen);
            glGetProgramInfoLog(gl_program, infoLen, &actualLen, buffer);
            NSLog(@"shader compile error: %@", [NSString stringWithUTF8String:(char*)buffer]);
            free(buffer);
        }
        glDeleteProgram(gl_program);
        return NO;
    }
    self.bLinkFlag = YES;
    
    return YES;
}

- (void)useProgram
{
    glUseProgram(gl_program);
}

- (GLint)attribLocationOfName:(NSString *)name
{
    return glGetAttribLocation(gl_program, (GLchar*)[name UTF8String]);
}

- (GLint)uniformLocationOfName:(NSString *)name
{
    return glGetUniformLocation(gl_program, (GLchar*)[name UTF8String]);
}

@end
