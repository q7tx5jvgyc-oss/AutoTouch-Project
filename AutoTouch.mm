#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface MoustacheAuto : NSObject
@property (nonatomic, strong) UIWindow *floatingWindow;
@property (nonatomic, strong) UIView *controlPanel;
@property (nonatomic, strong) UIButton *mainButton;
@property (nonatomic, strong) UIView *targetPointer;
@property (nonatomic, strong) NSTimer *clickTimer;
@property (nonatomic, assign) NSTimeInterval clickSpeed;
@property (nonatomic, assign) BOOL isClicking;
@property (nonatomic, strong) UILabel *speedValueLabel;
+ (instancetype)sharedInstance;
@end

@implementation MoustacheAuto

+ (void)load {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:UIApplicationDidFinishLaunchingNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification * _Nonnull note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MoustacheAuto sharedInstance];
        });
    }];
}

+ (instancetype)sharedInstance {
    static MoustacheAuto *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[self alloc] init]; });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.clickSpeed = 0.05; // سرعة بدائية سريعة
        self.isClicking = NO;
        [self initializeMenu];
    }
    return self;
}

- (void)initializeMenu {
    // إنشاء النافذة العائمة الرئيسية
    self.floatingWindow = [[UIWindow alloc] initWithFrame:CGRectMake(40, 150, 60, 60)];
    self.floatingWindow.windowLevel = UIWindowLevelAlert + 10.0;
    self.floatingWindow.backgroundColor = [UIColor clearColor];
    self.floatingWindow.layer.cornerRadius = 30;
    [self.floatingWindow makeKeyAndVisible];
    
    // تصميم الزر العائم الرئيسي مع أنيميشن نبض خفيف
    self.mainButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.mainButton.frame = CGRectMake(0, 0, 60, 60);
    self.mainButton.backgroundColor = [UIColor colorWithRed:0.09 green:0.09 blue:0.11 alpha:0.9];
    self.mainButton.layer.cornerRadius = 30;
    self.mainButton.layer.borderWidth = 2.5;
    self.mainButton.layer.borderColor = [UIColor systemRedColor].CGColor;
    [self.mainButton setTitle:@"👨🏻‍🦱" forState:UIControlStateNormal]; // رمز الشارب (موستاش)
    self.mainButton.titleLabel.font = [UIFont systemFontOfSize:28];
    [self.mainButton addTarget:self action:@selector(togglePanelWithAnimation) forControlEvents:UIControlEventTouchUpInside];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragMenu:)];
    [self.mainButton addGestureRecognizer:panGesture];
    [self.floatingWindow addSubview:self.mainButton];
    
    // تصميم لوحة تحكم "موستاش اوتو" بشكل احترافي ورهيب
    self.controlPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 70, 240, 240)];
    self.controlPanel.backgroundColor = [UIColor colorWithRed:0.07 green:0.07 blue:0.08 alpha:0.96];
    self.controlPanel.layer.cornerRadius = 20;
    self.controlPanel.layer.borderWidth = 2;
    self.controlPanel.layer.borderColor = [UIColor systemRedColor].CGColor;
    self.controlPanel.hidden = YES;
    self.controlPanel.alpha = 0.0;
    self.controlPanel.transform = CGAffineTransformMakeScale(0.8, 0.8); // للتأثير الحركي عند الفتح
    
    // إضافة تظليل خلفي فخم للوحة التحكم
    self.controlPanel.layer.shadowColor = [UIColor systemRedColor].CGColor;
    self.controlPanel.layer.shadowOpacity = 0.5;
    self.controlPanel.layer.shadowOffset = CGSizeMake(0, 4);
    self.controlPanel.layer.shadowRadius = 10;
    [self.floatingWindow addSubview:self.controlPanel];
    
    // عنوان الواجهة: موستاش اوتو
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, 220, 25)];
    titleLabel.text = @"موستاش اوتو | MUSTACHE";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:15];
    [self.controlPanel addSubview:titleLabel];
    
    // زر إضافة إصبع النقر
    UIButton *addBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 55, 200, 38)];
    [addBtn setTitle:@"➕ إضافة إصبع النقر" forState:UIControlStateNormal];
    addBtn.backgroundColor = [UIColor systemRedColor];
    addBtn.layer.cornerRadius = 10;
    addBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [addBtn addTarget:self action:@selector(spawnPointer) forControlEvents:UIControlEventTouchUpInside];
    [self.controlPanel addSubview:addBtn];
    
    // نص شريط السرعة التوضيحي
    UILabel *speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 105, 120, 15)];
    speedLabel.text = @"التحكم في سرعة النقر:";
    speedLabel.textColor = [UIColor lightGrayColor];
    speedLabel.font = [UIFont systemFontOfSize:12];
    [self.controlPanel addSubview:speedLabel];
    
    // نص يعرض قيمة السرعة الحالية
    self.speedValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(140, 105, 80, 15)];
    self.speedValueLabel.text = @"0.05 ثانية";
    self.speedValueLabel.textColor = [UIColor systemRedColor];
    self.speedValueLabel.textAlignment = NSTextAlignmentRight;
    self.speedValueLabel.font = [UIFont boldSystemFontOfSize:12];
    [self.controlPanel addSubview:self.speedValueLabel];
    
    // شريط السرعة التفاعلي (Slider)
    UISlider *speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(18, 125, 204, 30)];
    speedSlider.minimumValue = 0.001; // نقر مجنون وخارق جداً (أجزاء ملي ثانية)
    speedSlider.maximumValue = 0.500; // نقر بطيء ونصف ثانية
    speedSlider.value = self.clickSpeed;
    speedSlider.minimumTrackTintColor = [UIColor systemRedColor];
    speedSlider.maximumTrackTintColor = [UIColor darkGrayColor];
    [speedSlider addTarget:self action:@selector(speedChanged:) forControlEvents:UIControlEventValueChanged];
    [self.controlPanel addSubview:speedSlider];
    
    // أزرار التحكم السفلى (تشغيل / إيقاف) جنباً إلى جنب
    UIButton *startBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 175, 95, 45)];
    [startBtn setTitle:@"▶️ تشغيل" forState:UIControlStateNormal];
    startBtn.backgroundColor = [UIColor systemGreenColor];
    startBtn.layer.cornerRadius = 12;
    startBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [startBtn addTarget:self action:@selector(startAutoClick) forControlEvents:UIControlEventTouchUpInside];
    [self.controlPanel addSubview:startBtn];
    
    UIButton *stopBtn = [[UIButton alloc] initWithFrame:CGRectMake(125, 175, 95, 45)];
    [stopBtn setTitle:@"⏸️ إيقاف" forState:UIControlStateNormal];
    stopBtn.backgroundColor = [UIColor systemOrangeColor];
    stopBtn.layer.cornerRadius = 12;
    stopBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [stopBtn addTarget:self action:@selector(stopAutoClick) forControlEvents:UIControlEventTouchUpInside];
    [self.controlPanel addSubview:stopBtn];
}

