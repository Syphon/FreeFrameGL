/*
    FFPlugin.h
    Syphon Client
	
    Copyright 2010-2011 bangnoise (Tom Butterworth) & vade (Anton Marini).
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
#import "FFContext.h"
#import "FFTextureProvider.h"

/* This class-name must be unique - two plugins can't share it.
   FFPlugin is declared as an alias of this at the end of this file. */

#define FFPluginUniqueClassName Syphon_ClientFFPlugin

extern NSString * const FFPluginAttributesAuthorKey;
extern NSString * const FFPluginAttributesNameKey;
extern NSString * const FFPluginAttributesIdentifierKey;
extern NSString * const FFPluginAttributesTypeKey;
extern NSString * const FFPluginAttributesDescriptionKey;
extern NSString * const FFPluginAttributesMajorVersionKey;
extern NSString * const FFPluginAttributesMinorVersionKey;

#if __BIG_ENDIAN__
extern NSString * const FFPixelFormatRGB565;
extern NSString * const FFPixelFormatRGB888;
extern NSString * const FFPixelFormatARGB8888;
#else
extern NSString * const FFPixelFormatBGR565;
extern NSString * const FFPixelFormatBGR888;
extern NSString * const FFPixelFormatBGRA8888;
#endif

extern NSString * const FFPluginParameterAttributesNameKey;
extern NSString * const FFPluginParameterAttributesTypeKey;
extern NSString * const FFPluginParameterAttributesDefaultValueKey;

extern NSString * const FFPluginParameterTypeNumber;
extern NSString * const FFPluginParameterTypeBoolean;
extern NSString * const FFPluginParameterTypeEvent;
extern NSString * const FFPluginParameterTypeRed;
extern NSString * const FFPluginParameterTypeGreen;
extern NSString * const FFPluginParameterTypeBlue;
extern NSString * const FFPluginParameterTypeAlpha;
extern NSString * const FFPluginParameterTypeXPosition;
extern NSString * const FFPluginParameterTypeYPosition;
extern NSString * const FFPluginParameterTypeString;

typedef enum {
	kFFPluginTypeSource,
	kFFPluginTypeEffect
} FFPluginType;

@interface FFPluginUniqueClassName : NSObject {
@private
	FFContext *_context;
	NSTimeInterval _time;
	BOOL *_paramChanged;
	BOOL *_paramIsString;
	void **_paramsRaw;
	id *_paramsObj;
	id <FFTextureProvider> *_inputs;
	NSUInteger _activeInputs;
}
+ (FFPluginType)type;
+ (NSDictionary *)attributes;
+ (NSArray *)parameterAttributes;
+ (NSUInteger)minimumImageInputCount;
+ (NSUInteger)maximumImageInputCount;
- (id)initWithContext:(FFContext *)context;
@property (readonly) FFContext *context;
@property (readwrite, assign, nonatomic) NSTimeInterval time;
- (BOOL)didValueChangeForParameterAtIndex:(NSUInteger)index;
- (float)floatValueForParameterAtIndex:(NSUInteger)index;
- (NSString *)stringValueForParameterAtIndex:(NSUInteger)index;
- (BOOL)booleanValueForParameterAtIndex:(NSUInteger)index;
@property (readwrite, assign, nonatomic) NSUInteger activeInputCount;
- (id <FFTextureProvider>)inputAtIndex:(NSUInteger)index;
- (BOOL)render;
@end

@compatibility_alias FFPlugin FFPluginUniqueClassName;
