/*******************************************************************************
 * Контроллер НГМД ПЭВМ «Орион-128»
 ******************************************************************************/

#import "Orion128Floppy.h"

@implementation Orion128Floppy

- (void) WR:(uint16_t)addr data:(uint8_t)data CLK:(uint64_t)clock
{
	switch (addr)
	{
		case 0xF700:
		case 0xF701:
		case 0xF702:
		case 0xF703:

		case 0xF710:
		case 0xF711:
		case 0xF712:
		case 0xF713:

			[super WR:addr data:data CLK:clock];
			break;

		case 0xF708:

			self.selected = ((data & 0x02) >> 1) + 1;
			self.head = (data & 0x01) != 0;
			break;

		case 0xF714:
		case 0xF720:

			self.selected = data & 2 ? 0 : (data & 1) + 1;
			self.head = (data & 0x10) == 0;
			break;
	}
}

- (void) RD:(uint16_t)addr data:(uint8_t *)data CLK:(uint64_t)clock
{
	switch (addr)
	{
		case 0xF700:
		case 0xF701:
		case 0xF702:
		case 0xF703:

		case 0xF710:
		case 0xF711:
		case 0xF712:
		case 0xF713:

			[super RD:addr data:data CLK:clock];
			break;

		case 0xF704:

			[super RD:0xF700 data:data CLK:clock];
			*data = (*data & 0x01 ? 0x00 : 0x80) | ((*data & 0x02) >> 1);
			break;

		default:

			*data = 0xFF;
	}
}

@end