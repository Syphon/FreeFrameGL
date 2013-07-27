/*
    plugMain.m
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
#import <libkern/OSAtomic.h>
#import "FreeFrame.h"
#import "Syphon_ServerPlugin.h"
#import "FFContext.h"
#import "FFTexture.h"

@interface FFContext (Private)
- (id)initWithOriginX:(GLuint)originX originY:(GLuint)originY width:(NSUInteger)width height:(NSUInteger)height;
- (void)setBoundFBO:(GLuint)fbo;
@end

@interface FFPlugin (Private)
- (void)setValue:(FFMixed)value forParameterAtIndex:(unsigned int)index;
- (FFMixed)valueForParameterAtIndex:(unsigned int)index;
@end

@interface FFTexture (Private)
- (void)setPropertiesFromTextureStruct:(FFGLTextureStruct *)textureStruct;
@end

static FFPluginInfoStruct mPlugInfo;
static FFPluginExtendedInfoStruct mPlugExtendedInfo;
static BOOL mExtendedInfoIsInitted = NO;
static char * mParameterNames = NULL;
static FFMixed *mParameterDefaults = NULL;
static OSSpinLock mLock = OS_SPINLOCK_INIT;

__attribute__((destructor))
static void finalizer()
{
	if (mParameterDefaults != NULL)
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSArray *attributes = [Syphon_ServerPlugin parameterAttributes];
		int i = 0;
		for (NSDictionary *parameter in attributes) {
			if ([[parameter objectForKey:FFPluginParameterAttributesTypeKey] isEqualToString:FFPluginParameterTypeString])
			{
				free(mParameterDefaults[i].PointerValue);
			}
			i++;
		}
		[pool drain];
		free(mParameterDefaults);
	}
	if (mExtendedInfoIsInitted)
	{
		free(mPlugExtendedInfo.About);
		free(mPlugExtendedInfo.Description);
	}
	free(mParameterNames);
}

static void ffcopyNSStringToString(NSString *source, char *destination, int length)
{
	const char *cString;
	cString = [source cStringUsingEncoding:NSASCIIStringEncoding];
	BOOL atStringEnd = NO;
	for (int i = 0; i < length; i++) {
		if (!atStringEnd && (cString[i] == 0))
			atStringEnd = YES;
		destination[i] = atStringEnd ?  0 : cString[i];
	}
}

FFMixed plugMain(FFFunctionCode functionCode, FFMixed inputValue, FFPlugin *instance)
{
	FFMixed result;
//	@try {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		switch (functionCode) {
			case FF_GETINFO:
				
				mPlugInfo.APIMajorVersion = 1;
				mPlugInfo.APIMinorVersion = 5;
				
				NSDictionary *attributes = [Syphon_ServerPlugin attributes];
				NSString *name = [attributes objectForKey:FFPluginAttributesNameKey];
				ffcopyNSStringToString(name, mPlugInfo.PluginName, 16);
				
				NSString *fourCharCode = [attributes objectForKey:FFPluginAttributesIdentifierKey];
				ffcopyNSStringToString(fourCharCode, mPlugInfo.PluginUniqueID, 4);
				
				mPlugInfo.PluginType = (uint32_t)([Syphon_ServerPlugin type] == kFFPluginTypeSource ? FF_PLUGIN_SOURCE : FF_PLUGIN_EFFECT);
				result = (FFMixed)(void *)&mPlugInfo;
				break;
			case FF_INITIALISE:
				result = (FFMixed)FF_SUCCESS;
				break;
			case FF_DEINITIALISE:
				result = (FFMixed)FF_SUCCESS;
				break;
			case FF_GETNUMPARAMETERS:
				result = (FFMixed)(uint32_t)[[Syphon_ServerPlugin parameterAttributes] count];
				break;
			case FF_GETPARAMETERNAME:
				OSSpinLockLock(&mLock);
				if (mParameterNames == NULL)
				{
					NSArray *params = [Syphon_ServerPlugin parameterAttributes];
					mParameterNames = malloc(sizeof(char) * 16 * [params count]);
					int i = 0;
					for (NSDictionary *attributes in params) {
						NSString *name = [attributes objectForKey:FFPluginParameterAttributesNameKey];
						ffcopyNSStringToString(name, &mParameterNames[i], 16);
						i += 16;
					}
				}
				OSSpinLockUnlock(&mLock);
				result = (FFMixed)(void *)&mParameterNames[inputValue.UIntValue * 16];
				break;
			case FF_GETPARAMETERDEFAULT:
				OSSpinLockLock(&mLock);
				if (mParameterDefaults == NULL)
				{
					NSArray *attributes = [Syphon_ServerPlugin parameterAttributes];
					int count = [attributes count];
					mParameterDefaults = malloc(sizeof(FFMixed) * count);
					int i = 0;
					float defaultValue;
					for (NSDictionary *parameter in attributes) {
						if ([[parameter objectForKey:FFPluginParameterAttributesTypeKey] isEqualToString:FFPluginParameterTypeString])
						{
							mParameterDefaults[i].PointerValue = strdup([[parameter objectForKey:FFPluginParameterAttributesDefaultValueKey] cStringUsingEncoding:NSASCIIStringEncoding]);
						}
						else
						{
							defaultValue = [[parameter objectForKey:FFPluginParameterAttributesDefaultValueKey] floatValue];
							mParameterDefaults[i].UIntValue = *(uint32_t *)&defaultValue;
						}					
						i++;
					}
				}
				OSSpinLockUnlock(&mLock);
				result = mParameterDefaults[inputValue.UIntValue];
				break;
			case FF_GETPARAMETERDISPLAY:
				// TODO: is it OK to not support this?
				result = (FFMixed)FF_FAIL;			
				break;
			case FF_SETPARAMETER:
				[instance setValue:((FFSetParameterStruct *)inputValue.PointerValue)->NewParameterValue forParameterAtIndex:((FFSetParameterStruct *)inputValue.PointerValue)->ParameterNumber];
				result = (FFMixed)FF_SUCCESS;
				break;
			case FF_GETPARAMETER:
				result = [instance valueForParameterAtIndex:inputValue.UIntValue];
				break;
			case FF_GETPLUGINCAPS:
				switch (inputValue.UIntValue) {
					case FF_CAP_PROCESSOPENGL:
						result = (FFMixed)FF_SUPPORTED;
						break;
					case FF_CAP_SETTIME:
						// TODO: Maybe allow plugins to indicate this in a class method
						result = (FFMixed)FF_SUPPORTED;
						break;
					case FF_CAP_MINIMUMINPUTFRAMES:					
						result = (FFMixed)(uint32_t)[Syphon_ServerPlugin minimumImageInputCount];
						break;
					case FF_CAP_MAXIMUMINPUTFRAMES:
						result = (FFMixed)(uint32_t)[Syphon_ServerPlugin maximumImageInputCount];
						break;
					case FF_CAP_COPYORINPLACE:
					case FF_CAP_16BITVIDEO:
					case FF_CAP_24BITVIDEO:
					case FF_CAP_32BITVIDEO:
					case FF_CAP_PROCESSFRAMECOPY:
					default:
						result = (FFMixed)FF_UNSUPPORTED;
						break;
				}
				break;
			case FF_GETEXTENDEDINFO:
				OSSpinLockLock(&mLock);
				if (!mExtendedInfoIsInitted)
				{
					NSDictionary *attributes = [Syphon_ServerPlugin attributes];
					NSString *about = [attributes objectForKey:FFPluginAttributesAuthorKey];
					NSString *description = [attributes objectForKey:FFPluginAttributesDescriptionKey];
					mPlugExtendedInfo.About = strdup([about cStringUsingEncoding:NSASCIIStringEncoding]);
					mPlugExtendedInfo.Description = strdup([description cStringUsingEncoding:NSASCIIStringEncoding]);
					mPlugExtendedInfo.PluginMajorVersion = [[attributes objectForKey:FFPluginAttributesMajorVersionKey] unsignedIntValue];
					mPlugExtendedInfo.PluginMinorVersion = [[attributes objectForKey:FFPluginAttributesMinorVersionKey] unsignedIntValue];
					mPlugExtendedInfo.FreeFrameExtendedDataBlock = NULL;
					mPlugExtendedInfo.FreeFrameExtendedDataSize = 0;
					mExtendedInfoIsInitted = YES;
				}
				OSSpinLockUnlock(&mLock);
				result = (FFMixed)(void *)&mPlugExtendedInfo;
				break;
			case FF_GETPARAMETERTYPE:
			{
				NSString *type = [[[Syphon_ServerPlugin parameterAttributes] objectAtIndex:inputValue.UIntValue] objectForKey:FFPluginParameterAttributesTypeKey];
				if ([type isEqualToString:FFPluginParameterTypeNumber]) {
					result.UIntValue = FF_TYPE_STANDARD;
				} else if ([type isEqualToString:FFPluginParameterTypeBoolean])	{
					result.UIntValue = FF_TYPE_BOOLEAN;
				} else if ([type isEqualToString:FFPluginParameterTypeEvent]) {
					result.UIntValue = FF_TYPE_EVENT;
				} else if ([type isEqualToString:FFPluginParameterTypeRed])	{
					result.UIntValue = FF_TYPE_RED;
				} else if ([type isEqualToString:FFPluginParameterTypeGreen]) {
					result.UIntValue = FF_TYPE_GREEN;
				} else if ([type isEqualToString:FFPluginParameterTypeBlue]) {
					result.UIntValue = FF_TYPE_BLUE;
				} else if ([type isEqualToString:FFPluginParameterTypeAlpha]) {
					result.UIntValue = FF_TYPE_ALPHA;
				} else if ([type isEqualToString:FFPluginParameterTypeXPosition]) {
					result.UIntValue = FF_TYPE_XPOS;
				} else if ([type isEqualToString:FFPluginParameterTypeYPosition]) {
					result.UIntValue = FF_TYPE_YPOS;
				} else if ([type isEqualToString:FFPluginParameterTypeString]) {
					result.UIntValue = FF_TYPE_TEXT;
				} else {
					result.UIntValue = FF_FAIL;
				}
				break;
			}
			case FF_GETINPUTSTATUS:
				result = (FFMixed)FF_SUCCESS;
				break;
			case FF_SETTIME:
				[instance setTime:*(NSTimeInterval *)inputValue.PointerValue];
				result = (FFMixed)FF_SUCCESS;
				break;
			case FF_PROCESSOPENGL:
			{
				FFProcessOpenGLStruct *frameInfo = (FFProcessOpenGLStruct *)inputValue.PointerValue;
				for (int i = 0; i < frameInfo->numInputTextures; i++) {
					[(FFTexture *)[instance inputAtIndex:i] setPropertiesFromTextureStruct:frameInfo->ppInputTextures[i]];
				}
				[instance.context setBoundFBO:frameInfo->HostFBO];
				[instance setActiveInputCount:frameInfo->numInputTextures];
				result = [instance render] ? (FFMixed)FF_SUCCESS : (FFMixed)FF_FAIL;
				break;
			}
			case FF_INSTANTIATEGL:
			{
				FFGLViewportStruct *viewport = (FFGLViewportStruct *)inputValue.PointerValue;
				FFContext *context = [[FFContext alloc] initWithOriginX:viewport->X originY:viewport->Y width:viewport->Width height:viewport->Height];
				Syphon_ServerPlugin *newInstance = [[Syphon_ServerPlugin alloc] initWithContext:context];
				[context release];
				
				NSArray *attributes = [Syphon_ServerPlugin parameterAttributes];
				int count = [attributes count];
				for (unsigned int i = 0; i < count; i++) {
					[newInstance setValue:plugMain(FF_GETPARAMETERDEFAULT, (FFMixed)i, NULL) forParameterAtIndex:i];
				}
				result = (FFMixed)(void *)newInstance;
				break;
			}
			case FF_DEINSTANTIATEGL:
				[instance release];
				result = (FFMixed)FF_SUCCESS;
				break;
			case FF_PROCESSFRAME:
			case FF_PROCESSFRAMECOPY:				
			case FF_INSTANTIATE:
			case FF_DEINSTANTIATE:				
			default:
				result = (FFMixed)FF_FAIL;
				break;
		}
		[pool drain];
//	}
//	@catch ( NSException *e ) {
//		// We do nothing with the exception, we just need the handler to be in place.
//	}
	return result;
}
