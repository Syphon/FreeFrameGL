/*
    Syphon_ClientPlugin.h
    Syphon Client
	
    Copyright 2010 bangnoise (Tom Butterworth) & vade (Anton Marini).
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE FOR ANY
    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/*
    Based on a FreeFrame Plugin Xcode Template by Tom / bangnoise 2010.
*/

#import "Syphon_ClientPlugin.h"
#import "FFContext.h"
#import <Syphon/Syphon.h>
#import "SyphonNameboundClient.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/CGLMacro.h>

@implementation Syphon_ClientPlugin

+ (FFPluginType)type
{
	/* Return one of kFFPluginTypeEffect or kFFPluginTypeSource */
	return kFFPluginTypeSource;
}

+ (NSUInteger)minimumImageInputCount
{
	/* Return the smallest number of image inputs your plugin will use. */
	return 0;
}

+ (NSUInteger)maximumImageInputCount
{
	/* Return the largest number of image inputs your plugin will use. */
	return 0;
}

+ (NSDictionary *)attributes
{
	/* Return a dictionary with the attributes for your plugin. */
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Syphon Client", FFPluginAttributesNameKey,
			@"Copyright (c) vade (Anton Marini) & bangnoise (Tom Butterworth) 2010 - Creative Commons Non Commercial Share Alike Attribution 3.0.", FFPluginAttributesAuthorKey,
			@"SphC", FFPluginAttributesIdentifierKey, /* Replace XxXx with a unique four-character code */
			@"Syphon video source.", FFPluginAttributesDescriptionKey,
			[NSNumber numberWithUnsignedInt:0], FFPluginAttributesMajorVersionKey,
			[NSNumber numberWithUnsignedInt:3], FFPluginAttributesMinorVersionKey,
			nil];
	
}

+ (NSArray *)parameterAttributes
{
	/* Return an array of dictionaries describing the input parameters. Hosts will see them in the order specified here */
	return [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"App Name", FFPluginParameterAttributesNameKey,
									  FFPluginParameterTypeString, FFPluginParameterAttributesTypeKey,
									  @"", FFPluginParameterAttributesDefaultValueKey,
									  nil],
									[NSDictionary dictionaryWithObjectsAndKeys:@"Server Name", FFPluginParameterAttributesNameKey,
									 FFPluginParameterTypeString, FFPluginParameterAttributesTypeKey,
									 @"", FFPluginParameterAttributesDefaultValueKey,
									 nil],nil];
}

- (id)initWithContext:(FFContext *)context
{
	if (self = [super initWithContext:context])
	{
		_client = [[SyphonNameboundClient alloc] init];
	}
	return self;
}

- (void)finalize
{
	[super finalize];
}

- (void)dealloc
{
	[_client release];
	[super dealloc];
}

- (BOOL)render
{
	/*	 	 
	 You can check for changes to parameters using didValueChangeForParameterAtIndex: and access parameter values using
		floatValueForParameterAtIndex:
		stringValueForParameterAtIndex:
		booleanValueForParameterAtIndex:
	 
	 The currently valid number of inputs can be queried using [self activeInputCount]. Access inputs using [self inputAtIndex:theIndex]
	 For FreeFrame GL plugins, inputs may be of different sizes. Query the FFTextureProvider object to discover the texture dimensions for
	 each input. Inputs may have texture dimensions beyond the represented image dimensions to conform to POT hardware restrictions.
	 
	 Inputs will always be GL_TEXTURE_2D textures.

	 The current time can be queried using self.time.
	 
	 The context has methods to discover the viewport dimensions.
	 
	 Return YES to indicate success, NO to indicate failure.
	 */
		
	if ([self didValueChangeForParameterAtIndex:0])
	{
		[_client setAppName:[self stringValueForParameterAtIndex:0]];
	}
	if ([self didValueChangeForParameterAtIndex:1])
	{
		[_client setName:[self stringValueForParameterAtIndex:1]];
	}
	[_client lockClient];
	
	CGLContextObj cgl_ctx = CGLGetCurrentContext();
	
	
	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity();
	
	glOrtho(self.context.originX, self.context.width, self.context.originY, self.context.height, -1, 1);

	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glLoadIdentity();
	
	SyphonImage *image = [[_client client] newFrameImageForContext:cgl_ctx];
	if(image)
	{
		glEnable(GL_TEXTURE_RECTANGLE_ARB);
		
		glBindTexture(GL_TEXTURE_RECTANGLE_ARB, image.textureName);
		
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);				
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
		
		glColor4f(1.0, 1.0, 1.0, 1.0);
		
		NSSize scaled;
		float wr = image.textureSize.width / self.context.width;
		float hr = image.textureSize.height / self.context.height;
		float ratio;
		ratio = (hr < wr ? wr : hr);
		scaled = NSMakeSize((image.textureSize.width / ratio), (image.textureSize.height / ratio));

		GLfloat tax, tay, tbx, tby, tcx, tcy, tdx, tdy, vax, vay, vbx, vby, vcx, vcy, vdx, vdy;
		
		tax = tbx = 0.0;
		tay = tdy = 0.0;
		tby = tcy = image.textureSize.height;
		tcx = tdx = image.textureSize.width;
		
		GLfloat tex_coords[] =
		{
			tax, tay,
			tbx, tby,
			tcx, tcy,
			tdx, tdy
		};
		
		NSPoint at = {self.context.originX + (self.context.width / 2) - (scaled.width / 2), self.context.originY + (self.context.height / 2) - (scaled.height / 2)};

		vax = vbx = at.x;
		vcx = vdx = at.x + scaled.width;
		vay = vdy = at.y;
		vby = vcy = at.y + scaled.height;
		
		GLfloat verts[] =
		{
			vax, vay,
			vbx, vby,
			vcx, vcy,
			vdx, vdy
		};
		
		glEnableClientState( GL_TEXTURE_COORD_ARRAY );
		glTexCoordPointer(2, GL_FLOAT, 0, tex_coords );
		glEnableClientState(GL_VERTEX_ARRAY);
		glVertexPointer(2, GL_FLOAT, 0, verts );
		glDrawArrays(GL_QUADS, 0, 4);
		
		// Restore OpenGL states

		glDisableClientState(GL_VERTEX_ARRAY);
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);

		glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);		

		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_LINEAR);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_REPEAT);				
		glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_R, GL_REPEAT);
		
		glDisable(GL_TEXTURE_RECTANGLE_ARB);
		
		[image release];
	}

	glMatrixMode(GL_MODELVIEW);
	glPopMatrix();
	
	glMatrixMode(GL_PROJECTION);
	glPopMatrix();
	
	[_client unlockClient];
	
	/*
	 If you use FBOs for rendering, you must restore the host's bound FBO when you are finished rendering. 
	 
		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, [self.context boundFBO]);
	 
	 You must also restore any GL states you changed to their default state.
	 */

	return YES;
}

@end
