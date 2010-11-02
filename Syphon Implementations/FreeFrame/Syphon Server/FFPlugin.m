/*
    FFPlugin.m
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

#import "FFPlugin.h"
#import "FreeFrame.h"
#import "FFTexture.h"
#import "FFContext.h"

NSString * const FFPluginAttributesAuthorKey = @"FFPluginAttributesAuthorKey";
NSString * const FFPluginAttributesNameKey = @"FFPluginAttributesNameKey";
NSString * const FFPluginAttributesIdentifierKey = @"FFPluginAttributesIdentifierKey";
NSString * const FFPluginAttributesTypeKey = @"FFPluginAttributesTypeKey";
NSString * const FFPluginAttributesDescriptionKey = @"FFPluginAttributesDescriptionKey";
NSString * const FFPluginAttributesMajorVersionKey = @"FFPluginAttributesMajorVersionKey";
NSString * const FFPluginAttributesMinorVersionKey = @"FFPluginAttributesMinorVersionKey";

NSString * const FFPluginParameterAttributesNameKey = @"FFPluginParameterAttributesNameKey";
NSString * const FFPluginParameterAttributesTypeKey = @"FFPluginParameterAttributesTypeKey";
NSString * const FFPluginParameterAttributesDefaultValueKey = @"FFPluginParameterAttributesDefaultValueKey";

NSString * const FFPluginParameterTypeNumber = @"FFPluginParameterTypeNumber";
NSString * const FFPluginParameterTypeBoolean = @"FFPluginParameterTypeBoolean";
NSString * const FFPluginParameterTypeEvent = @"FFPluginParameterTypeEvent";
NSString * const FFPluginParameterTypeRed = @"FFPluginParameterTypeRed";
NSString * const FFPluginParameterTypeGreen = @"FFPluginParameterTypeGreen";
NSString * const FFPluginParameterTypeBlue = @"FFPluginParameterTypeBlue";
NSString * const FFPluginParameterTypeAlpha = @"FFPluginParameterTypeAlpha";
NSString * const FFPluginParameterTypeXPosition = @"FFPluginParameterTypeXPosition";
NSString * const FFPluginParameterTypeYPosition = @"FFPluginParameterTypeYPosition";
NSString * const FFPluginParameterTypeString = @"FFPluginParameterTypeString";

@implementation FFPlugin

@synthesize time = _time, activeInputCount = _activeInputs;

+ (FFPluginType)type
{
	return kFFPluginTypeEffect;
}

+ (NSUInteger)minimumImageInputCount
{
	return 0U;
}

+ (NSUInteger)maximumImageInputCount
{
	return 0U;
}

+ (NSDictionary *)attributes
{
	return [NSDictionary dictionary];
	
}

+ (NSArray *)parameterAttributes
{
	return [NSArray array];
}

- (id)initWithContext:(FFContext *)context
{
	if (self = [super init])
	{
		_context = [context retain];
		NSArray *attributes = [[self class] parameterAttributes];
		int paramCount = [attributes count];
		if (paramCount > 0)
		{
			_paramsObj = malloc(sizeof(id) * paramCount);
			_paramsRaw = malloc(sizeof(FFMixed) * paramCount);
			_paramChanged = malloc(sizeof(BOOL) * paramCount);
			_paramIsString = malloc(sizeof(BOOL) * paramCount);
			if (_paramsObj == NULL || _paramsRaw == NULL || _paramChanged == NULL || _paramIsString == NULL)
			{
				[self release];
				return nil;
			}
			for (int i = 0; i < paramCount; i++) {
				_paramsObj[i] = nil;
				((FFMixed *)_paramsRaw)[i] = (FFMixed)NULL;
				_paramChanged[i] = YES;
				_paramIsString[i] = [[[attributes objectAtIndex:i] objectForKey:FFPluginParameterAttributesTypeKey] isEqualToString:FFPluginParameterTypeString];
			}
		}
		int inputCount = [[self class] maximumImageInputCount];
		if (inputCount > 0)
		{
			_inputs = malloc(sizeof(FFTexture *) * inputCount);
			if (_inputs == NULL)
			{
				[self release];
				return nil;
			}
			for (int i = 0; i < inputCount; i++) {
				_inputs[i] = [[FFTexture alloc] init];
			}
		}
	}
	return self;
}

- (void)finalize
{
	free(_paramsObj);
	free(_paramChanged);
	free(_paramIsString);
	free(_paramsRaw);
	free(_inputs);
	[super finalize];
}

- (void)dealloc
{
	[_context release];
	int paramCount = [[[self class] parameterAttributes] count];
	for (int i = 0; i < paramCount; i++) {
		[_paramsObj[i] release];
	}
	free(_paramsObj);
	free(_paramChanged);
	free(_paramIsString);
	free(_paramsRaw);
	free(_inputs);
	[super dealloc];
}

- (FFContext *)context
{
	return _context;
}

- (void)setValue:(FFMixed)value forParameterAtIndex:(unsigned int)index
{
	// Some apps set parameters every single render pass, yuck
	if (_paramIsString[index])
	{
		// some hosts don't keep string parameters around, unhelpfully, so check for change and copy it immediately
		NSString *oldString = _paramsObj[index];
		NSString *newString;
		if (value.PointerValue != NULL)
		{
			newString = [[NSString alloc] initWithCString:value.PointerValue encoding:NSASCIIStringEncoding];
		} else {
			newString = nil;
		}
		if ((newString && ![oldString isEqualToString:newString])
			|| (newString == nil && oldString != nil))
		{
			_paramsObj[index] = newString;
			[oldString release];
			_paramChanged[index] = YES;
		}
		else
		{
			[newString release];
			_paramChanged[index] = NO;
		}
		((FFMixed *)_paramsRaw)[index] = value; // we'll spit this out at clients again if they ask, but don't use it internally
	}
	else if (((FFMixed *)_paramsRaw)[index].PointerValue != value.PointerValue)
	{
		_paramChanged[index] = YES;
		((FFMixed *)_paramsRaw)[index] = value;
	}
}

- (FFMixed)valueForParameterAtIndex:(unsigned int)index
{
	return ((FFMixed *)_paramsRaw)[index];
}

- (BOOL)didValueChangeForParameterAtIndex:(NSUInteger)index
{
	return _paramChanged[index];
}

- (float)floatValueForParameterAtIndex:(NSUInteger)index
{
	_paramChanged[index] = NO;
	FFMixed value = ((FFMixed *)_paramsRaw)[index];
	return *(float *)&value.UIntValue;
}

- (NSString *)stringValueForParameterAtIndex:(NSUInteger)index
{
	_paramChanged[index] = NO;
	return _paramsObj[index];
}

- (BOOL)booleanValueForParameterAtIndex:(NSUInteger)index
{
	_paramChanged[index] = NO;
	FFMixed value = ((FFMixed *)_paramsRaw)[index];
	return value.UIntValue == 0 ? NO : YES;
}

- (id <FFTextureProvider>)inputAtIndex:(NSUInteger)index
{
	return _inputs[index];
}

- (BOOL)render
{
	return NO;
}

@end
