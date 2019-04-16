//
//  NesGameScreenView.m
//  NESSimulator
//
//  Created by qingzhao on 2019/4/11.
//  Copyright © 2019年 qingzhao. All rights reserved.
//

#import "NesGameScreenView.h"
#import "EGL_Program.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

@interface NesGameScreenView()

@property(nonatomic, strong)EAGLContext* oldContext;
@property(nonatomic, strong)EAGLContext* glContext;
@property(nonatomic, strong)EGL_Program* eglProgram;

@end

@implementation NesGameScreenView{
    GLuint frameBuffer;
    GLuint renderBuffer;
    GLuint texture;
    dispatch_queue_t renderQueue;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+ (Class)layerClass{
    return [CAEAGLLayer class];
}

- (void)dealloc{
    [EAGLContext setCurrentContext:self.oldContext];
    glDeleteTextures(1, &texture);
    texture = 0;
    glDeleteRenderbuffers(1, &renderBuffer);
    renderBuffer = 0;
    glDeleteFramebuffers(1, &frameBuffer);
    frameBuffer = 0;
}

- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        renderQueue = dispatch_queue_create("renderqueue", DISPATCH_QUEUE_SERIAL);
        [self setGLContext];
    }
    return self;
}

- (void)useContext
{
    if([EAGLContext currentContext] != self.glContext)
    {
        [EAGLContext setCurrentContext:self.glContext];
    }
}

- (void)setupStorage
{
    CAEAGLLayer* renderLayer = (CAEAGLLayer*)[self layer];
    [self.glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:renderLayer];
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        NSLog(@"创建缓冲区错误 0x%x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return ;
    }
    
    //    glViewport(0,0, self.bounds.size.width, self.bounds.size.height);
    GLint backingWidth, backingHeight;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    glViewport(0, 0, backingWidth, backingHeight);
}

- (void)setGLContext
{
    self.oldContext = [EAGLContext currentContext];
    
    EAGLContext* context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    self.glContext = context;
    [self useContext];
    
    CAEAGLLayer* renderLayer = (CAEAGLLayer*)[self layer];
    renderLayer.contentsScale = [[UIScreen mainScreen] scale];
    renderLayer.opaque = YES;
    renderLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    glDisable(GL_DEPTH_TEST);
    
    GLuint fb;
    glGenFramebuffers(1, &fb);
    glBindFramebuffer(GL_FRAMEBUFFER, fb);
    frameBuffer = fb;
    
    GLuint rb;
    glGenRenderbuffers(1, &rb);
    glBindRenderbuffer(GL_RENDERBUFFER, rb);
    renderBuffer = rb;
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, rb);
    [self setupStorage];
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    EGL_Program* program = [EGL_Program eglProgram];
    self.eglProgram = program;
    NSString* vertextShader = [[NSBundle mainBundle] pathForResource:@"displayVertexShader.vs" ofType:nil];
    [program loadShader:GL_VERTEX_SHADER shaderPath:vertextShader];
    NSString* fragmentShader = [[NSBundle mainBundle] pathForResource:@"displayFragmentShader.fs" ofType:nil];
    [program loadShader:GL_FRAGMENT_SHADER shaderPath:fragmentShader];
    
    [program linkProgram];
    [program useProgram];
    
    GLuint texy;
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &texy);
    glBindTexture(GL_TEXTURE_2D, texy);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    texture = texy;
}

- (void)nes_newframe:(u32 *)pic{
    dispatch_async(renderQueue, ^{
        if(self.pause)
            return ;
        
        [self useContext];
        glBindFramebuffer(GL_FRAMEBUFFER, self->frameBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, self->renderBuffer);
        glClearColor(0, 0, 0, 1);
        glClear(GL_COLOR_BUFFER_BIT);
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, self->texture);
        
        GLint nW = 256;
        GLint nH = 240;
        
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)nW, (int)nH, 0, GL_BGRA, GL_UNSIGNED_BYTE, pic);
        
        GLint backingWidth, backingHeight;
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
        CGFloat fWScale = nW/(CGFloat)backingWidth;
        CGFloat fHScale = nH/(CGFloat)backingHeight;
        CGFloat fScale = 0;
        if(fWScale > fHScale)
        {
            fScale = fWScale;
        }
        else
        {
            fScale = fHScale;
        }
        
        GLfloat fCoorW = fWScale/fScale;
        GLfloat fCoorH = fHScale/fScale;
        const GLfloat vertexVertices[] = {
            -fCoorW, -fCoorH,
            fCoorW, -fCoorH,
            -fCoorW,  fCoorH,
            fCoorW, fCoorH
        };
        
        static const GLfloat textureVertices[] = {
            0.0f,  1.0f,
            1.0f,  1.0f,
            0.0f,  0.0f,
            1.0f,  0.0f
        };
        
        GLint vertexIndex = [self.eglProgram attribLocationOfName:@"position"];
        glEnableVertexAttribArray(vertexIndex);
        glVertexAttribPointer(vertexIndex, 2, GL_FLOAT, GL_FALSE, 0, vertexVertices);
        
        GLint textureIndex = [self.eglProgram attribLocationOfName:@"inputTextureCoordinate"];
        glEnableVertexAttribArray(textureIndex);
        glVertexAttribPointer(textureIndex, 2, GL_FLOAT, GL_FALSE, 0, textureVertices);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        [[EAGLContext currentContext] presentRenderbuffer:GL_RENDERBUFFER];
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        glBindRenderbuffer(GL_RENDERBUFFER, 0);
        glDisableVertexAttribArray(vertexIndex);
        glDisableVertexAttribArray(textureIndex);
    });
}

@end
