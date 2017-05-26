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
#import "FBRunLoopSpinner.h"
#import "FBSession.h"
#import "FBSpringboardApplication.h"
#import "XCUIApplication+FBHelpers.h"
#import "XCUIDevice+FBHelpers.h"
#import "XCUIElement.h"
#import "XCUIElement+FBIsVisible.h"
#import "XCUIElementQuery.h"
#import "XCUIDevice+AVHelpers.h"
#import "FBErrorBuilder.h"
#import "FBRouteRequest-Private.h"

@implementation FBCustomCommands

+ (NSArray *)routes
{
  return
  @[
    [[FBRoute POST:@"/timeouts"] respondWithTarget:self action:@selector(handleTimeouts:)],
    [[FBRoute POST:@"/timeouts/implicit_wait"] respondWithTarget:self action:@selector(handleTimeouts:)],
    [[FBRoute POST:@"/wda/homescreen"] respondWithTarget:self action:@selector(handleHomescreenCommand:)],
    [[FBRoute POST:@"/wda/homescreen"].withoutSession respondWithTarget:self action:@selector(handleHomescreenCommand:)],
    [[FBRoute POST:@"/wda/homescreenDoubleTap"] respondWithTarget:self action:@selector(handleDoubleTapHomescreenCommand:)],
    [[FBRoute POST:@"/wda/homescreenDoubleTap"].withoutSession respondWithTarget:self action:@selector(handleDoubleTapHomescreenCommand:)],
    [[FBRoute POST:@"/openApp"].withoutSession respondWithTarget:self action:@selector(handleOpenAppCommand:)],
    [[FBRoute POST:@"/wda/deactivateApp"] respondWithTarget:self action:@selector(handleDeactivateAppCommand:)],
    [[FBRoute POST:@"/wda/keyboard/dismiss"] respondWithTarget:self action:@selector(handleDismissKeyboardCommand:)],
    [[FBRoute POST:@"/setToPasteboard"] respondWithTarget:self action:@selector(handleSetToPasteboard:)],
    [[FBRoute POST:@"/connectRunApp"] respondWithTarget:self action:@selector(handleRefreshSessionCommand:)],
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

+ (id<FBResponsePayload>)handleRefreshSessionCommand:(FBRouteRequest *)request
{
    [request.session refreshTestingApplication];
    return FBResponseWithOK();
}

+ (id<FBResponsePayload>)handleDismissKeyboardCommand:(FBRouteRequest *)request
{
  [request.session.application dismissKeyboard];
  NSError *error;
  NSString *errorDescription = @"The keyboard cannot be dismissed. Try to dismiss it in the way supported by your application under test.";
  if ([UIDevice.currentDevice userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    errorDescription = @"The keyboard on iPhone cannot be dismissed because of a known XCTest issue. Try to dismiss it in the way supported by your application under test.";
  }
  BOOL isKeyboardNotPresent =
  [[[[FBRunLoopSpinner new]
     timeout:5]
    timeoutErrorMessage:errorDescription]
   spinUntilTrue:^BOOL{
     XCUIElement *foundKeyboard = [[FBApplication fb_activeApplication].query descendantsMatchingType:XCUIElementTypeKeyboard].element;
     return !(foundKeyboard.exists && foundKeyboard.fb_isVisible);
   }
   error:&error];
  if (!isKeyboardNotPresent) {
    return FBResponseWithError(error);
  }
  return FBResponseWithOK();
}

@end
