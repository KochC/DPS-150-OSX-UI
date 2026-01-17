//
//  SerialPortHelper.h
//  Runner
//

#import <Foundation/Foundation.h>

NSData* _Nullable safeReadData(NSFileHandle* _Nonnull handle, NSUInteger length);
