#import "x8255.h"

@interface ROMDisk : X8255 <NSOpenSavePanelDelegate>

@property (readonly) const uint8_t* bytes;
@property (readonly) NSUInteger length;
@property NSURL* url;

@end
