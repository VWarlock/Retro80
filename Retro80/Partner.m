/*******************************************************************************
 ПЭВМ «Партнер 01.01»
 ******************************************************************************/

#import "Partner.h"

@implementation Partner

+ (NSString *) title
{
	return @"Партнер 01.01";
}

+ (NSString *) ext
{
	return @"rkp";
}

// -----------------------------------------------------------------------------
// validateMenuItem
// -----------------------------------------------------------------------------

- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
	if (menuItem.action == @selector(floppy:))
	{
		if (menuItem.tag == 0)
		{
			menuItem.state = self.isFloppy;
			return (self.sys2.slot & 0x02) == 0;
		}

		else if (self.isFloppy)
		{
			menuItem.state = [self.floppy getDisk:menuItem.tag] != nil;
			return !self.floppy.busy || menuItem.tag != self.floppy.selected;
		}

		else
		{
			menuItem.state = FALSE;
			return NO;
		}
	}

	if (menuItem.action == @selector(colorModule:))
	{
		menuItem.state = self.isColor;
		return (self.sys2.slot & 0x04) == 0;
	}

	return [super validateMenuItem:menuItem];
}

// -----------------------------------------------------------------------------
// Модуль контроллера дисковода "Партнер 01.51"
// -----------------------------------------------------------------------------

- (IBAction) floppy:(NSMenuItem *)menuItem
{
	if (menuItem.tag == 0) @synchronized(self.snd.sound)
	{
		if ((self.sys2.slot & 0x02) == 0)
		{
			[self.document registerUndoWithMenuItem:menuItem];
			self.isFloppy = !self.isFloppy;
		}
	}
	else if (menuItem.tag && self.isFloppy)
	{
		NSOpenPanel *panel = [NSOpenPanel openPanel];
		panel.allowedFileTypes = @[@"cpm"];
		panel.title = menuItem.title;

		if ([panel runModal] == NSFileHandlingPanelOKButton && panel.URLs.count == 1)
		{
			@synchronized(self.snd.sound)
			{
				[self.document registerUndoWithMenuItem:menuItem];
				[self.floppy setDisk:menuItem.tag URL:panel.URLs.firstObject];
			}
		}
		else if ([self.floppy getDisk:menuItem.tag] != nil)
		{
			@synchronized(self.snd.sound)
			{
				[self.document registerUndoWithMenuItem:menuItem];
				[self.floppy setDisk:menuItem.tag URL:nil];
			}
		}
	}
}

// -----------------------------------------------------------------------------
// МОДУЛЬ ЦВЕТНОЙ ПСЕВДОГРАФИЧЕСКИЙ "ПАРТНЕР 01.61"
// -----------------------------------------------------------------------------

- (IBAction) colorModule:(NSMenuItem *)menuItem
{
	@synchronized(self.snd.sound)
	{
		if ((self.sys2.slot & 0x04) == 0)
		{
			[self.document registerUndoWithMenuItem:menuItem];
			self.isColor = !self.isColor;

			self.snd.channel0 = self.isColor;
			self.snd.channel1 = self.isColor;
			self.snd.channel2 = self.isColor;

			self.sys2.mcpg = self.sys2.mcpg;
		}
	}
}

// -----------------------------------------------------------------------------
// createObjects
// -----------------------------------------------------------------------------

- (BOOL) createObjects
{
	if ((self.cpu = [[X8080 alloc] initWithQuartz:18000000]) == nil)
		return FALSE;

	if ((self.rom = [[ROM alloc] initWithContentsOfResource:@"Partner" mask:0x1FFF]) == nil)
		return FALSE;

	if ((self.basic = [[ROM alloc] initWithContentsOfResource:@"Basic" mask:0x1FFF]) == nil)
		return FALSE;

	if ((self.ram = [[RAM alloc] initWithLength:0x10000 mask:0xFFFF]) == nil)
		return FALSE;

	if ((self.kbd = [[PartnerKeyboard alloc] init]) == nil)
		return FALSE;

	if ((self.sys2 = [[PartnerSystem2 alloc] init]) == nil)
		return FALSE;

	if ((self.fddbios = [[ROM alloc] initWithContentsOfResource:@"fdd" mask:0x07FF]) == nil)
		return FALSE;

	if ((self.floppy = [[VG93 alloc] initWithQuartz:self.cpu.quartz]) == nil)
		return FALSE;

	if ((self.mcpgbios = [[ROM alloc] initWithContentsOfResource:@"mcpg" mask:0x07FF]) == nil)
		return FALSE;

	if ((self.mcpgfont = [[RAM alloc] initWithLength:0x1000 mask:0x0FFF]) == nil)
		return FALSE;

	if (![super createObjects])
		return FALSE;

	self.snd.channel0 = TRUE;
	self.snd.channel1 = TRUE;
	self.snd.channel2 = TRUE;

	self.isFloppy = TRUE;
	self.isColor = TRUE;

	return TRUE;
}

