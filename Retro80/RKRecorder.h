/*****

 Проект «Ретро КР580» (http://uart.myqnapcloud.com/retro80.html)
 Copyright © 2014-2016 Andrey Chicherov <chicherov@mac.com>

 *****/

#import "x8080.h"

// -----------------------------------------------------------------------------
// F806 - Ввод байта с магнитофона
// -----------------------------------------------------------------------------

@interface F806 : NSObject <Adjustment, RD, BYTE>
{
	NSOpenPanel *panel;
	BOOL cancel;
}

- (id) initWithX8080:(X8080 *)cpu;

- (void) openPanel;
- (void) open;

@property (weak) X8080 *cpu;
@property NSObject<RD, BYTE> *mem;
@property NSObject<SND> *snd;

@property NSString *extension;
@property unsigned type;

@property NSData *buffer;
@property NSUInteger pos;

@end

// -----------------------------------------------------------------------------
// F80C - Вывод байта на магнитофон
// -----------------------------------------------------------------------------

@interface F80C : NSObject <Adjustment, RD, BYTE>
{
	NSTimeInterval last;
}

- (id) initWithX8080:(X8080 *)cpu;

- (void) save;

@property (weak) X8080 *cpu;
@property NSObject<RD, BYTE> *mem;
@property NSObject<SND> *snd;

@property NSString *extension;
@property unsigned type;

@property NSMutableData *buffer;

@end
