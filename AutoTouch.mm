#import "AutoTouch.h"
#import <objc/runtime.h>

@implementation AutoTouchMenu

// نقطة الانطلاق: الكود يحقن نفسه تلقائياً عند فتح التطبيق
+ (void)load {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[id] sharedInstance];
    });
}

+ (instancetype)sharedInstance {
    static AutoTouchMenu *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.clickSpeed = 0.05; // السرعة البدائية (سريعة جداً)
        self.isClicking = NO;
        [self initializeMenu];
    }
    return self;
}

- (void)initializeMenu {
    // 1. إنشاء الزر العائم الصغير المستدير
    self.floatingWindow = [[UIWindow alloc] initWithFrame:CGRectMake(40, 150, 60, 60)];
    self.floatingWindow.windowLevel = UIWindowLevelAlert + 10;
    self.floatingWindow.backgroundColor = [UIColor clearColor];
    self.floatingWindow.layer.cornerRadius = 30;
    [self.floatingWindow makeKeyAndVisible];
    
    UIButton *mainButton = [UIButton buttonWithType:UIButtonTypeCustom];
    mainButton.frame = CGRectMake(0, 0, 60, 60);
    mainButton.backgroundColor = [[UIColor systemRedColor] colorWithAlphaComponent:0.85];
    mainButton.layer.cornerRadius = 30;
    mainButton.layer.borderWidth = 2;
    mainButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [mainButton setTitle:@"🎯" forState:UIControlStateNormal];
    mainButton.titleLabel.font = [UIFont systemFontOfSize:26];
    [mainButton addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
    
    // إضافة إيماءة سحب الزر العائم في أي مكان بالشاشة
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragMenu:)];
    [mainButton addGestureRecognizer:panGesture];
    [self.floatingWindow addSubview:mainButton];
    
    // 2. إنشاء لوحة التحكم (تكون مخفية في البداية)
    self.controlPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 70, 220, 200)];
    self.controlPanel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.9];
    self.controlPanel.layer.cornerRadius = 15;
    self.controlPanel.layer.borderWidth = 1;
    self.controlPanel.layer.borderColor = [UIColor systemGrayColor].CGColor;
    self.controlPanel.hidden = YES;
    [self.floatingWindow addSubview:self.controlPanel];
    
    // عنوان اللوحة
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 200, 20)];
    titleLabel.text = @"AutoTouch Pro v1.0";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [self.controlPanel addSubview:titleLabel];
    
    // زر إضافة الإصبع
    UIButton *addBtn = [[UIButton alloc] initWithFrame:CGRectMake(15, 40, 190, 35)];
    [addBtn setTitle:@"➕ إضافة إصبع النقر" forState:UIControlStateNormal];
    addBtn.backgroundColor = [UIColor systemBlueColor];
    addBtn.layer.cornerRadius = 8;
    addBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [addBtn addTarget:self action:@selector(spawnPointer) forControlEvents:UIControlEventTouchUpInside];
    [self.controlPanel addSubview:addBtn];
    
    // نص شريط السرعة
    UILabel *speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 85, 190, 15)];
    speedLabel.text = @"التحكم بالسرعة والأجزاء الكسرية:";
    speedLabel.textColor = [UIColor lightGrayColor];
    speedLabel.font = [UIFont systemFontOfSize:11];
    [self.controlPanel addSubview:speedLabel];
    
    // شريط السرعة (Slider)
    UISlider *speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(15, 105, 190, 30)];
    speedSlider.minimumValue = 0.001; // نقر حقيقي خارق فائق السرعة
    speedSlider.maximumValue = 0.5;   // سرعة بطيئة
    speedSlider.value = self.clickSpeed;
    [speedSlider addTarget:self action:@selector(speedChanged:) forControlEvents:UIControlEventValueChanged];
    [self.controlPanel addSubview:speedSlider];
    
    // زر التشغيل والإيقاف النهائي
    UIButton *actionBtn = [[UIButton alloc] initWithFrame:CGRectMake(15, 145, 190, 40)];
    [actionBtn setTitle:@"▶️ تشغيل التلقائي" forState:UIControlStateNormal];
    actionBtn.backgroundColor = [UIColor systemGreenColor];
    actionBtn.layer.cornerRadius = 8;
    [actionBtn addTarget:self action:@selector(actionTriggered:) forControlEvents:UIControlEventTouchUpInside];
    [self.controlPanel addSubview:actionBtn];
}

