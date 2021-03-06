/*****

 Проект «Ретро КР580» (http://uart.myqnapcloud.com/retro80.html)
 Copyright © 2014-2016 Andrey Chicherov <chicherov@mac.com>

 ПЭВМ «Радио-86РК»

 *****/

#import "RK86Base.h"
#import "ROMDisk.h"
#import "Floppy.h"

// -----------------------------------------------------------------------------
// Radio86RK8253 - ВИ53 (только запись) повешен параллельно ВВ55
// -----------------------------------------------------------------------------

@interface Radio86RK8253 : X8253

@property X8255 *ext;

@end

// -----------------------------------------------------------------------------
// ПЭВМ «Радио-86РК»
// -----------------------------------------------------------------------------

@interface Radio86RK : RK86Base

@property Radio86RK8253 *snd;
@property ROMDisk *ext;

@property Floppy *fdd;
@property ROM *dos;

@end