// -----------------------------------------------------------------------------
// mapObjects
// -----------------------------------------------------------------------------

- (BOOL) mapObjects
{
	static uint16_t fonts[16] =
	{
		0x0000, 0x1000, 0x0000, 0x1000,
		0x0400, 0x1400, 0x0400, 0x1400,
		0x0800, 0x1800, 0x0800, 0x1800,
		0x0C00, 0x1C00, 0x0C00, 0x1C00
	};

	[self.crt setColors:NULL attributesMask:0x3F shiftMask:0x3D];
	[self.crt setFonts:fonts];

	// Системный регистр 1

	if ((self.sys1 = [[PartnerSystem1 alloc] init]) == nil)
		return FALSE;

	self.sys1.cpu = self.cpu;
	self.sys1.crt = self.crt;

	// Окошки для внешних устройств

	self.win1 = [[PartnerExternal alloc] init];
	self.win2 = [[PartnerExternal alloc] init];
	
	// Системный регистр 2

	self.sys2.partner = self;
	self.sys2.slot = self.sys2.slot;
	self.sys2.mcpg = self.sys2.mcpg;

	// Область D800-DFFF всегда принадлежит системным контролерам

	[self.cpu mapObject:self.crt	from:0xD800 to:0xD8FF];
	[self.cpu mapObject:self.kbd	from:0xD900 to:0xD9FF];
	[self.cpu mapObject:self.sys1	from:0xDA00 to:0xDAFF RD:nil];
	[self.cpu mapObject:self.dma	from:0xDB00 to:0xDBFF];
	[self.cpu mapObject:self.sys2	from:0xDC00 to:0xDFFF];

	// Страница 2 идет в виде базовой страницы

	[self.cpu mapObject:self.ram	from:0x0000 to:0xD7FF];

	[self.cpu mapObject:self.win1	from:0xE000 to:0xE7FF];
	[self.cpu mapObject:self.rom	from:0xE800 to:0xFFFF WR:nil];

	// Страница 0, с адреса 0000 идут первые 2К монитора
	// Предназначена для старта по Reset

	[self.cpu mapObject:self.rom	atPage:0 from:0x0000 to:0x07FF WR:nil];

	// Страница 1, верхние 8К полностью занимает монитор
	// Предназначена для копирования ассемблера в память

	[self.cpu mapObject:self.rom	atPage:1 from:0xE000 to:0xE7FF WR:nil];

	// Страница 3, верхние 8К полностью занимает внешнее окошко 1

	[self.cpu mapObject:self.win1	atPage:3 from:0xE800 to:0xFFFF];

	// Страница 4, верхние 8К полностью занимает внешнее окошко 1
	// Кроме того, внешние окошко 2 подключается B800-BFFF

	[self.cpu mapObject:self.win1	atPage:4 from:0xE800 to:0xFFFF];
	[self.cpu mapObject:self.win2	atPage:4 from:0xB800 to:0xBFFF];

	// Страница 5, верхние 8К полностью занимает внешнее окошко 1
	// Кроме того, внешние окошко 2 подключается 8000-BFFF

	[self.cpu mapObject:self.win1	atPage:5 from:0xE800 to:0xFFFF];
	[self.cpu mapObject:self.win2	atPage:5 from:0x8000 to:0xBFFF];

	// Страница 6, ПЗУ Бейсика подключается по адресам A000-BFFF

	[self.cpu mapObject:self.basic	atPage:6 from:0xA000 to:0xBFFF WR:nil];

	// Страница 7, ОЗУ1 и ОЗУ2 меняются местами

	[self.cpu mapObject:[self.ram memoryAtOffest:0x8000 length:0x8000 mask:0x7FFF]	atPage:7 from:0x0000 to:0x7FFF];
	[self.cpu mapObject:[self.ram memoryAtOffest:0x0000 length:0x8000 mask:0x7FFF]	atPage:7 from:0x8000 to:0xD7FF];

	// Страница 8, ПЗУ Бейсика подключается по адресам A000-9FFF
	// Кроме того, внешние окошко 1 подключается 8000-BFFF

	[self.cpu mapObject:self.win2	atPage:8 from:0xC800 to:0xD7FF];
	[self.cpu mapObject:self.rom	atPage:8 from:0xC000 to:0xC7FF WR:nil];
	[self.cpu mapObject:self.basic	atPage:8 from:0xA000 to:0xBFFF WR:nil];
	[self.cpu mapObject:self.win1	atPage:8 from:0x8000 to:0x9FFF];

	// Страница 9

	[self.cpu mapObject:self.win1	atPage:9 from:0x8000 to:0x9FFF];
	[self.cpu mapObject:self.win2	atPage:9 from:0xC800 to:0xD7FF];

	// Странца 10

	[self.cpu mapObject:self.win1	atPage:10 from:0x4000 to:0x5FFF];
	[self.cpu mapObject:self.win2	atPage:10 from:0x8000 to:0xBFFF];
	[self.cpu mapObject:self.rom	atPage:10 from:0xC000 to:0xCFFF WR:nil];

	self.cpu.INTA = self.sys1;
	self.cpu.INTR = self.crt;
	self.cpu.FF = TRUE;

	self.dma.DMA0 = self.floppy;
	[self.cpu addObjectToRESET:self.floppy];

	[self.cpu mapHook:self.kbdHook = [[F81B alloc] initWithRKKeyboard:self.kbd] atAddress:0xF81B];

	[self.cpu mapHook:self.inpHook = [[F806 alloc] initWithSound:self.snd] atAddress:0xF806];
	self.inpHook.extension = @"rkp";
	self.inpHook.type = 1;

	[self.cpu mapHook:self.outHook = [[F80C alloc] init] atAddress:0xF80C];
	self.outHook.extension = @"rkp";
	self.outHook.type = 1;

	return [super mapObjects];
}

