/*
     File: RosyWriterPreviewView.m
 Abstract: The OpenGL ES view, responsible for creating a CVOpenGLESTexture from each CVImageBuffer and displaying the texture on the screen.
  Version: 1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import <QuartzCore/CAEAGLLayer.h>
#import "RosyWriterPreviewView.h"
#include "ShaderUtilities.h"

enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXTUREPOSITON,
    NUM_ATTRIBUTES
};

static size_t  _glReadPixelsBufferSize;
static void   *_glReadPixelsBuffer;

static inline const char * GLErrorString(GLenum error)
{
	const char *str;
	switch( error )
	{
		case GL_NO_ERROR:
			str = "GL_NO_ERROR";
			break;
		case GL_INVALID_ENUM:
			str = "GL_INVALID_ENUM";
			break;
		case GL_INVALID_VALUE:
			str = "GL_INVALID_VALUE";
			break;
		case GL_INVALID_OPERATION:
			str = "GL_INVALID_OPERATION";
			break;
		case GL_OUT_OF_MEMORY:
			str = "GL_OUT_OF_MEMORY";
			break;
#ifdef __gl_h_
		case GL_STACK_OVERFLOW:
			str = "GL_STACK_OVERFLOW";
			break;
		case GL_STACK_UNDERFLOW:
			str = "GL_STACK_UNDERFLOW";
			break;
		case GL_TABLE_TOO_LARGE:
			str = "GL_TABLE_TOO_LARGE";
			break;
#endif
			//#if GL_EXT_framebuffer_object
		case GL_INVALID_FRAMEBUFFER_OPERATION:
			str = "GL_INVALID_FRAMEBUFFER_OPERATION";
			break;
			//#endif
		default:
			str = [[NSString stringWithFormat:@"(ERROR: Unknown GL Error Enum: %i)" , error] cStringUsingEncoding:NSASCIIStringEncoding];
			break;
	}
	return str;
}


//  GL_FLOAT, GL_FLOAT_VEC2, GL_FLOAT_VEC3, GL_FLOAT_VEC4, 
//	GL_INT, GL_INT_VEC2, GL_INT_VEC3, GL_INT_VEC4, 
//	GL_BOOL, GL_BOOL_VEC2, GL_BOOL_VEC3, GL_BOOL_VEC4, 
//	GL_FLOAT_MAT2, GL_FLOAT_MAT3, GL_FLOAT_MAT4, 
//	GL_SAMPLER_2D, or GL_SAMPLER_CUBE 



static inline const NSString *GLSLTypeNSString(GLenum type)
{
	NSString *str;
	switch( type )
	{
		case GL_FLOAT:
			str = @"GL_FLOAT";
			break;
		case GL_FLOAT_VEC2:
			str = @"GL_FLOAT_VEC2";
			break;
		case GL_FLOAT_VEC3:
			str = @"GL_FLOAT_VEC3";
			break;
		case GL_FLOAT_VEC4:
			str = @"GL_FLOAT_VEC4";
			break;
		case GL_FLOAT_MAT2:
			str = @"GL_FLOAT_MAT2";
			break;
		case GL_FLOAT_MAT3:
			str = @"GL_FLOAT_MAT3";
			break;
		case GL_FLOAT_MAT4:
			str = @"GL_FLOAT_MAT4";
			break;
		case GL_INT:
			str = @"GL_INT";
			break;
		case GL_INT_VEC2:
			str = @"GL_INT_VEC2";
			break;
		case GL_INT_VEC3:
			str = @"GL_INT_VEC3";
			break;
		case GL_INT_VEC4:
			str = @"GL_INT_VEC4";
			break;
		case GL_BOOL:
			str = @"GL_BOOL";
			break;
		case GL_BOOL_VEC2:
			str = @"GL_BOOL_VEC2";
			break;
		case GL_BOOL_VEC3:
			str = @"GL_BOOL_VEC3";
			break;
		case GL_BOOL_VEC4:
			str = @"GL_BOOL_VEC4";
			break;
		case GL_SAMPLER_2D:
			str = @"GL_SAMPLER_2D";
			break;
		case GL_SAMPLER_CUBE:
			str = @"GL_SAMPLER_CUBE";
			break;
		default:
			str = @"??";
			break;
	}
	return str;
}

#define GetGLError()									\
{                                                       \
														\
	GLenum err = glGetError();							\
	int noGLerror = 1;                                  \
	while (err != GL_NO_ERROR) {						\
		noGLerror = 0;                                  \
		NSLog(@"GLError %s set in File:%s Line:%d\n",	\
					GLErrorString(err),					\
				__FILE__,								\
				__LINE__);								\
		err = glGetError();								\
	}													\
}


void releasePixelDataCallback(void *info, const void *pixelData, size_t size);

void releasePixelDataCallback(void *info, const void *pixelData, size_t size) 
{
    if (pixelData != NULL) {
		
        free(_glReadPixelsBuffer);    
        _glReadPixelsBuffer = NULL;
        _glReadPixelsBufferSize = 0;
    }
};



@implementation RosyWriterPreviewView

@synthesize x;
@synthesize y;
@synthesize z;
@synthesize secondExposure;

+ (Class)layerClass 
{
    return [CAEAGLLayer class];
}

- (const GLchar *)readFile:(NSString *)name
{
    NSString *path;
    const GLchar *source;
    
    path = [[NSBundle mainBundle] pathForResource:name ofType: nil];
    source = (GLchar *)[[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] UTF8String];
    
    return source;
}

- (BOOL)initializeBuffers
{
	BOOL success = YES;
	
	glDisable(GL_DEPTH_TEST);
    
    glGenFramebuffers(1, &frameBufferHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBufferHandle);
    
    glGenRenderbuffers(1, &colorBufferHandle);
    glBindRenderbuffer(GL_RENDERBUFFER, colorBufferHandle);
    
    [oglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &renderBufferWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &renderBufferHeight);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorBufferHandle);
	if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failure with framebuffer generation");
		success = NO;
	}
    
    //  Create a new CVOpenGLESTexture cache
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, oglContext, NULL, &videoTextureCache);
    if (err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
        success = NO;
    }
    
    // Load vertex and fragment shaders
    const GLchar *vertSrc = [self readFile:@"passThrough.vsh"];
    const GLchar *fragSrc = [self readFile:@"passThrough.fsh"];
    
    // attributes
    GLint attribLocation[NUM_ATTRIBUTES] = {
        ATTRIB_VERTEX, ATTRIB_TEXTUREPOSITON,
    };
    GLchar *attribName[NUM_ATTRIBUTES] = {
        "position", "textureCoordinate",			
    };
    
    glueCreateProgram(vertSrc, fragSrc,
                      NUM_ATTRIBUTES, (const GLchar **)&attribName[0], attribLocation,
                      0, 0, 0, // we don't need to get uniform locations in this example
                      &passThroughProgram);
    
    if (!passThroughProgram)
        success = NO;
    
    return success;
}

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil) {
		// Use 2x scale factor on Retina displays.
		self.contentScaleFactor = [[UIScreen mainScreen] scale];

        // Initialize OpenGL ES 2
        CAEAGLLayer* eaglLayer = (CAEAGLLayer *)self.layer;
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
                                        kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                        nil];
        oglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        if (!oglContext || ![EAGLContext setCurrentContext:oglContext]) {
            NSLog(@"Problem with OpenGL context.");
            [self release];
            
            return nil;
        }
    }
	
    return self;
}

- (void)renderWithSquareVertices:(const GLfloat*)squareVertices textureVertices:(const GLfloat*)textureVertices
{
    // Use shader program.
    glUseProgram(passThroughProgram);

    // update uniform values
	const GLchar *rName = [@"redF" UTF8String];
	GLint rFLoc = glGetUniformLocation(passThroughProgram, rName);
	glUniform1f(rFLoc, x);
	
	const GLchar *gName = [@"greenF" UTF8String];
	GLint gFLoc = glGetUniformLocation(passThroughProgram, gName);
	glUniform1f(gFLoc, y);
	
	const GLchar *bName = [@"blueF" UTF8String];
	GLint bFLoc = glGetUniformLocation(passThroughProgram, bName);
	glUniform1f(bFLoc, z);

	
    // Update attribute values.
	glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
	glEnableVertexAttribArray(ATTRIB_VERTEX);
	glVertexAttribPointer(ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, textureVertices);
	glEnableVertexAttribArray(ATTRIB_TEXTUREPOSITON);
    
    // Update uniform values if there are any
    
    // Validate program before drawing. This is a good check, but only really necessary in a debug build.
    // DEBUG macro must be defined in your debug configurations if that's not already the case.
#if defined(DEBUG)    
    if (glueValidateProgram(passThroughProgram) != 0) {
        NSLog(@"Failed to validate program: %d", passThroughProgram);
        return;
    }    
#endif
	
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    // Present
    glBindRenderbuffer(GL_RENDERBUFFER, colorBufferHandle);
    [oglContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (CGRect)textureSamplingRectForCroppingTextureWithAspectRatio:(CGSize)textureAspectRatio toAspectRatio:(CGSize)croppingAspectRatio
{
	CGRect normalizedSamplingRect = CGRectZero;	
	CGSize cropScaleAmount = CGSizeMake(croppingAspectRatio.width / textureAspectRatio.width, croppingAspectRatio.height / textureAspectRatio.height);
	CGFloat maxScale = fmax(cropScaleAmount.width, cropScaleAmount.height);
	CGSize scaledTextureSize = CGSizeMake(textureAspectRatio.width * maxScale, textureAspectRatio.height * maxScale);
	
	if ( cropScaleAmount.height > cropScaleAmount.width ) {
		normalizedSamplingRect.size.width = croppingAspectRatio.width / scaledTextureSize.width;
		normalizedSamplingRect.size.height = 1.0;
	}
	else {
		normalizedSamplingRect.size.height = croppingAspectRatio.height / scaledTextureSize.height;
		normalizedSamplingRect.size.width = 1.0;
	}
	// Center crop
	normalizedSamplingRect.origin.x = (1.0 - normalizedSamplingRect.size.width)/2.0;
	normalizedSamplingRect.origin.y = (1.0 - normalizedSamplingRect.size.height)/2.0;
	
	return normalizedSamplingRect;
}

- (void)displayPixelBuffer:(CVImageBufferRef)pixelBuffer 
{    
	if (frameBufferHandle == 0) {
		BOOL success = [self initializeBuffers];
		if ( !success ) {
			NSLog(@"Problem initializing OpenGL buffers.");	
		}
	}

    if (videoTextureCache == NULL)
        return;
	
    // Create a CVOpenGLESTexture from the CVImageBuffer
	size_t frameWidth = CVPixelBufferGetWidth(pixelBuffer);
	size_t frameHeight = CVPixelBufferGetHeight(pixelBuffer);

	CVOpenGLESTextureRef texture = NULL;
    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, 
                                                                videoTextureCache,
                                                                pixelBuffer,
                                                                NULL,
                                                                GL_TEXTURE_2D,
                                                                GL_RGBA,
                                                                frameWidth,
                                                                frameHeight,
                                                                GL_BGRA,
                                                                GL_UNSIGNED_BYTE,
                                                                0,
                                                                &texture);
    
    
    if (!texture || err) {
        NSLog(@"CVOpenGLESTextureCacheCreateTextureFromImage failed (error: %d)", err);  
        return;
    }
    
	glBindTexture(CVOpenGLESTextureGetTarget(texture), CVOpenGLESTextureGetName(texture));
    
    // Set texture parameters
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);   
    
    glBindFramebuffer(GL_FRAMEBUFFER, frameBufferHandle);
    
    // Set the view port to the entire view
    glViewport(0, 0, renderBufferWidth, renderBufferHeight);
	
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };

	// The texture vertices are set up such that we flip the texture vertically.
	// This is so that our top left origin buffers match OpenGL's bottom left texture coordinate system.
	CGRect textureSamplingRect = [self textureSamplingRectForCroppingTextureWithAspectRatio:CGSizeMake(frameWidth, frameHeight) toAspectRatio:self.bounds.size];
	GLfloat textureVertices[] = {
		CGRectGetMinX(textureSamplingRect), CGRectGetMaxY(textureSamplingRect),
		CGRectGetMaxX(textureSamplingRect), CGRectGetMaxY(textureSamplingRect),
		CGRectGetMinX(textureSamplingRect), CGRectGetMinY(textureSamplingRect),
		CGRectGetMaxX(textureSamplingRect), CGRectGetMinY(textureSamplingRect),
	};
	
    // Draw the texture on the screen with OpenGL ES 2
    [self renderWithSquareVertices:squareVertices textureVertices:textureVertices];
    
    glBindTexture(CVOpenGLESTextureGetTarget(texture), 0);
    
    // Flush the CVOpenGLESTexture cache and release the texture
    CVOpenGLESTextureCacheFlush(videoTextureCache, 0);
    CFRelease(texture);
}

- (UIImage *)imageFromFramebuffer
{    
    //    http://stackoverflow.com/questions/3274244/memory-map-uiimage
	
    releasePixelDataCallback(NULL, _glReadPixelsBuffer, _glReadPixelsBufferSize);
    
	GLuint _width  = ceilf(self.layer.bounds.size.width  * self.layer.contentsScale);
	GLuint _height = ceilf(self.layer.bounds.size.height * self.layer.contentsScale);

	const size_t bytesPerPixel = 4;

    _glReadPixelsBufferSize = _width * _height * bytesPerPixel;	
	_glReadPixelsBuffer = (GLvoid*) malloc(_glReadPixelsBufferSize);

    glPixelStorei(GL_PACK_ALIGNMENT, bytesPerPixel);
    glReadPixels(0, 0, _width, _height, GL_RGBA, GL_UNSIGNED_BYTE, _glReadPixelsBuffer);
	GetGLError();
	
	CGBitmapInfo bitmapInfoBitMask = kCGImageAlphaLast | kCGBitmapByteOrder32Big; /* XRGB Big Endian */
	const size_t bitsPerComponent = 8;
	const size_t bitsPerPixel = bytesPerPixel * bitsPerComponent;
	const size_t bytesPerRow =  bytesPerPixel * _width;
	
    const CGColorSpaceRef colorspaceRef = CGColorSpaceCreateDeviceRGB();
	
    const CGDataProviderRef dataProviderRef = CGDataProviderCreateWithData(NULL, _glReadPixelsBuffer, _glReadPixelsBufferSize, releasePixelDataCallback);
    
    const CGImageRef framebufferImageRef = CGImageCreate(_width, _height, 
														 bitsPerComponent, bitsPerPixel, bytesPerRow, 
														 colorspaceRef, bitmapInfoBitMask, dataProviderRef,  
														 NULL  /* decode array */, false,  /* should interpolate */
														 kCGRenderingIntentDefault);
    // Clean up 
	CGColorSpaceRelease(colorspaceRef);
	CGDataProviderRelease(dataProviderRef);
    
	
	UIImage *image = [[[UIImage alloc] initWithCGImage:framebufferImageRef] autorelease];
    CGImageRelease(framebufferImageRef);
    
    return image;
}

- (void)dealloc 
{
	if (frameBufferHandle) {
        glDeleteFramebuffers(1, &frameBufferHandle);
        frameBufferHandle = 0;
    }
	
    if (colorBufferHandle) {
        glDeleteRenderbuffers(1, &colorBufferHandle);
        colorBufferHandle = 0;
    }
	
    if (passThroughProgram) {
        glDeleteProgram(passThroughProgram);
        passThroughProgram = 0;
    }
	
    if (videoTextureCache) {
        CFRelease(videoTextureCache);
        videoTextureCache = 0;
    }
    
    [super dealloc];
}

@end
