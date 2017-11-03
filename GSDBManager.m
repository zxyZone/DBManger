//
//  GSDBMannager.h
//  GSDBTest
//
//  Created by Johnson on 17/3/8.
//  Copyright © 2017年 Johnson. All rights reserved.
//

#import "GSDBManager.h"
#import "FMDB.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

#define GSCURRENTDB (FMDatabase *)self.dataBaseDictM[self.dbName]

@interface GSDBManager ()

@property (nonatomic, copy) NSString *dbName;
@property (nonatomic, strong) NSMutableDictionary *dataBaseDictM;

@end

@implementation GSDBManager

static GSDBManager *_instance = nil;

+ (instancetype)shareManager:(NSString *)dbName{
    
    // 1、获取沙盒中数据库的路径
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    
    NSString *tempDBName = nil;
    if (dbName && ![dbName isEqualToString:@""]) {
        tempDBName = dbName;
    }
    else{
        tempDBName = DEFAULT_NAME;
    }
    
    NSString *sqlFilePath = [path stringByAppendingPathComponent:[tempDBName stringByAppendingString:@".sqlite"]];
    
    // 2、判断 caches 文件夹是否存在.不存在则创建
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDirectory = YES;
    BOOL tag = [manager fileExistsAtPath:sqlFilePath isDirectory:&isDirectory];
    
    static GSDBManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.dataBaseDictM = [NSMutableDictionary dictionary];
        if (tag) {
            FMDatabase *dataBase = [FMDatabase databaseWithPath:sqlFilePath];
            [instance.dataBaseDictM setValue:dataBase forKey:tempDBName];
        }
    });
    
    if (!tag) {
        [manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
        // 通过路径创建数据库
        FMDatabase *dataBase = [FMDatabase databaseWithPath:sqlFilePath];
        [instance.dataBaseDictM setValue:dataBase forKey:tempDBName];
    }
    
    instance.dbName = tempDBName;
    
    return instance;
}

+ (GSDBManager *)readDBManger:(NSString *)dbName{
    // 1、获取沙盒中数据库的路径
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    NSString *sqlFilePath = [path stringByAppendingPathComponent:[dbName stringByAppendingString:@".sqlite"]];
    
    NSString *resourcePath =[[NSBundle mainBundle] pathForResource:dbName ofType:@"sqlite"];
    // 2、判断 caches 文件夹是否存在.不存在则创建
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDirectory = YES;
    BOOL tag = [manager fileExistsAtPath:sqlFilePath isDirectory:&isDirectory];
    static GSDBManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      instance = [[self alloc] init];
      instance.dataBaseDictM = [NSMutableDictionary dictionary];
      if (tag) {
            FMDatabase *dataBase = [FMDatabase databaseWithPath:sqlFilePath];
            [instance.dataBaseDictM setValue:dataBase forKey:dbName];
        }
    });
    
    if (!tag) {
        [manager copyItemAtPath:resourcePath toPath:sqlFilePath error:nil];
        // 通过路径创建数据库
        FMDatabase *dataBase = [FMDatabase databaseWithPath:sqlFilePath];
        [instance.dataBaseDictM setValue:dataBase forKey:dbName];
    }
    
    instance.dbName = dbName;
    
    return instance;

}

- (BOOL)createTable:(Class)modelClass{
    
    return [self createTable:modelClass autoCloseDB:YES];
}

- (BOOL)insertModel:(id)model{
    if ([model isKindOfClass:[NSArray class]] || [model isKindOfClass:[NSMutableArray class]]) {
        NSArray *modelArr = (NSArray *)model;
        return [self insertModelArr:modelArr];
    }
    else{
        return [self insertModel:model autoCloseDB:YES];
    }
}

- (id)queryModel:(Class)modelClass byID:(NSString *)dbId{
    return [self queryModel:modelClass byID:dbId autoCloseDB:YES];
}

