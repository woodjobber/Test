//
//  XYCache.m
//  UIRefreshControl
//
//  Created by chengbin on 15/6/15.
//  Copyright (c) 2015年 chengbin. All rights reserved.
//
#define kCACHE_NAME @"com.xycache.shared"
#define kCACHE_DIR @"com.xycache.www"
#import "XYCache.h"


@interface XYCache ()
@property (nonatomic, readonly) NSFileManager *fileManager;
@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, copy, readwrite) NSString *directory;
@property (nonatomic, strong) NSCache *cache;
@property (nonatomic, strong) dispatch_queue_t callbackQueue;
@property (nonatomic, strong) dispatch_queue_t diskQueue;

@end


@implementation XYCache
@synthesize name = _name;
@synthesize directory = _directory;
@synthesize cache = _cache;
@synthesize fileManager = _fileManager;
@synthesize callbackQueue = _callbackQueue;
@synthesize diskQueue = _diskQueue;
@synthesize rootDir= _rootDir;

+ (XYCache *)sharedCache{
    static XYCache *sharedCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCache = [[XYCache alloc]init];
    });
    
    return sharedCache;
}

- (void)dealloc{
#if(!__has_feature(objc_arc))
      [super dealloc];
#endif
    self.directory = nil;
    self.rootDir = nil;
    [self.cache removeAllObjects];
}
- (NSCache *)cache{
    if (!_cache) {
        _cache = [[NSCache alloc]init];
    }
    return _cache;
}

- (NSFileManager *)fileManager{
    if (!_fileManager) {
     _fileManager = [[NSFileManager alloc]init];
    }
    return _fileManager;
}


#pragma mark -- Initializing
- (instancetype)init
{
    self =[super init];
    if (self) {
  
    }
    return self;
}
- (instancetype)initWithName:(NSString *)name{
    return [self initWithName:name directory:nil];
}
- (instancetype)initWithName:(NSString *)name directory:(NSString *)directory{
    if (self= [super init]) {
        if (!name) {
            name = kCACHE_NAME;
        }
       
        self.name = [name copy];
        self.cache.name = self.name;
        if (self.callbackQueue) {
#if(!__has_feature(objc_arc))
            dispatch_release(self.callbackQueue);
            self.callbackQueue = nil;
#endif
            
        }
        if (self.diskQueue) {
#if(!__has_feature(objc_arc))
            dispatch_release(self.diskQueue);
            self.diskQueue = nil;
#endif
            
        }
         self.callbackQueue = dispatch_queue_create([[name stringByAppendingString:@".callback"] cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_CONCURRENT);//生成并发队列，block被分发多个线程中执行
      
      
        self.diskQueue = dispatch_queue_create([[name stringByAppendingString:@".disk"]cStringUsingEncoding:NSUTF8StringEncoding], NULL);
        if (!self.rootDir) {
            self.rootDir = kCACHE_DIR;
        }
        
        if (!directory) {
            NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
            directory = [cachesDirectory stringByAppendingFormat:@"/%@/%@",self.rootDir,self.name];
        }
        self.directory = directory;
        if (![self.fileManager fileExistsAtPath:self.directory]) {
            NSError *error = nil;
            [self.fileManager createDirectoryAtPath:self.directory withIntermediateDirectories:YES attributes:nil error:&error];
            if (error) {
                NSLog(@"Failed to create cache directory:%@",error);
            }else{
                [self _excludeFileFromBackup:[NSURL fileURLWithPath:self.directory]];
            }
        }
    }
    return self;
}


#pragma mark -- geting a Cached value

- (id)objectForKey:(NSString *)key{
 
    // read object from cache ,if it is not exited,and from disk.
    __block id object = [self.cache objectForKey:key];
    if (object) {
        return object;
    }
    NSString *path = [self pathForKey:key];
    if (!path) {
        return nil;
    }
    dispatch_sync(self.diskQueue, ^{
        // read object from disk,synchronously.
        object = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        if (!object) {
            return;
        }
    });
    
    if (object) {
        // store the object from disk in the memory cache.
        [self.cache setObject:object forKey:key];
    }
    return object;
}

- (BOOL)objectExistsForKey:(NSString *)key{
    // 先从 缓存（内存）中读取，如果没有，再从 ，磁盘从读取。
    
    __block BOOL exists = (BOOL)[self.cache objectForKey:key];
    if (exists) {
        return YES;
    }else{
        exists = [self.fileManager fileExistsAtPath:[self _pathForKey:key]];
    }
    return exists;
}

- (void)objectForKey:(NSString *)key usingBlock:(void (^)(id<NSCopying>))block{
    __block XYCache *__weak weakSelf = self;
    if (self.callbackQueue) {
        dispatch_async(self.callbackQueue, ^{
            block([weakSelf objectForKey:key]);
        });
    }
  
}

#pragma mark -- accessing the disk cache

- (NSString *)pathForKey:(NSString *)key{
    if ([self objectExistsForKey:key]) {
        return [self _pathForKey:key];
    }
    return nil;
}

#pragma mark -- Adding and Removing Cached Values

- (void)setObject:(id<NSCopying>)object forKey:(NSString *)aKey{
    if (!object) {
        [self removeObjectForKey:aKey];
        return;
    }
    [self.cache setObject:object forKey:aKey];
    __block XYCache *__weak weakSelf = self;
    dispatch_async(self.diskQueue, ^{
        if ([NSKeyedArchiver archiveRootObject:object toFile:[self _pathForKey:aKey]]) {
            [weakSelf _excludeFileFromBackup:[NSURL fileURLWithPath:[self _pathForKey:aKey]]];
        }
    });
}

- (void)removeObjectForKey:(NSString *)aKey{
    [self.cache removeObjectForKey:aKey];
     __block XYCache *__weak weakSelf = self;
    dispatch_async(self.diskQueue, ^{
        
        [weakSelf.fileManager removeItemAtPath:[self _pathForKey:aKey] error:nil];
    });
}
- (NSArray *)subpathsOfDirectoryAtPath:(NSString *)path{
    if ([self _fileExistsAtPath:path]) {
       return [self.fileManager subpathsOfDirectoryAtPath:path error:nil];
    }
    return nil;
}
- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path{
    if ([self _fileExistsAtPath:path]) {
        return [self.fileManager contentsOfDirectoryAtPath:path error:nil];
    }
    return nil;
}
- (void)removeAllObjects{
    if (self.cache) {
        [self.cache removeAllObjects];
    }
     __block XYCache *__weak weakSelf = self;
    dispatch_async(self.diskQueue, ^{
        for (NSString *path in [self.fileManager contentsOfDirectoryAtPath:self.directory error:nil]) {
            [weakSelf.fileManager removeItemAtPath:[self.directory stringByAppendingPathComponent:path] error:nil];
        }
            [weakSelf.fileManager removeItemAtPath:self.directory error:nil];
        
    });
}

- (void)excludeDirectory{
    [self removeAllObjects];
    __block NSString *_path =nil;
    __block XYCache *__weak weakSelf = self;
    
    dispatch_sync(self.diskQueue, ^{
        
    NSArray *paths  = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectory =  paths!=nil ? [paths lastObject]:nil;
    _path = [cachesDirectory stringByAppendingString:self.rootDir];
    [weakSelf.fileManager removeItemAtPath:_path error:nil];
        
    });
   
    
}


#pragma mark -- private

- (NSString *)_pathForKey:(NSString *)key{
    key = [self safeguardFileNameString:key];
    return [self.directory stringByAppendingPathComponent:key];
}

- (NSString *)safeguardFileNameString:(NSString *)fileName{
    static NSCharacterSet *illegalFileNameCharacters = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"\\?%*|\"<>:"];
    });
    return [[fileName componentsSeparatedByCharactersInSet:illegalFileNameCharacters]componentsJoinedByString:@""];
}

