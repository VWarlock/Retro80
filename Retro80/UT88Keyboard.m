/*****
 
 Проект «Ретро КР580» (http://uart.myqnapcloud.com/retro80.html)
 Copyright © 2014-2016 Andrey Chicherov <chicherov@mac.com>
 
 Интерфейс клавиатуры ПЭВМ «ЮТ-88»
 + дополнительная клавиатура
 + модуль сопряжения
 
 *****/

#include "UT88Keyboard.h"

@implementation UT88Keyboard
{
    uint8_t key;
}

// -----------------------------------------------------------------------------

- (void) keyDown:(NSEvent*)theEvent
{
    NSUInteger index = [@"0123456789ABCDEF\x7F" rangeOfString:theEvent.charactersIgnoringModifiers.uppercaseString].location;
    key = index == NSNotFound ? 0x00 : index == 0 ? 0x10 : index == 16 ? 0x80 : (uint8_t)index;
    [super keyDown:theEvent];
}

// -----------------------------------------------------------------------------

- (void) keyUp:(NSEvent *)theEvent
{
    if (theEvent)
    {
        NSUInteger index = [@"0123456789ABCDEF\x7F" rangeOfString:theEvent.charactersIgnoringModifiers.uppercaseString].location;
        if (key == index == 0 ? 0x10 : index == 16 ? 0x80 : (uint8_t)index) key = 0x00;
    }
    else
    {
        key = 00;
    }

    [super keyUp:theEvent];
}

// -----------------------------------------------------------------------------

- (void) RD:(uint16_t)addr data:(uint8_t *)data CLK:(uint64_t)clock
{
    if ((addr & 0xF000) != 0xA000)
        [super RD:addr data:data CLK:clock];
    
    else if (addr & 0x0100)
        *data = self.snd.sound.input;
    
    else
        *data = key;
}

// -----------------------------------------------------------------------------

- (void) WR:(uint16_t)addr data:(uint8_t)data CLK:(uint64_t)clock
{
    if ((addr & 0xF000) != 0xA000)
        [super WR:addr data:data CLK:clock];
    
    else if (addr & 0x0100)
        self.snd.sound.output = data & 0x01;
}

// -----------------------------------------------------------------------------

- (void) RESET:(uint64_t)clock
{
    [super RESET:clock];
    key = 0x00;
}

@end
