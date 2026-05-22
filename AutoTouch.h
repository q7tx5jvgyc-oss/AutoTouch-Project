#import <UIKit/UIKit.h>

@interface AutoTouchMenu : NSObject

@property (nonatomic, strong) UIWindow *floatingWindow;
@property (nonatomic, strong) UIView *controlPanel;
@property (nonatomic, strong) UIView *targetPointer;
@property (nonatomic, strong) NSTimer *clickTimer;
@property (nonatomic, assign) NSTimeInterval clickSpeed;
@property (nonatomic, assign) BOOL isClicking;

+ (instancetype)sharedInstance;
- (void)initializeMenu;
- (void)spawnPointer;
- (void)startAutoClick;
- (void)stopAutoClick;

@end
