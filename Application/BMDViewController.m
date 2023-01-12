/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of the cross-platform view controller
*/

#import "BMDViewController.h"
#import <VungleSDK/VungleSDK.h>
#import "Firebase.h"
@import UIKit;


@implementation BMDViewController {
    @public
//    UIWindow *window;
    BMDAppDelegate *appd;

    CAGradientLayer *homeViewColorGradient;
    int gradientAnimationIndex;
    CGFloat yOffsetPrevBackNextInEditMode;
    
}

@synthesize renderer;
@synthesize backgroundRenderDictionary;
@synthesize background;

//@synthesize nextButton;
@synthesize prevButton;
@synthesize backButton;
@synthesize editPlayButton;
@synthesize deleteButton;
@synthesize duplicateButton;
@synthesize saveButton;
@synthesize soundsEnabledButton;
@synthesize musicEnabledButton;
@synthesize leaderboardsButton;
@synthesize startPuzzleButton;
@synthesize dailyPuzzleButton;
@synthesize startPuzzleButtonCheckmark;
@synthesize dailyPuzzleButtonCheckmark;
@synthesize moreHintPacksButton;
@synthesize noAdsButton;
@synthesize removeAdsLabel;

@synthesize packButtonsArray;
@synthesize hintButtonsArray;

@synthesize tutorialTitleLabelText;
@synthesize tutorialHeadingLabel;
@synthesize gameTitleLabel;
@synthesize puzzleSolvedLabel;
@synthesize gamePuzzleLabel;
@synthesize numberOfPointsLabel;
@synthesize todaysDateLabelHome;
@synthesize todaysDateLabelGame;
@synthesize packAndPuzzlesLabel;
@synthesize puzzleCompleteMessage;
@synthesize puzzleSolvedLabelFrame;
@synthesize puzzleCompleteMessageInitialFrame;
@synthesize puzzleCompleteMessageText;

@synthesize nextButtonRectEdit;
@synthesize nextButtonRectPlay;
@synthesize prevButtonRectEdit;
@synthesize prevButtonRectPlay;
@synthesize backButtonRectEdit;
@synthesize backButtonRectPlay;

@synthesize tutorialMessageLabel1;
@synthesize tutorialMessageLabel2;
@synthesize tutorialMessageLabel3;
@synthesize tutorialMessageLabel4;

@synthesize packAndPuzzleNumbersLabel;

@synthesize contentScaleFactor;
@synthesize safeFrame;
@synthesize topPaddingInPoints;
@synthesize bottomPaddingInPoints;
@synthesize screenWidthInPixels;
@synthesize screenHeightInPixels;
@synthesize safeAreaScreenWidthInPixels;
@synthesize safeAreaScreenHeightInPixels;
@synthesize displayAspectRatio;
@synthesize appCurrentPageNumber;
@synthesize appPreviousPageNumber;
@synthesize appCurrentGamePackType;
@synthesize appPreviousGamePackType;

@synthesize hintsViewController;
@synthesize packsViewController;
@synthesize puzzleViewController;
@synthesize settingsViewController;

@synthesize rootView;
@synthesize homeView;
@synthesize bannerAdView;
@synthesize scoresView;

@synthesize logoView;
@synthesize puzzleSolvedView;

@synthesize numberOfJewelsBeamed;
@synthesize numberOfPoints;
@synthesize numberOfMoves;
@synthesize jewelsCollectedLabelStats;
@synthesize puzzlesSolvedLabelStats;
@synthesize pointsLabelStats;
@synthesize tilesPositionedStats;
@synthesize puzzleStartTime;
@synthesize puzzleSolutionTime;
@synthesize gamekitAccessPoint;

@synthesize renderPuzzleON;
@synthesize renderBackgroundON;

- (void)viewDidLoad
{
    DLog(">>> BMDViewController.viewDidLoad");

    [super viewDidLoad];

    appd = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];

    self.renderPuzzleON = NO;           // MetalKit Puzzle rendering is initially disabled
    self.renderBackgroundON = NO;       // MetalKit Background rendering is initially disabled

    [self setupPhysicalDeviceDisplay];
    
    [self setupViewsButtonsLabels];

    // Notify that we have loaded
    appd.rootViewControllerHasLoaded = YES;
    
    // Show the launch screen
    [self showLaunchScreen];
    
    // Connect with GameCenter
    if ([appd isGameCenterAvailable]){
        [appd authenticatePlayer];
    }
    
}


- (void)viewDidAppear:(BOOL)animated
{
    DLog(">>> BMDViewController.viewDidAppear");
    [super viewDidAppear:animated];
    
    // Start loop1Player
    [appd playMusicLoop:appd.loop1Player];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // No permittedToUseiCloud so ask the user if they wish to use iCloud to store defaults
    if ([[defaults objectForKey:@"permittedToUseiCloud"] isEqualToString:@"NOTHING"] && appd.currentiCloudToken != nil) {
        [self chooseWhetherToUseiCloudStorage];
    }
    else {
        // We have no iCloud token so inform user we will run locally
        if ([[defaults objectForKey:@"permittedToUseiCloud"] isEqualToString:@"NOTHING"] && appd.currentiCloudToken == nil){
            [defaults setObject:@"NO" forKey:@"permittedToUseiCloud"];
            [self iCloudStorageUnreachable];
            // Initialize tracking of Puzzle Pack Progress in NSDefaults
            [appd initializePuzzlePacksProgress];
        }
        else {
            // We do have a valid iCloud token so we can go ahead and use it
            //
            // Skip running PACKTYPE_DEMO if it has already been completed OR if the PE is enabled
            //
            if ([[defaults objectForKey:@"demoHasBeenCompleted"] isEqualToString:@"YES"] ||
                (ENABLE_PUZZLE_EDITOR == YES)){
                appCurrentGamePackType = PACKTYPE_MAIN;
                [self refreshHomeView];
                [self hideLaunchScreen];
                [self loadAppropriateSizeBannerAd];
            }
            else {
                [self startDemoPuzzle];
            }
        }
    }
    
#ifdef ENABLE_GA
    [FIRAnalytics logEventWithName:kFIREventSelectContent
                        parameters:@{
                                     kFIRParameterItemID:[NSString stringWithFormat:@"id-%@", @"VC viewDidAppear"],
                                     kFIRParameterItemName:@"VC viewDidAppear",
                                     kFIRParameterContentType:@"image"
                                     }];
#endif

    if (![[defaults objectForKey:@"demoHasBeenCompleted"] isEqualToString:@"NOTHING"]){
        if (![appd checkForEndlessHintsPurchased] && [defaults objectForKey:@"numberOfHintsRemaining"] == nil){
            [defaults setObject:[NSNumber numberWithInt:kInitialFreeHints] forKey:@"numberOfHintsRemaining"];
        }
        //    appCurrentGamePackType = PACKTYPE_MAIN;
        [self refreshHomeView];
        [self hideLaunchScreen];
        [self loadAppropriateSizeBannerAd];
    }
}

//- (NSMutableDictionary *)renderBackground {
//    DLog("renderBackground");
//    animationFrame++;
//    backgroundRenderDataImage = [background renderBackgroundImage:7];
//    backgroundAnimationImage = [background renderBackgroundAnimations:animationFrame backgroundColor:7];
//    [backgroundRenderDictionary setObject:backgroundRenderDataImage forKey:@"backgroundImage"];
//    [backgroundRenderDictionary setObject:backgroundAnimationImage forKey:@"backgroundAnimationImage"];
//    return backgroundRenderDictionary;
//}