- (id)queryModel:(Class)modelClass byColumnName:(NSString*)columnName Value:(NSString *)value{
    return [self queryModel:modelClass byColumnName:columnName Value:value autoCloseDB:YES];
}


- (NSArray *)queryModelArr:(Class)modelClass{
    return  [self queryModelArr:modelClass autoCloseDB:YES];
}

- (BOOL)updateModel:(id)model byID:(NSString *)dbId{
    return [self updateModel:model byID:dbId autoCloseDB:YES];
}

- (BOOL)dropTable:(Class)modelClass{
    if ([GSCURRENTDB open]) {

        if(![self isExitTable:modelClass autoCloseDB:NO])return NO;
        // 删除数据
        NSMutableString *sql = [NSMutableString stringWithFormat:@"DROP TABLE %@;",modelClass];
        BOOL success = [GSCURRENTDB executeUpdate:sql];
        [GSCURRENTDB close];
        return success;
    }
    else{
        return NO;
    }
}

- (BOOL)dropDB{
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    NSString *sqlFilePath = [path stringByAppendingPathComponent:[self.dbName stringByAppendingString:@".sqlite"]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager removeItemAtPath:sqlFilePath error:NULL];
}

- (BOOL)deleteAllModel:(Class)modelClass{
    if ([GSCURRENTDB open]) {

        if(![self isExitTable:modelClass autoCloseDB:NO])return NO;
        NSArray *modelArr = [self queryModelArr:modelClass autoCloseDB:NO];
        if (modelArr && modelArr.count) {
            // 删除数据
            NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM %@;",modelClass];
            BOOL success = [GSCURRENTDB executeUpdate:sql];
            [GSCURRENTDB close];
            return success;
        }
        return NO;
    }
    else{
        return NO;
    }
}

- (BOOL)deleteModel:(Class)modelClass byId:(NSString *)dbId{
    if ([GSCURRENTDB open]) {
//        GS_ISEXITTABLE(modelClass);
        if(![self isExitTable:modelClass autoCloseDB:NO])return NO;
        if ([self queryModel:modelClass byID:dbId autoCloseDB:NO]) {
            // 删除数据
            NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM %@ WHERE  id = '%@';",modelClass,dbId];
            BOOL success = [GSCURRENTDB executeUpdate:sql];
            [GSCURRENTDB close];
            return success;
        }
        return NO;
    }
    else{
        return NO;
    }
}

- (BOOL)isExitTable:(Class)modelClass{
    return [self isExitTable:modelClass autoCloseDB:YES];
}

#pragma mark -- private method

- (NSString *)createTableSQL:(Class)modelClass{
    NSMutableString *sqlPropertyM = [NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id INTEGER PRIMARY KEY AUTOINCREMENT ",modelClass];
    
    unsigned int outCount;
    Ivar * ivars = class_copyIvarList(modelClass, &outCount);
    for (int i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
        if([[key substringToIndex:1] isEqualToString:@"_"]){
            key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
        [sqlPropertyM appendFormat:@", %@",key];
    }
    [sqlPropertyM appendString:@")"];
    
    return sqlPropertyM;
}

/**
 *  创建插入表的SQL语句
 */
- (NSString *)createInsertSQL:(id)model{
    NSMutableString *sqlValueM = [NSMutableString stringWithFormat:@"INSERT OR REPLACE INTO %@ (",[model class]];
    unsigned int outCount;
    Ivar * ivars = class_copyIvarList([model class], &outCount);
    for (int i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
        if([[key substringToIndex:1] isEqualToString:@"_"]){
            key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
        
        if (i == 0) {
            [sqlValueM appendString:key];
        }
        else{
            [sqlValueM appendFormat:@", %@",key];
        }
    }
    [sqlValueM appendString:@") VALUES ("];
    
    for (int i = 0; i < outCount; i ++) {
        Ivar ivar = ivars[i];
        NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
        if([[key substringToIndex:1] isEqualToString:@"_"]){
            key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
        
        id value = [model valueForKey:key];
        if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]] || [value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSMutableArray class]]) {
            value = [NSString stringWithFormat:@"%@",value];
        }
        if (i == 0) {
            // sql 语句中字符串需要单引号或者双引号括起来
            [sqlValueM appendFormat:@"%@",[value isKindOfClass:[NSString class]] ? [NSString stringWithFormat:@"'%@'",value] : value];
        }
        else{
            [sqlValueM appendFormat:@", %@",[value isKindOfClass:[NSString class]] ? [NSString stringWithFormat:@"'%@'",value] : value];
        }
    }

    [sqlValueM appendString:@");"];
    
    return sqlValueM;
}