// أنيميشن قوي ورهيب لفتح وإغلاق القائمة بالسحب والتكبير والتصغير الفاخر
- (void)togglePanelWithAnimation {
    BOOL isHidden = self.controlPanel.hidden;
    
    if (isHidden) {
        self.controlPanel.hidden = NO;
        // تكبير حجم النافذة لتستوعب لوحة التحكم كاملة
        self.floatingWindow.frame = CGRectMake(self.floatingWindow.frame.origin.x, self.floatingWindow.frame.origin.y, 240, 320);
        
        [UIView animateWithDuration:0.4 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.controlPanel.alpha = 1.0;
            self.controlPanel.transform = CGAffineTransformIdentity; // يعود لحجمه الطبيعي بانسيابية
            self.mainButton.transform = CGAffineTransformMakeRotation(M_PI_4); // حركة لف خفيفة للزر الرئيسي
        } completion:nil];
    } else {
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.controlPanel.alpha = 0.0;
            self.controlPanel.transform = CGAffineTransformMakeScale(0.8, 0.8);
            self.mainButton.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            self.controlPanel.hidden = YES;
            self.floatingWindow.frame = CGRectMake(self.floatingWindow.frame.origin.x, self.floatingWindow.frame.origin.y, 60, 60);
        }];
    }
}

- (void)dragMenu:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.floatingWindow];
    self.floatingWindow.center = CGPointMake(self.floatingWindow.center.x + translation.x, self.floatingWindow.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:self.floatingWindow];
}

- (void)spawnPointer {
    if (self.targetPointer) return;
    
    // تصميم إصبع النقر الدائري التفاعلي الذكي
    self.targetPointer = [[UIView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width / 2 - 25, [UIScreen mainScreen].bounds.size.height / 2 - 25, 50, 50)];
    self.targetPointer.backgroundColor = [[UIColor systemRedColor] colorWithAlphaComponent:0.35];
    self.targetPointer.layer.cornerRadius = 25;
    self.targetPointer.layer.borderWidth = 2.5;
    self.targetPointer.layer.borderColor = [UIColor systemRedColor].CGColor;
    
    // السنتر الداخلي الأبيض الدقيق لضبط الهدف
    UIView *centerTarget = [[UIView alloc] initWithFrame:CGRectMake(22, 22, 6, 6)];
    centerTarget.backgroundColor = [UIColor whiteColor];
    centerTarget.layer.cornerRadius = 3;
    [self.targetPointer addSubview:centerTarget];
    
    UIPanGestureRecognizer *pointerDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragPointer:)];
    [self.targetPointer addGestureRecognizer:pointerDrag];
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (keyWindow) {
        [keyWindow addSubview:self.targetPointer];
        
        // أنيميشن ظهور الإصبع (تأثير نبضة أولية رهيبة)
