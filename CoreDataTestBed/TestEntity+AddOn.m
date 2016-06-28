//
//  _TestEntity+AddOn.m
//  test
//
//  Created by neo_chen on 2015/5/12.
//

#import "TestEntity+AddOn.h"

@implementation TestEntity (AddOn)
-(void)didTurnIntoFault{
    NSLog(@"didTurnIntoFault:%@",self);
}
-(void)willTurnIntoFault{
    NSLog(@"willTurnIntoFault:%@",self);
}
@end
