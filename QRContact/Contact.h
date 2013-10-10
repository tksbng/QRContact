//
//  Contact.h
//  QRContact
//
//  Created by Takeshi Bingo on 2013/08/03.
//  Copyright (c) 2013年 Takeshi Bingo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Contact : NSObject
//【追記ここから】
@property NSString *lastname;
@property NSString *firstname;
@property NSString *lastyomi;
@property NSString *firstyomi;
@property NSMutableArray *email;
@property NSMutableArray *phone;
//【追記ここまで】
@end