- (void)refreshHomeView {
    homeView.hidden = NO;
    
    // Set background color and graphic image
    homeView.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.14 alpha:1.0];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"backgroundLandscapeGrid" ofType:@"png"];
    UIImage *sourceImage = [UIImage imageWithContentsOfFile:filePath];
    CGFloat imageWidth = (CGFloat)sourceImage.size.width;
    CGFloat imageHeight = (CGFloat)sourceImage.size.height;
    CGFloat displayWidth = self.view.frame.size.width;
    CGFloat displayHeight = self.view.frame.size.height;
    CGFloat scaleFactor = displayHeight / imageHeight;
    CGFloat newHeight = displayHeight;
    CGFloat newWidth = imageWidth * scaleFactor;
    CGSize imageSize = CGSizeMake(newWidth, newHeight);
    UIGraphicsBeginImageContext(imageSize);
    [sourceImage drawInRect:CGRectMake(-(newWidth-displayWidth)/2.0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImageView *homeViewBackground = [[UIImageView alloc]initWithImage:newImage];
    homeViewBackground.contentMode = UIViewContentModeScaleAspectFill;
    homeViewBackground.clipsToBounds = YES;
    [homeView addSubview:homeViewBackground];
    [homeView sendSubviewToBack:homeViewBackground];
    
    [rootView sendSubviewToBack:homeView];
    
    //
    // Activate BMDRenderer
    //
//    homeView.enableSetNeedsDisplay = NO;
//    homeView.preferredFramesPerSecond = 30;
//    homeView.presentsWithTransaction = NO;
//    homeView.device = MTLCreateSystemDefaultDevice();
//    NSAssert(homeView.device, @"Metal is not supported on this device");
//    renderer = [[BMDRenderer alloc] initWithMetalKitView:homeView];
//    NSAssert(renderer, @"Renderer failed initialization");
//    // Initialize the renderer with the view size
//    [renderer mtkView:homeView drawableSizeWillChange:homeView.drawableSize];
//    homeView.delegate = renderer;
//    [appd initAllTextures:homeView metalRenderer:renderer];
//
//    // The fixed part of the background only needs to get rendered once
//    background = [[Background alloc] init];
//    backgroundRenderDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
//    animationFrame = 0;
//    renderBackgroundON = YES;

    
    //
    // Activate Game Center Access Point
    //
    gamekitAccessPoint.active = YES;

    // Fetch the current pack name and number of puzzles left for the startPuzzle button
    NSMutableDictionary *packDictionary = [appd fetchPuzzlePack:[appd fetchCurrentPackNumber]];
    NSString *packName = [packDictionary objectForKey:@"pack_name"];
    NSString *packTitle;
    NSMutableAttributedString *packTitle1, *packTitle2;
    unsigned int unsolvedPuzzleCount = [appd queryNumberOfPuzzlesLeftInCurrentPack];
    if (unsolvedPuzzleCount == 0){
        startPuzzleButtonCheckmark.hidden = NO;
        packTitle = [NSString stringWithFormat:@"%s Completed!\nChoose New Pack", [packName UTF8String]];
        packTitle1 = [[NSMutableAttributedString alloc] initWithString:packTitle];
    }
    else {
        startPuzzleButtonCheckmark.hidden = YES;
        packTitle = [NSString stringWithFormat:@"Resume Puzzle Pack\n%s", [packName UTF8String]];
        packTitle1 = [[NSMutableAttributedString alloc] initWithString:packTitle];
        if (unsolvedPuzzleCount == 1){
            packTitle = [NSString stringWithFormat:@"\n%d puzzle left", unsolvedPuzzleCount];
        }
        else {
            packTitle = [NSString stringWithFormat:@"\n%d puzzles left", unsolvedPuzzleCount];
        }
        NSRange range1 = NSMakeRange(0, [packTitle length]);
        packTitle2 = [[NSMutableAttributedString alloc] initWithString:packTitle];
        [packTitle2 addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"PingFang SC Light" size:[self querySmallFontSize]] range:range1];
        startPuzzleButton.enabled = YES;
        [packTitle1 appendAttributedString:packTitle2];
    }
    [startPuzzleButton setAttributedTitle:packTitle1 forState:UIControlStateNormal];

    // Start loop1Player
    [appd playMusicLoop:appd.loop1Player];

    // Update the dailyPuzzleButton
    NSNumber *dailyPuzzleCompletionDay = [appd getObjectFromDefaults:@"dailyPuzzleCompletionDay"];
    NSNumber *todayLocal = [NSNumber numberWithUnsignedInt:[appd getLocalDaysSinceReferenceDate]];
    // The Daily Puzzle Button is used to enter the Puzzle Editor when editMode == YES
    if (ENABLE_PUZZLE_EDITOR == YES){
        [dailyPuzzleButton setTitle:@"Puzzle Editor" forState:UIControlStateNormal];
        dailyPuzzleButton.enabled = YES;
    }
    else {
        if (dailyPuzzleCompletionDay != nil && dailyPuzzleCompletionDay == todayLocal){
            [dailyPuzzleButton setTitle:@"Daily Puzzle Completed!" forState:UIControlStateNormal];
            dailyPuzzleButtonCheckmark.hidden = NO;
        }
        else {
            [dailyPuzzleButton setTitle:@"Play Daily Puzzle" forState:UIControlStateNormal];
            dailyPuzzleButton.enabled = YES;
            dailyPuzzleButtonCheckmark.hidden = YES;
        }
    }

    // Update moreHintPacksButton to show how many hints are left
    [self updateMoreHintPacksButton];
    
    // Update packAndPuzzleNumbersLabel
//    packAndPuzzleNumbersLabel.text = [NSString stringWithFormat:@"Pack: %d,  Puzzle: %d",
//                                      [appd fetchCurrentPackNumber],
//                                      [appd fetchCurrentPuzzleNumber]
//    ];
    
    // Update the noAdsButton status
    NSString *adFreeStatus = [appd getObjectFromDefaults:@"AD_FREE_PUZZLES"];
    if ([adFreeStatus isEqualToString:@"YES"]){
        noAdsButton.hidden = YES;
        removeAdsLabel.hidden = YES;
    }
    else {
        noAdsButton.hidden = NO;
        removeAdsLabel.hidden = NO;
    }

    [self loadAppropriateSizeBannerAd];
}

- (void)loadAppropriateSizeBannerAd {
    DLog("Is Vungle Ad Network Initialized?");
    NSString *adFree = [appd getObjectFromDefaults:@"AD_FREE_PUZZLES"];
    if ([adFree isEqualToString:@"YES"]){
        DLog("User purchased Ad Free Puzzles");
    }
    else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        // Load Vungle Banner Ad
        if (appd->vungleIsLoaded &&
            ([[defaults objectForKey:@"demoHasBeenCompleted"] isEqualToString:@"YES"] ||
             TARGET_OS_SIMULATOR)){
            switch (displayAspectRatio) {
                case ASPECT_4_3:
                    // iPad (9th generation)
                case ASPECT_10_7:
                    // iPad Air (5th generation)
                case ASPECT_3_2: {
                    // iPad Mini (6th generation)
                    [appd vungleLoadBannerLeaderboardAd];
                    break;
                }
                case ASPECT_16_9:
                case ASPECT_13_6:
                default: {
                    // iPhones
                    [appd vungleLoadBannerAd];
                    break;
                }
            }
        }
    }
}

- (void)startMainScreenMusicLoop {
    [appd playMusicLoop:appd.loop1Player];
}

//
// Present UIAlert to allow user whether to choose to use iCloud storage
//
- (void)chooseWhetherToUseiCloudStorage {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Choose Storage Option"
                                                                   message:@"Should documents be stored in iCloud and available on all your devices?"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* yesAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
        [defaults setObject:@"YES" forKey:@"permittedToUseiCloud"];
        [defaults setObject:@"NO" forKey:@"firstLaunchOfThisApp"];
        if ([self->appd existsKeyInNSUbiquitousKeyValueStore:@"PacksProgressPuzzlesDictionary"] == NO){
            // Initialize tracking of Puzzle Pack Progress in NSUbiquitousKeyValueStore
            [self->appd initializePuzzlePacksProgress];
        }
        // If the NSNumber numberOfHintsRemaining is not stored then initialize it to kInitialFreeHints
        if (![self->appd checkForEndlessHintsPurchased] && [self->appd getObjectFromDefaults:@"numberOfHintsRemaining"] == nil){
            [self->appd setObjectInDefaults:[NSNumber numberWithInt:kInitialFreeHints] forKey:@"numberOfHintsRemaining"];
        }
        [self updateMoreHintPacksButton];
        [self->appd setObjectInDefaults:@"YES" forKey:@"musicEnabled"];
        [self->appd setObjectInDefaults:@"YES" forKey:@"soundsEnabled"];
        [self->appd setObjectInDefaults:@"YES" forKey:@"editModeEnabled"];
        self->appd.numberOfHintsRemaining = [[self->appd getObjectFromDefaults:@"numberOfHintsRemaining"] intValue];
        if (ENABLE_PUZZLE_EDITOR == NO){
            //
            // Only consider running PACKTYPE_DEMO when PE disabled
            //
            if ([[defaults objectForKey:@"demoHasBeenCompleted"] isEqualToString:@"NOTHING"]){
                [self startDemoPuzzle];
            }
        }
        else {
            self->appCurrentGamePackType = PACKTYPE_MAIN;
            [self refreshHomeView];
            [self hideLaunchScreen];
            [self loadAppropriateSizeBannerAd];
        }
    }];
    [alert addAction:yesAction];
    
    UIAlertAction* noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
        [defaults setObject:@"NO" forKey:@"permittedToUseiCloud"];
        [defaults setObject:@"NO" forKey:@"firstLaunchOfThisApp"];
        if ([self->appd existsKeyInDefaults:@"PacksProgressPuzzlesDictionary"] == NO){
            // Initialize tracking of Puzzle Pack Progress in NSUbiquitousKeyValueStore
            [self->appd initializePuzzlePacksProgress];
        }
        // If the NSNumber numberOfHintsRemaining is not stored then initialize it to kInitialFreeHints
        if (![self->appd checkForEndlessHintsPurchased] && [self->appd getObjectFromDefaults:@"numberOfHintsRemaining"] == nil){
            [self->appd setObjectInDefaults:[NSNumber numberWithInt:kInitialFreeHints] forKey:@"numberOfHintsRemaining"];
        }
        [self updateMoreHintPacksButton];
        [self->appd setObjectInDefaults:@"YES" forKey:@"musicEnabled"];
        [self->appd setObjectInDefaults:@"YES" forKey:@"soundsEnabled"];
        [self->appd setObjectInDefaults:@"YES" forKey:@"editModeEnabled"];
        self->appd.numberOfHintsRemaining = [[self->appd getObjectFromDefaults:@"numberOfHintsRemaining"] intValue];
        if (ENABLE_PUZZLE_EDITOR == NO){
            //
            // Only consider running PACKTYPE_DEMO when PE disabled
            //
            if ([[defaults objectForKey:@"demoHasBeenCompleted"] isEqualToString:@"NOTHING"]){
                [self startDemoPuzzle];
            }
        }
        else {
            self->appCurrentGamePackType = PACKTYPE_MAIN;
            [self refreshHomeView];
            [self hideLaunchScreen];
            [self loadAppropriateSizeBannerAd];
        }
    }];
    [alert addAction:noAction];

    [self presentViewController:alert animated:YES completion:nil];
}


//
// Present UIAlert to inform user that iCloud is unreachable and local storage is being used
//
- (void)iCloudStorageUnreachable {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"iCloud Unreachable"
                                                                   message:@"Beamed 2 using local storage."
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* localAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
        [defaults setObject:@"NO" forKey:@"permittedToUseiCloud"];
        [defaults setObject:@"NO" forKey:@"firstLaunchOfThisApp"];
        if ([self->appd existsKeyInDefaults:@"PacksProgressPuzzlesDictionary"] == NO){
            // Initialize tracking of Puzzle Pack Progress in NSUbiquitousKeyValueStore
            [self->appd initializePuzzlePacksProgress];
        }
        // If the NSNumber numberOfHintsRemaining is not stored then initialize it to kInitialFreeHints
        if (![self->appd checkForEndlessHintsPurchased] && [self->appd getObjectFromDefaults:@"numberOfHintsRemaining"] == nil){
            [self->appd setObjectInDefaults:[NSNumber numberWithInt:kInitialFreeHints] forKey:@"numberOfHintsRemaining"];
        }
        [self updateMoreHintPacksButton];
        if ([self->appd getStringFromDefaults:@"musicEnabled"] == nil){
            [self->appd setObjectInDefaults:@"YES" forKey:@"musicEnabled"];
        }
        if ([self->appd getStringFromDefaults:@"soundsEnabled"] == nil){
            [self->appd setObjectInDefaults:@"YES" forKey:@"soundsEnabled"];
        }
        if ([self->appd getStringFromDefaults:@"editModeEnabled"] == nil){
            [self->appd setObjectInDefaults:@"YES" forKey:@"editModeEnabled"];
        }
        self->appd.numberOfHintsRemaining = [[self->appd getObjectFromDefaults:@"numberOfHintsRemaining"] intValue];
        [self hideLaunchScreen];
    }];
    [alert addAction:localAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}


// Hide the launch screen when the application is ready for user input
- (void)hideLaunchScreen{
    [self.rootView sendSubviewToBack:self->launchView];
    self->launchView.hidden = YES;
    self.rootView.layer.backgroundColor = [UIColor blackColor].CGColor;
}