- (BOOL)isExitTable:(Class)modelClass autoCloseDB:(BOOL)autoCloseDB{
    if ([GSCURRENTDB open]){

        FMResultSet *rs = [GSCURRENTDB executeQuery:@"select count(*) as 'count' from sqlite_master where type ='table' and name = ?", modelClass];
        while ([rs next]){
            NSInteger count = [rs intForColumn:@"count"];
            
            if (0 == count){
                // 操作完毕是否需要关闭
                if (autoCloseDB) {
                    [GSCURRENTDB close];
                }
                return NO;
            }
            else{
                // 操作完毕是否需要关闭
                if (autoCloseDB) {
                    [GSCURRENTDB close];
                }
                return YES;
            }
        }
        // 操作完毕是否需要关闭
        if (autoCloseDB) {
            [GSCURRENTDB close];
        }
        return NO;
    }
    else{
        return NO;
    }
}

- (BOOL)createTable:(Class)modelClass autoCloseDB:(BOOL)autoCloseDB{
    if ([GSCURRENTDB open]) {
        // 创表,判断是否已经存在
        if ([self isExitTable:modelClass autoCloseDB:NO]) {
            if (autoCloseDB) {
                [GSCURRENTDB close];
            }
            return YES;
        }
        else{
            BOOL success = [GSCURRENTDB executeUpdate:[self createTableSQL:modelClass]];
            // 关闭数据库
            if (autoCloseDB) {
                [GSCURRENTDB close];
            }
            return success;
        }
    }
    else{
        return NO;
    }
}

- (BOOL)insertModel:(id)model autoCloseDB:(BOOL)autoCloseDB{
   
    if ([GSCURRENTDB open]) {
        
        // 没有表的时候，先创建再插入
        
        // 此时有三步操作，第一步处理完不关闭数据库
        if (![self isExitTable:[model class] autoCloseDB:NO]) {
            // 第二步处理完不关闭数据库
            BOOL success = [self createTable:[model class] autoCloseDB:NO];
            if (success) {
                NSString *dbId = [model valueForKey:kDBId];
                id judgeModle = [self queryModel:[model class] byID:dbId autoCloseDB:NO];
                
                if ([[judgeModle valueForKey:kDBId] isEqualToString:dbId]) {
                    BOOL updataSuccess = [self updateModel:model byID:dbId autoCloseDB:NO];
                    if (autoCloseDB) {
                        [GSCURRENTDB close];
                    }
                    return updataSuccess;
                }
                else{
                    BOOL insertSuccess = [GSCURRENTDB executeUpdate:[self createInsertSQL:model]];
                    // 最后一步操作完毕，询问是否需要关闭
                    if (autoCloseDB) {
                        [GSCURRENTDB close];
                    }
                    return insertSuccess;
                }
                
            }
            else {
                // 第二步操作失败，询问是否需要关闭,可能是创表失败，或者是已经有表
                if (autoCloseDB) {
                    [GSCURRENTDB close];
                }
                return NO;
            }
        }
        // 已经创建有对应的表，直接插入
        else{
            NSString *dbId = [model valueForKey:kDBId];
            id judgeModle = [self queryModel:[model class] byID:dbId autoCloseDB:NO];
            
            if ([[judgeModle valueForKey:kDBId] isEqualToString:dbId]) {
                BOOL updataSuccess = [self updateModel:model byID:dbId autoCloseDB:NO];
                if (autoCloseDB) {
                    [GSCURRENTDB close];
                }
                return updataSuccess;
            }
            else{
                BOOL insertSuccess = [GSCURRENTDB executeUpdate:[self createInsertSQL:model]];
                // 最后一步操作完毕，询问是否需要关闭
                if (autoCloseDB) {
                    [GSCURRENTDB close];
                }
                return insertSuccess;
            }
        }
    }
    else{
        return NO;
    }
}

