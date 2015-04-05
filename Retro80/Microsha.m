/*******************************************************************************
 ПЭВМ «Микроша»
 ******************************************************************************/

#import "Microsha.h"

@implementation Microsha

+ (NSString *) title
{
	return @"Микроша";
}

+ (NSString *) ext
{
	return @"rkm";
}

// -----------------------------------------------------------------------------
// validateMenuItem
// -----------------------------------------------------------------------------

- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
	if (menuItem.action == @selector(colorModule:))
	{
		menuItem.state = self.isColor;
		return YES;
	}

	if (menuItem.action == @selector(extraMemory:))
	{
		if (menuItem.tag == 0)
		{
			menuItem.state = self.ram.length == 0xC000;
			menuItem.submenu = nil;
			return YES;
		}
	}

	if (menuItem.action == @selector(floppy:))
	{
		if (self.isFloppy)
		{
			menuItem.state = menuItem.tag == 0 || [self.floppy getDisk:menuItem.tag];
			return menuItem.tag == 0 || menuItem.tag != [self.floppy selected];
		}
		else
		{
			menuItem.state = FALSE; return menuItem.tag == 0;
		}
	}

	return [super validateMenuItem:menuItem];
}

// -----------------------------------------------------------------------------
// Модуль цветности
// -----------------------------------------------------------------------------

static uint32_t colors[] =
{
	0xFFFFFFFF, 0xFFFF00FF, 0xFFFFFFFF, 0xFFFF00FF,
	0xFFFFFF00, 0xFFFF0000, 0xFFFFFF00, 0xFFFF0000,
	0xFF00FFFF, 0xFF0000FF, 0xFF00FFFF, 0xFF0000FF,
	0xFF00FF00, 0xFF000000, 0xFF00FF00, 0xFF000000
};

- (IBAction) colorModule:(NSMenuItem *)menuItem
{
	[self.document registerUndoWithMenuItem:menuItem];

	if ((self.isColor = !self.isColor))
	{
		if (self.rom.length > 0x42 && self.rom.mutableBytes[0x42] == 0x93)
			self.rom.mutableBytes[0x42] = 0xD3;

		[self.crt setColors:colors attributesMask:0x2F shiftMask:0x0D];
	}
	else
	{
		if (self.rom.length > 0x42 && self.rom.mutableBytes[0x42] == 0xD3)
			self.rom.mutableBytes[0x42] = 0x93;

		[self.crt setColors:NULL attributesMask:0x22 shiftMask:0x00];
	}
}

// -----------------------------------------------------------------------------
// Модуль ОЗУ
// -----------------------------------------------------------------------------

- (IBAction) extraMemory:(NSMenuItem *)menuItem
{
	if (menuItem.tag == 0) @synchronized(self.snd.sound)
	{
		[self.document registerUndoWithMenuItem:menuItem];

		RAM *ram = [[RAM alloc] initWithLength:self.ram.length == 0x8000 ? 0xC000 : 0x8000 mask:0xFFFF];
		memcpy(ram.mutableBytes, self.ram.mutableBytes, 0x8000);
		[self.cpu mapObject:self.ram = ram from:0x0000 to:0xBFFF];
	}
}

// -----------------------------------------------------------------------------
// Модуль НГМД
// -----------------------------------------------------------------------------

- (IBAction) floppy:(NSMenuItem *)menuItem;
{
	if (menuItem.tag == 0) @synchronized(self.snd.sound)
	{
		[self.document registerUndoWithMenuItem:menuItem];

		if ((self.isFloppy = !self.isFloppy))
		{
			if (self.dos29 == nil && (self.dos29 = [[ROM alloc] initWithContentsOfResource:@"dos29" mask:0x0FFF]) != nil)
				if (self.dos29.length > 0xDBF && self.dos29.mutableBytes[0xDBF] == 0xC1)
					self.dos29.mutableBytes[0xDBF] = 0xD1;

			if (self.floppy == nil && (self.floppy = [[Floppy alloc] init]) != nil)
				[self.cpu addObjectToRESET:self.floppy];

			if (self.dos29 && self.floppy)
			{
				[self.cpu mapObject:self.dos29 from:0xE000 to:0xEFFF WR:nil];
				[self.cpu mapObject:self.floppy from:0xF000 to:0xF7FF];
			}
		}
		else
		{
			[self.cpu mapObject:nil from:0xE000 to:0xF7FF];
		}
	}
	else if (menuItem.tag && self.isFloppy)
	{
		NSOpenPanel *panel = [NSOpenPanel openPanel];
		panel.allowedFileTypes = @[@"rkdisk"];
		panel.canChooseDirectories = FALSE;
		panel.title = menuItem.title;

		if ([panel runModal] == NSFileHandlingPanelOKButton && panel.URLs.count == 1)
		{
			[self.document registerUndoWithMenuItem:menuItem];
			[self.floppy setDisk:menuItem.tag URL:panel.URLs.firstObject];
		}
		else if ([self.floppy getDisk:menuItem.tag] != nil)
		{
			[self.document registerUndoWithMenuItem:menuItem];
			[self.floppy setDisk:menuItem.tag URL:nil];
		}
	}
}

// -----------------------------------------------------------------------------
// createObjects/encodeWithCoder/decodeWithCoder
// -----------------------------------------------------------------------------

- (BOOL) createObjects
{
	if ((self.rom = [[ROM alloc] initWithContentsOfResource:@"Microsha" mask:0x07FF]) == nil)
		return FALSE;

	if ((self.kbd = [[MicroshaKeyboard alloc] init]) == nil)
		return FALSE;

	if ((self.ext = [[MicroshaExt alloc] init]) == nil)
		return FALSE;

	if (![super createObjects])
		return FALSE;

	[self.crt selectFont:0x0C00];

	return TRUE;
}