// Show the launch screen while the application is processing and not ready for user input
- (void)showLaunchScreen{
    UIImage *launchImage = [UIImage imageNamed:@"LoadingScreen.png"];
//    UIImage *launchImage = [UIImage imageNamed:@"LoadingScreen.png"];
    UIImageView *launchImageView = [[UIImageView alloc] initWithImage:launchImage];
    CGSize launchSize = launchImage.size;
    CGFloat launchWidth = screenWidthInPixels/contentScaleFactor;
    CGFloat launchHeight = launchWidth*launchSize.height/launchSize.width;
    CGFloat launchCx, launchCy;
    switch (displayAspectRatio) {
        case ASPECT_4_3:
            // iPad (9th generation)
        case ASPECT_10_7:
            // iPad Air (5th generation)
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            launchCx = 0.5*screenWidthInPixels/contentScaleFactor - 0.5*launchWidth;
            launchCy = 0.5*screenHeightInPixels/contentScaleFactor - 0.67*launchHeight;
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            launchCx = 0.5*screenWidthInPixels/contentScaleFactor - 0.5*launchWidth;
            launchCy = 0.5*screenHeightInPixels/contentScaleFactor - 0.5*launchHeight;
            break;
        }
        case ASPECT_13_6:
        default:{
            // iPhone 14
            launchCx = 0.5*screenWidthInPixels/contentScaleFactor - 0.5*launchWidth;
            launchCy = 0.5*screenHeightInPixels/contentScaleFactor - 0.5*launchHeight;
            break;
        }
    }
    launchImageView.frame = CGRectMake(launchCx, launchCy, launchWidth, launchHeight);
    
    CGRect launchFrame = rootView.bounds;
    launchView = [[UIView alloc] initWithFrame:launchFrame];
    launchView.backgroundColor = [UIColor blackColor];
    launchView.alpha = 1.0;

    [launchView addSubview: launchImageView];
    [launchView bringSubviewToFront:launchImageView];
    [rootView addSubview:launchView];
    [rootView bringSubviewToFront:launchView];
}


// Hide the launch screen when the application is ready for user input
- (void)hideJewelsView{
    [self.rootView sendSubviewToBack:self->launchView];
    self->launchView.hidden = YES;
    self.rootView.layer.backgroundColor = [UIColor blackColor].CGColor;
}


// Show the launch screen while the application is processing and not ready for user input
- (void)scoresButtonPressed{
    // Create scoresView
//    CGRect scoresViewFrame = rootView.bounds;
    CGRect scoresViewFrame = CGRectMake(rootView.bounds.origin.x,
                                        rootView.bounds.origin.y,
                                        rootView.bounds.size.width,
                                        1.0*rootView.bounds.size.height);
    scoresView = [[UIView alloc] initWithFrame:scoresViewFrame];
    scoresView.backgroundColor = [UIColor blackColor];
    scoresView.alpha = 1.0;
    
    // Set background color and graphic image
    scoresView.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.14 alpha:1.0];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"backgroundLandscapeGrid" ofType:@"png"];
    UIImage *sourceImage = [UIImage imageWithContentsOfFile:filePath];
    CGFloat imageWidth = (CGFloat)sourceImage.size.width;
    CGFloat imageHeight = (CGFloat)sourceImage.size.height;
    CGFloat displayWidth = self.view.frame.size.width;
    CGFloat displayHeight = self.view.frame.size.height;
    CGFloat scaleFactor = displayHeight / imageHeight;
    CGFloat newHeight = displayHeight;
    CGFloat newWidth = imageWidth * scaleFactor;
    CGSize imageSize = CGSizeMake(newWidth, newHeight);
    UIGraphicsBeginImageContext(imageSize);
    [sourceImage drawInRect:CGRectMake(-(newWidth-displayWidth)/2.0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImageView *scoresViewBackground = [[UIImageView alloc]initWithImage:newImage];
    scoresViewBackground.contentMode = UIViewContentModeScaleAspectFill;
    scoresViewBackground.clipsToBounds = YES;
    [scoresView addSubview:scoresViewBackground];
    [scoresView sendSubviewToBack:scoresViewBackground];
    
    // Get the starry sky image
//    UIImage *starrySkyImage = [UIImage imageNamed:@"starrysky.jpg"];
//    UIImageView *starrySkyImageView = [[UIImageView alloc] initWithImage:starrySkyImage];
//    CGSize starrySkySize = starrySkyImage.size;
//    CGFloat starrySkyWidth = starrySkySize.width/contentScaleFactor;
//    CGFloat starrySkyHeight = starrySkySize.height/contentScaleFactor;
//    starrySkyImageView.frame = CGRectMake(homeView.frame.origin.x,
//                                          homeView.frame.origin.y,
//                                          starrySkyWidth,
//                                          starrySkyHeight);
//    [scoresView addSubview:starrySkyImageView];
//    [scoresView sendSubviewToBack:starrySkyImageView];

    NSString *adFree = [appd getObjectFromDefaults:@"AD_FREE_PUZZLES"];
    if (![adFree isEqualToString:@"YES"]){
        [scoresView addSubview:bannerAdView];
        [scoresView bringSubviewToFront:bannerAdView];
    }

    CGFloat titleLabelSize;
    CGFloat jewelWidth;
    int fontSize;
    CGFloat backButtonIconSizeInPoints = 60;
    CGFloat backArrowPosX, backArrowPosY;
    CGPoint centerInPoints;
    switch (displayAspectRatio) {
        case ASPECT_4_3:
            // iPad (9th generation)
        case ASPECT_10_7:
            // iPad Air (5th generation)
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            titleLabelSize = 36;
            jewelWidth = 0.15*screenWidthInPixels/contentScaleFactor;
            fontSize = 28;
            backButtonIconSizeInPoints = 60;
            backArrowPosX = 48;
            backArrowPosY = 162;
            centerInPoints = CGPointMake(0.50*screenWidthInPixels/contentScaleFactor, 0.50*screenHeightInPixels/contentScaleFactor);
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            titleLabelSize = 22;
            jewelWidth = 0.15*screenWidthInPixels/contentScaleFactor;
            fontSize = 20;
            backButtonIconSizeInPoints = 40;
            backArrowPosX = 33;
            backArrowPosY = 99;
            centerInPoints = CGPointMake(0.50*screenWidthInPixels/contentScaleFactor, 0.40*screenHeightInPixels/contentScaleFactor);
            break;
        }
        case ASPECT_13_6:
        default:{
            // iPhone 14
            titleLabelSize = 22;
            jewelWidth = 0.15*screenWidthInPixels/contentScaleFactor;
            fontSize = 20;
            backButtonIconSizeInPoints = 40;
            backArrowPosX = 33;
            backArrowPosY = 99;
            centerInPoints = CGPointMake(0.50*screenWidthInPixels/contentScaleFactor, 0.40*screenHeightInPixels/contentScaleFactor);
            break;
        }
    }
    CGFloat radius = 0.30*screenWidthInPixels/contentScaleFactor;
    
    // Scores Label
    CGRect scoresFrame = rootView.bounds;
    CGFloat w = 0.5*scoresFrame.size.width;
    CGFloat h = 1.5*titleLabelSize;
    CGFloat settingsLabelY = 3.0*h;
    CGRect scoresLabelFrame = CGRectMake(0.5*scoresFrame.size.width - w/2.0,
                                           settingsLabelY,
                                           w,
                                           h);
    UILabel *scoresPageLabel = [[UILabel alloc] initWithFrame:scoresLabelFrame];
    scoresPageLabel.text = @"Scores";
    scoresPageLabel.textColor = [UIColor cyanColor];
    scoresPageLabel.layer.borderColor = [UIColor clearColor].CGColor;
    scoresPageLabel.layer.borderWidth = 1.0;
    [scoresPageLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:titleLabelSize]];
    scoresPageLabel.textAlignment = NSTextAlignmentCenter;
    scoresPageLabel.adjustsFontSizeToFitWidth = NO;
    [scoresView addSubview:scoresPageLabel];
    [scoresView bringSubviewToFront:scoresPageLabel];
    
    //
    // backButton icon
    //
    // Create a back arrow icon at the left hand side
    UIButton *backArrow = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect backArrowRect = CGRectMake(backArrowPosX,
                                      backArrowPosY,
                                      backButtonIconSizeInPoints,
                                      backButtonIconSizeInPoints);
    backArrow.frame = backArrowRect;
    backArrow.enabled = YES;
    [backArrow addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UIImage *backArrowImage = [UIImage imageNamed:@"backArrow.png"];
    [backArrow setBackgroundImage:backArrowImage forState:UIControlStateNormal];
    [scoresView addSubview:backArrow];
    [scoresView bringSubviewToFront:backArrow];
    
    // Add Jewel Images
    
    // Get total count for each Jewel color
    int redJewelCount = [appd countTotalJewelsCollectedByColorKey:@"redCount"];
    int greenJewelCount = [appd countTotalJewelsCollectedByColorKey:@"greenCount"];
    int blueJewelCount = [appd countTotalJewelsCollectedByColorKey:@"blueCount"];
    int yellowJewelCount = [appd countTotalJewelsCollectedByColorKey:@"yellowCount"];
    int cyanJewelCount = [appd countTotalJewelsCollectedByColorKey:@"cyanCount"];
    int magentaJewelCount = [appd countTotalJewelsCollectedByColorKey:@"magentaCount"];
    int whiteJewelCount = [appd countTotalJewelsCollectedByColorKey:@"whiteCount"];

    // White
    UIImageView *jewelImageView = [self createImageView:@"JewelWhite.png"
                                                  width:jewelWidth
                                                   posX:centerInPoints.x
                                                   posY:centerInPoints.y];
    [scoresView addSubview: jewelImageView];
    [scoresView bringSubviewToFront:jewelImageView];
    UILabel *jewelLabel = [self createJewelLabel:COLOR_WHITE
                                        fontSize:fontSize
                                  numberOfJewels:whiteJewelCount
                                      jewelWidth:jewelWidth
                                       jewelPosX:centerInPoints.x
                                       jewelPosY:centerInPoints.y];
    [scoresView addSubview: jewelLabel];
    [scoresView bringSubviewToFront:jewelLabel];
    
    // Red
    jewelImageView = [self createImageView:@"JewelRed.png"
                                     width:jewelWidth
                                      posX:centerInPoints.x
                                      posY:centerInPoints.y-radius];
    [scoresView addSubview: jewelImageView];
    [scoresView bringSubviewToFront:jewelImageView];
    jewelLabel = [self createJewelLabel:COLOR_RED
                               fontSize:fontSize
                         numberOfJewels:redJewelCount
                             jewelWidth:jewelWidth
                              jewelPosX:centerInPoints.x
                              jewelPosY:centerInPoints.y-radius];
    [scoresView addSubview: jewelLabel];
    [scoresView bringSubviewToFront:jewelLabel];
    
    // Yellow
    jewelImageView = [self createImageView:@"JewelYellow.png"
                                     width:jewelWidth
                                      posX:centerInPoints.x+0.866*radius
                                      posY:centerInPoints.y-0.5*radius];
    [scoresView addSubview: jewelImageView];
    [scoresView bringSubviewToFront:jewelImageView];
    jewelLabel = [self createJewelLabel:COLOR_YELLOW
                               fontSize:fontSize
                         numberOfJewels:yellowJewelCount
                             jewelWidth:jewelWidth
                              jewelPosX:centerInPoints.x+0.866*radius
                              jewelPosY:centerInPoints.y-0.5*radius];
    [scoresView addSubview: jewelLabel];
    [scoresView bringSubviewToFront:jewelLabel];
    
    // Green
    jewelImageView = [self createImageView:@"JewelGreen.png"
                                     width:jewelWidth
                                      posX:centerInPoints.x+0.866*radius
                                      posY:centerInPoints.y+0.5*radius];
    [scoresView addSubview: jewelImageView];
    [scoresView bringSubviewToFront:jewelImageView];
    jewelLabel = [self createJewelLabel:COLOR_GREEN
                               fontSize:fontSize
                         numberOfJewels:greenJewelCount
                             jewelWidth:jewelWidth
                              jewelPosX:centerInPoints.x+0.866*radius
                              jewelPosY:centerInPoints.y+0.5*radius];
    [scoresView addSubview: jewelLabel];
    [scoresView bringSubviewToFront:jewelLabel];
    
    // Cyan
    jewelImageView = [self createImageView:@"JewelCyan.png"
                                     width:jewelWidth
                                      posX:centerInPoints.x
                                      posY:centerInPoints.y+radius];
    [scoresView addSubview: jewelImageView];
    [scoresView bringSubviewToFront:jewelImageView];
    jewelLabel = [self createJewelLabel:COLOR_CYAN
                               fontSize:fontSize
                         numberOfJewels:cyanJewelCount
                             jewelWidth:jewelWidth
                              jewelPosX:centerInPoints.x
                              jewelPosY:centerInPoints.y+radius];
    [scoresView addSubview: jewelLabel];
    [scoresView bringSubviewToFront:jewelLabel];
    
    // Blue
    jewelImageView = [self createImageView:@"JewelBlue.png"
                                     width:jewelWidth
                                      posX:centerInPoints.x-0.866*radius
                                      posY:centerInPoints.y+0.5*radius];
    [scoresView addSubview: jewelImageView];
    [scoresView bringSubviewToFront:jewelImageView];
    jewelLabel = [self createJewelLabel:COLOR_BLUE
                               fontSize:fontSize
                         numberOfJewels:blueJewelCount
                             jewelWidth:jewelWidth
                              jewelPosX:centerInPoints.x-0.866*radius
                              jewelPosY:centerInPoints.y+0.5*radius];
    [scoresView addSubview: jewelLabel];
    [scoresView bringSubviewToFront:jewelLabel];
    
    // Magenta
    jewelImageView = [self createImageView:@"JewelMagenta.png"
                                     width:jewelWidth
                                      posX:centerInPoints.x-0.866*radius
                                      posY:centerInPoints.y-0.5*radius];
    [scoresView addSubview: jewelImageView];
    [scoresView bringSubviewToFront:jewelImageView];
    jewelLabel = [self createJewelLabel:COLOR_MAGENTA
                               fontSize:fontSize
                         numberOfJewels:magentaJewelCount
                             jewelWidth:jewelWidth
                              jewelPosX:centerInPoints.x-0.866*radius
                              jewelPosY:centerInPoints.y-0.5*radius];
    [scoresView addSubview: jewelLabel];
    [scoresView bringSubviewToFront:jewelLabel];
    
    [rootView addSubview:scoresView];
    [rootView bringSubviewToFront:scoresView];
}


