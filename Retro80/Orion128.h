/*****

 Проект «Ретро КР580» (http://uart.myqnapcloud.com/retro80.html)
 Copyright © 2014-2016 Andrey Chicherov <chicherov@mac.com>

 ПЭВМ «Орион 128»

 *****/

#import "x8080.h"
#import "mem.h"

#import "Orion128Screen.h"
#import "Orion128Floppy.h"

#import "RKKeyboard.h"
#import "RKRecorder.h"
#import "ROMDisk.h"

#import "x8253.h"

// -----------------------------------------------------------------------------
// Системные регистры ПЭВМ "Орион 128"
// -----------------------------------------------------------------------------

@interface Orion128SystemF8 : NSObject<RD, WR>
- (id) initWithCRT:(Orion128Screen *)crt;
@end

@interface Orion128SystemF9 : NSObject<RD, WR>
- (id) initWithRAM:(RAM *)ram;
@end

@interface Orion128SystemFA : NSObject<RD, WR>
- (id) initWithCRT:(Orion128Screen *)crt;
@end

// -----------------------------------------------------------------------------
// ПЭВМ "Орион 128"
// -----------------------------------------------------------------------------

@interface Orion128 : Computer

@property X8080 *cpu;
@property ROM *rom;
@property RAM *ram;
@property MEM *mem;

@property Orion128SystemF8 *sysF8;
@property Orion128SystemF9 *sysF9;
@property Orion128SystemFA *sysFA;

@property Orion128Screen *crt;
@property Orion128Floppy *fdd;

@property RKKeyboard *kbd;
@property ROMDisk *ext;
@property X8255 *prn;

@property X8253 *snd;

@property F806 *inpHook;
@property F80C *outHook;

@end

// -----------------------------------------------------------------------------
// Системные регистры Z80Card-II
// -----------------------------------------------------------------------------

@interface Orion128SystemFB : NSObject<RD, WR>
- (id) initWithCPU:(X8080 *)cpu MEM:(MEM *)mem CRT:(Orion128Screen *)crt;
@end

@interface Orion128SystemFE : NSObject <RD, WR>
- (id) initWithX8253:(X8253 *)snd EXT:(ROMDisk *)ext;
@end

@interface Orion128SystemFF : NSObject <RD, WR>
- (id) initWithX8253:(X8253 *)snd;
@end

// -----------------------------------------------------------------------------
// ПЭВМ "Орион 128" + Z80Card-II
// -----------------------------------------------------------------------------

@interface Orion128Z80CardII : Orion128

@property Orion128SystemFB *sysFB;
@property Orion128SystemFE *sysFE;
@property Orion128SystemFF *sysFF;

@end