- (BOOL)_excludeFileFromBackup:(NSURL *)fileUrl
{
    NSError *error;
    BOOL result = [fileUrl setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];
    if (error) {
        NSLog(@"Failed to exclude file from backup:%@",error);
    }
    
    return result;
}

- (BOOL)_fileExistsAtPath:(NSString *)path{
    BOOL isDir = NO;
    BOOL exists =[self.fileManager fileExistsAtPath:path isDirectory:&isDir];
    if (isDir && exists) {
        
        return YES;
    }
    return NO;
}
@end


#if TARGET_OS_IPHONE

#import <UIKit/UIScreen.h>
#import <UIKit/UIImage.h>
@implementation XYCache (UIImageAdditions)
- (NSString *)imagePathForKey:(NSString *)key{
    key = [[self class] _keyForImageKey:key];
    
    return [self pathForKey:key];
}

- (UIImage *)imageForKey:(NSString *)key{
    key = [[self class] _keyForImageKey:key];
    __block UIImage *image = [self.cache objectForKey:key];
    if (image) {
        return image;
    }
    NSString *path = [self pathForKey:key];
    if (!path) {
        return nil;
    }
    image = [UIImage imageWithContentsOfFile:path];
    [self.cache setObject:image forKey:key];
    return image;
}
- (void)imageForKey:(NSString *)key usingBlock:(void (^)(UIImage *image))block{
    key = [[self class] _keyForImageKey:key];
    typeof(XYCache) *__weak weakSelf = self;
    dispatch_sync(self.diskQueue , ^{
        UIImage *image = [self.cache objectForKey:key];
        if (!image) {
            image = [[UIImage alloc] initWithContentsOfFile:[weakSelf _pathForKey:key]];
            [self.cache setObject:image forKey:key];
        }
        __block UIImage *blockImage = image;
        block(blockImage);
    });
}
- (void)setImage:(UIImage *)image forKey:(NSString *)key{
    if (!image) {
        
    }
    key = [[self class] _keyForImageKey:key];
    typeof(XYCache) *__weak weakSelf = self;
    
    dispatch_async(self.diskQueue, ^{
        NSString *path = [weakSelf _pathForKey:key];
        
        // Save to memory cache
        [self.cache setObject:image forKey:key];
        
        // Save to disk cache
        [UIImagePNGRepresentation(image) writeToFile:path atomically:YES];
    });
}

- (BOOL)imageExistsForKey:(NSString *)key{
    return [self objectExistsForKey:[[self class] _keyForImageKey:key]];
}

- (void)removeImageForKey:(NSString *)key{
    [self removeObjectForKey:[[self class] _keyForImageKey:key]];
}

#pragma mark -- private
+ (NSString *)_keyForImageKey:(NSString *)imageKey{
    NSString *scale = nil;
    if ([[UIScreen mainScreen]scale] == 3.0f) {
        scale = @"3x";
    }else if ([[UIScreen mainScreen]scale] == 2.0f){
        scale = @"2x";
    }else{
        scale = @"";
    }
    return [imageKey stringByAppendingFormat:@"%@.png",scale];
}

@end

#endif