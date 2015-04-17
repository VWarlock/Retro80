/*******************************************************************************
 ПЭВМ «Специалист MX»
 ******************************************************************************/

#import "SpecialistMX.h"

// =============================================================================
// Интерфейс клавиатуры ПЭВМ "Специалист MX"
// =============================================================================

@implementation SpecialistMXKeyboard

- (id) init
{
	if (self = [super init])
	{
		kbdmap = @[
				   @53,  @109, @122, @120, @99,  @118, @96,  @97,  @98,  @100, @101, @51,
				   @10,  @18,  @19,  @20,  @21,  @23,  @22,  @26,  @28,  @25,  @29,  @27,
				   @12,  @13,  @14,  @15,  @17,  @16,  @32,  @34,  @31,  @35,  @33,  @30,
				   @0,   @1,   @2,   @3,   @5,   @4,   @38,  @40,  @37,  @41,  @39,  @42,
				   @6,   @7,   @8,   @9,   @11,  @45,  @46,  @43,  @47,  @44,  @50,  @117,
				   @999, @115, @126, @125, @999, @999, @49,  @123, @48,  @124, @76,  @36
				   ];
	}

	return self;
}

@end

// =============================================================================
// Системный регистр ПЭВМ "Специалист MX"
// =============================================================================

@implementation SpecialistMXSystem

@synthesize cpu;
@synthesize crt;
@synthesize fdd;

- (uint8_t) RD:(uint16_t)addr CLK:(uint64_t)clock data:(uint8_t)data
{
	switch (addr)
	{
		case 0xFFF8:
			return crt.color;

		default:
			return data;
	}
}

- (void) WR:(uint16_t)addr byte:(uint8_t)data CLK:(uint64_t)clock
{
	switch (addr)
	{
		case 0xFFF0:	// D3.1 (pF0 - захват)

			fdd.HOLD = TRUE;
			break;

		case 0xFFF1:	// D3.2	(pF1 - мотор)

			break;
			
		case 0xFFF2:	// D4.2	(pF2 - сторона)

			fdd.head = data & 1;
			break;

		case 0xFFF3:	// D4.1	(pF3 - дисковод)

			fdd.selected = (data & 1) + 1;
			break;

		case 0xFFF8:	// Регистр цвета
		case 0xFFF9:
		case 0xFFFA:
		case 0xFFFB:

			crt.color = data;
			break;

		case 0xFFFC:	// Выбрать RAM

			cpu.PAGE = 1;
			break;

		case 0xFFFD:	// Выбрать RAM-диск

			cpu.PAGE = 2 + (data & 7);
			break;

		case 0xFFFE:	// Выбрать ROM-диск

			cpu.PAGE = 0;
			break;

		case 0xFFFF:	// Резерв для Специалист MX2
			break;
	}
}

- (void) RESET
{
	fdd.selected = 1;
}

@end

// =============================================================================
// ПЭВМ "Специалист MX"
// =============================================================================

@implementation SpecialistMX

+ (NSString *) title
{
	return @"Специалист MX";
}

+ (NSArray *) extensions
{
	return @[@"mon", @"cpu", @"i80"];
}

// -----------------------------------------------------------------------------
// validateMenuItem
// -----------------------------------------------------------------------------

- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
	if (menuItem.action == @selector(extraMemory:))
	{
		switch (menuItem.tag)
		{
			case 0:

				menuItem.submenu = [[NSMenu alloc] init];
				[menuItem.submenu addItemWithTitle:@"128K" action:@selector(extraMemory:) keyEquivalent:@""].tag = 1;
				[menuItem.submenu addItemWithTitle:@"256K" action:@selector(extraMemory:) keyEquivalent:@""].tag = 2;
				[menuItem.submenu addItemWithTitle:@"512K" action:@selector(extraMemory:) keyEquivalent:@""].tag = 3;

				menuItem.state = self.ram.length != 0x20000;
				break;

			case 1:
				menuItem.state = self.ram.length == 0x30000;
				break;

			case 2:
				menuItem.state = self.ram.length == 0x50000;
				break;

			case 3:
				menuItem.state = self.ram.length == 0x90000;
				break;
		}

		return YES;
	}

	if (menuItem.action == @selector(floppy:))
	{
		if (menuItem.tag == 0)
		{
			menuItem.state = TRUE; return NO;
		}
		else
		{
			NSURL *url = [self.fdd getDisk:menuItem.tag]; if ((menuItem.state = url != nil))
				menuItem.title = [((NSString *)[menuItem.title componentsSeparatedByString:@":"][0]) stringByAppendingFormat:@": %@", url.lastPathComponent];
			else
				menuItem.title = [((NSString *)[menuItem.title componentsSeparatedByString:@":"][0]) stringByAppendingString:@":"];

			return menuItem.tag != self.fdd.selected || !self.fdd.busy;
		}
	}

	return [super validateMenuItem:menuItem];
}