- (UIImageView *)createImageView:(NSString *)imageFileName
                           width:(CGFloat)width
                            posX:(CGFloat)posX
                            posY:(CGFloat)posY {
    UIImage *image = [UIImage imageNamed:imageFileName];
    CGFloat height = width*image.size.height/image.size.width;
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = CGRectMake(posX-0.5*width,
                                 posY-0.5*height,
                                 width,
                                 height);
    return imageView;
}


- (UILabel *)createJewelLabel:(int)color
                     fontSize:(int)fontSize
               numberOfJewels:(int)numberOfJewels
                        jewelWidth:(CGFloat)jewelWidth
                         jewelPosX:(CGFloat)jewelPosX
                         jewelPosY:(CGFloat)jewelPosY {
    CGFloat labelWidth = 4.0*jewelWidth;
    CGFloat labelHeight = 1.25*fontSize;
    CGRect labelFrame = CGRectMake(jewelPosX-0.5*labelWidth, jewelPosY+0.5*jewelWidth, labelWidth, labelHeight);
    UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
    label.layer.borderColor = [UIColor clearColor].CGColor;
    label.layer.borderWidth = 1.0;
    label.text = [NSString stringWithString:[NSString stringWithFormat:@"%d",numberOfJewels]];
    [label setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:fontSize]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setTextColor:[UIColor whiteColor]];
    return label;
}

// - Refresh todaysDateLabelHome and todaysDateLabelGame when the app is energized or there is a screen transition
// - If the Daily Puzzle is currently being displayed then refresh it with the current Daily Puzzle in case the
//   date has changed since the last time the page was refreshed.
- (void)updateTodaysDate {
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateStyle:NSDateFormatterFullStyle];
    NSString *dateString = [formatter stringFromDate:date];
    todaysDateLabelHome.text = dateString;
}


//- (void)gameScreenTransition:(enum eGamePackType)pack {
//    // No flips on Tutorial, Daily or Demo puzzle transitions
//    if (appCurrentGamePackType == PACKTYPE_DAILY || appCurrentGamePackType == PACKTYPE_DEMO) {
//        [self showHideButtonsAndLabels:PAGE_GAME appCurrentGamePackType:pack];
//    }
//    else {
//        // Flips on all other puzzle transitions
//        [UIView transitionWithView:rootView
//                          duration:0.4
//                           settings:UIViewAnimationOptionTransitionFlipFromLeft
//                        animations:^{
//            [self showHideButtonsAndLabels:PAGE_GAME appCurrentGamePackType:pack];
//                        }
//                        completion:NULL];
//    }
//}


- (void)updateMoreHintPacksButton {
    if ([appd checkForEndlessHintsPurchased]){
        // Endless Hints
        [moreHintPacksButton setAttributedTitle:nil forState:UIControlStateNormal];
        [moreHintPacksButton setTitle:@"Endless Hints" forState:UIControlStateNormal];
        moreHintPacksButton.enabled = NO;
    }
    else {
        // Update moreHintPacksButton to show how many hints are left
        id numberOfHintsRemainingObject = [appd getObjectFromDefaults:@"numberOfHintsRemaining"];
        NSMutableAttributedString *hintTitle1, *hintTitle2;
        NSString *hintTitle = [NSString stringWithFormat:@"More Hint Packs"];
        hintTitle1 = [[NSMutableAttributedString alloc] initWithString:hintTitle];

        if (numberOfHintsRemainingObject == nil){
            hintTitle = [NSString stringWithFormat:@""];
        }
        else {
            appd.numberOfHintsRemaining = [[appd getObjectFromDefaults:@"numberOfHintsRemaining"] intValue];
            if (appd.numberOfHintsRemaining == 0){
                hintTitle = [NSString stringWithFormat:@"\nNo hints left!"];
            }
            else {
                hintTitle = [NSString stringWithFormat:@"\n%d hints left", appd.numberOfHintsRemaining];
            }
        }

        NSRange range1 = NSMakeRange(0, [hintTitle length]);
        hintTitle2 = [[NSMutableAttributedString alloc] initWithString:hintTitle];
        [hintTitle2 addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"PingFang SC Light" size:[self querySmallFontSize]] range:range1];
        moreHintPacksButton.enabled = YES;
        [hintTitle1 appendAttributedString:hintTitle2];
        [moreHintPacksButton setAttributedTitle:hintTitle1 forState:UIControlStateNormal];
    }
}






// Returns an NSString with the name of the current Game Dictionary based on the current setting of appCurrentGamePackType
- (NSString *)gameDictionaryNameFromPuzzlePack {
    NSString *retVal = [[NSString alloc] init];
    switch(appCurrentGamePackType){
        case PACKTYPE_MAIN:{
            retVal = kPuzzlePacksArray;
            break;
        }
        case PACKTYPE_DAILY:{
            retVal = @"dailyPuzzlesPackDictionary.plist";
            break;
        }
        case PACKTYPE_DEMO:{
            retVal = @"demoPuzzlePackDictionary.plist";
            break;
        }
        default:{
            retVal = nil;
        }
    }
    return retVal;
}


- (void)setPuzzleLabel {
    if (appCurrentPageNumber == PAGE_GAME || appCurrentPageNumber == PAGE_HOME) {
        if (appCurrentGamePackType == PACKTYPE_MAIN) {
            todaysDateLabelGame.hidden = YES;
            gamePuzzleLabel.hidden = NO;
            numberOfPointsLabel.hidden = NO;
            unsigned int numberOfPuzzlesLeft = [appd queryNumberOfPuzzlesLeftInCurrentPack];
            if (numberOfPuzzlesLeft > 1){
                gamePuzzleLabel.text = [NSString stringWithFormat:@"%d puzzles left", [appd queryNumberOfPuzzlesLeftInCurrentPack]];
            }
            else if (numberOfPuzzlesLeft == 1) {
                gamePuzzleLabel.text = [NSString stringWithFormat:@"%d puzzle left", [appd queryNumberOfPuzzlesLeftInCurrentPack]];
            }
            else {
                gamePuzzleLabel.text = [NSString stringWithFormat:@"Puzzle Pack Completed!"];
            }
//            numberOfPointsLabel.text = [NSString stringWithFormat:@"Points: %d", [appd countTotalPoints]];
        } else if (appCurrentGamePackType == PACKTYPE_DAILY) {
            todaysDateLabelGame.hidden = NO;
            gamePuzzleLabel.hidden = YES;
            numberOfPointsLabel.hidden = YES;
        } else {
            todaysDateLabelGame.hidden = YES;
            gamePuzzleLabel.hidden = YES;
            numberOfPointsLabel.hidden = YES;
        }
    } else {
        todaysDateLabelGame.hidden = YES;
        gamePuzzleLabel.hidden = YES;
        numberOfPointsLabel.hidden = YES;
    }
}

