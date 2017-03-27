/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface XCUIDevice (AVHelpers)

/**
 Double click on homescreen button

 @return YES if the operation succeeds, otherwise NO.
 */
- (BOOL)av_doubleTapHomescreen;

@end

NS_ASSUME_NONNULL_END
