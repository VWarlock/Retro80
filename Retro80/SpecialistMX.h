/*******************************************************************************
 ПЭВМ «Специалист MX»
 ******************************************************************************/

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
// ПЭВМ "Специалист MX" с MXOS (Commander)
// -----------------------------------------------------------------------------

@interface SpecialistMX_Commander : Specialist

@property SpecialistMXSystem *sys;
@property ROMDisk *ext;

@property BOOL isFloppy;
@property VG93 *fdd;

@end

// -----------------------------------------------------------------------------
// ПЭВМ "Специалист MX" с MXOS (RAMFOS)
// -----------------------------------------------------------------------------

@interface SpecialistMX_RAMFOS : SpecialistMX_Commander

@property SpecialistMXKeyboard *kbd;

@end