// -----------------------------------------------------------------------------
// encodeWithCoder/decodeWithCoder
// -----------------------------------------------------------------------------

- (void) encodeWithCoder:(NSCoder *)encoder
{
	[super encodeWithCoder:encoder];

	[encoder encodeObject:self.basic forKey:@"basic"];
	[encoder encodeObject:self.sys2 forKey:@"sys2"];

	[encoder encodeBool:self.isFloppy forKey:@"isFloppy"];
	[encoder encodeObject:self.fddbios forKey:@"fddbios"];
	[encoder encodeObject:self.floppy forKey:@"floppy"];

	[encoder encodeObject:self.mcpgbios forKey:@"mcpgbios"];
	[encoder encodeObject:self.mcpgfont forKey:@"mcpgfont"];
}

- (BOOL) decodeWithCoder:(NSCoder *)decoder
{
	if (![super decodeWithCoder:decoder])
		return FALSE;

	if ((self.basic = [decoder decodeObjectForKey:@"basic"]) == nil)
		return FALSE;

	if ((self.sys2 = [decoder decodeObjectForKey:@"sys2"]) == nil)
		return FALSE;

	self.isFloppy = [decoder decodeBoolForKey:@"isFloppy"];

	if ((self.fddbios = [decoder decodeObjectForKey:@"fddbios"]) == nil)
		return FALSE;

	if ((self.floppy = [decoder decodeObjectForKey:@"floppy"]) == nil)
		return FALSE;

	if ((self.mcpgbios = [decoder decodeObjectForKey:@"mcpgbios"]) == nil)
		return FALSE;

	if ((self.mcpgfont = [decoder decodeObjectForKey:@"mcpgfont"]) == nil)
		return FALSE;

	return TRUE;
}

@end

// -----------------------------------------------------------------------------
// Системнный регистр 1 - выбор станицы адресного простарнства
// -----------------------------------------------------------------------------

@implementation PartnerSystem1

