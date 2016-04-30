/*****

 Проект «Ретро КР580» (http://uart.myqnapcloud.com/retro80.html)
 Copyright © 2014-2016 Andrey Chicherov <chicherov@mac.com>

 ПЭВМ «Микро-80»

 *****/

#import "Micro80.h"

@implementation Micro80

+ (NSString *) title
{
	return @"Микро-80";
}

+ (NSArray *) extensions
{
	return @[@"rk8"];
}

// -----------------------------------------------------------------------------
// Инициализация
// -----------------------------------------------------------------------------

- (BOOL) createObjects
{
	if (self.cpu == nil && (self.cpu = [[X8080 alloc] initWithQuartz:16000000 start:0xF800]) == nil)
		return FALSE;

	if (self.rom == nil && (self.rom = [[ROM alloc] initWithContentsOfResource:@"Micro80" mask:0x07FF]) == nil)
		return FALSE;

	if (self.ram == nil && (self.ram = [[RAM alloc] initWithLength:0xF800 mask:0xFFFF]) == nil)
		return FALSE;

	if (self.kbd == nil && (self.kbd = [[Micro80Keyboard alloc] init]) == nil)
		return FALSE;

	return TRUE;
}

- (BOOL) mapObjects
{
	if (self.snd == nil && (self.snd = [[Micro80Recorder alloc] init]) == nil)
		return FALSE;

	if (self.crt == nil && (self.crt = [[Micro80Screen alloc] init]) == nil)
		return FALSE;

	self.crt.memory = self.ram.mutableBytes + 0xE800;
	self.crt.cursor = self.ram.mutableBytes + 0xE000;

	if (self.inpHook == nil)
	{
		self.inpHook = [[F806 alloc] initWithX8080:self.cpu];
		self.inpHook.mem = self.rom;
		self.inpHook.snd = self.snd;

		self.inpHook.extension = @"rk8";
	}

	if (self.outHook == nil)
	{
		self.outHook = [[F80C alloc] initWithX8080:self.cpu];
		self.outHook.mem = self.rom;
		self.outHook.snd = self.snd;

		self.outHook.extension = @"rk8";
	}

	[self.cpu mapObject:self.ram from:0x0000 to:0xF7FF];
	[self.cpu mapObject:self.rom from:0xF800 to:0xFFFF WR:nil];

	[self.cpu mapObject:self.inpHook from:0xFD95 to:0xFD95 WR:nil];
	[self.cpu mapObject:self.outHook from:0xFDE6 to:0xFDE6 WR:nil];

	[self.cpu mapObject:self.snd atPort:0x00 count:0x02];
	[self.cpu mapObject:self.kbd atPort:0x04 count:0x04];

	return TRUE;
}

- (id) initWithData:(NSData *)data URL:(NSURL *)url
{
	if (self = [self initWithType:0])
	{
		self.inpHook.buffer = data;
		[self.kbd paste:@"I\n"];
	}

	return self;
}

// -----------------------------------------------------------------------------
// encodeWithCoder/decodeWithCoder
// -----------------------------------------------------------------------------

- (void) encodeWithCoder:(NSCoder *)encoder
{
	[super encodeWithCoder:encoder];

	[encoder encodeObject:self.cpu forKey:@"cpu"];
	[encoder encodeObject:self.rom forKey:@"rom"];
	[encoder encodeObject:self.ram forKey:@"ram"];
	[encoder encodeObject:self.kbd forKey:@"kbd"];
}

- (BOOL) decodeWithCoder:(NSCoder *)decoder
{
	if (![super decodeWithCoder:decoder])
		return FALSE;

	if ((self.cpu = [decoder decodeObjectForKey:@"cpu"]) == nil)
		return FALSE;

	if ((self.rom = [decoder decodeObjectForKey:@"rom"]) == nil)
		return FALSE;

	if ((self.ram = [decoder decodeObjectForKey:@"ram"]) == nil)
		return FALSE;

	if ((self.kbd = [decoder decodeObjectForKey:@"kbd"]) == nil)
		return FALSE;

	return TRUE;
}

@end

// -----------------------------------------------------------------------------
// Дисплей "Микро-80"
// -----------------------------------------------------------------------------

@implementation Micro80Screen
{
	NSData *rom;

	uint8_t screen[32][64];
	uint32_t* bitmap;
}

@synthesize display;
@synthesize memory;
@synthesize cursor;
@synthesize rows;

