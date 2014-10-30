@protocol SoundController;
@protocol Processor;
@class Document;

// -----------------------------------------------------------------------------
// Sound - Поддеркжа звукового ввода/вывода
// -----------------------------------------------------------------------------

@interface Sound : NSResponder

@property (assign) IBOutlet NSTextField *textField;
@property (assign) IBOutlet Document* document;

@property (weak) NSObject <SoundController> *snd;
@property (weak) NSObject <Processor> *cpu;

@property (readonly) BOOL isInput;
@property (readonly) BOOL input;

@property uint16_t beeper;
@property BOOL output;

- (BOOL) open:(NSURL *)url;
- (void) close;

- (void) start;
- (void) stop;

@end
