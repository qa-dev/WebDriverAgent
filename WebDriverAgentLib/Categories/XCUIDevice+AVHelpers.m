/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIDevice+FBHelpers.h"

#import <arpa/inet.h>
#import <ifaddrs.h>
#include <notify.h>

#import "FBSpringboardApplication.h"

#import "XCAXClient_iOS.h"

static const NSTimeInterval FBHomeButtonCoolOffTime = 1.;

@implementation XCUIDevice (AVHelpers)

- (BOOL)av_doubleTapHomescreen
{
  [self pressButton:XCUIDeviceButtonHome];
  [self pressButton:XCUIDeviceButtonHome];
  // This is terrible workaround to the fact that pressButton:XCUIDeviceButtonHome is not a synchronous action.
  // On 9.2 some first queries  will trigger additional "go to home" event
  // So if we don't wait here it will be interpreted as double home button gesture and go to application switcher instead.
  // On 9.3 pressButton:XCUIDeviceButtonHome can be slightly delayed.
  // Causing waitUntilApplicationBoardIsVisible not to work properly in some edge cases e.g. like starting session right after this call, while being on home screen
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:FBHomeButtonCoolOffTime]];
  return YES;
}
@end