- (void)announceGameplayPuzzleComplete:(NSString *)puzzleCompleteText {
    prevButton.hidden = NO;
    if (puzzleCompleteText){
        puzzleCompleteMessage.text = puzzleCompleteText;
        backButton.hidden = NO;
    }
    else {
    }
    puzzleCompleteMessage.hidden = NO;
}

- (void)playSound:(SystemSoundID)sound {
    if ([[appd getStringFromDefaults:@"soundsEnabled"] isEqualToString:@"YES"]){
        AudioServicesPlaySystemSound(sound);
    }
}

//
// GameKit Support
//
- (void)showLeaderboard {
    GKGameCenterViewController *gameCenterController = [[GKGameCenterViewController alloc] init];
    gameCenterController.delegate = self;
//    if (leaderboardController != nil)
//    {
//        leaderboardController.leaderboardDelegate = appd;
//        [self presentModalViewController: leaderboardController animated: YES];
//    }
}

- (void)showAchievements {
    GKAchievementViewController *achievements = [[GKAchievementViewController alloc] init];
    if (achievements != nil)
    {
        achievements.achievementDelegate = appd;
        [self presentModalViewController: achievements animated: YES];
    }
}

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController {
    [self refreshHomeView];
}


//
// Setup of physical device display, views, buttons, labels etc.
//

- (void)setupPhysicalDeviceDisplay {
    // Determine the physical screen size as well as the usable region
    contentScaleFactor = self.view.contentScaleFactor;
    safeFrame = self.view.safeAreaLayoutGuide.layoutFrame;
    screenWidthInPixels = safeFrame.size.width*contentScaleFactor;
    screenHeightInPixels = safeFrame.size.height*contentScaleFactor;
    // Calculate and store display aspect ratio
    CGFloat aspectRatio = (float)screenHeightInPixels/(float)screenWidthInPixels;
    if (aspectRatio < 1.4) {
        displayAspectRatio = ASPECT_4_3;
        topPaddingInPoints = appd.window.safeAreaInsets.top + 0.15*screenWidthInPixels/contentScaleFactor;
        bottomPaddingInPoints = appd.window.safeAreaInsets.bottom;
        safeAreaScreenWidthInPixels = safeFrame.size.width*contentScaleFactor;
        safeAreaScreenHeightInPixels = (0.875*safeFrame.size.height-topPaddingInPoints-bottomPaddingInPoints)*contentScaleFactor;
    }
    else if (aspectRatio < 1.48) {
        displayAspectRatio = ASPECT_10_7;
        topPaddingInPoints = appd.window.safeAreaInsets.top + 0.15*screenWidthInPixels/contentScaleFactor;
        bottomPaddingInPoints = appd.window.safeAreaInsets.bottom;
        safeAreaScreenWidthInPixels = safeFrame.size.width*contentScaleFactor;
        safeAreaScreenHeightInPixels = (0.875*safeFrame.size.height-topPaddingInPoints-bottomPaddingInPoints)*contentScaleFactor;
    }
    else if (aspectRatio < 1.6) {
        displayAspectRatio = ASPECT_3_2;
        topPaddingInPoints = appd.window.safeAreaInsets.top + 0.15*screenWidthInPixels/contentScaleFactor;
        bottomPaddingInPoints = appd.window.safeAreaInsets.bottom;
        safeAreaScreenWidthInPixels = safeFrame.size.width*contentScaleFactor;
        safeAreaScreenHeightInPixels = (0.875*safeFrame.size.height-topPaddingInPoints-bottomPaddingInPoints)*contentScaleFactor;
    }
    else if (aspectRatio < 2.0) {
        displayAspectRatio = ASPECT_16_9;
        topPaddingInPoints = appd.window.safeAreaInsets.top;
//        topPaddingInPoints = appd.window.safeAreaInsets.top + 0.2*screenWidthInPixels/contentScaleFactor;
        bottomPaddingInPoints = appd.window.safeAreaInsets.bottom;
        safeAreaScreenWidthInPixels = safeFrame.size.width*contentScaleFactor;
        safeAreaScreenHeightInPixels = (0.875*safeFrame.size.height-topPaddingInPoints-bottomPaddingInPoints)*contentScaleFactor;
    }
    else {
        displayAspectRatio = ASPECT_13_6;
        topPaddingInPoints = appd.window.safeAreaInsets.top;
        bottomPaddingInPoints = appd.window.safeAreaInsets.bottom;
        safeAreaScreenWidthInPixels = safeFrame.size.width*contentScaleFactor;
        safeAreaScreenHeightInPixels = (safeFrame.size.height-topPaddingInPoints-bottomPaddingInPoints)*contentScaleFactor;
    }
}

// Home page animated gradient utilities
    
- (UIColor *)getGradientColorValue:(uint)index {
    switch(index % 6){
        case 0:
            return [UIColor cyanColor];
            break;
        case 1:
            return [UIColor magentaColor];
            break;
        case 2:
            return [UIColor whiteColor];
            break;
        case 3:
            return [UIColor orangeColor];
            break;
        case 4:
            return [UIColor greenColor];
            break;
        case 5:
        default:
            return [UIColor purpleColor];
            break;
    }
}



- (void)animationDidStop:(CAAnimation *)anim
                finished:(BOOL)flag {
    DLog("BMDViewController.animationDidStop");
    [homeViewColorGradient removeFromSuperlayer];
    if (gradientAnimationIndex++ > 239){
        gradientAnimationIndex = 0;
    }
    CGPoint startPoint, endPoint;
    // With gradient
//    startPoint = CGPointMake(-0.4, -0.4);
//    endPoint = CGPointMake(0.8, 0.8);
//    [self animateColors:[UIColor blackColor] endColor1:[self getGradientColorValue:gradientAnimationIndex] startColor2:[UIColor blackColor] endColor2:[self getGradientColorValue:gradientAnimationIndex+1]
//              startPoint:startPoint endPoint:endPoint view:rootView];
    // Without gradient
    startPoint = CGPointMake(0, 0);
    endPoint = CGPointMake(1.0, 1.0);
    [self animateColors:[self getGradientColorValue:gradientAnimationIndex] endColor1:[self getGradientColorValue:gradientAnimationIndex] startColor2:[self getGradientColorValue:gradientAnimationIndex+1] endColor2:[self getGradientColorValue:gradientAnimationIndex+1] startPoint:CGPointMake(0, 0) endPoint:CGPointMake(1.0, 1.0) view:rootView];
}

- (void)animationDidStart:(CAAnimation *)anim {
    DLog("BMDViewController.animationDidStart");
}

-(void)pauseLayer:(CALayer*)layer
{
    CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
    layer.speed = 0.0;
    layer.timeOffset = pausedTime;
}

-(void)resumeLayer:(CALayer*)layer
{
    CFTimeInterval pausedTime = [layer timeOffset];
    layer.speed = 1.0;
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime = timeSincePause;
}

- (void)animateColors:(UIColor *)startColor1 endColor1:(UIColor *)endColor1 startColor2:(UIColor *)startColor2 endColor2:(UIColor *)endColor2 startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint view:(UIView *)view {
    // Create color gradient
    homeViewColorGradient = [CAGradientLayer layer];
    homeViewColorGradient.frame = view.bounds;
    homeViewColorGradient.startPoint = startPoint;
    homeViewColorGradient.endPoint = endPoint;
    homeViewColorGradient.colors = @[(id)startColor1.CGColor, (id)endColor1.CGColor];
    
    // Animate color gradient
    CABasicAnimation *gradient1Animation = [CABasicAnimation animationWithKeyPath:@"colors"];
    gradient1Animation.fromValue = @[(id)startColor1.CGColor, (id)endColor1.CGColor];
    gradient1Animation.toValue = @[(id)startColor2.CGColor, (id)endColor2.CGColor];
    gradient1Animation.duration = 7;
    gradient1Animation.delegate = self;
    gradient1Animation.fillMode = kCAFillModeForwards;
    [gradient1Animation setRemovedOnCompletion:NO];
    [homeViewColorGradient addAnimation:gradient1Animation forKey:@"colors"];
    [view.layer insertSublayer:homeViewColorGradient atIndex:0];
}

- (unsigned int)querySmallFontSize {
    unsigned int packSmallFontSize;
    switch (displayAspectRatio) {
        case ASPECT_4_3:{
            // iPad (9th generation)
            packSmallFontSize = 20;
           break;
        }
        case ASPECT_10_7:{
            // iPad Air (5th generation)
            packSmallFontSize = 22;
           break;
        }
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            packSmallFontSize = 20;
           break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            packSmallFontSize = 14;
            break;
        }
        case ASPECT_13_6: {
            // iPhone 14
            packSmallFontSize = 14;
            break;
        }
    }
    return packSmallFontSize;
}

- (void)startPuzzleEditor {
    // Activate BMDPuzzleViewController
    if (ENABLE_PUZZLE_EDITOR){
        appCurrentGamePackType = PACKTYPE_EDITOR;
        // Force PE into editMode rather than playMode
        [appd setObjectInDefaults:@"YES" forKey:@"editModeEnabled"];
        [editPlayButton setTitle:[NSString stringWithFormat:@"Edit Mode"] forState:UIControlStateNormal];
    }
    puzzleViewController = [[BMDPuzzleViewController alloc] init];
    [self addChildViewController:puzzleViewController];
    
    [self.view addSubview:puzzleViewController.view];
    [puzzleViewController didMoveToParentViewController:self];
}

- (void)startDemoPuzzle {
    //
    // Explicitly block running PACKTYPE_DEMO when the PE is enabled
    //
    // View controller approach
    DLog("BMDViewController.startDemoPuzzle");
    self.homeView.hidden = YES;
    [appd playSound:appd.tapPlayer];
    self.appCurrentGamePackType = PACKTYPE_DEMO;
    puzzleViewController = [[BMDPuzzleViewController alloc] init];
    [self addChildViewController:puzzleViewController];
    [self.view addSubview:puzzleViewController.view];
    [puzzleViewController didMoveToParentViewController:self];
}