- (void) draw
{
	if (bitmap == NULL)
		bitmap = [self.display setupTextWidth:64 height:rows cx:6 cy:10];

	if (bitmap)
	{
		const uint8_t *mem1 = memory;
		const uint8_t *mem2 = cursor;

		for (unsigned row = 0; row < rows; row++)
		{
			for (unsigned col = 0; col < 64; col++)
			{
				uint8_t ch = (*mem1++ & 0x7F); ch |= *++mem2 & 0x80;

				if (screen[row][col] != ch)
				{
					screen[row][col] = ch;

					const uint8_t *fnt = rom.bytes + ((ch & 0x7F) << 3);
					uint32_t *ptr = bitmap + (row * 64 * 10 + col) * 6;

					for (int line = 0; line < 10; line++)
					{
						uint8_t byte = (line == 0 || line == 9) ? 0xFF : *fnt++; if (ch & 0x80)
							byte ^= 0xFF;

						for (int i = 0; i < 6; i++, byte <<= 1)
							*ptr++ = byte & 0x20 ? 0xFF000000 : 0xFFAAAAAA;

						ptr += 63 * 6;
					}
				}
			}
		}

		self.display.needsDisplay = TRUE;
	}

}

// -----------------------------------------------------------------------------
// Copy to pasteboard
// -----------------------------------------------------------------------------

- (unichar) charAtX:(unsigned int)x Y:(unsigned int)y
{
	NSString *unicode = @
	" ▘▝▀▗▚▐▜ ⌘ ⬆  ➡⬇▖▌▞▛▄▙▟█   ┃━⬅☼ "
	" !\"#$%&'()*+,-./0123456789:;<=>?"
	"@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_"
	"ЮАБЦДЕФГХИЙКЛМНОПЯРСТУЖВЬЫЗШЭЩЧ▇";


	return [unicode characterAtIndex:screen[y][x] & 0x7F];
}
- (id) init
{
	if (self = [super init])
	{
		if ((rom = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Micro80" ofType:@"fnt"]]) == nil)
			return self = nil;

		rows = 32;
	}
	
	return self;
}

@end

// -----------------------------------------------------------------------------
// Интерфейс сопряжения "Микро-80"
// -----------------------------------------------------------------------------

@implementation Micro80Recorder

@synthesize sound;

- (void) RD:(uint16_t)addr data:(uint8_t *)data CLK:(uint64_t)clock
{
	*data = sound.input;
}

- (void) WR:(uint16_t)addr data:(uint8_t)data CLK:(uint64_t)clock
{
	sound.output = data & 0x01;
}

@end

// -----------------------------------------------------------------------------
// Интерфейс клавиатуры "Микро-80"
// -----------------------------------------------------------------------------

@implementation Micro80Keyboard

- (void) RD:(uint16_t)addr data:(uint8_t *)data CLK:(uint64_t)clock
{
	[super RD:addr ^ 3 data:data CLK:clock];
}

- (void) WR:(uint16_t)addr data:(uint8_t)data CLK:(uint64_t)clock
{
	[super WR:addr ^ 3 data:data CLK:clock];
}

// -----------------------------------------------------------------------------
// Порт B
// -----------------------------------------------------------------------------

- (uint8_t) B
{
	return [super B] & 0x7F;
}

// -----------------------------------------------------------------------------
// Порт C
// -----------------------------------------------------------------------------

- (uint8_t) C
{
	[self scan:current];

	uint8_t data = 0xFF & ~(RUSLAT | CTRL | SHIFT);

	if (!(modifierFlags & NSAlphaShiftKeyMask))
		data |= RUSLAT;

	if (!(modifierFlags & NSControlKeyMask))
		data |= CTRL;

	if (!(modifierFlags & NSShiftKeyMask))
		data |= SHIFT;

	else if (self.qwerty) for (int i = 8; i < 48; i++)
	{
		if (i != 40 && i != 41 && keyboard[i])
		{
			data &= ~RUSLAT; data |= SHIFT; break;
		}
	}

	return data;
}

- (void) setC:(uint8_t)data
{
}

- (void) keyboardInit
{
	[super keyboardInit];

	kbdmap = @[
			   // 18 08    19    1A    0D    1F    0C    ?
			   @124, @123, @126, @125, @36,  @117, @115, @-1,
			   // 5A 5B    5C    5D    5E    5F    20    ?
			   @35,  @34,  @39,  @31,  @7,   @51,  @49,  @-1,
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

	chr1Map =  @"\r\0Z[\\]^_ \0STUVWXY\0LMNOPQR\0EFGHIJK\0./@ABCD\0""789:;,-\0""0123456\0";
	chr2Map =  @"\r\0ЗШЭЩЧ\0 \0СТУЖВЬЫ\0ЛМНОПЯР\0ЕФГХИЙК\0>?ЮАБЦД\0'()*+<=\0""0!\"#$%&\0";

	RUSLAT = 0x01;
	SHIFT = 0x04;
	CTRL = 0x02;
}

@end
