/*
    FFContext.h
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

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>

/* This class-name must be unique - two plugins can't share it.
   FFContext is declared as an alias of this at the end of this file. */

#define FFContextUniqueClassName Syphon_ServerFFContext

@interface FFContextUniqueClassName : NSObject {
@private
	GLuint _originX;
	GLuint _originY;
	GLuint _width;
	GLuint _height;
	GLuint _boundFBO;
}
@property (readonly) GLuint originX;
@property (readonly) GLuint originY;
@property (readonly) GLuint width;
@property (readonly) GLuint height;
@end

@compatibility_alias FFContext FFContextUniqueClassName;