- (void)buildVungleAdView {
    //
    // Add UIView for Vungle Ad Banner to PAGE_HOME
    //
    CGFloat adWidth, adHeight, adX, adY;
    CGRect adBannerFrame;
    switch (displayAspectRatio) {
        case ASPECT_4_3:{
            // iPad (9th generation)
            adWidth = 728;
            adHeight = 90;
            break;
        }
        case ASPECT_10_7:{
            // iPad Air (5th generation)
            adWidth = 728;
            adHeight = 90;
            break;
        }
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            adWidth = 728;
            adHeight = 90;
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            adWidth = 320;
            adHeight = 50;
            break;
        }
        case ASPECT_13_6: {
            // iPhone 14
            adWidth = 320;
            adHeight = 50;
            break;
        }
    }
    if (bannerAdView == nil){
        adX = (screenWidthInPixels/contentScaleFactor-adWidth)/2.0;
        adY = screenHeightInPixels/contentScaleFactor - bottomPaddingInPoints - 1.3*adHeight;
        adBannerFrame = CGRectMake(adX, adY, adWidth, adHeight);
        bannerAdView = [[UIView alloc]initWithFrame:adBannerFrame];
//        bannerAdView.backgroundColor = [UIColor grayColor];
        DLog("buildVungleAdView: (%d, %d, %d, %d)", (int)adX, (int)adY, (int)adWidth, (int)adHeight);

        [rootView addSubview:bannerAdView];
        [rootView bringSubviewToFront:bannerAdView];
    }
    else {
        DLog("Vungle error: existing bannerAdView");
    }
}

- (void)vunglePlayRewardedAd {
    VungleSDK* sdk = [VungleSDK sharedSDK];
    NSError *error;
    if (![sdk playAd:self options:nil placementID:vunglePlacementRewardedHint error:&error]) {
        if (error) {
            DLog("Error encountered playing ad: %@", error);
        }
    }
}

- (void)setupViewsButtonsLabels {
    //
    // Set up rootView
    //  rootView holds the main window view
    //
    rootView = self.view;
    rootView.opaque = YES;
    rootView.alpha = 1.0;
    rootView.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.14 alpha:1.0];


    
    //
    // Set up PAGE_HOME with homeView
    // homeView holds the home page view
    //
    CGRect homeBounds = rootView.bounds;
//    homeView = [[UIView alloc] initWithFrame:homeBounds];
    homeView = [[MTKView alloc] initWithFrame:homeBounds device:MTLCreateSystemDefaultDevice()];
    
//    homeView.enableSetNeedsDisplay = NO;
//    homeView.preferredFramesPerSecond = 30;
//    homeView.presentsWithTransaction = NO;
//    homeView.device = MTLCreateSystemDefaultDevice();
//    NSAssert(homeView.device, @"Metal is not supported on this device");
//    renderer = [[BMDRenderer alloc] initWithMetalKitView:homeView];
//    NSAssert(renderer, @"Renderer failed initialization");
//    // Initialize the renderer with the view size
//    [renderer mtkView:homeView drawableSizeWillChange:homeView.drawableSize];
//    homeView.delegate = renderer;

    // homeView background
//    homeView.backgroundColor = [UIColor blackColor];
//    homeView.alpha = 1.0;
//    homeView.opaque = YES;
    
    // Get the logo image size
    UIImage *logoImage = [UIImage imageNamed:@"Beamed2Logo.png"];
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:logoImage];
    CGSize logoSize = logoImage.size;
    CGFloat logoWidth = screenWidthInPixels/contentScaleFactor;
    CGFloat logoHeight = logoWidth*logoSize.height/logoSize.width;
    CGFloat logoCx, logoCy;
    switch (displayAspectRatio) {
        case ASPECT_4_3:{
            // iPad (9th generation)
            logoHeight = 0.8*logoHeight;
            logoWidth = 0.8*logoWidth;
            logoCx = 0.5*screenWidthInPixels/contentScaleFactor - 0.5*logoWidth;
            logoCy = 0.15*screenHeightInPixels/contentScaleFactor - 0.58*logoHeight;
            break;
        }
        case ASPECT_10_7: {
            // iPad Air (5th generation)
            logoCx = 0.5*screenWidthInPixels/contentScaleFactor - 0.5*logoWidth;
            logoCy = 0.15*screenHeightInPixels/contentScaleFactor - 0.58*logoHeight;
            break;
        }
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            logoCx = 0.5*screenWidthInPixels/contentScaleFactor - 0.5*logoWidth;
            logoCy = 0.17*screenHeightInPixels/contentScaleFactor - 0.58*logoHeight;
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            logoHeight = 1.2*logoHeight;
            logoWidth = 1.2*logoWidth;
            logoCx = 0.5*screenWidthInPixels/contentScaleFactor - 0.5*logoWidth;
            logoCy = 0.14*screenHeightInPixels/contentScaleFactor - 0.45*logoHeight;
            break;
        }
        case ASPECT_13_6:
        default:{
            // iPhone 14
            logoHeight = 1.2*logoHeight;
            logoWidth = 1.2*logoWidth;
            logoCx = 0.5*screenWidthInPixels/contentScaleFactor - 0.5*logoWidth;
            logoCy = 0.17*screenHeightInPixels/contentScaleFactor - 0.5*logoHeight;
            break;
        }
    }
    logoImageView.frame = CGRectMake(logoCx, logoCy, logoWidth, logoHeight);
    [homeView addSubview: logoImageView];
    [homeView bringSubviewToFront:logoImageView];
    
    
    //
    // Add Game Center Access Point
    //
    gamekitAccessPoint = [GKAccessPoint shared];
    gamekitAccessPoint.location = GKAccessPointLocationTopTrailing;
    gamekitAccessPoint.parentWindow = homeView.window;
    gamekitAccessPoint.active = YES;
    gamekitAccessPoint.showHighlights = YES;

    appCurrentGamePackType = PACKTYPE_MAIN;
    //
    // Add "Daily Puzzle" button to homeView
    //
    dailyPuzzleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat buttonWidth, buttonHeight;
    CGFloat buttonCx = screenWidthInPixels/contentScaleFactor/2.0;
    CGFloat buttonCy, dateLabelCy;
    CGFloat todaysDateLabelFontSizeHome;
    CGFloat objectCy;
    switch (displayAspectRatio) {
        case ASPECT_4_3:{
            // iPad (9th generation)
            [dailyPuzzleButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:28]];
            todaysDateLabelFontSizeHome = 16;
            buttonWidth = 0.6*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/8.0;
            buttonCy = logoCy + logoHeight + 1.0*buttonHeight;
            dateLabelCy = buttonCy - 1.0*buttonWidth/8.0;
            break;
        }
        case ASPECT_10_7:{
            // iPad Air (5th generation)
            [dailyPuzzleButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:28]];
            todaysDateLabelFontSizeHome = 16;
            buttonWidth = 0.6*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/8.0;
            buttonCy = logoCy + logoHeight + 1.0*buttonHeight;
            dateLabelCy = buttonCy - 1.0*buttonWidth/8.0;
            break;
        }
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            [dailyPuzzleButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:28]];
            todaysDateLabelFontSizeHome = 16;
            buttonWidth = 0.6*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/8.0;
            buttonCy = logoCy + logoHeight + 1.0*buttonHeight;
            dateLabelCy = buttonCy - 1.0*buttonWidth/8.0;
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            [dailyPuzzleButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:16]];
            todaysDateLabelFontSizeHome = 14;
            buttonWidth = 0.8*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/8.0;
            buttonCy = logoCy + logoHeight + 1.0*buttonHeight;
            dateLabelCy = logoCy + logoHeight - 1.1*buttonWidth/8.0;
            break;
        }
        case ASPECT_13_6:
        default:{
            // iPhone 14
            [dailyPuzzleButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:16]];
            todaysDateLabelFontSizeHome = 14;
            buttonWidth = 0.8*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/6.0;
            buttonCy = logoCy + logoHeight + 1.0*buttonHeight;
            dateLabelCy = buttonCy - 0.9*buttonWidth/8.0;
            break;
        }
    }
    UIImage *btnImage = [UIImage imageNamed:@"yellowRectangle.png"];
    UIImage *btnSelectedImage = [UIImage imageNamed:@"yellowRectangleSelected.png"];
    [dailyPuzzleButton setBackgroundImage:btnImage forState:UIControlStateNormal];
    [dailyPuzzleButton setBackgroundImage:btnSelectedImage forState:UIControlStateHighlighted];
    CGRect buttonRect = CGRectMake(buttonCx-buttonWidth/2.0,
                                   buttonCy,
                                   buttonWidth,
                                   buttonHeight);
    dailyPuzzleButton.frame = buttonRect;
    [dailyPuzzleButton addTarget:self action:@selector(dailyPuzzleButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    dailyPuzzleButton.showsTouchWhenHighlighted = YES;
    [dailyPuzzleButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [homeView addSubview:dailyPuzzleButton];
    [homeView bringSubviewToFront:dailyPuzzleButton];
    
    // Create a checkmark at the right hand side
    dailyPuzzleButtonCheckmark = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat checkmarkHeight = 0.75*buttonHeight;
    CGRect checkRect = CGRectMake(buttonCx+buttonWidth/2.0-0.45*checkmarkHeight,
                                  buttonCy+buttonHeight/2.0-1.1*checkmarkHeight,
                                  checkmarkHeight,
                                  checkmarkHeight);
//    CGRect checkRect = CGRectMake(buttonCx+buttonWidth/2.0-1.1*checkmarkHeight,
//                                  buttonCy+buttonHeight/2.0-checkmarkHeight/2.0,
//                                  checkmarkHeight,
//                                  checkmarkHeight);
    dailyPuzzleButtonCheckmark.frame = checkRect;
    dailyPuzzleButtonCheckmark.enabled = YES;
    dailyPuzzleButtonCheckmark.hidden = YES;
    UIImage *checkImage = [UIImage imageNamed:@"CheckmarkInCircle.png"];
    [dailyPuzzleButtonCheckmark setBackgroundImage:checkImage forState:UIControlStateNormal];
    [homeView addSubview:dailyPuzzleButtonCheckmark];
    [homeView bringSubviewToFront:dailyPuzzleButtonCheckmark];


    // todaysDateLabelHome
    CGFloat w = buttonWidth;  CGFloat h = w/8;
    CGRect todaysDateLabelFrame = CGRectMake(buttonCx-buttonWidth/2.0, dateLabelCy, w, h);
    todaysDateLabelHome = [[UILabel alloc]initWithFrame:todaysDateLabelFrame];
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateStyle:NSDateFormatterFullStyle];
    NSString *dateString = [formatter stringFromDate:date];
    todaysDateLabelHome.text = dateString;
    todaysDateLabelHome.textColor = [UIColor whiteColor];
    [todaysDateLabelHome setFont:[UIFont fontWithName:@"PingFang SC Light" size:todaysDateLabelFontSizeHome]];
    todaysDateLabelHome.hidden = NO;
//    [homeView addSubview:todaysDateLabelHome];
//    [homeView bringSubviewToFront:todaysDateLabelHome];
    
    //
    // Add startPuzzleButton to homeView
    //
    startPuzzleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    switch (displayAspectRatio) {
        case ASPECT_4_3:{
            // iPad (9th generation)
            buttonWidth = 0.6*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/4.0;
            buttonCy = buttonCy + 0.6*buttonHeight;
            [startPuzzleButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:28]];
            break;
        }
        case ASPECT_10_7:{
            // iPad Air (5th generation)
            buttonWidth = 0.6*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/4.0;
            buttonCy = buttonCy + 0.6*buttonHeight;
            [startPuzzleButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:28]];
            break;
        }
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            buttonWidth = 0.6*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/3.6;
            buttonCy = buttonCy + 0.6*buttonHeight;
            [startPuzzleButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:28]];
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            buttonWidth = 0.8*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/4.5;
            buttonCy = buttonCy + 0.75*buttonHeight;
            [startPuzzleButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:16]];
            break;
        }
        case ASPECT_13_6: {
            // iPhone 14
            buttonWidth = 0.80*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/4.0;
            buttonCy = buttonCy + 0.88*buttonHeight;
            [startPuzzleButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:16]];
            break;
        }
    }
    [startPuzzleButton setBackgroundImage:btnImage forState:UIControlStateNormal];
    [startPuzzleButton setBackgroundImage:btnSelectedImage forState:UIControlStateHighlighted];
    buttonRect = CGRectMake(buttonCx-buttonWidth/2.0,
                            buttonCy,
                            buttonWidth,
                            buttonHeight);
    startPuzzleButton.frame = buttonRect;
    startPuzzleButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    startPuzzleButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    // Set startPuzzleButton title based upon currentPackIndex