@synthesize cpu;
@synthesize crt;

- (void) WR:(uint16_t)addr byte:(uint8_t)data CLK:(uint64_t)clock
{
	cpu.PAGE = data >> 4;
}

- (uint8_t) INTA:(uint64_t)clock
{
	crt.INTR = FALSE;
	return 0xF7;
}

@end

// -----------------------------------------------------------------------------
// Системнный регистр 2 и внешние устройства
// -----------------------------------------------------------------------------

@implementation PartnerSystem2
{
	uint8_t slot;
	BOOL mcpg;
}

@synthesize partner;

- (void) setSlot:(uint8_t)data
{
	slot = data;

	if (slot & 0x02 && partner.isFloppy)
	{
		partner.win1.object = partner.fddbios;
		partner.win2.object = nil;
	}

	else if (slot & 0x04 && partner.isColor)
	{
		partner.win1.object = partner.mcpgbios;
		partner.win2.object = partner.mcpgfont;
	}

	else
	{
		partner.win1.object = nil;
		partner.win2.object = nil;
	}
}

- (uint8_t) slot
{
	return slot;
}

- (void) setMcpg:(BOOL)data
{
	mcpg = data; [partner.crt setMcpg:(mcpg && partner.isColor ? partner.mcpgfont.mutableBytes : NULL)];
}

- (BOOL) mcpg
{
	return mcpg;
}

- (uint8_t) RD:(uint16_t)addr CLK:(uint64_t)clock data:(uint8_t)data
{
	if ((addr & 0x200) == 0)
	{
		if (slot & 0x02 && partner.isFloppy)
			return (addr & 0x100) == 0 ? [partner.floppy RD:addr CLK:clock data:data] : data;

		if (slot & 0x04 && partner.isColor)
			return (addr & 0x100) == 0 ? data : [partner.snd RD:addr>>2 CLK:clock data:data];

		return data;
	}

	return data;
}

- (void) WR:(uint16_t)addr byte:(uint8_t)data CLK:(uint64_t)clock
{
	if ((addr & 0x200) == 0)
	{
		if (slot & 0x02 && partner.isFloppy)
		{
			if ((addr & 0x100) == 0)
				[partner.floppy WR:addr byte:data CLK:clock];

			else
			{
				partner.floppy.selected = data & 0x40 ? 1 : data & 0x08 ? 2 : 0;
				partner.floppy.head = (data & 0x80) != 0;
			}
		}

		else if (slot & 0x04 && partner.isColor)
		{
			if ((addr & 0x100) == 0)
				self.mcpg = data != 0xFF;
			else
				[partner.snd WR:addr>>2 byte:data CLK:clock];
		}
	}

	else if ((addr & 0x100) == 0)
	{
		self.slot = ~(data | 0xF0);
	}
}

- (void) encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeInt:slot forKey:@"slot"];
	[encoder encodeBool:mcpg forKey:@"mcpg"];
}

- (id) initWithCoder:(NSCoder *)decoder
{
	if (self = [super init])
	{
		slot = [decoder decodeIntForKey:@"slot"];
		mcpg = [decoder decodeBoolForKey:@"mcpg"];
	}

	return self;
}

@end

// -----------------------------------------------------------------------------
// Окно внешнего устройства
// -----------------------------------------------------------------------------

@implementation PartnerExternal

@synthesize object;

- (uint8_t) RD:(uint16_t)addr CLK:(uint64_t)clock data:(uint8_t)data
{
	return object ? [object RD:addr CLK:clock data:data] : data;
}

- (void) WR:(uint16_t)addr byte:(uint8_t)data CLK:(uint64_t)clock
{
	if ([object conformsToProtocol:@protocol(WR)])
		[(NSObject<WR> *)object WR:addr byte:data CLK:clock];
}

@end

// -----------------------------------------------------------------------------
// Вариант клавиатуры РК86 для Партнера
// -----------------------------------------------------------------------------

@implementation PartnerKeyboard

- (id) init
{
	if (self = [super init])
	{
		RUSLAT = 0x10;
		TAPEI = 0x80;
	}

	return self;
}

- (void) setC:(uint8_t)data
{
	self.snd.sound.beeper = data & 0x02 ? 0 : 4000 * 9;
	[super setC:data];
}

@end
