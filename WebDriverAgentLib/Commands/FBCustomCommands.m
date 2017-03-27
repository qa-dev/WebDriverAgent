/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBCustomCommands.h"

#import <XCTest/XCUIDevice.h>

#import "FBApplication.h"
#import "FBConfiguration.h"
#import "FBExceptionHandler.h"
#import "FBKeyboard.h"
#import "FBResponsePayload.h"
#import "FBRoute.h"
#import "FBRouteRequest.h"
#import "FBSession.h"
#import "FBSpringboardApplication.h"
#import "XCUIApplication+FBHelpers.h"
#import "XCUIDevice+FBHelpers.h"
#import "XCUIElement.h"
#import "XCUIElementQuery.h"
#import "XCUIDevice+AVHelpers.h"
#import "FBErrorBuilder.h"

@implementation FBCustomCommands

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute POST:@"/homescreen"].withoutSession respondWithTarget:self action:@selector(handleHomescreenCommand:)],
    [[FBRoute POST:@"/homescreenDoubleTap"].withoutSession respondWithTarget:self action:@selector(handleDoubleTapHomescreenCommand:)],
    [[FBRoute POST:@"/openApp"].withoutSession respondWithTarget:self action:@selector(handleOpenAppCommand:)],
    [[FBRoute POST:@"/deactivateApp"] respondWithTarget:self action:@selector(handleDeactivateAppCommand:)],
    [[FBRoute POST:@"/timeouts"] respondWithTarget:self action:@selector(handleTimeouts:)],
    [[FBRoute POST:@"/timeouts/implicit_wait"] respondWithTarget:self action:@selector(handleTimeouts:)],
    [[FBRoute POST:@"/setToPasteboard"] respondWithTarget:self action:@selector(handleSetToPasteboard:)],
  ];
}


#pragma mark - Commands

+ (id<FBResponsePayload>)handleHomescreenCommand:(FBRouteRequest *)request
{
  NSError *error;
  if (![[XCUIDevice sharedDevice] fb_goToHomescreenWithError:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithOK();
}


+ (id<FBResponsePayload>)handleDoubleTapHomescreenCommand:(FBRouteRequest *)request
{
  if (![[XCUIDevice sharedDevice] av_doubleTapHomescreen]) {
    NSError *error = [[[FBErrorBuilder builder] withDescriptionFormat:@"Can't double click on home button"] build];
    return FBResponseWithError(error);
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleOpenAppCommand:(FBRouteRequest *)request
{
  NSString *applicationIdentifier = request.arguments[@"name"];
  NSError *error;
  if (![[FBSpringboardApplication fb_springboard] fb_tapApplicationWithIdentifier:applicationIdentifier error:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithOK();
}


+ (id<FBResponsePayload>)handleDeactivateAppCommand:(FBRouteRequest *)request
{
  NSNumber *requestedDuration = request.arguments[@"duration"];
  NSTimeInterval duration = (requestedDuration ? requestedDuration.doubleValue : 3.);
  NSError *error;
  if (![request.session.application fb_deactivateWithDuration:duration error:&error]) {
    return FBResponseWithError(error);
  }
  return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleTimeouts:(FBRouteRequest *)request
{
  // This method is intentionally not supported.
  NSDictionary *result = @{
          @"value": @"200",
  };
  return FBResponseWithStatus(FBCommandStatusNoError, result);
}

+ (id<FBResponsePayload>)handleSetToPasteboard:(FBRouteRequest *)request
{
  NSString *requestedText = request.arguments[@"value"];
  UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
  pasteboard.string = requestedText;

  return FBResponseWithOK();
}

@end
