#import "x8080.h"

// -----------------------------------------------------------------------------
// MEM - базовый класс для RAM, так же часть памяти RAM
// -----------------------------------------------------------------------------

@interface MEM : NSObject <RD, WR, BYTE>

- (MEM *) memoryAtOffest:(NSUInteger)offset length:(NSUInteger)len mask:(uint16_t)msk;

- (id) initWithMemory:(uint8_t *)ptr length:(NSUInteger)len mask:(uint16_t)msk;

@property (readonly) uint8_t *mutableBytes;
@property (readonly) NSUInteger length;
@property (readonly) uint16_t mask;

@end

// -----------------------------------------------------------------------------
// RAM
// -----------------------------------------------------------------------------

@interface RAM : MEM <NSCoding>

- (id) initWithLength:(unsigned)len mask:(uint16_t)msk;

@end

// -----------------------------------------------------------------------------
// ROM
// -----------------------------------------------------------------------------

@interface ROM : NSObject <RD, BYTE, NSCoding>

- (id) initWithContentsOfResource:(NSString *)name mask:(uint16_t)mask;

@property (readonly) uint8_t *mutableBytes;
@property (readonly) NSUInteger length;
@property (readonly) uint16_t mask;

@end
