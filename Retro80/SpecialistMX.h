/*****

 Проект «Ретро КР580» (http://uart.myqnapcloud.com/retro80.html)
 Copyright © 2014-2016 Andrey Chicherov <chicherov@mac.com>

 ПЭВМ «Специалист MX»

 *****/

#import "Specialist.h"
#import "ROMDisk.h"
#import "vg93.h"

// -----------------------------------------------------------------------------
// Интерфейс клавиатуры ПЭВМ "Специалист MX"
// -----------------------------------------------------------------------------

@interface SpecialistMXKeyboard : SpecialistKeyboard

@end

// -----------------------------------------------------------------------------
// Системные регистры ПЭВМ "Специалист MX"
// -----------------------------------------------------------------------------

@interface SpecialistMXSystem : NSObject <RD, WR, RESET>

@property SpecialistScreen *crt;
@property (weak) X8080 *cpu;
@property VG93 *fdd;

@end

// -----------------------------------------------------------------------------
// Системные регистры ПЭВМ "Специалист MX2"
// -----------------------------------------------------------------------------

@interface SpecialistMX2System : SpecialistMXSystem

@property SpecialistMXKeyboard *kbd;

@end

// -----------------------------------------------------------------------------
// ПЭВМ "Специалист MX" с MXOS (Commander)
// -----------------------------------------------------------------------------

@interface SpecialistMX_Commander : Specialist

@property SpecialistMXSystem *sys;
@property ROMDisk *ext;

@end

// -----------------------------------------------------------------------------
// ПЭВМ "Специалист MX" с MXOS (RAMFOS)
// -----------------------------------------------------------------------------

@interface SpecialistMX_RAMFOS : SpecialistMX_Commander

@property SpecialistMXKeyboard *kbd;
@property VG93 *fdd;

@end

// -----------------------------------------------------------------------------
// ПЭВМ "Специалист MX2"
// -----------------------------------------------------------------------------

@interface SpecialistMX2 : SpecialistMX_RAMFOS

@property SpecialistMX2System *sys;

@end