// -----------------------------------------------------------------------------
// Модуль ОЗУ
// -----------------------------------------------------------------------------

- (IBAction) extraMemory:(NSMenuItem *)menuItem
{
	unsigned size = menuItem.tag == 0 && self.ram.length == 0x20000 ? 0x30000 : 0x10000 + (1 << (menuItem.tag + 16));

	if (self.ram.length != size) @synchronized(self.snd.sound)
	{
		[self.document registerUndoWithMenuItem:menuItem];

		RAM *ram = [[RAM alloc] initWithLength:size mask:0xFFFF];
		memcpy(ram.mutableBytes, self.ram.mutableBytes, size < self.ram.length ? size : self.ram.length);
		self.ram = ram; [self mapObjects]; self.cpu.RESET = TRUE;
	}
}

// -----------------------------------------------------------------------------
// Модуль контроллера дисковода
// -----------------------------------------------------------------------------

- (IBAction) floppy:(NSMenuItem *)menuItem
{
	if (menuItem.tag)
	{
		NSOpenPanel *panel = [NSOpenPanel openPanel];
		panel.allowedFileTypes = @[@"odi", @"cpm"];
		panel.title = menuItem.title;

		if ([panel runModal] == NSFileHandlingPanelOKButton && panel.URLs.count == 1)
		{
			@synchronized(self.snd.sound)
			{
				[self.document registerUndoWithMenuItem:menuItem];
				[self.fdd setDisk:menuItem.tag URL:panel.URLs.firstObject];
			}
		}
		else if ([self.fdd getDisk:menuItem.tag] != nil)
		{
			@synchronized(self.snd.sound)
			{
				[self.document registerUndoWithMenuItem:menuItem];
				[self.fdd setDisk:menuItem.tag URL:nil];
			}
		}
	}
}

// -----------------------------------------------------------------------------
// Инициализация
// -----------------------------------------------------------------------------

- (BOOL) createObjects
{
	if ((self.rom = [[ROM alloc] initWithContentsOfResource:@"SpecialistMX" mask:0xFFFF]) == nil)
		return FALSE;

	if ((self.ram = [[RAM alloc] initWithLength:0x20000 mask:0xFFFF]) == nil)
		return FALSE;

	if ((self.kbd = [[SpecialistMXKeyboard alloc] init]) == nil)
		return FALSE;

	if ([super createObjects] == FALSE)
		return FALSE;

	if ((self.fdd = [[VG93 alloc] initWithQuartz:self.cpu.quartz]) == nil)
		return FALSE;

	self.snd.channel0 = TRUE;
	self.snd.rkmode = TRUE;

	self.crt.isColor = TRUE;

	self.cpu.START = 0x0000;
	return TRUE;
}

// -----------------------------------------------------------------------------

- (BOOL) mapObjects
{
	self.crt.screen = self.ram.mutableBytes + 0x9000;

	[self.cpu mapObject:self.rom atPage:0 from:0x0000 to:0xBFFF WR:nil];
	[self.cpu mapObject:self.ram atPage:0 from:0xC000 to:0xFFBF];

	[self.cpu mapObject:self.ram atPage:1 from:0x0000 to:0x8FFF];
	[self.cpu mapObject:self.crt atPage:1 from:0x9000 to:0xBFFF RD:self.ram];
	[self.cpu mapObject:self.ram atPage:1 from:0xC000 to:0xFFBF];

	[self.cpu mapObject:[self.ram memoryAtOffest:0x10000 length:0x10000 mask:0xFFFF] atPage:2 from:0x0000 to:0xFFBF];
	[self.cpu mapObject:[self.ram memoryAtOffest:0x20000 length:0x10000 mask:0xFFFF] atPage:3 from:0x0000 to:0xFFBF];
	[self.cpu mapObject:[self.ram memoryAtOffest:0x30000 length:0x10000 mask:0xFFFF] atPage:4 from:0x0000 to:0xFFBF];
	[self.cpu mapObject:[self.ram memoryAtOffest:0x40000 length:0x10000 mask:0xFFFF] atPage:5 from:0x0000 to:0xFFBF];
	[self.cpu mapObject:[self.ram memoryAtOffest:0x50000 length:0x10000 mask:0xFFFF] atPage:6 from:0x0000 to:0xFFBF];
	[self.cpu mapObject:[self.ram memoryAtOffest:0x60000 length:0x10000 mask:0xFFFF] atPage:7 from:0x0000 to:0xFFBF];
	[self.cpu mapObject:[self.ram memoryAtOffest:0x70000 length:0x10000 mask:0xFFFF] atPage:8 from:0x0000 to:0xFFBF];
	[self.cpu mapObject:[self.ram memoryAtOffest:0x80000 length:0x10000 mask:0xFFFF] atPage:9 from:0x0000 to:0xFFBF];

	if ((self.sys = [[SpecialistMXSystem alloc] init]) == nil)
		return FALSE;

	self.sys.cpu = self.cpu;
	self.sys.crt = self.crt;
	self.sys.fdd = self.fdd;

	[self.cpu mapObject:self.sys	from:0xFFF8 to:0xFFFF];
	//	[self.cpu mapObject:nil       from:0xFFF4 to:0xFFF7];
	[self.cpu mapObject:self.sys	from:0xFFF0 to:0xFFF3];
	[self.cpu mapObject:self.snd	from:0xFFEC to:0xFFEF];
	[self.cpu mapObject:self.fdd	from:0xFFE8 to:0xFFEB];
	[self.cpu mapObject:self.ext	from:0xFFE4 to:0xFFE7];
	[self.cpu mapObject:self.kbd	from:0xFFE0 to:0xFFE3];
	[self.cpu mapObject:self.ram	from:0xFFC0 to:0xFFDF];

	[self.cpu addObjectToRESET:self.kbd];
	[self.cpu addObjectToRESET:self.ext];
	[self.cpu addObjectToRESET:self.fdd];
	[self.cpu addObjectToRESET:self.sys];

	self.cpu.HLDA = self.fdd;
	self.kbd.snd = self.snd;
	return TRUE;
}