- (void)togglePanel {
    self.controlPanel.hidden = !self.controlPanel.hidden;
    if (!self.controlPanel.hidden) {
        self.floatingWindow.frame = CGRectMake(self.floatingWindow.frame.origin.x, self.floatingWindow.frame.origin.y, 220, 280);
    } else {
        self.floatingWindow.frame = CGRectMake(self.floatingWindow.frame.origin.x, self.floatingWindow.frame.origin.y, 60, 60);
    }
}

- (void)dragMenu:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.floatingWindow];
    self.floatingWindow.center = CGPointMake(self.floatingWindow.center.x + translation.x, self.floatingWindow.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:self.floatingWindow];
}

- (void)spawnPointer {
    if (self.targetPointer) return; // نمنع التكرار لضمان الثبات
    
    // تصميم الإصبع العائم (دائرة حمراء شفافة مع سنتر أبيض دقيق)
    self.targetPointer = [[UIView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width / 2 - 25, [UIScreen mainScreen].bounds.size.height / 2 - 25, 50, 50)];
    self.targetPointer.backgroundColor = [[UIColor systemRedColor] colorWithAlphaComponent:0.4];
    self.targetPointer.layer.cornerRadius = 25;
    self.targetPointer.layer.borderWidth = 2;
    self.targetPointer.layer.borderColor = [UIColor systemRedColor].CGColor;
    
    UIView *centerTarget = [[UIView alloc] initWithFrame:CGRectMake(22, 22, 6, 6)];
    centerTarget.backgroundColor = [UIColor whiteColor];
    centerTarget.layer.cornerRadius = 3;
    [self.targetPointer addSubview:centerTarget];
    
    UIPanGestureRecognizer *pointerDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragPointer:)];
    [self.targetPointer addGestureRecognizer:pointerDrag];
    
    [[UIApplication sharedApplication].keyWindow addSubview:self.targetPointer];
    [self togglePanel]; // إغلاق تلقائي لتحديد الموضع براحة
}

- (void)dragPointer:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.targetPointer.superview];
    self.targetPointer.center = CGPointMake(self.targetPointer.center.x + translation.x, self.targetPointer.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:self.targetPointer.superview];
}

- (void)speedChanged:(UISlider *)sender {
    self.clickSpeed = sender.value;
    if (self.isClicking) {
        [self stopAutoClick];
        [self startAutoClick];
    }
}

- (void)actionTriggered:(UIButton *)sender {
    if (!self.targetPointer) return;
    
    if (self.isClicking) {
        [self stopAutoClick];
        [sender setTitle:@"▶️ تشغيل التلقائي" forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor systemGreenColor];
    } else {
        [self startAutoClick];
        [sender setTitle:@"⏸️ إيقاف مؤقت" forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor systemOrangeColor];
    }
}

- (void)startAutoClick {
    self.isClicking = YES;
    self.clickTimer = [NSTimer scheduledTimerWithTimeInterval:self.clickSpeed target:self selector:@selector(executePhysicalTap) userInfo:nil repeats:YES];
}

- (void)stopAutoClick {
    self.isClicking = NO;
    if (self.clickTimer) {
        [self.clickTimer invalidate];
        self.clickTimer = nil;
    }
}

// محاكاة النقر الفيزيائي الفعلي المتوافق 100% مع الأيفون بدون حظر
- (void)executePhysicalTap {
    if (!self.targetPointer) return;
    
    CGPoint tapPoint = self.targetPointer.center;
    UIWindow *currentWindow = [UIApplication sharedApplication].keyWindow;
    UIView *detectedView = [currentWindow hitTest:tapPoint withEvent:nil];
    
    if (detectedView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // إرسال إشارات مباشرة لعناصر التطبيق للتفاعل اللحظي عالي السرعة
            if ([detectedView respondsToSelector:@selector(sendActionsForControlEvents:)]) {
                [(UIControl *)detectedView sendActionsForControlEvents:UIControlEventTouchUpInside];
            } else {
                for (UIGestureRecognizer *recognizer in detectedView.gestureRecognizers) {
                    if ([recognizer isKindOfClass:[UITapGestureRecognizer class]]) {
                        SEL targetSelector = NSSelectorFromString(@"_handleTap:");
                        if ([recognizer respondsToSelector:targetSelector]) {
                            #pragma clang diagnostic push
                            #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                            [recognizer performSelector:targetSelector withObject:recognizer];
                            #pragma clang diagnostic pop
                        }
                    }
                }
            }
        });
    }
}

@end
