//
//  XYCache.h
//  UIRefreshControl
//
//  Created by chengbin on 15/6/15.
//  Copyright (c) 2015年 chengbin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XYCache : NSObject

@property  (nonatomic, readonly, copy)  NSString  *name;      //file name ;default:@"com.xycache.shared"

@property  (nonatomic, readonly, copy)  NSString  *directory; // file directory;default:@".../com.xycache.www/com.xycache.shared"

@property  (nonatomic, readwrite, copy) NSString  *rootDir;     // root/first directory; default: @"com.xycache.www"


/*
  note:returns the default singleton instance.
*/
+ (XYCache *)sharedCache;
/*
  name:file name,default:@"com.xycache.shared"
*/
- (instancetype) initWithName:(NSString *)name;
/*
 name:file name
 directory: file directory,default:@".../com.xycache.www/com.xycache.shared"
*/
- (instancetype) initWithName:(NSString *)name directory:(NSString *)directory;
/*
 key:get object with the key.
*/
- (id)objectForKey:(NSString *)key;
/*
 key:using the key to get the object.
*/
- (void)objectForKey:(NSString *)key usingBlock:(void(^)(id <NSCopying>object))block;
/*
 key:using hte key to sure whether there is this object.
*/
- (BOOL)objectExistsForKey:(NSString *)key;
/*
 note:cache object.
*/
- (void)setObject:(id <NSCopying>)object forKey:(NSString *)aKey;
/*
 note:remove object from cache and disk.
*/
- (void)removeObjectForKey:(NSString *)aKey;
/*
 note:remove all objects from cache and disk.
*/
- (void)removeAllObjects;
/*
 key:using the key to get the key(==file name) path.
*/
- (NSString *)pathForKey:(NSString *)key;
/*
 path:get the subpaths of the directory at the path.
*/
- (NSArray *)subpathsOfDirectoryAtPath:(NSString *)path;
/*
 path:get the contents Of the directory  at the path.
 */
- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path;
/*
 note:exclude the directroy.
*/
- (void)excludeDirectory;

@end


#if TARGEET_OS_IPHONE
#import <UIKit/UIImage.h>

@interface XYCache (UIImageAdditions)
/*
 key:using the key to get path of image.
*/
- (NSString *)imagePathForKey:(NSString *)key;
/*
 key:using the key to get the image at path of image.
*/
- (UIImage *)imageForKey:(NSString *)key;
/*
 key:using the key to get the image.
*/
- (void)imageForKey:(NSString *)key usingBlock:(void (^)(UIImage *image))block;
/*
 note:cache the image with the key.
*/
- (void)setImage:(UIImage *)image forKey:(NSString *)key;
/*
 note:using hte key to sure whether there is this object.
*/
- (BOOL)imageExistsForKey:(NSString *)key;
/*
 note:using the key to remove the image.
*/
- (void)removeImageForKey:(NSString *)key;
/*
 
*/

@end

#endif