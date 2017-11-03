//
//  GSSQLStateMannager.h
//  GSDBTest
//
//  Created by Johnson on 17/3/8.
//  Copyright © 2017年 Johnson. All rights reserved.
//


#import <Foundation/Foundation.h>

#define DEFAULT_NAME @"GSDB"

#define GSFMDBMANAGER [GSDBManager shareManager:DEFAULT_NAME]

#define GSFMDBMANAGERX(DB_NAME) [GSDBManager shareManager:DB_NAME]

#define GSFMDBMANAGERR(DB_NAME) [GSDBManager readDBManger:DB_NAME]

static NSString *const kDBId    = @"id";

@interface GSDBManager : NSObject

+ (GSDBManager *)shareManager:(NSString *)dbName;///从沙盒读取路径判断

+ (GSDBManager *)readDBManger:(NSString *)dbName;///从本地资源包读取路径判断

#pragma mark -- 创表


- (BOOL)createTable:(Class)modelClass;

#pragma mark -- 插入


- (BOOL)insertModel:(id)model;



#pragma mark -- 查询

- (BOOL)isExitTable:(Class)modelClass;

- (id)queryModel:(Class)modelClass byID:(NSString *)dbId;

- (id)queryModel:(Class)modelClass byColumnName:(NSString*)columnName Value:(NSString *)value;

- (NSArray *)queryModelArr:(Class)modelClass;


#pragma mark -- 修改

- (BOOL)updateModel:(id)model byID:(NSString *)dbId;


#pragma mark -- 删除

- (BOOL)dropTable:(Class)modelClass;

- (BOOL)dropDB;

- (BOOL)deleteAllModel:(Class)modelClass;

- (BOOL)deleteModel:(Class)modelClass byId:(NSString *)dbId;

@end
