/*******************************************************************************
 ПЭВМ «Микро-80»
 ******************************************************************************/

#import "x8080.h"
#import "mem.h"

#import "TextScreen.h"
#import "RKKeyboard.h"
#import "RKRecorder.h"

// -----------------------------------------------------------------------------
// Интерфейс сопряжения "Микро-80"
// -----------------------------------------------------------------------------

@interface Micro80Recorder : NSObject <SoundController, ReadWrite>

@end

// -----------------------------------------------------------------------------
// Интерфейс клавиатуры "Микро-80"
// -----------------------------------------------------------------------------

@interface Micro80Keyboard : RKKeyboard

@end

// -----------------------------------------------------------------------------
// ПЭВМ "Микро-80"
// -----------------------------------------------------------------------------

@interface Micro80 : Computer

@property X8080 *cpu;
@property Memory *rom;
@property Memory *ram;

@property TextScreen *crt;

@property Micro80Recorder *snd;
@property Micro80Keyboard *kbd;

@property F812 *kbdHook;
@property F806 *inpHook;
@property F80C *outHook;

@end