// -----------------------------------------------------------------------------

- (id) initWithData:(NSData *)data URL:(NSURL *)url
{
	if (self = [self init])
	{
		unsigned addr; if ([url.pathExtension.lowercaseString isEqualToString:@"mon"])
		{
			NSScanner *scanner = [NSScanner scannerWithString:url.lastPathComponent.stringByDeletingPathExtension];
			scanner.scanLocation = 3; if (![scanner scanHexInt:&addr] || addr + data.length > 0xFFBF)
				return self = nil;

			memcpy(self.ram.mutableBytes + addr, data.bytes, data.length);
			self.cpu.PC = addr;
		}

		else
		{
			NSArray *cpu = nil; if ([url.pathExtension.lowercaseString isEqualToString:@"cpu"])
			{
				cpu = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]
					   componentsSeparatedByCharactersInSet:[NSCharacterSet controlCharacterSet]];

				data = [NSData dataWithContentsOfURL:[url.URLByDeletingPathExtension URLByAppendingPathExtension:@"i80"]];
			}
			else
			{
				cpu = [[NSString stringWithContentsOfURL:[url.URLByDeletingPathExtension URLByAppendingPathExtension:@"cpu"] encoding:NSASCIIStringEncoding error:nil]
					   componentsSeparatedByCharactersInSet:[NSCharacterSet controlCharacterSet]];
			}

			if (cpu.count < 3 || data == nil)
				return self = nil;

			if (cpu.count > 4 && ((NSString *)cpu[4]).length && ![((NSString *)cpu[4]).lowercaseString isEqualToString:@"spmx.rom"])
			{
				NSData *bios; if ((bios = [NSData dataWithContentsOfURL:[url.URLByDeletingLastPathComponent URLByAppendingPathComponent:cpu[4]]]) == nil)
					return self = nil;

				NSScanner *scanner = [NSScanner scannerWithString:((NSString *)cpu[4]).stringByDeletingPathExtension];
				scanner.scanLocation = 3; if (![scanner scanHexInt:&addr] || addr + bios.length > 0xFFBF)
					return self = nil;

				memcpy(self.ram.mutableBytes + addr, bios.bytes, bios.length);

				self.cpu.RESET = FALSE;
				self.cpu.PC = addr;
				self.cpu.PAGE = 1;
			}

			[self.cpu execute:self.cpu.quartz];
			self.crt.color = 0x70;

			if (![[NSScanner scannerWithString:cpu[0]] scanHexInt:&addr] || addr + data.length > 0xFFBF)
				return self = nil;

			memcpy(self.ram.mutableBytes + addr, data.bytes, data.length);

			if (![[NSScanner scannerWithString:cpu[2]] scanHexInt:&addr] || addr + data.length > 0xFFBF)
				return self = nil;

			self.cpu.PC = addr;
		}

		self.cpu.RESET = FALSE;
		self.cpu.PAGE = 1;
	}

	return self;
}

// -----------------------------------------------------------------------------

- (void) encodeWithCoder:(NSCoder *)encoder
{
	[super encodeWithCoder:encoder];
	[encoder encodeObject:self.fdd forKey:@"fdd"];
}

- (BOOL) decodeWithCoder:(NSCoder *)decoder
{
	if (![super decodeWithCoder:decoder])
		return FALSE;
	
	if ((self.fdd = [decoder decodeObjectForKey:@"fdd"]) == nil)
		return FALSE;

	return TRUE;
}

@end