// -----------------------------------------------------------------------------

- (void) encodeWithCoder:(NSCoder *)encoder
{
	[super encodeWithCoder:encoder];

	[encoder encodeBool:self.isFloppy forKey:@"isFloppy"]; if (self.isFloppy)
	{
		[encoder encodeObject:self.floppy forKey:@"floppy"];
		[encoder encodeObject:self.dos29 forKey:@"dos29"];
	}
}

// -----------------------------------------------------------------------------

- (BOOL) decodeWithCoder:(NSCoder *)decoder
{
	if (![super decodeWithCoder:decoder])
		return FALSE;

	if ((self.isFloppy = [decoder decodeBoolForKey:@"isFloppy"]))
	{
		if ((self.floppy = [decoder decodeObjectForKey:@"floppy"]) == nil)
			return FALSE;

		if ((self.dos29 = [decoder decodeObjectForKey:@"dos29"]) == nil)
			return FALSE;
	}

	return TRUE;
}

// -----------------------------------------------------------------------------
// mapObjects
// -----------------------------------------------------------------------------

- (BOOL) mapObjects
{
	if (self.isColor)
		[self.crt setColors:colors attributesMask:0x2F shiftMask:0x0D];
	else
		[self.crt setColors:NULL attributesMask:0x22 shiftMask:0x00];

	self.ext.crt = self.crt;

	[self.cpu mapObject:self.ram from:0x0000 to:0xBFFF];
	[self.cpu mapObject:self.kbd from:0xC000 to:0xC7FF];
	[self.cpu mapObject:self.ext from:0xC800 to:0xCFFF];
	[self.cpu mapObject:self.crt from:0xD000 to:0xD7FF];
	[self.cpu mapObject:self.snd from:0xD800 to:0xDFFF];
	[self.cpu mapObject:self.rom from:0xF800 to:0xFFFF WR:self.dma];

	if (self.isFloppy)
	{
		[self.cpu mapObject:self.dos29 from:0xE000 to:0xEFFF WR:nil];
		[self.cpu mapObject:self.floppy from:0xF000 to:0xF7FF];
		[self.cpu addObjectToRESET:self.floppy];
	}

	[self.cpu mapHook:self.kbdHook = [[F81B alloc] initWithRKKeyboard:self.kbd] atAddress:0xFEEA];

	[self.cpu mapHook:self.inpHook = [[F806 alloc] initWithSound:self.snd] atAddress:0xF806];
	self.inpHook.extension = @"rkm";
	self.inpHook.type = 2;

	[self.cpu mapHook:self.outHook = [[FCAB alloc] init] atAddress:0xFCAB];
	self.outHook.extension = @"rkm";
	self.outHook.type = 2;

	return [super mapObjects];
}

@end

// -----------------------------------------------------------------------------
// Первый интерфейс 8255, вариант клавиатуры РК86 для Микроши
// -----------------------------------------------------------------------------

@implementation MicroshaKeyboard

- (id) init
{
	if (self = [super init])
	{
		kbdmap = @[
				   // 58 59    5A    5B    5C    5D    5E    5F
				   @46,  @1,   @35,  @34,  @39,  @31,  @7,   @24,
				   // 50 51    52    53    54    55    56    57
				   @5,   @6,   @4,   @8,   @45,  @14,  @41,  @2,
				   // 48 49    4A    4B    4C    4D    4E    4F
				   @33,  @11,  @12,  @15,  @40,  @9,   @16,  @38,
				   // 40 41    42    43    44    45    46    47
				   @47,  @3,   @43,  @13,  @37,  @17,  @0,   @32,
				   // 38 39    3A    3B    2C    2D    2E    2F
				   @28,  @25,  @30,  @10,  @44,  @27,  @42,  @50,
				   // 30 31    32    33    34    35    36    37
				   @29,  @18,  @19,  @20,  @21,  @23,  @22,  @26,
				   // 19 1A    0C    00    01     02   03    04
				   @126, @125, @115, @122, @120,  @99, @118, @96,
				   // 20 1B    09    0A    0D    1F    08    18
				   @49,  @53,  @48,  @76,  @36,  @117, @123, @124
				   ];

		RUSLAT = 0x20;
		SHIFT = 0x80;
	}

	return self;
}

// -----------------------------------------------------------------------------

- (void) setC:(uint8_t)data
{
	self.snd.channel2 = self.snd.sound.beeper = data & 0x02;
	[self.snd setGate2:data & 0x04 clock:current];

	[super setC:data];
}

@end

// -----------------------------------------------------------------------------
// Второй интерфейс 8255, управление знакогенератором
// -----------------------------------------------------------------------------

@implementation MicroshaExt

@synthesize crt;

- (void) setB:(uint8_t)data
{
	[crt selectFont:data & 0x80 ? 0x2800 : 0x0C00];
}

// -----------------------------------------------------------------------------

- (uint8_t) A
{
	return 0x00;
}

- (uint8_t) B
{
	return 0x00;
}

- (uint8_t) C
{
	return 0x00;
}

@end

// -----------------------------------------------------------------------------
// FCAB - Вывод байта на магнитофон (Микроша)
// -----------------------------------------------------------------------------

@implementation FCAB

- (int) execute:(X8080 *)cpu
{
	if (cpu.SP == 0x76CD && MEMR(cpu, 0x76CD, 0) == 0x9D && MEMR(cpu, 0x76CE, 0) == 0xF8)
		return 2;

	return [super execute:cpu];
}

@end
