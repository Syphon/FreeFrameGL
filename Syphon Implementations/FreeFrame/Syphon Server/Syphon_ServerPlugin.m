/*
    Syphon_ServerPlugin.m
    Syphon Server
	
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

#import "Syphon_ServerPlugin.h"
#import "FFContext.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/CGLMacro.h>

#define kSyphonFFServer_UntitledServerName @"Untitled"

@implementation Syphon_ServerPlugin

+ (FFPluginType)type
{
	/* Return one of kFFPluginTypeEffect or kFFPluginTypeSource */
	return kFFPluginTypeEffect;
}

+ (NSUInteger)minimumImageInputCount
{
	/* Return the smallest number of image inputs your plugin will use. */
	return 1;
}

+ (NSUInteger)maximumImageInputCount
{
	/* Return the largest number of image inputs your plugin will use. */
	return 1;
}

+ (NSDictionary *)attributes
{
	/* Return a dictionary with the attributes for your plugin. */
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Syphon Server", FFPluginAttributesNameKey,
			@"Copyright (c) 2010 Tom Butterworth, All Rights Reserved.", FFPluginAttributesAuthorKey,
			@"SphS", FFPluginAttributesIdentifierKey, /* Replace XxXx with a unique four-character code */
			@"Server for Syphon.", FFPluginAttributesDescriptionKey,
			[NSNumber numberWithUnsignedInt:0], FFPluginAttributesMajorVersionKey,
			[NSNumber numberWithUnsignedInt:3], FFPluginAttributesMinorVersionKey,
			nil];
	
}

+ (NSArray *)parameterAttributes
{
	/* Return an array of dictionaries describing the input parameters. Hosts will see them in the order specified here */
	return [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"Name", FFPluginParameterAttributesNameKey,
									  FFPluginParameterTypeString, FFPluginParameterAttributesTypeKey,
									  kSyphonFFServer_UntitledServerName, FFPluginParameterAttributesDefaultValueKey,
									  nil],
									 [NSDictionary dictionaryWithObjectsAndKeys:@"Monitor", FFPluginParameterAttributesNameKey,
									  FFPluginParameterTypeBoolean, FFPluginParameterAttributesTypeKey,
									  [NSNumber numberWithBool:YES], FFPluginParameterAttributesDefaultValueKey,
									  nil],nil];
}

- (id)initWithContext:(FFContext *)context
{
    self = [super initWithContext:context];
	if (self)
	{	
		
		/* Your init stuff here */
		_server = [[SyphonServer alloc] initWithName:kSyphonFFServer_UntitledServerName
											 context:CGLGetCurrentContext()
											 options:nil];
		
	}
	return self;
}

- (void)finalize
{
	
	[super finalize];
}

- (void)dealloc
{
	[_server release];
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
		NSString *name = [self stringValueForParameterAtIndex:0];
		if ([name length] == 0)
		{
			name = kSyphonFFServer_UntitledServerName;
		}
		[_server setName:name];
	}
	
	CGLContextObj cgl_ctx = CGLGetCurrentContext();
	
	glClearColor(0.0, 0.0, 0.0, 1);
	glClear(GL_COLOR_BUFFER_BIT);

	id <FFTextureProvider> input = [self inputAtIndex:0];
	if (input)
	{
		[_server publishFrameTexture:input.textureName
					   textureTarget:GL_TEXTURE_2D
						 imageRegion:NSMakeRect(0.0, 0.0, input.imageWidth, input.imageHeight)
				   textureDimensions:NSMakeSize(input.textureWidth, input.textureHeight)
							 flipped:NO];

		if ([self booleanValueForParameterAtIndex:1])
		{
			glMatrixMode(GL_PROJECTION);
			glPushMatrix();
			glLoadIdentity();
			
			glOrtho(self.context.originX, self.context.originX + self.context.width, self.context.originY, self.context.originY + self.context.height, -1, 1);
			
			glMatrixMode(GL_MODELVIEW);
			glPushMatrix();
			glLoadIdentity();
			
			glEnable(GL_TEXTURE_2D);
			glBindTexture(GL_TEXTURE_2D, input.textureName);
				
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);				
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
			
			glColor4f(1.0, 1.0, 1.0, 1.0);
			
			GLfloat tax, tay, tbx, tby, tcx, tcy, tdx, tdy, vax, vay, vbx, vby, vcx, vcy, vdx, vdy;
			
			tax = tbx = 0.0;
			tay = tdy = 0.0;
			tby = tcy = (float)input.imageHeight / (float)input.textureHeight;
			tcx = tdx = (float)input.imageWidth / (float)input.textureWidth;
			
			GLfloat tex_coords[] =
			{
				tax, tay,
				tbx, tby,
				tcx, tcy,
				tdx, tdy
			};
			
			vax = vbx = self.context.originX;
			vcx = vdx = self.context.originX + self.context.width;
			vay = vdy = self.context.originY;
			vby = vcy = self.context.originY + self.context.height;
			
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
			
			glBindTexture(GL_TEXTURE_2D, 0);

			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);				
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_R, GL_REPEAT);
						
			glDisable(GL_TEXTURE_2D);
			
			glMatrixMode(GL_MODELVIEW);
			glPopMatrix();
			
			glMatrixMode(GL_PROJECTION);
			glPopMatrix();
		}
	}
	/*
	 If you use FBOs for rendering, you must restore the host's bound FBO when you are finished rendering. 
	 
		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, [self.context boundFBO]);
	 
	 You must also restore any GL states you changed to their default state.
	 */

	return YES;
}
@end
