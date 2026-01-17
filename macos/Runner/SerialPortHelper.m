//
//  SerialPortHelper.m
//  Runner
//
//  Helper to handle NSException from FileHandle operations
//

#import <Foundation/Foundation.h>

NSData* safeReadData(NSFileHandle* handle, NSUInteger length) {
    @try {
        return [handle readDataOfLength:length];
    }
    @catch (NSException* exception) {
        // No data available or error
        return nil;
    }
}
