#import "FileStreamOperation.h"
#import <CommonCrypto/CommonDigest.h>

//// 把FileStreamOpenration类保存到UserDefault中
//static NSString *const UserDefaultFileInfo = @"UserDefaultFileInfo";

#pragma mark - FileStreamOperation

@interface FileStreamOperation ()
@property (nonatomic, copy) NSString                          *fileName;
@property (nonatomic, assign) NSUInteger                      fileSize;
@property (nonatomic, copy) NSString                          *filePath;
@property (nonatomic, strong) NSArray<FileFragment*>          *fileFragments;
@property (nonatomic, strong) NSFileHandle                    *readFileHandle;
@property (nonatomic, strong) NSFileHandle                    *writeFileHandle;
@property (nonatomic, assign) BOOL                            isReadOperation;
@end

@implementation FileStreamOperation

+ (instancetype)sharedOperation
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

+ (NSString *)fileKey {
    
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef cfstring = CFUUIDCreateString(kCFAllocatorDefault, uuid);
    const char *cStr = CFStringGetCStringPtr(cfstring,CFStringGetFastestEncoding(cfstring));
    unsigned char result[16];
    CC_MD5( cStr, (unsigned int)strlen(cStr), result );
    CFRelease(uuid);
    
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%08lx",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15],
            (unsigned long)(arc4random() % NSUIntegerMax)];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:[self fileName] forKey:@"fileName"];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:[self fileSize]] forKey:@"fileSize"];
    [aCoder encodeObject:[self filePath] forKey:@"filePath"];
    [aCoder encodeObject:[self fileFragments] forKey:@"fileFragments"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self != nil) {
        [self setFileName:[aDecoder decodeObjectForKey:@"fileName"]];
        [self setFileSize:[[aDecoder decodeObjectForKey:@"fileSize"] unsignedIntegerValue]];
        [self setFilePath:[aDecoder decodeObjectForKey:@"filePath"]];
        [self setFileFragments:[aDecoder decodeObjectForKey:@"fileFragments"]];
    }
    
    return self;
}


- (BOOL)getFileInfoAtPath:(NSString*)path {
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if (![fileMgr fileExistsAtPath:path]) {
        NSLog(@"文件不存在：%@",path);
        return NO;
    }
    
    self.filePath = path;
    
    NSDictionary *attr =[fileMgr attributesOfItemAtPath:path error:nil];
    self.fileSize = attr.fileSize;
    
    NSString *fileName = [path lastPathComponent];
    self.fileName = fileName;
    
    return YES;
}

// 若为读取文件数据，打开一个已存在的文件。
// 若为写入文件数据，如果文件不存在，会创建的新的空文件。
- (instancetype)initFileOperationAtPath:(NSString*)path forReadOperation:(BOOL)isReadOperation {
    
    if (self = [super init]) {
        self.isReadOperation = isReadOperation;
        if (_isReadOperation) {
            if (![self getFileInfoAtPath:path]) {
                return nil;
            }
            self.readFileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
            [self cutFileForFragments];
        } else {
            NSFileManager *fileMgr = [NSFileManager defaultManager];
            if (![fileMgr fileExistsAtPath:path]) {
                [fileMgr createFileAtPath:path contents:nil attributes:nil];
            }
            
            if (![self getFileInfoAtPath:path]) {
                return nil;
            }
            
            self.writeFileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
        }
    }
    
    return self;
}

#pragma mark - 读操作
// 切分文件片段
- (void)cutFileForFragments {
    
    NSUInteger offset = FileFragmentMaxSize;
    // 块数
    NSUInteger chunks = (_fileSize%offset==0)?(_fileSize/offset):(_fileSize/(offset) + 1);
    
    NSMutableArray<FileFragment *> *fragments = [[NSMutableArray alloc] initWithCapacity:0];
    for (NSUInteger i = 0; i < chunks; i ++) {
        
        FileFragment *fFragment = [[FileFragment alloc] init];
        fFragment.fragmentStatus = NO;
        fFragment.fragmentId = [[self class] fileKey];
        fFragment.fragementOffset = i * offset;
        
        if (i != chunks - 1) {
            fFragment.fragmentSize = offset;
        } else {
            fFragment.fragmentSize = _fileSize - fFragment.fragementOffset;
        }
        
        [fragments addObject:fFragment];
    }
    
    self.fileFragments = fragments;
}

// 通过分片信息读取对应的片数据
- (NSData*)readDateOfFragment:(FileFragment*)fragment {
    
    if (fragment) {
        [self seekToFileOffset:fragment.fragementOffset];
        return [_readFileHandle readDataOfLength:fragment.fragmentSize];
    }
    
    return nil;
}

- (NSData*)readDataOfLength:(NSUInteger)bytes {
    return [_readFileHandle readDataOfLength:bytes];
}


- (NSData*)readDataToEndOfFile {
    return [_readFileHandle readDataToEndOfFile];
}

#pragma mark - 写操作

// 写入文件数据
- (void)writeData:(NSData *)data {
    [_writeFileHandle writeData:data];
}

#pragma mark - common
// 获取当前偏移量
- (NSUInteger)offsetInFile{
    if (_isReadOperation) {
        return [_readFileHandle offsetInFile];
    }
    
    return [_writeFileHandle offsetInFile];
}

// 设置偏移量, 仅对读取设置
- (void)seekToFileOffset:(NSUInteger)offset {
    [_readFileHandle seekToFileOffset:offset];
}

// 将偏移量定位到文件的末尾
- (NSUInteger)seekToEndOfFile{
    if (_isReadOperation) {
        return [_readFileHandle seekToEndOfFile];
    }
    
    return [_writeFileHandle seekToEndOfFile];
}

// 关闭文件
- (void)closeFile {
    if (_isReadOperation) {
        [_readFileHandle closeFile];
    } else {
        [_writeFileHandle closeFile];
    }
}

@end

#pragma mark - FileFragment

@implementation FileFragment

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:[self fragmentId] forKey:@"fragmentId"];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:[self fragmentSize]] forKey:@"fragmentSize"];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:[self fragementOffset]] forKey:@"fragementOffset"];
    [aCoder encodeObject:[NSNumber numberWithUnsignedInteger:[self fragmentStatus]] forKey:@"fragmentStatus"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self != nil) {
        [self setFragmentId:[aDecoder decodeObjectForKey:@"fragmentId"]];
        [self setFragmentSize:[[aDecoder decodeObjectForKey:@"fragmentSize"] unsignedIntegerValue]];
        [self setFragementOffset:[[aDecoder decodeObjectForKey:@"fragementOffset"] unsignedIntegerValue]];
        [self setFragmentStatus:[[aDecoder decodeObjectForKey:@"fragmentStatus"] boolValue]];
    }
    
    return self;
}

@end