//    NSMutableArray *array = [appd.gameDictionaries objectForKey:kPuzzlePacksArray];
//    long packCost;
//    NSMutableDictionary *packDictionary;
//    if ([array count] > appd.currentPack){
//        packDictionary = [array objectAtIndex:appd.currentPack];
//        packCost = [[packDictionary objectForKey:@"AppStorePackCost"] integerValue];
//    }
//    else {
//        packCost = 0;
//    }
//    if (packCost == 0){
//        startPuzzleButton.layer.borderColor = [UIColor whiteColor].CGColor;
//    }
//    else {
//        startPuzzleButton.layer.borderColor = [UIColor whiteColor].CGColor;
//    }
    
    [startPuzzleButton addTarget:self action:@selector(startPuzzleButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [startPuzzleButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    startPuzzleButton.showsTouchWhenHighlighted = YES;
    [homeView addSubview:startPuzzleButton];
    [homeView bringSubviewToFront:startPuzzleButton];
    
    // Create a checkmark at the right hand side
    startPuzzleButtonCheckmark = [UIButton buttonWithType:UIButtonTypeCustom];
    checkRect = CGRectMake(dailyPuzzleButtonCheckmark.frame.origin.x,
                           buttonRect.origin.y+buttonRect.size.height/4.0,
                           dailyPuzzleButtonCheckmark.frame.size.width,
                           dailyPuzzleButtonCheckmark.frame.size.width);
    startPuzzleButtonCheckmark.frame = checkRect;
    startPuzzleButtonCheckmark.enabled = YES;
    startPuzzleButtonCheckmark.hidden = YES;
    [startPuzzleButtonCheckmark setBackgroundImage:checkImage forState:UIControlStateNormal];
    [homeView addSubview:startPuzzleButtonCheckmark];
    [homeView bringSubviewToFront:startPuzzleButtonCheckmark];

    
    //
    // Add "More Puzzle Packs" button to homeView
    //
    UIButton *morePuzzlePacksButton = [UIButton buttonWithType:UIButtonTypeCustom];
    switch (displayAspectRatio) {
        case ASPECT_4_3:{
            // iPad (9th generation)
            buttonWidth = 0.6*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/8.0;
            buttonCy = buttonCy + 2.25*buttonHeight;
            [morePuzzlePacksButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:28]];
            break;
        }
        case ASPECT_10_7:{
            // iPad Air (5th generation)
            buttonWidth = 0.6*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/8.0;
            buttonCy = buttonCy + 2.25*buttonHeight;
            [morePuzzlePacksButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:28]];
            break;
        }
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            buttonWidth = 0.6*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/8.0;
            buttonCy = buttonCy + 2.25*buttonHeight;
            [morePuzzlePacksButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:28]];
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            buttonWidth = 0.8*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/10.0;
            buttonCy = buttonCy + 2.75*buttonHeight;
            [morePuzzlePacksButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:16]];
            break;
        }
        case ASPECT_13_6: {
            // iPhone 14
            buttonWidth = 0.80*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/8.0;
            buttonCy = buttonCy + 2.50*buttonHeight;
            [morePuzzlePacksButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:16]];
            break;
        }
    }
    [morePuzzlePacksButton setBackgroundImage:btnImage forState:UIControlStateNormal];
    [morePuzzlePacksButton setBackgroundImage:btnSelectedImage forState:UIControlStateHighlighted];
    buttonRect = CGRectMake(buttonCx-buttonWidth/2.0,
                            buttonCy,
                            buttonWidth,
                            buttonHeight);
    morePuzzlePacksButton.frame = buttonRect;
    [morePuzzlePacksButton setTitle:@"More Puzzle Packs" forState:UIControlStateNormal];
    [morePuzzlePacksButton addTarget:self action:@selector(morePuzzlePacksButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [morePuzzlePacksButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    morePuzzlePacksButton.showsTouchWhenHighlighted = YES;
    [homeView addSubview:morePuzzlePacksButton];
    [homeView bringSubviewToFront:morePuzzlePacksButton];
    
    //
    // Add "More Hint Packs" button to homeView
    //
    moreHintPacksButton = [UIButton buttonWithType:UIButtonTypeCustom];
    switch (displayAspectRatio) {
        case ASPECT_4_3:{
            // iPad (9th generation)
            buttonWidth = 0.6*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/6.0;
            buttonCy = buttonCy + 1.0*buttonHeight;
            [moreHintPacksButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:28]];
            break;
        }
        case ASPECT_10_7:{
            // iPad Air (5th generation)
            buttonWidth = 0.6*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/6.0;
            buttonCy = buttonCy + 1.0*buttonHeight;
            [moreHintPacksButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:28]];
            break;
        }
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            buttonWidth = 0.6*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/6.0;
            buttonCy = buttonCy + 1.0*buttonHeight;
            [moreHintPacksButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:28]];
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            buttonWidth = 0.8*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/6.0;
            buttonCy = buttonCy + 0.9*buttonHeight;
            [moreHintPacksButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:16]];
            break;
        }
        case ASPECT_13_6: {
            // iPhone 14
            buttonWidth = 0.8*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/6.0;
            buttonCy = buttonCy + 1.1*buttonHeight;
            [moreHintPacksButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:16]];
            break;
        }
    }
    [moreHintPacksButton setBackgroundImage:btnImage forState:UIControlStateNormal];
    [moreHintPacksButton setBackgroundImage:btnSelectedImage forState:UIControlStateHighlighted];
    buttonRect = CGRectMake(buttonCx-buttonWidth/2.0,
                            buttonCy,
                            buttonWidth,
                            buttonHeight);
    moreHintPacksButton.frame = buttonRect;
    moreHintPacksButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    moreHintPacksButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [moreHintPacksButton addTarget:self action:@selector(moreHintPacksButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [moreHintPacksButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    moreHintPacksButton.showsTouchWhenHighlighted = YES;
    [self updateMoreHintPacksButton];
    [homeView addSubview:moreHintPacksButton];
    [homeView bringSubviewToFront:moreHintPacksButton];
        
    //
    // Add "Scores" button to homeView
    //
    UIButton *scoresButton = [UIButton buttonWithType:UIButtonTypeCustom];
    int scoresButtonFontSize;
    switch (displayAspectRatio) {
        case ASPECT_4_3:{
            // iPad (9th generation)
            buttonWidth = 0.6*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/10.0;
            buttonCy = buttonCy + 2.0*buttonHeight;
            scoresButtonFontSize = 28;
            [scoresButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:scoresButtonFontSize]];
            break;
        }
        case ASPECT_10_7:{
            // iPad Air (5th generation)
            buttonWidth = 0.6*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/10.0;
            buttonCy = buttonCy + 2.0*buttonHeight;
            scoresButtonFontSize = 28;
            [scoresButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:scoresButtonFontSize]];
            break;
        }
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            buttonWidth = 0.6*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/10.0;
            buttonCy = buttonCy + 2.0*buttonHeight;
            scoresButtonFontSize = 28;
            [scoresButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:scoresButtonFontSize]];
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            buttonWidth = 0.8*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/10.0;
            buttonCy = buttonCy + 2.25*buttonHeight;
            scoresButtonFontSize = 16;
            [scoresButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:scoresButtonFontSize]];
            break;
        }
        case ASPECT_13_6: {
            // iPhone 14
            buttonWidth = 0.8*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth/8.0;
            buttonCy = buttonCy + 1.85*buttonHeight;
            scoresButtonFontSize = 16;
            [scoresButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:scoresButtonFontSize]];
            break;
        }
    }
    [scoresButton setBackgroundImage:btnImage forState:UIControlStateNormal];
    [scoresButton setBackgroundImage:btnSelectedImage forState:UIControlStateHighlighted];
    buttonRect = CGRectMake(buttonCx-buttonWidth/2.0,
                            buttonCy,
                            buttonWidth,
                            buttonHeight);
    scoresButton.frame = buttonRect;
    [scoresButton setTitle:@"Scores" forState:UIControlStateNormal];
    [scoresButton addTarget:self action:@selector(scoresButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [scoresButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    scoresButton.showsTouchWhenHighlighted = YES;
    scoresButton.alpha = 1.0;
    [homeView addSubview:scoresButton];
    [homeView bringSubviewToFront:scoresButton];
    
    //
    // Add "Settings Gear" button to homeView
    //
    UIButton *settingsGearButton = [UIButton buttonWithType:UIButtonTypeCustom];
    switch (displayAspectRatio) {
        case ASPECT_4_3:{
            // iPad (9th generation)
            buttonWidth = 0.1*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth;
            buttonCy = buttonCy + 1.2*buttonHeight;
            break;
        }
        case ASPECT_10_7:{
            // iPad Air (5th generation)
            buttonWidth = 0.1*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth;
            buttonCy = buttonCy + 1.5*buttonHeight;
            break;
        }
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            buttonWidth = 0.1*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth;
            buttonCy = buttonCy + 1.5*buttonHeight;
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            buttonWidth = 0.125*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth;
            buttonCy = buttonCy + 1.15*buttonHeight;
            break;
        }
        case ASPECT_13_6: {
            // iPhone 14
            buttonWidth = 0.125*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth;
            buttonCy = buttonCy + 1.25*buttonHeight;
            break;
        }
    }
    UIImage *settingsGearImage = [UIImage imageNamed:@"settingsGear.png"];
    [settingsGearButton setBackgroundImage:settingsGearImage forState:UIControlStateNormal];
    buttonRect = CGRectMake(buttonCx-3.0*buttonWidth,
                            buttonCy,
                            buttonWidth,
                            buttonHeight);
    settingsGearButton.frame = buttonRect;
    [settingsGearButton addTarget:self action:@selector(settingsButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    settingsGearButton.showsTouchWhenHighlighted = YES;
    settingsGearButton.alpha = 1.0;
    [homeView addSubview:settingsGearButton];
    [homeView bringSubviewToFront:settingsGearButton];
    
    //
    // Add "No Ads" button to homeView
    //
    noAdsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    switch (displayAspectRatio) {
        case ASPECT_4_3:{
            // iPad (9th generation)
            buttonWidth = 0.1*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth;
            break;
        }
        case ASPECT_10_7:{
            // iPad Air (5th generation)
            break;
        }
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            break;
        }
        case ASPECT_13_6: {
            // iPhone 14
            break;
        }
    }
    UIImage *noAdsImage = [UIImage imageNamed:@"NoAds.png"];
    [noAdsButton setBackgroundImage:noAdsImage forState:UIControlStateNormal];
    buttonRect = CGRectMake(buttonCx-buttonWidth/2.0,
                            buttonCy,
                            buttonWidth,
                            buttonHeight);
    noAdsButton.frame = buttonRect;
    [noAdsButton addTarget:self action:@selector(noAdsButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    noAdsButton.showsTouchWhenHighlighted = YES;
    noAdsButton.alpha = 1.0;
    [homeView addSubview:noAdsButton];
    [homeView bringSubviewToFront:noAdsButton];

    CGRect removeAdsLabelFrame = CGRectMake(buttonCx-3.0*buttonWidth/2.0,
                                           buttonCy+0.75*buttonHeight,
                                           3.0*buttonWidth,
                                           buttonHeight);
    removeAdsLabel = [[UILabel alloc] initWithFrame:removeAdsLabelFrame];
    removeAdsLabel.text = [NSString stringWithFormat:@"Remove Ads"];
    [removeAdsLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:scoresButtonFontSize]];
    removeAdsLabel.textColor = [UIColor colorWithRed:251.0/255.0
                                               green:212.0/255.0
                                                blue:12.0/255.0
                                               alpha:1.0];
    removeAdsLabel.layer.borderColor = [UIColor clearColor].CGColor;
    removeAdsLabel.layer.borderWidth = 1.0;
    [removeAdsLabel setTextAlignment:NSTextAlignmentCenter];
    [homeView addSubview:removeAdsLabel];
    [homeView bringSubviewToFront:removeAdsLabel];
    
    NSString *adFreeStatus = [appd getObjectFromDefaults:@"AD_FREE_PUZZLES"];
    if ([adFreeStatus isEqualToString:@"YES"]){
        noAdsButton.hidden = YES;
        removeAdsLabel.hidden = YES;
    }
    else {
        noAdsButton.hidden = NO;
        removeAdsLabel.hidden = NO;
    }


    
    //
    // Add "Shopping Cart" button to homeView
    //
    UIButton *shoppingCartButton = [UIButton buttonWithType:UIButtonTypeCustom];
    switch (displayAspectRatio) {
        case ASPECT_4_3:{
            // iPad (9th generation)
            buttonWidth = 0.1*screenWidthInPixels/contentScaleFactor;
            buttonHeight = buttonWidth;
            break;
        }
        case ASPECT_10_7:{
            // iPad Air (5th generation)
            break;
        }
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            break;
        }
        case ASPECT_13_6: {
            // iPhone 14
            break;
        }
    }
    UIImage *shoppingCartImage = [UIImage imageNamed:@"shoppingCart.png"];
    [shoppingCartButton setBackgroundImage:shoppingCartImage forState:UIControlStateNormal];
    buttonRect = CGRectMake(buttonCx-buttonWidth/2.0+2.5*buttonWidth,
                            buttonCy,
                            buttonWidth,
                            buttonHeight);
    shoppingCartButton.frame = buttonRect;
    [shoppingCartButton addTarget:self action:@selector(morePuzzlePacksButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    shoppingCartButton.showsTouchWhenHighlighted = YES;
    shoppingCartButton.alpha = 1.0;
    [homeView addSubview:shoppingCartButton];
    [homeView bringSubviewToFront:shoppingCartButton];
    
    // Add homeView to rootView
    [rootView addSubview:homeView];
    [rootView bringSubviewToFront:homeView];

    //
    // Create an instance of the hintsViewController
    //
//    hintsViewController = [[BMDHintsViewController alloc] init];

}

//
// Button Handler Methods Go Here
//

- (void)startPuzzleButtonPressed {
    // View controller approach
    DLog("BMDViewController.startPuzzleButtonPressed");
    self.homeView.hidden = YES;
    [appd playSound:appd.tapPlayer];
    
    unsigned int unsolvedPuzzleCount = [appd queryNumberOfPuzzlesLeftInCurrentPack];
    if (unsolvedPuzzleCount == 0){
        [self morePuzzlePacksButtonPressed];
    }
    else {
        DLog("startPuzzleButtonPressed, starting puzzle %d", [appd fetchCurrentPuzzleNumber]);
        [appd playSound:appd.tapPlayer];
        if ([appd fetchCurrentPuzzleNumber] == [appd fetchCurrentPackLength]+1){
            [appd.loop2Player pause];
            [self morePuzzlePacksButtonPressed];
        }
        else {
            appCurrentGamePackType = PACKTYPE_MAIN;
            puzzleViewController = [[BMDPuzzleViewController alloc] init];
            [self addChildViewController:puzzleViewController];
            [self.view addSubview:puzzleViewController.view];
            [puzzleViewController didMoveToParentViewController:self];
        }
    }
}

- (void)dailyPuzzleButtonPressed {
    // View controller approach
    DLog("BMDViewController.dailyPuzzleButtonPressed");
    [appd playSound:appd.tapPlayer];
    self.homeView.hidden = YES;
    NSNumber *dailyPuzzleCompletionDay = [appd getObjectFromDefaults:@"dailyPuzzleCompletionDay"];
    NSNumber *todayLocal = [NSNumber numberWithUnsignedInt:[appd getLocalDaysSinceReferenceDate]];
    
    if (ENABLE_PUZZLE_EDITOR == YES){
        [self startPuzzleEditor];
    }
    else if (dailyPuzzleCompletionDay == nil || dailyPuzzleCompletionDay != todayLocal){
        
#ifdef ENABLE_GA
        [FIRAnalytics logEventWithName:@"dailyPuzzleButtonPressed"
                            parameters:@{
                                         @"puzzleNumber":[NSString stringWithFormat:@"%d", [appd fetchDailyPuzzleNumber]]
                                         }];
#endif

        [appd playSound:appd.tapPlayer];
        appCurrentGamePackType = PACKTYPE_DAILY;
        // If Edit Mode is enabled then trigger the Puzzle Editor to either Edit or Play puzzles being edited
        // ...else trigger the Daily Puzzle
        NSTimeInterval localDaysSinceReferenceDate = [appd getLocalDaysSinceReferenceDate];
        appd.currentDailyPuzzleNumber = (unsigned int)localDaysSinceReferenceDate % ([appd fetchCurrentPackLength]);
        DLog("Pressed Daily Puzzle Button, starting puzzle %d", appd.currentDailyPuzzleNumber);
        
        puzzleViewController = [[BMDPuzzleViewController alloc] init];
        [self addChildViewController:puzzleViewController];
        [self.view addSubview:puzzleViewController.view];
        [puzzleViewController didMoveToParentViewController:self];
    }
    else {
        DLog("Daily Puzzle Already Completed - do not start");
        [self refreshHomeView];
        [self loadAppropriateSizeBannerAd];
//        [self startMainScreenMusicLoop];
    }
}

- (void)morePuzzlePacksButtonPressed {
    DLog("BMDViewController.morePuzzlePacksButtonPressed");
    // View controller approach
    [appd playSound:appd.tapPlayer];
    packsViewController = [[BMDPacksViewController alloc] init];
    [self addChildViewController:packsViewController];
    [self.view addSubview:packsViewController.view];
    [packsViewController didMoveToParentViewController:self];
}

- (void)moreHintPacksButtonPressed {
    DLog("BMDViewController.moreHintPacksButtonPressed");
    // View controller approach
    [appd playSound:appd.tapPlayer];
    hintsViewController = [[BMDHintsViewController alloc] init];
    [self addChildViewController:hintsViewController];
    [self.view addSubview:hintsViewController.view];
    [hintsViewController didMoveToParentViewController:self];
}

- (void)settingsButtonPressed {
    DLog("BMDViewController.settingsButtonPressed");
    // View controller approach
    [appd playSound:appd.tapPlayer];
    settingsViewController = [[BMDSettingsViewController alloc] init];
    [self addChildViewController:settingsViewController];
    [self.view addSubview:settingsViewController.view];
    [settingsViewController didMoveToParentViewController:self];
}

// Uncomment when you want to use the settingsButton to test something such as:
// - Crash handling
// - Prompting for App Store review
//- (void)settingsButtonPressed {
//    [SKStoreReviewController requestReviewInScene:nil];
//    // The following line was used to test Crashlytics
//    //    @[][1];
//}

- (void)noAdsButtonPressed {
    DLog("BMDViewController.noAdsButtonPressed");
    // View controller approach
    [appd playSound:appd.tapPlayer];
    [appd purchaseAdFreePuzzles];
}

- (void)backButtonPressed{
    scoresView.hidden = YES;
    [scoresView removeFromSuperview];
    [self refreshHomeView];
}

@end