- (BOOL)insertModelArr:(NSArray *)modelArr{
    BOOL flag = YES;
    for (id model in modelArr) {
        // 处理过程中不关闭数据库
        if (![self insertModel:model autoCloseDB:NO]) {
            flag = NO;
        }
    }
    // 处理完毕关闭数据库
    [GSCURRENTDB close];
    // 全部插入成功才返回YES
    return flag;
}

- (NSArray *)queryModelArr:(Class)modelClass autoCloseDB:(BOOL)autoCloseDB{
    if ([GSCURRENTDB open]) {
        if(![self isExitTable:modelClass autoCloseDB:NO])return nil;
        // 查询数据
        FMResultSet *rs = [GSCURRENTDB executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@",modelClass]];
        NSMutableArray *modelArrM = [NSMutableArray array];
        // 遍历结果集
        while ([rs next]) {
            
            // 创建对象
            id object = [[modelClass class] new];
            
            unsigned int outCount;
            Ivar * ivars = class_copyIvarList(modelClass, &outCount);
            for (int i = 0; i < outCount; i ++) {
                Ivar ivar = ivars[i];
                NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
                if([[key substringToIndex:1] isEqualToString:@"_"]){
                    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
                }
                
                id value = [rs objectForColumnName:key];
                if ([value isKindOfClass:[NSString class]]) {
                    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
                    id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    if ([result isKindOfClass:[NSDictionary class]] || [result isKindOfClass:[NSMutableDictionary class]] || [result isKindOfClass:[NSArray class]] || [result isKindOfClass:[NSMutableArray class]]) {
                        [object setValue:result forKey:key];
                    }
                    else{
                        [object setValue:value forKey:key];
                    }
                }
                else{
                    [object setValue:value forKey:key];
                }
            }
            
            // 添加
            [modelArrM addObject:object];
        }
        if (autoCloseDB) {
            [GSCURRENTDB close];
        }
        return modelArrM;
    }
    else{
        return nil;
    }
}

- (id)queryModel:(Class)modelClass byColumnName:(NSString *)columnName Value:(NSString *)value
     autoCloseDB:(BOOL)autoCloseDB{
    if ([GSCURRENTDB open]) {
        
        if(![self isExitTable:modelClass autoCloseDB:NO]){
            if (autoCloseDB) {
                [GSCURRENTDB close];
            }
            return nil;
        }
        // 查询数据
        FMResultSet *rs = [GSCURRENTDB executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = '%@'",modelClass,columnName,value]];
        NSMutableArray *modelArrM = [NSMutableArray array];
        
        // 创建对象
        id object = nil;
        // 遍历结果集
        while ([rs next]) {
            object = [[modelClass class] new];
            unsigned int outCount;
            Ivar * ivars = class_copyIvarList(modelClass, &outCount);
            for (int i = 0; i < outCount; i ++) {
                Ivar ivar = ivars[i];
                NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
                if([[key substringToIndex:1] isEqualToString:@"_"]){
                    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
                }
                
                id value = [rs objectForColumnName:key];
                if ([value isKindOfClass:[NSString class]]) {
                    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
                    id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    if ([result isKindOfClass:[NSDictionary class]] || [result isKindOfClass:[NSMutableDictionary class]] || [result isKindOfClass:[NSArray class]] || [result isKindOfClass:[NSMutableArray class]]) {
                        [object setValue:result forKey:key];
                    }
                    else{
                        [object setValue:value forKey:key];
                    }
                }
                else{
                    [object setValue:value forKey:key];
                }
            }
            [modelArrM addObject:object];
        }
        
        
        if (autoCloseDB) {
            [GSCURRENTDB close];
        }
        
        return modelArrM;
    }
    else{
        if (autoCloseDB) {
            [GSCURRENTDB close];
        }
        return nil;
    }
    
}

- (id)queryModel:(Class)modelClass byID:(NSString *)dbId autoCloseDB:(BOOL)autoCloseDB{
    if ([GSCURRENTDB open]) {

        if(![self isExitTable:modelClass autoCloseDB:NO]){
            if (autoCloseDB) {
                [GSCURRENTDB close];
            }
            return nil;
        }
        // 查询数据
        FMResultSet *rs = [GSCURRENTDB executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE id = '%@';",modelClass,dbId]];
        // 创建对象
        id object = nil;
        // 遍历结果集
        while ([rs next]) {
            object = [[modelClass class] new];
            unsigned int outCount;
            Ivar * ivars = class_copyIvarList(modelClass, &outCount);
            for (int i = 0; i < outCount; i ++) {
                Ivar ivar = ivars[i];
                NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
                if([[key substringToIndex:1] isEqualToString:@"_"]){
                    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
                }
                
                id value = [rs objectForColumnName:key];
                if ([value isKindOfClass:[NSString class]]) {
                    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
                    id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    if ([result isKindOfClass:[NSDictionary class]] || [result isKindOfClass:[NSMutableDictionary class]] || [result isKindOfClass:[NSArray class]] || [result isKindOfClass:[NSMutableArray class]]) {
                        [object setValue:result forKey:key];
                    }
                    else{
                        [object setValue:value forKey:key];
                    }
                }
                else{
                    [object setValue:value forKey:key];
                }
            }
            
        }
        if (autoCloseDB) {
            [GSCURRENTDB close];
        }
        return object;
    }
    else{
        if (autoCloseDB) {
            [GSCURRENTDB close];
        }
        return nil;
    }
    
}

- (BOOL)updateModel:(id)model byID:(NSString *)dbId autoCloseDB:(BOOL)autoCloseDB{
    if ([GSCURRENTDB open]) {
        if(![self isExitTable:[model class] autoCloseDB:NO]){
            if (autoCloseDB) {
                [GSCURRENTDB close];
            }
            return NO;
        }
     
        NSMutableString *sql = [NSMutableString stringWithFormat:@"UPDATE %@ SET ",[model class]];
        unsigned int outCount;
        class_copyIvarList([model superclass],&outCount);
        Ivar * ivars = class_copyIvarList([model class], &outCount);
        for (int i = 0; i < outCount; i ++) {
            Ivar ivar = ivars[i];
            NSString * key = [NSString stringWithUTF8String:ivar_getName(ivar)] ;
            if([[key substringToIndex:1] isEqualToString:@"_"]){
                key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
            }
            id value = [model valueForKey:key];
            if (value == [NSNull null]) {
                value = @"";
            }
            if (i == 0) {
                [sql appendFormat:@"%@ = %@",key,([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]] || [value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSMutableArray class]]) ? [NSString stringWithFormat:@"'%@'",value] : value];
            }
            else{
                [sql appendFormat:@",%@ = %@",key,([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]] || [value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSMutableArray class]]) ? [NSString stringWithFormat:@"'%@'",value] : value];
            }
        }
        
        [sql appendFormat:@" WHERE id = '%@';",dbId];
        BOOL success = [GSCURRENTDB executeUpdate:sql];
        if (autoCloseDB) {
            [GSCURRENTDB close];
        }
        return success;
    }
    else{
        if (autoCloseDB) {
            [GSCURRENTDB close];
        }
        return NO;
    }
}

@end
