//
//  WVElementPropsDomainController.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Weaver/WVElementPropsDomainController.h>

#import <Weaver/WVDOMContext.h>
#import <Weaver/NSObject+WVCSSRuleMatchesProviding.h>

#import <Weaver/PDCSSTypes.h>

#import <Texture/Texture.h>

#import <UIKit/UIKit.h>

@implementation WVElementPropsDomainController

@dynamic domain;

+ (WVElementPropsDomainController *)defaultInstance;
{
  static WVElementPropsDomainController *defaultInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    defaultInstance = [[WVElementPropsDomainController alloc] init];
  });
  return defaultInstance;
}

+ (Class)domainClass;
{
  return [PDCSSDomain class];
}

#pragma mark - PDCSSCommandDelegate

- (void)domain:(PDDynamicDebuggerDomain *)domain enableWithCallback:(void (^)(id))callback
{
  NSLog(@"CSS Domain enable");
  callback(nil);
}

- (void)domain:(PDDynamicDebuggerDomain *)domain disableWithCallback:(void (^)(id))callback
{
  NSLog(@"CSS Domain disable");
  callback(nil);
}

- (void)domain:(PDCSSDomain *)domain getMatchedStylesForNodeWithNodeId:(NSNumber *)nodeId includePseudo:(NSNumber *)includePseudo includeInherited:(NSNumber *)includeInherited callback:(void (^)(NSArray<PDCSSRuleMatch *> *, NSArray *, NSArray *, id))callback
{
  NSObject *object = [[self context] objectForKey:nodeId];
  NSArray<PDCSSRuleMatch *> *matches;
  if (object != nil) {
    matches = [object wv_generateCSSRuleMatchesWithObjectId:nodeId];
  }
  callback(matches, nil, nil, nil);
}

- (void)domain:(PDCSSDomain *)domain setStyleTextsWithEdits:(NSArray<PDCSSStyleDeclarationEdit *> *)edits callback:(void (^)(NSArray<PDCSSStyle *> *, id))callback
{
  NSMutableArray<PDCSSStyle *> *result = [NSMutableArray array];
  for (PDCSSStyleDeclarationEdit *edit in edits) {
    NSString *text = [edit valueForKey:@"text"];
    NSRange range = [text rangeOfString:@":"];
    if (range.location == NSNotFound) {
      continue;
    }
    
    NSString *propertyName = [[text substringToIndex:range.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSMutableCharacterSet *valueTrimmingCharacterSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [valueTrimmingCharacterSet addCharactersInString:@";"];
    NSString *propertyValue = [[text substringFromIndex:range.location + range.length] stringByTrimmingCharactersInSet:valueTrimmingCharacterSet];
    
    PDCSSProperty *property = [PDCSSProperty propertyWithName:propertyName value:propertyValue];
    
    NSArray<NSString *> *stringComponents = [[edit valueForKey:@"styleSheetId"] componentsSeparatedByString:@"."];
    if (stringComponents.count != 2) {
      continue;
    }
    
    NSNumber *objectId = [WVDOMContext keyFromString:stringComponents[0]];
    NSObject *object = [[self context] objectForKey:objectId];
    ASDisplayNodeAssertNotNil(object, @"Object with given ID not found");
    
    NSString *ruleMatchName = stringComponents[1];
    
    [object wv_applyCSSProperty:property withRuleMatchName:ruleMatchName];
    
    PDCSSRuleMatch *updatedRuleMatch = [object wv_generateCSSRuleMatchWithName:ruleMatchName objectId:objectId];
    [result addObject:updatedRuleMatch.rule.style];
  }
  
  callback(result, nil);
}

#pragma mark Private methods

- (nullable WVDOMContext *)context
{
  return [_dataSource contextForElementPropsDomainController:self];
}

@end
