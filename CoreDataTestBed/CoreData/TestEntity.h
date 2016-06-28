//
//  TestEntity.h
//  
//
//  Created by neo_chen on 2015/5/19.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TestEntity : NSManagedObject

@property (nonatomic, retain) NSNumber * money;
@property (nonatomic, retain) NSString * name;

@end
