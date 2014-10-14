#import "Micro80.h"
#import "Sound.h"

// -----------------------------------------------------------------------------
// Интерфейс сопряжения "Микро-80"
// -----------------------------------------------------------------------------

@implementation Micro80Recorder

- (void) WR:(uint16_t)addr byte:(uint8_t)data CLK:(uint64_t)clock
{
	self.output = data != 0x00;
}

- (uint8_t) RD:(uint16_t)addr CLK:(uint64_t)clock status:(uint8_t)status
{
	return self.input;
}

@end

// -----------------------------------------------------------------------------
// Интерфейс клавиатуры "Микро-80"
// -----------------------------------------------------------------------------

@implementation Micro80Keyboard

- (void) WR:(uint16_t)addr byte:(uint8_t)data CLK:(uint64_t)clock
{
	[super WR:addr ^ 3 byte:data CLK:clock];
}

- (uint8_t) RD:(uint16_t)addr CLK:(uint64_t)clock status:(uint8_t)status
{
	return [super RD:addr ^ 3 CLK:clock status:status];
}

- (id) init
{
	if (self = [super init])
	{
		kbdmap = @[
				   // 18 08    19    1A    0D    1F    0C    ?
				   @124, @123, @126, @125, @36,  @117, @115, @-1,
				   // 5A 5B    5C    5D    5E    5F    20    ?
				   @35,  @34,  @39,  @31,  @7,   @24,  @49,  @-1,
				   // 53 54    55    56    57    58    59    ?
				   @8,   @45,  @14,  @41,  @2,   @46,  @1,   @-1,
				   // 4C 4D    4E    4F    50    51    52    ?
				   @40,  @9,   @16,  @38,  @5,   @6,   @4,   @-1,
				   // 45 46    47    48    49    4A    4B    ?
				   @17,  @0,   @32,  @33,  @11,  @12,  @15,  @-1,
				   // 2E 2F    40    41    42    43    44    ?
				   @42,  @50,  @47,  @3,   @43,  @13,  @37,  @-1,
				   // 37 38    39    3A    3B    2C    2D    ?
				   @26,  @28,  @25,  @30,  @10,  @44,  @27,  @-1,
				   // 30 31    32    33    34    35    36    ?
				   @29,  @18,  @19,  @20,  @21,  @23,  @22,  @-1
				   ];

		RUSLAT = 0x01;
		SHIFT = 0x04;
		CTRL = 0x02;
	}

	return self;
}

@end

// -----------------------------------------------------------------------------
// ПЭВМ "Микро-80"
// -----------------------------------------------------------------------------

@implementation Micro80

+ (NSString *) title
{
	return @"Микро-80";
}

// -----------------------------------------------------------------------------
// Управление компьютером
// -----------------------------------------------------------------------------

- (void) start
{
	[self.snd start];
}

- (void) reset
{
	[self stop];

	if (self.snd.isInput)
		[self.snd close];

	self.cpu.PC = 0xF800;
	self.cpu.IF = FALSE;

	[self start];
}

- (void) stop
{
	[self.snd stop];
}

// -----------------------------------------------------------------------------
// Инициализация
// -----------------------------------------------------------------------------

- (BOOL) createObjects
{
	if ((self.cpu = [[X8080 alloc] initWithQuartz:18000000]) == nil)
		return FALSE;

	if ((self.ram = [[RAM alloc] initWithLength:0xF800 mask:0xFFFF]) == nil)
		return FALSE;

	if ((self.crt = [[TextScreen alloc] init]) == nil)
		return FALSE;

	if ((self.kbd = [[Micro80Keyboard alloc] init]) == nil)
		return FALSE;

	return TRUE;
}

- (BOOL) mapObjects
{
	if ((self.rom = [[ROM alloc] initWithContentsOfResource:@"Micro80" mask:0x07FF]) == nil)
		return FALSE;

	if ((self.snd = [[Micro80Recorder alloc] init]) == nil)
		return FALSE;

	self.snd.cpu = self.cpu;

	self.cpu.HLDA = self.crt;

	[self.cpu mapObject:self.ram atPage:0x00 count:0xF8];
	[self.cpu mapObject:self.rom atPage:0xF8 count:0x08];

	[self.cpu mapObject:self.crt atPage:0xE0 count:0x10];

	[self.cpu mapObject:self.snd atPort:0x00 count:0x02];
	[self.cpu mapObject:self.kbd atPort:0x04 count:0x04];

	[self.cpu mapHook:self.kbdHook = [[F812 alloc] initWithRKKeyboard:self.kbd] atAddress:0xF812];
	[self.cpu mapHook:[[F803 alloc] initWithF812:self.kbdHook] atAddress:0xF803];

	[self.cpu mapHook:self.inpHook = [[F806 alloc] initWithSound:self.snd] atAddress:0xF806];
	self.inpHook.extension = @"rk8";

	[self.cpu mapHook:self.outHook = [[F80C alloc] init] atAddress:0xF80C];
	self.outHook.extension = @"rk8";
	self.outHook.Micro80 = TRUE;

	return TRUE;
}

- (id) init
{
	if (self = [super init])
	{
		if (![self createObjects])
			return self = nil;

		if (![self mapObjects])
			return self = nil;

		self.cpu.PC = 0xF800;

		self.kbdHook.enabled = TRUE;
		self.inpHook.enabled = TRUE;
		self.outHook.enabled = TRUE;
	}

	return self;
	
}

// -----------------------------------------------------------------------------
// encodeWithCoder/initWithCoder
// -----------------------------------------------------------------------------

- (void) encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:self.cpu forKey:@"cpu"];
	[encoder encodeObject:self.ram forKey:@"ram"];
	[encoder encodeObject:self.crt forKey:@"crt"];
	[encoder encodeObject:self.kbd forKey:@"kbd"];

	[encoder encodeBool:self.kbdHook.enabled forKey:@"kbdHook"];
	[encoder encodeBool:self.inpHook.enabled forKey:@"inpHook"];
	[encoder encodeBool:self.outHook.enabled forKey:@"outHook"];
}

- (id) initWithCoder:(NSCoder *)decoder
{
	if ((self.cpu = [decoder decodeObjectForKey:@"cpu"]) == nil)
		return self = nil;

	if ((self.ram = [decoder decodeObjectForKey:@"ram"]) == nil)
		return self = nil;

	if ((self.crt = [decoder decodeObjectForKey:@"crt"]) == nil)
		return self = nil;

	if ((self.kbd = [decoder decodeObjectForKey:@"kbd"]) == nil)
		return self = nil;

	if (![self mapObjects])
		return self = nil;

	self.kbdHook.enabled = [decoder decodeBoolForKey:@"kbdHook"];
	self.inpHook.enabled = [decoder decodeBoolForKey:@"inpHook"];
	self.outHook.enabled = [decoder decodeBoolForKey:@"outHook"];

	return self;
}

@end
