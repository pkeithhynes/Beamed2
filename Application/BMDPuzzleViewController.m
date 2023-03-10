//
//  BMDPuzzleViewController.m
//  Beamed
//
//  Created by Patrick Keith-Hynes on 8/15/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#import "BMDPuzzleViewController.h"
#import "BMDHintsViewController.h"
#import "BMDAppDelegate.h"
#import "Firebase.h"

@import UIKit;


@interface BMDPuzzleViewController ()

@end

@implementation BMDPuzzleViewController{
//    BMDRenderer *renderer;
    BMDViewController *rc;
    BMDAppDelegate *appd;
}

@synthesize hintsViewController;
@synthesize demoMessageButtonsAndLabels;

@synthesize puzzleView;
@synthesize puzzlePageBlurView;
@synthesize puzzleSolvedView;

@synthesize editPlayButton;
@synthesize autoManualButton;
@synthesize deleteButton;
@synthesize saveButton;
@synthesize duplicateButton;
@synthesize clearButton;

@synthesize wholeScreenButton;
@synthesize wholeScreenFilter;
@synthesize settingsGearButton;
@synthesize puzzlePacksButton;
@synthesize helpButton;
@synthesize hintButton;
@synthesize hintBulb;
@synthesize nextButton;
@synthesize prevButton;
@synthesize backButton;
@synthesize verifyButton;
@synthesize homeArrow;
@synthesize nextArrow;
@synthesize homeArrowWhite;
@synthesize prevArrowWhite;
@synthesize replayIconWhite;

@synthesize prevButtonRectEdit;
@synthesize prevButtonRectPlay;
@synthesize backButtonRectEdit;
@synthesize backButtonRectPlay;
@synthesize nextButtonRectEdit;
@synthesize nextButtonRectPlay;

@synthesize helpImageView;
@synthesize helpLabel;
@synthesize puzzleTitleLabel;
@synthesize numberOfPuzzlesLabel;
@synthesize puzzleSolvedLabel;
@synthesize todaysDateLabelPuzzle;
@synthesize puzzleCompleteLabel;
@synthesize packAndPuzzlesLabel;
@synthesize puzzleCompleteMessage;
@synthesize puzzleSolvedLabelFrame;
@synthesize puzzleCompleteLabelInitialFrame;
@synthesize puzzleCompleteMessageInitialFrame;
@synthesize puzzleCompleteLabelFinalFrame;
@synthesize puzzleCompleteLabelDemoFinalFrame;
@synthesize puzzleCompleteMessageFinalFrame;
@synthesize numberOfPointsLabel;
@synthesize puzzlesSolvedLabelStats;
@synthesize pointsLabelStats;
@synthesize gridSizeLabel;
@synthesize gridSizeStepper;

@synthesize allowableLaserGridPositionArray;
@synthesize allowableTileGridPositionArray;
@synthesize puzzleDictionary;
@synthesize inputPuzzleDictionary;

@synthesize infoScreenLabelArray;

- (void)viewDidLoad {
    DLog("DEBUG1 - BMDPuzzleViewController.viewDidLoad");
    [super viewDidLoad];
    
    rc = (BMDViewController*)[[(BMDAppDelegate *)[[UIApplication sharedApplication]delegate] window] rootViewController];
    appd = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // Turn off rendering while initializing puzzleView and optics
    rc.renderBackgroundON = NO;
    rc.renderPuzzleON = NO;
    rc.renderOverlayON = NO;
    
    // Set up puzzleView
    CGRect puzzleBounds = rc.rootView.bounds;
    puzzleView = [[MTKView alloc] initWithFrame:puzzleBounds device:MTLCreateSystemDefaultDevice()];
    self.view = puzzleView;
    
    puzzleView.enableSetNeedsDisplay = NO;
    puzzleView.preferredFramesPerSecond = METAL_RENDERER_FPS;
    puzzleView.presentsWithTransaction = NO;
    puzzleView.device = MTLCreateSystemDefaultDevice();
    NSAssert(puzzleView.device, @"Metal is not supported on this device");
    rc.renderer = [[BMDRenderer alloc] initWithMetalKitView:puzzleView];
    NSAssert(rc.renderer, @"Renderer failed initialization");
    // Initialize the renderer with the view size
    [rc.renderer mtkView:puzzleView drawableSizeWillChange:puzzleView.drawableSize];
    puzzleView.delegate = rc.renderer;
    
    // Load Textures
    [appd initAllTextures:puzzleView metalRenderer:rc.renderer];
    
    NSMutableDictionary *pack = nil;
    NSMutableDictionary *puzzle = nil;
    // Puzzle Play - Free and Paid Packs
    if (rc.appCurrentGamePackType == PACKTYPE_MAIN &&
        [appd editModeIsEnabled] == NO){
        unsigned int currentPackNumber = [appd fetchCurrentPackNumber];
        puzzle = [appd fetchCurrentPuzzleFromPackGameProgress:currentPackNumber];
        if (puzzle == nil ||
            [appd puzzleIsEmpty:puzzle] == YES){
            // Handle case where no puzzle or an empty puzzle is stored
            // Read puzzle from the main bundle
            puzzle = [appd fetchCurrentPuzzleFromPackDictionary:currentPackNumber];
            // Save the puzzle to PackGameProgress
            [appd saveCurrentPuzzleToPackGameProgress:currentPackNumber puzzle:puzzle];
        }
    }
    // Puzzle Play - Daily Puzzle
    else if (rc.appCurrentGamePackType == PACKTYPE_DAILY &&
             [appd editModeIsEnabled] == NO){
        if ([self queryPuzzleExists:kDailyPuzzlesPackDictionary puzzle:appd.currentDailyPuzzleNumber]) {
            // If the Daily Puzzle has changed from the previously stored Daily Puzzle then load and store a new one
            if (appd.currentDailyPuzzleNumber != [appd fetchDailyPuzzleNumber]){
                // Save the new daily puzzle number
                [appd saveDailyPuzzleNumber:appd.currentDailyPuzzleNumber];
                // Load a new Daily Puzzle from the main bundle (not pack parameter not used for daily puzzle)
                puzzle = [appd fetchGamePuzzle:0 puzzleIndex:[appd fetchPackIndexForPackNumber:
                                                              appd.currentDailyPuzzleNumber]];
                // Save the new daily puzzle
                [appd saveDailyPuzzle:appd.currentDailyPuzzleNumber puzzle:puzzle];
            }
            else {
                // Fetch the stored version of the daily puzzle, which may include partial completion by the player
                puzzle = [appd fetchDailyPuzzle:appd.currentDailyPuzzleNumber];
            }
        }
    }
    // Puzzle Play - Demo Pack
    else if (rc.appCurrentGamePackType == PACKTYPE_DEMO &&
             [appd editModeIsEnabled] == NO){
        DLog("rc.appCurrentGamePackType == PACKTYPE_DEMO");
        unsigned int demoPuzzleNumber = [appd fetchDemoPuzzleNumber];
        [appd saveDemoPuzzleNumber:demoPuzzleNumber];
        if ([self queryPuzzleExists:kDemoPuzzlePackDictionary puzzle:demoPuzzleNumber]){
            puzzle = [appd fetchGamePuzzle:0 puzzleIndex:demoPuzzleNumber];
        }
    }
    // Puzzle Editor
    //
    // The PE fetches a pack (an NSMutableDictionary containing zero or more puzzle
    // NSMutableDictionaries.
    else if ([appd editModeIsEnabled]){
        pack = [appd fetchEditedPack];
        // Initialize longPressRecognizer
        UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressDetected:)];
        longPressRecognizer.delegate = self;
        longPressRecognizer.minimumPressDuration = 0.5;
        longPressRecognizer.numberOfTouchesRequired = 1;
        [puzzleView addGestureRecognizer:longPressRecognizer];
        
        // Initialize TapGestureRecognizer
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureDetected:)];
        tapGestureRecognizer.delegate = self;
        [puzzleView addGestureRecognizer:tapGestureRecognizer];
    }
    else {
        puzzle = nil;
        DLog("Unexpected PACKTYPE = %d", rc.appCurrentGamePackType);
    }
    
    if (rc.appCurrentGamePackType == PACKTYPE_MAIN ||
        rc.appCurrentGamePackType == PACKTYPE_DAILY){
        // Detect when app loses focus so you can save puzzle timeSegment to pause timing
        [[NSNotificationCenter defaultCenter]
         addObserver: self
         selector: @selector (handleUIApplicationWillResignActiveNotification)
         name: UIApplicationWillResignActiveNotification
         object: nil];
        // Detect when app gains focus so you can restore puzzle timeSegment to reenable timing
        [[NSNotificationCenter defaultCenter]
         addObserver: self
         selector: @selector (handleUIApplicationDidBecomeActiveNotification)
         name: UIApplicationDidBecomeActiveNotification
         object: nil];
    }
    
    
    // If not running the PE then start the selected puzzle
    if (rc.appCurrentGamePackType == PACKTYPE_MAIN ||
        rc.appCurrentGamePackType == PACKTYPE_DAILY ||
        rc.appCurrentGamePackType == PACKTYPE_DEMO){
        
        // Update puzzle startTime tracking
        long startTime = [[NSNumber numberWithLong: [[NSDate date] timeIntervalSince1970]] integerValue];
        int currentPackNumber = -1;
        int currentPuzzleNumber = 0;
        NSMutableDictionary *emptyJewelCountDictionary = [appd buildEmptyJewelCountDictionary];
        if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
            currentPackNumber = [appd fetchCurrentPackNumber];
            currentPuzzleNumber = [appd fetchCurrentPuzzleNumber];
            [appd updatePuzzleScoresArray:currentPackNumber
                             puzzleNumber:currentPuzzleNumber
                           numberOfJewels:emptyJewelCountDictionary
                                startTime:startTime
                                  endTime:-1
                                   solved:NO];
        }
        else if (rc.appCurrentGamePackType == PACKTYPE_DAILY) {
            currentPackNumber = -1;
            currentPuzzleNumber = [appd fetchDailyPuzzleNumber];
            [appd updatePuzzleScoresArray:currentPackNumber
                             puzzleNumber:currentPuzzleNumber
                           numberOfJewels:emptyJewelCountDictionary
                                startTime:startTime
                                  endTime:-1
                                   solved:NO];
        }
        
        // Track start of DEMO
        if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
            
            if (ENABLE_GA == YES){
                [FIRAnalytics logEventWithName:kFIREventTutorialBegin
                                    parameters:@{
                }];
            }        }
        
        appd->optics = [Optics alloc];
        [appd->optics initWithDictionary:puzzle viewController:self];
    }
    // else if Auto Generation enabled then start the PE with an empty puzzle
    else if ([appd autoGenIsEnabled]) {
        puzzle = nil;
        gridSizeStepperInitialValue = kDefaultGridStartingSizeX;
        appd->optics = [Optics alloc];
        [appd->optics initWithDictionary:puzzle viewController:self];
    }
    // else start the PE with a pack of zero or more puzzles
    else if ([appd editModeIsEnabled]) {
        int puzzleIndex = 0;
        NSMutableArray *puzzleArray = [NSMutableArray arrayWithArray:[pack objectForKey:@"puzzles"]];
        puzzle = [NSMutableDictionary dictionaryWithCapacity:1];
        if ([puzzleArray count] != 0){
            puzzle = [puzzleArray objectAtIndex:puzzleIndex];
            gridSizeStepperInitialValue = [[puzzle objectForKey:@"gridSizeX"]doubleValue];
        }
        else {
            gridSizeStepperInitialValue = kDefaultGridStartingSizeX;
        }
        appd->optics = [Optics alloc];
        [appd->optics initWithDictionary:puzzle viewController:self];
    }
    else {
        DLog("Failure to load puzzle, dict == nil");
        puzzle = nil;
        appd->optics = [Optics alloc];
        [appd->optics initWithDictionary:puzzle viewController:self];
    }
    
    
    // Start rendering
    rc.renderPuzzleON = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    DLog("BMDPuzzleViewController.viewDidAppear");
    puzzleView.preferredFramesPerSecond = METAL_RENDERER_FPS;
    rc.renderPuzzleON = YES;
    
    NSString *adFree = [appd getObjectFromDefaults:@"AD_FREE_PUZZLES"];
    if (![adFree isEqualToString:@"YES"] &&
        self->rc.appCurrentGamePackType != PACKTYPE_DEMO){
        [puzzleView addSubview:rc.bannerAdView];
        [puzzleView bringSubviewToFront:rc.bannerAdView];
    }
    
    [rc hideLaunchScreen];
    rc.gamekitAccessPoint.active = NO;

    if (ENABLE_GA == YES){
        
        [FIRAnalytics logEventWithName:kFIREventSelectContent
                            parameters:@{
            kFIRParameterItemID:[NSString stringWithFormat:@"id-%@", @"PuzzleVC viewDidAppear"],
            kFIRParameterItemName:@"PuzzleVC viewDidAppear",
            kFIRParameterContentType:@"image"
        }];
    }
    
    if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
        [appd playMusicLoop:appd.loop3Player];
    }
    else {
        [appd playMusicLoop:appd.loop2Player];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    DLog("BMDPuzzleViewController.viewDidDisappear");
    rc.renderPuzzleON = NO;
    rc.renderOverlayON = NO;
}

- (BOOL)queryPuzzleExists:(NSString *)dictionaryName puzzle:(unsigned int)puzzleIndex {
    BOOL exists = NO;
    NSMutableDictionary *dictionaryPack = [appd fetchGameDictionaryForKey:dictionaryName];
    if (dictionaryPack){
        NSMutableArray *puzzleArray = [NSMutableArray arrayWithArray:[dictionaryPack objectForKey:@"puzzles"]];
        if ([puzzleArray objectAtIndex:puzzleIndex] != nil){
            exists = YES;
        }
    }
    return exists;
}

- (void)setPuzzleLabel {
    if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
        // puzzleTitleLabel
        puzzleTitleLabel.hidden = NO;
        NSMutableArray *array = [appd->gameDictionaries objectForKey:kPuzzlePacksArray];
        unsigned int currentPackNumber = [appd fetchCurrentPackNumber];
        unsigned int currentPackIndex = [appd fetchPackIndexForPackNumber:currentPackNumber];
        if ([array count] > currentPackIndex){
            NSMutableDictionary *dict = [array objectAtIndex:currentPackIndex];
            puzzleTitleLabel.text = [NSString stringWithFormat:@"%@", [dict objectForKey:@"pack_name"]];
            hintButton.hidden = [appd->optics allTilesArePlaced];
            hintBulb.hidden = [appd->optics allTilesArePlaced];
        }
    }
    else if (rc.appCurrentGamePackType == PACKTYPE_DAILY){
        puzzleTitleLabel.hidden = NO;
        puzzleTitleLabel.text = [NSString stringWithFormat:@"Daily Puzzle"];
    }
    else if ([appd editModeIsEnabled] && rc.appCurrentGamePackType == PACKTYPE_EDITOR){
        NSMutableDictionary *pack = nil, *puzzle = nil;
        pack = [appd fetchEditedPack];
        int index = [appd fetchEditedPuzzleIndexFromDefaults];
        if (index < 0){
            index = 0;
        }
        if (pack){
            NSMutableArray *puzzleArray = [NSMutableArray arrayWithArray:[pack objectForKey:@"puzzles"]];
            if (index < [puzzleArray count]){
                puzzle = [puzzleArray objectAtIndex:index];
                if (puzzle){
                    int puzzleDisplayIndex = index+1;
                    puzzleTitleLabel.text = [NSString stringWithFormat:@"%.6d", puzzleDisplayIndex];
                }
                else {
                    puzzleTitleLabel.text = [NSString stringWithFormat:@"No Puzzle"];
                }
            }
            else {
                puzzleTitleLabel.text = [NSString stringWithFormat:@"No Puzzle"];
            }
        }
    }
    else {
        puzzleTitleLabel.hidden = YES;
        puzzleTitleLabel.text = [NSString stringWithFormat:@""];
    }
}

- (void)displayButtonsAndLabels {
    
    [self setPuzzleLabel];
    
    // numberOfPuzzlesLabel
    numberOfPuzzlesLabel.hidden = NO;
    if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
        numberOfPuzzlesLabel.text = [NSString stringWithFormat:@"%d / %d", [appd fetchCurrentPuzzleNumber]+1, [appd fetchCurrentPackLength]];
    }
    else if ([appd editModeIsEnabled]){
        NSMutableDictionary *packDictionary = nil;
        packDictionary = [appd fetchEditedPack];
        unsigned int numberOfPuzzles = [appd countPuzzlesWithinPack:packDictionary];
        if (numberOfPuzzles > 1 || numberOfPuzzles == 0){
            numberOfPuzzlesLabel.text = [NSString stringWithFormat:@"%d / %d", [appd fetchCurrentPuzzleNumber]+1, [appd fetchCurrentPackLength]];
        }
        else {
            numberOfPuzzlesLabel.text = [NSString stringWithFormat:@"%d / %d", [appd fetchCurrentPuzzleNumber]+1, [appd fetchCurrentPackLength]];
        }
    }
   
    // numberOfPointsLabel
    if (rc.appCurrentGamePackType == PACKTYPE_MAIN ||
        rc.appCurrentGamePackType == PACKTYPE_DEMO){
        numberOfPointsLabel.hidden = NO;
//        numberOfPointsLabel.text = [NSString stringWithFormat:@"Points: %d", [appd countTotalPoints]];
    }
    else if ([appd editModeIsEnabled] && rc.appCurrentGamePackType == PACKTYPE_EDITOR){
        numberOfPointsLabel.hidden = YES;
    }
    
    // hintButton
    [self disableFlash:hintButton];
    [self enableFlash:hintButton];
    [self setHintButtonLabel:appd.numberOfHintsRemaining];
    
    
    hintButton.hidden = [appd->optics allTilesArePlaced];
    hintBulb.hidden = [appd->optics allTilesArePlaced];

    if ([appd checkForEndlessHintsPurchased]){
        [hintButton setTitle:[NSString stringWithFormat:@"Endless Hints"] forState:UIControlStateNormal];
    }
    else {
        int numberOfHintsRemaining = [[appd getObjectFromDefaults:@"numberOfHintsRemaining"] intValue];
        if (numberOfHintsRemaining > 0){
            [hintButton setTitle:[NSString stringWithFormat:@"Hints %d", numberOfHintsRemaining] forState:UIControlStateNormal];
        }
        else {
            [hintButton setTitle:[NSString stringWithFormat:@"Get Hints"] forState:UIControlStateNormal];
        }
    }

    
    // todaysDateLabelPuzzle
    if ([appd editModeIsEnabled] && rc.appCurrentGamePackType == PACKTYPE_EDITOR){
        todaysDateLabelPuzzle.hidden = YES;
    }
    else {
        todaysDateLabelPuzzle.hidden = NO;
        todaysDateLabelPuzzle.text = [self fetchTodaysDateAsString];
    }
    
    // deleteButton
    // duplicateButton
    // saveButton
    if ([appd editModeIsEnabled]){
        deleteButton.hidden = NO;
        saveButton.hidden = NO;
        duplicateButton.hidden = NO;
    }
    else {
        deleteButton.hidden = YES;
        saveButton.hidden = YES;
        duplicateButton.hidden = YES;
    }
    
    // puzzleSolvedView
    puzzleSolvedView.hidden = YES;
    
    // puzzleCompleteLabel
    puzzleCompleteLabel.hidden = YES;
    
    // nextButton
    nextButton.hidden = YES;
    
    // homeArrowWhite
    homeArrowWhite.hidden = YES;
    replayIconWhite.hidden = YES;

    // prevButton
    if ([appd editModeIsEnabled]){
        prevButton.hidden = NO;
    }
    else {
        prevButton.hidden = YES;
    }
    
    if (rc.appCurrentGamePackType == PACKTYPE_MAIN) {
        numberOfPuzzlesLabel.hidden = NO;
        numberOfPointsLabel.hidden = NO;
        todaysDateLabelPuzzle.hidden = NO;
        hintButton.hidden = NO;
        hintBulb.hidden = NO;
        puzzleTitleLabel.hidden = NO;
        backButton.hidden = NO;
        prevArrowWhite.hidden = YES;
        nextArrow.hidden = YES;
    } else if (rc.appCurrentGamePackType == PACKTYPE_DAILY) {
        numberOfPuzzlesLabel.hidden = YES;
        numberOfPointsLabel.hidden = YES;
        todaysDateLabelPuzzle.hidden = NO;
        hintButton.hidden = NO;
        hintBulb.hidden = NO;
        puzzleTitleLabel.hidden = NO;
        backButton.hidden = NO;
        prevArrowWhite.hidden = YES;
        nextArrow.hidden = YES;
    } else if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
        numberOfPuzzlesLabel.hidden = YES;
        numberOfPointsLabel.hidden = YES;
        todaysDateLabelPuzzle.hidden = YES;
        hintButton.hidden = !appd->optics->circleAroundHintsButton;
        hintBulb.hidden = !appd->optics->circleAroundHintsButton;
        puzzleTitleLabel.hidden = NO;
        backButton.hidden = YES;
        if ([appd fetchDemoPuzzleNumber] > 0){
            prevArrowWhite.hidden = NO;
        }
        else {
            prevArrowWhite.hidden = YES;
        }
        if ([appd packHasBeenCompleted]){
            nextArrow.hidden = YES;
        }
        else {
            nextArrow.hidden = NO;
        }
    }
    
}

- (void)buildButtonsAndLabelsForPlay {
    DLog("buildButtonsAndLabelsForPlay");
    // Setup control buttons and information view at the top of the screen
    CGFloat width, height, posX, posY;
    // Font sizes
    int puzzleTitleLabelFontSize,
    numberOfPuzzlesLabelFontSize,
    hintButtonFontSize,
    packAndPuzzlesLabelFontSize,
    todaysDateLabelFontSize,
    puzzleCompleteFontSize,
    puzzleCompleteMessageFontSize,
    numberOfPointsLabelFontSize,
    bulbSizeInPoints,
    jewelChestButtonSizeInPoints,
    completedPuzzleButtonSizeInPoints,
    helpLabelFontSize;
    CGFloat gameTitleLabelAnchorPointsX, gameTitleLabelAnchorPointsY;
    CGFloat puzzleCompleteLabelAnchorPointsY;
    CGFloat prevHomeNextFontSize;
    CGFloat backButtonIconSizeInPoints = 60;
    CGFloat settingsGearIconSizeInPoints = 66;
    CGFloat shoppingCartIconSizeInPoints = 66;
    int scoreFontSize;

    switch (rc.displayAspectRatio) {
        case ASPECT_4_3:
            // iPad (9th generation)
        case ASPECT_10_7:
            // iPad Air (5th generation)
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            //
            // Font sizes
            puzzleTitleLabelFontSize = 36;
            todaysDateLabelFontSize = 20;
            numberOfPointsLabelFontSize = 20;
            numberOfPuzzlesLabelFontSize = 20;
            hintButtonFontSize = 36;
            prevHomeNextFontSize = 36;
            backButtonIconSizeInPoints = 60;
            bulbSizeInPoints = 60;
            settingsGearIconSizeInPoints = 66;
            shoppingCartIconSizeInPoints = 62;
            
            jewelChestButtonSizeInPoints = 140;
            completedPuzzleButtonSizeInPoints = 140;
            scoreFontSize = 14;
            helpLabelFontSize = 14;
            
            packAndPuzzlesLabelFontSize = 18;
            puzzleCompleteFontSize = 32;
            puzzleCompleteMessageFontSize = 36;
            
            gameTitleLabelAnchorPointsX = 20.0;
            gameTitleLabelAnchorPointsY = rc.topPaddingInPoints/3.0;
            puzzleCompleteLabelAnchorPointsY = (appd->optics->gridTouchGestures.maxPuzzleBoundary.y-appd->optics->_squareTileSideLengthInPixels)/rc.contentScaleFactor;
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            //
            // Font sizes
            puzzleTitleLabelFontSize = 20;
            todaysDateLabelFontSize = 12;
            numberOfPointsLabelFontSize = 12;
            numberOfPuzzlesLabelFontSize = 12;
            hintButtonFontSize = 20;
            prevHomeNextFontSize = 20;
            backButtonIconSizeInPoints = 40;
            bulbSizeInPoints = 40;
            settingsGearIconSizeInPoints = 44;
            shoppingCartIconSizeInPoints = 42;
            
            jewelChestButtonSizeInPoints = 90;
            completedPuzzleButtonSizeInPoints = 90;
            scoreFontSize = 10;
            helpLabelFontSize = 10;
            
            packAndPuzzlesLabelFontSize = 14;
            puzzleCompleteFontSize = 28;
            puzzleCompleteMessageFontSize = 20;
            
            gameTitleLabelAnchorPointsX = 20.0;
            gameTitleLabelAnchorPointsY = appd->optics->_tileVerticalOffsetInPixels/rc.contentScaleFactor - 4.0*puzzleTitleLabelFontSize;
            puzzleCompleteLabelAnchorPointsY = (appd->optics->gridTouchGestures.maxPuzzleBoundary.y-appd->optics->_squareTileSideLengthInPixels)/rc.contentScaleFactor;
            break;
        }
        default:
        case ASPECT_13_6: {
            // iPhone 14
            //
            // Font sizes
            puzzleTitleLabelFontSize = 20;
            todaysDateLabelFontSize = 14;
            numberOfPointsLabelFontSize = 16;
            numberOfPuzzlesLabelFontSize = 16;
            hintButtonFontSize = 20;
            prevHomeNextFontSize = 26;
            backButtonIconSizeInPoints = 40;
            bulbSizeInPoints = 40;
            settingsGearIconSizeInPoints = 44;
            shoppingCartIconSizeInPoints = 42;

            jewelChestButtonSizeInPoints = 90;
            completedPuzzleButtonSizeInPoints = 90;
            scoreFontSize = 10;
            helpLabelFontSize = 10;

            packAndPuzzlesLabelFontSize = 16;
            puzzleCompleteFontSize = 28;
            puzzleCompleteMessageFontSize = 20;
            
            gameTitleLabelAnchorPointsX = 20.0;
            gameTitleLabelAnchorPointsY = appd->optics->_tileVerticalOffsetInPixels/rc.contentScaleFactor - 4.20*puzzleTitleLabelFontSize;
            puzzleCompleteLabelAnchorPointsY = (appd->optics->gridTouchGestures.maxPuzzleBoundary.y-appd->optics->_squareTileSideLengthInPixels)/rc.contentScaleFactor;
            break;
        }
    }
    
    //
    // puzzleTitleLabel
    //
    width = 0.75*rc.screenWidthInPixels/rc.contentScaleFactor;
    height = puzzleTitleLabelFontSize;
    posX = gameTitleLabelAnchorPointsX;
    posY = gameTitleLabelAnchorPointsY;
    CGRect labelFrame = CGRectMake(posX, posY, width, height);
    puzzleTitleLabel = [[UILabel alloc] initWithFrame:labelFrame];
    UIFont *puzzleTitleLabelFont = [UIFont fontWithName:@"PingFang SC Semibold" size:puzzleTitleLabelFontSize];
    puzzleTitleLabel.textColor = [UIColor whiteColor];
    puzzleTitleLabel.layer.borderWidth = 0.0;
    [puzzleTitleLabel setFont:puzzleTitleLabelFont];
    puzzleTitleLabel.textAlignment = NSTextAlignmentLeft;
    [puzzleView addSubview:puzzleTitleLabel];
    [puzzleView bringSubviewToFront:puzzleTitleLabel];
    
    //
    // numberOfPuzzlesLabel
    //
    width = 0.5*rc.screenWidthInPixels/rc.contentScaleFactor;
    height = puzzleTitleLabelFontSize;
    posX = (appd->optics->_puzzleScreenHorizontalOffsetInPixels +
            appd->optics->_safeAreaScreenWidthInPixels)/rc.contentScaleFactor - 1.1*width;
    posY = gameTitleLabelAnchorPointsY;
    labelFrame = CGRectMake(posX, posY, width, height);
    numberOfPuzzlesLabel = [[UILabel alloc] initWithFrame:labelFrame];
    [numberOfPuzzlesLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:puzzleTitleLabelFontSize]];
    numberOfPuzzlesLabel.textColor = [UIColor whiteColor];
    numberOfPuzzlesLabel.layer.borderWidth = 0.0;
    numberOfPuzzlesLabel.textAlignment = NSTextAlignmentRight;
    [puzzleView addSubview:numberOfPuzzlesLabel];
    [puzzleView bringSubviewToFront:numberOfPuzzlesLabel];
    
    //
    // todaysDateLabelPuzzle
    //
    width = 0.5*rc.screenWidthInPixels/rc.contentScaleFactor;
    height = todaysDateLabelFontSize;
    posX = gameTitleLabelAnchorPointsX;
    posY = posY + height*2.0;
    labelFrame = CGRectMake(posX, posY, width, height);
    todaysDateLabelPuzzle = [[UILabel alloc]initWithFrame:labelFrame];
    [todaysDateLabelPuzzle setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:todaysDateLabelFontSize]];
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateStyle:NSDateFormatterFullStyle];
    NSString *dateString = [formatter stringFromDate:date];
    todaysDateLabelPuzzle.text = dateString;
    todaysDateLabelPuzzle.textColor = [UIColor whiteColor];
    todaysDateLabelPuzzle.textAlignment = NSTextAlignmentLeft;
    todaysDateLabelPuzzle.hidden = NO;
    if (rc.appCurrentGamePackType == PACKTYPE_DAILY){
        [puzzleView addSubview:todaysDateLabelPuzzle];
        [puzzleView bringSubviewToFront:todaysDateLabelPuzzle];
    }
    
    //
    // homeArrow icon
    //
    // Create a back arrow icon at the left hand side
    homeArrow = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect homeArrowRect = CGRectMake(posX,
                                      posY+1.25*height,
                                      backButtonIconSizeInPoints,
                                      backButtonIconSizeInPoints);
    homeArrow.frame = homeArrowRect;
    homeArrow.enabled = YES;
    if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
        homeArrow.hidden = NO;
        prevArrowWhite.hidden = NO;
    }
    else {
        homeArrow.hidden = NO;
        prevArrowWhite.hidden = YES;
    }
    [homeArrow addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UIImage *homeArrowImage = [UIImage imageNamed:@"homeArrow.png"];
    [homeArrow setBackgroundImage:homeArrowImage forState:UIControlStateNormal];
    
    [puzzleView addSubview:homeArrow];
    [puzzleView bringSubviewToFront:homeArrow];

    
    //
    // hintButton (use one hint to correctly position an unplaced tile)
    //
    hintButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [hintButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:todaysDateLabelFontSize]];
    width = 0.4*rc.screenWidthInPixels/rc.contentScaleFactor;
    height = todaysDateLabelFontSize;
    posX = (appd->optics->_puzzleScreenHorizontalOffsetInPixels +
            appd->optics->_safeAreaScreenWidthInPixels)/rc.contentScaleFactor - 1.1*width;
    CGRect buttonRect = CGRectMake(posX, posY, width, height);
    hintButton.frame = buttonRect;
    hintButton.layer.borderWidth = buttonBorderWidth;
    hintButton.layer.borderColor = [UIColor clearColor].CGColor;
    hintButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    hintButton.titleLabel.textAlignment = NSTextAlignmentLeft;
    [self setHintButtonLabel:appd.numberOfHintsRemaining];
    [hintButton addTarget:self action:@selector(hintButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    hintButton.showsTouchWhenHighlighted = YES;
    hintButton.hidden = [appd->optics allTilesArePlaced] ||
                        ((rc.appCurrentGamePackType == PACKTYPE_DEMO) && !appd->optics->circleAroundHintsButton);
    [hintButton setTitleColor:[UIColor colorWithRed:251.0/255.0
                                              green:212.0/255.0
                                               blue:12.0/255.0
                                              alpha:1.0]
                                forState:UIControlStateNormal];
    hintButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [self enableFlash:hintButton];

    //
    // hint light bulb
    //
    // Create a light bulb at the right hand side
    hintBulb = [UIButton buttonWithType:UIButtonTypeCustom];
    posY = 1.1*homeArrowRect.origin.y;
    CGRect hintRect = CGRectMake(rc.screenWidthInPixels/rc.contentScaleFactor-1.5*bulbSizeInPoints,
                                 posY-0.90*height,
                                 bulbSizeInPoints,
                                 bulbSizeInPoints);
    hintBulb.frame = hintRect;
    hintBulb.enabled = YES;
    hintBulb.hidden = [appd->optics allTilesArePlaced] ||
                        ((rc.appCurrentGamePackType == PACKTYPE_DEMO) && !appd->optics->circleAroundHintsButton);
    [hintBulb addTarget:self action:@selector(hintButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    hintBulb.hidden = [appd->optics allTilesArePlaced] ||
                        ((rc.appCurrentGamePackType == PACKTYPE_DEMO) && !appd->optics->circleAroundHintsButton);
    UIImage *hintImage = nil;
    if (appd->optics->circleAroundHintsButton){
        hintImage = [UIImage imageNamed:@"lightBulbInCircle.png"];
    }
    else {
        hintImage = [UIImage imageNamed:@"lightBulb.png"];
    }
    [hintBulb setImage:hintImage forState:UIControlStateNormal];

    [puzzleView addSubview:hintBulb];
    [puzzleView bringSubviewToFront:hintBulb];
    [puzzleView addSubview:hintButton];
    [puzzleView bringSubviewToFront:hintButton];

    //
    // help button
    //
    // Create a help button at top center for iPhones and below the homeArrow for iPads
    helpButton = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect helpRect;
    switch (rc.displayAspectRatio) {
        case ASPECT_4_3:
            // iPad (9th generation)
        case ASPECT_10_7:
            // iPad Air (5th generation)
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            //
            helpRect = CGRectMake(homeArrowRect.origin.x,
                                  homeArrowRect.origin.y+1.5*backButtonIconSizeInPoints,
                                  backButtonIconSizeInPoints,
                                  backButtonIconSizeInPoints);
            break;
        }
        case ASPECT_16_9:
            // iPhone 14
        case ASPECT_13_6: {
            // iPhone 8
        default:
            helpRect = CGRectMake(0.5*rc.screenWidthInPixels/rc.contentScaleFactor-0.5*hintRect.size.width,
                                         hintRect.origin.y,
                                         hintRect.size.width,
                                         hintRect.size.height);
            break;
        }
    }
    helpButton.frame = helpRect;
    helpButton.enabled = YES;
    helpButton.hidden = [appd->optics allTilesArePlaced] || (rc.appCurrentGamePackType == PACKTYPE_DEMO);
//    [helpButton addTarget:self action:@selector(replayIconPressed) forControlEvents:UIControlEventTouchUpInside];
    [helpButton addTarget:self action:@selector(helpButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UIImage *helpImage = [UIImage imageNamed:@"helpButton.png"];
    [helpButton setBackgroundImage:helpImage forState:UIControlStateNormal];

    [puzzleView addSubview:hintBulb];
    [puzzleView bringSubviewToFront:hintBulb];
    [puzzleView addSubview:helpButton];
    [puzzleView bringSubviewToFront:helpButton];
    [puzzleView addSubview:hintButton];
    [puzzleView bringSubviewToFront:hintButton];

    //
    // helpImageView
    //
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"helpImage" ofType:@"png"];
    UIImage *sourceImage = [UIImage imageWithContentsOfFile:filePath];
    CGFloat imageWidth = (CGFloat)sourceImage.size.width/rc.contentScaleFactor;
    CGFloat imageHeight = (CGFloat)sourceImage.size.height/rc.contentScaleFactor;
    CGFloat displayWidth, displayHeight;
    CGRect imageViewRect, helpImageViewRect;
    switch (rc.displayAspectRatio) {
        case ASPECT_4_3:
            // iPad (8th, 9th, 10th generation)
        case ASPECT_10_7:
            // iPad Air (5th generation)
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            //
            // Vertically constrained
            displayWidth = 0.9*rc.screenWidthInPixels/rc.contentScaleFactor;
            displayHeight = 0.9*rc.screenHeightInPixels/rc.contentScaleFactor;
            imageViewRect = CGRectMake((displayWidth-imageWidth*displayHeight/imageHeight)/2.0,
                                       0.0,
                                       imageWidth*displayHeight/imageHeight,
                                       displayHeight);
            helpImageViewRect = CGRectMake(0.05*rc.screenWidthInPixels/rc.contentScaleFactor,
                                              0.05*rc.screenHeightInPixels/rc.contentScaleFactor,
                                              displayWidth,
                                              displayHeight);
            break;
        }
        case ASPECT_16_9:
            // iPhone 14
        case ASPECT_13_6: {
            // iPhone 8
        default:
            // Horizontally constrained
            displayWidth = 1.0*rc.screenWidthInPixels/rc.contentScaleFactor;
            displayHeight = 0.7*rc.screenHeightInPixels/rc.contentScaleFactor;
            imageViewRect = CGRectMake(0.0,
                                       (displayHeight-imageHeight*displayWidth/imageWidth)/2.0,
                                       displayWidth,
                                       imageHeight*displayWidth/imageWidth);
            helpImageViewRect = CGRectMake(0.0*rc.screenWidthInPixels/rc.contentScaleFactor,
                                              0.15*rc.screenHeightInPixels/rc.contentScaleFactor,
                                              displayWidth,
                                              displayHeight);
            break;
        }
    }
    CGSize imageSize = CGSizeMake(displayWidth, displayHeight);
    UIGraphicsBeginImageContext(imageSize);
    [sourceImage drawInRect:imageViewRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    helpImageView = [[UIImageView alloc]initWithImage:newImage];
    helpImageView.frame = helpImageViewRect;
    helpImageView.contentMode = UIViewContentModeScaleAspectFill;
    helpImageView.clipsToBounds = NO;
    helpImageView.hidden = YES;
    [helpImageView.layer setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0].CGColor];
    [helpImageView.layer setBorderColor:[UIColor whiteColor].CGColor];
    [helpImageView.layer setBorderWidth:2.0];
    [helpImageView.layer setCornerRadius:15.0];

    //
    // Add "Settings Gear" button to homeView
    //
    settingsGearButton = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect settingsRect;
    switch (rc.displayAspectRatio) {
        case ASPECT_4_3:
            // iPad (9th generation)
        case ASPECT_10_7:
            // iPad Air (5th generation)
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            //
            settingsRect = CGRectMake(helpRect.origin.x,
                                      helpRect.origin.y+1.5*settingsGearIconSizeInPoints,
                                      settingsGearIconSizeInPoints,
                                      settingsGearIconSizeInPoints);
            break;
        }
        case ASPECT_16_9:
            // iPhone 14
        case ASPECT_13_6: {
            // iPhone 8
        default:
            settingsRect = CGRectMake(homeArrowRect.origin.x+0.5*(helpRect.origin.x-homeArrowRect.origin.x),
                                      helpRect.origin.y,
                                      settingsGearIconSizeInPoints,
                                      settingsGearIconSizeInPoints);
            break;
        }
    }
    settingsGearButton.frame = settingsRect;
    settingsGearButton.enabled = YES;
    settingsGearButton.hidden = [appd->optics allTilesArePlaced] || (rc.appCurrentGamePackType == PACKTYPE_DEMO);
    [settingsGearButton addTarget:self action:@selector(settingsButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UIImage *settingsGearImage = [UIImage imageNamed:@"settingsGear.png"];
    [settingsGearButton setBackgroundImage:settingsGearImage forState:UIControlStateNormal];
    settingsGearButton.alpha = 1.0;
    [puzzleView addSubview:settingsGearButton];
    [puzzleView bringSubviewToFront:settingsGearButton];

    //
    // Add "Shopping Cart" button to homeView
    //
    puzzlePacksButton = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect shoppingRect;
    switch (rc.displayAspectRatio) {
        case ASPECT_4_3:
            // iPad (9th generation)
        case ASPECT_10_7:
            // iPad Air (5th generation)
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            //
            shoppingRect = CGRectMake(settingsRect.origin.x,
                                      settingsRect.origin.y+1.5*shoppingCartIconSizeInPoints,
                                      shoppingCartIconSizeInPoints,
                                      shoppingCartIconSizeInPoints);
            break;
        }
        case ASPECT_16_9:
            // iPhone 14
        case ASPECT_13_6: {
            // iPhone 8
        default:
            shoppingRect = CGRectMake(helpRect.origin.x+0.5*(hintRect.origin.x-helpRect.origin.x),
                                      helpRect.origin.y,
                                      shoppingCartIconSizeInPoints,
                                      shoppingCartIconSizeInPoints);
            break;
        }
    }
    puzzlePacksButton.frame = shoppingRect;
    puzzlePacksButton.enabled = YES;
    puzzlePacksButton.hidden = [appd->optics allTilesArePlaced] || (rc.appCurrentGamePackType == PACKTYPE_DEMO);
    [puzzlePacksButton addTarget:self action:@selector(morePuzzlePacksButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UIImage *shoppingCartImage = [UIImage imageNamed:@"puzzlePacks.png"];
    [puzzlePacksButton setBackgroundImage:shoppingCartImage forState:UIControlStateNormal];
    puzzlePacksButton.alpha = 1.0;
    [puzzleView addSubview:puzzlePacksButton];
    [puzzleView bringSubviewToFront:puzzlePacksButton];
    
    //
    // wholeScreenFilter
    //
    // Create a translucent filter (button) covering the entire screen
//    CGRect wholeScreenFilterRect = CGRectMake(0,
//                                              0,
//                                              rc.screenWidthInPixels/rc.contentScaleFactor,
//                                              rc.screenHeightInPixels/rc.contentScaleFactor);
//    wholeScreenFilter = [[UILabel alloc]initWithFrame:wholeScreenFilterRect];
//    wholeScreenFilter.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.75];
//    wholeScreenFilter.layer.borderColor = [UIColor blackColor].CGColor;
//    wholeScreenFilter.layer.borderWidth = 0.0;
//    wholeScreenFilter.hidden = YES;
//    [puzzleView addSubview:wholeScreenFilter];
//    [puzzleView bringSubviewToFront:wholeScreenFilter];
    

    // Add helpLabel and helpImageView on top of puzzlePacksButton and settingsGearButton
//    [puzzleView addSubview:helpLabel];
//    [puzzleView bringSubviewToFront:helpLabel];
    [puzzleView addSubview:helpImageView];
    [puzzleView bringSubviewToFront:helpImageView];

    
    //
    // nextArrow icon
    //
    // Create a next arrow icon near the right hand side of the Unplaced Tiles Tray
    CGFloat homeArrowCenterX, nextArrowCenterX;
    CGFloat nextArrowHomeArrowCenterY;
    CGFloat arrowWidthInPoints = 1.0/7.0*appd->optics->_safeAreaScreenWidthInPixels/rc.contentScaleFactor;
    switch (rc.displayAspectRatio) {
        case ASPECT_4_3:
        case ASPECT_10_7:
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            //
            nextArrowCenterX = appd->optics->gridTouchGestures.maxPuzzleBoundary.x/rc.contentScaleFactor + 1.2*0.5*arrowWidthInPoints;
            homeArrowCenterX = appd->optics->gridTouchGestures.minPuzzleBoundary.x/rc.contentScaleFactor - 1.2*0.5*arrowWidthInPoints;
            // Adjust the Y position so that the top of the arrow and the top of the Tile are aligned
            nextArrowHomeArrowCenterY = 0.994*appd->optics->gridTouchGestures.minUnplacedTilesBoundary.y/rc.contentScaleFactor;
            break;
        }
        case ASPECT_16_9:
            // iPhone 14
        case ASPECT_13_6:
            // iPhone 8
        default: {
            homeArrowCenterX = 1.0/7.0*appd->optics->_safeAreaScreenWidthInPixels/rc.contentScaleFactor;
            nextArrowCenterX = 6.0/7.0*appd->optics->_safeAreaScreenWidthInPixels/rc.contentScaleFactor;
            if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
                // In the How to Play Guide the arrows are dropped low to make room for text
                nextArrowHomeArrowCenterY =  1.025*(appd->optics->gridTouchGestures.maxUnplacedTilesBoundary.y/rc.contentScaleFactor);
            }
            else {
                // In normal play the arrows are kept higher to avoind the banner ad
                nextArrowHomeArrowCenterY = appd->optics->gridTouchGestures.minUnplacedTilesBoundary.y/rc.contentScaleFactor;
            }
            break;
        }
    }
    nextArrow = [UIButton buttonWithType:UIButtonTypeCustom];
//    CGFloat centerX = 6.0/7.0*appd->optics->_safeAreaScreenWidthInPixels/rc.contentScaleFactor;
    CGFloat centerY = nextArrowHomeArrowCenterY;
    CGRect nextArrowRect = CGRectMake(nextArrowCenterX-arrowWidthInPoints/2.0,
                                     centerY,
                                     arrowWidthInPoints,
                                     arrowWidthInPoints);
    nextArrow.frame = nextArrowRect;
    nextArrow.enabled = YES;
    nextArrow.hidden = NO;
    [nextArrow addTarget:self action:@selector(nextButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UIImage *nextArrowImage = [UIImage imageNamed:@"nextArrowWhite.png"];
    [nextArrow setBackgroundImage:nextArrowImage forState:UIControlStateNormal];
    [puzzleView addSubview:nextArrow];
    [puzzleView bringSubviewToFront:nextArrow];

    //
    // homeArrowWhite icon
    //
    // Create a white home arrow icon near the left hand side of the Unplaced Tiles Tray
    homeArrowWhite = [UIButton buttonWithType:UIButtonTypeCustom];
//    centerX = 1.0/7.0*appd->optics->_safeAreaScreenWidthInPixels/rc.contentScaleFactor;
    centerY = nextArrowHomeArrowCenterY;
    CGRect homeArrowWhiteRect = CGRectMake(homeArrowCenterX-arrowWidthInPoints/2.0,
                                     centerY,
                                     arrowWidthInPoints,
                                     arrowWidthInPoints);
    homeArrowWhite.frame = homeArrowWhiteRect;
    homeArrowWhite.enabled = YES;
    homeArrowWhite.hidden = YES;
    [homeArrowWhite addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UIImage *homeArrowWhiteImage = [UIImage imageNamed:@"homeArrowWhite.png"];
    [homeArrowWhite setBackgroundImage:homeArrowWhiteImage forState:UIControlStateNormal];
    if (rc.appCurrentGamePackType != PACKTYPE_DEMO){
        [puzzleView addSubview:homeArrowWhite];
        [puzzleView bringSubviewToFront:homeArrowWhite];
    }

    //
    // prevArrowWhite icon
    //
    // Create a white prev arrow icon near the left hand side of the Unplaced Tiles Tray
    prevArrowWhite = [UIButton buttonWithType:UIButtonTypeCustom];
    prevArrowWhite.frame = homeArrowWhiteRect;
    prevArrowWhite.enabled = YES;
    prevArrowWhite.hidden = YES;
    [prevArrowWhite addTarget:self action:@selector(prevButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UIImage *prevArrowWhiteImage = [UIImage imageNamed:@"prevArrowWhite.png"];
    [prevArrowWhite setBackgroundImage:prevArrowWhiteImage forState:UIControlStateNormal];
    if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
        [puzzleView addSubview:prevArrowWhite];
        [puzzleView bringSubviewToFront:prevArrowWhite];
    }

    //
    // replayIconWhite icon
    //
    // Create a white replay icon at the center of the Unplaced Tiles Tray
    replayIconWhite = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat centerX = 3.5/7.0*appd->optics->_safeAreaScreenWidthInPixels/rc.contentScaleFactor;
    centerY = appd->optics->gridTouchGestures.minUnplacedTilesBoundary.y/rc.contentScaleFactor;
    CGRect replayIconWhiteRect = CGRectMake(centerX-arrowWidthInPoints/2.0,
                                     centerY,
                                     arrowWidthInPoints,
                                     arrowWidthInPoints);
    replayIconWhite.frame = replayIconWhiteRect;
    replayIconWhite.enabled = YES;
    replayIconWhite.hidden = YES;
    [replayIconWhite addTarget:self action:@selector(replayIconPressed) forControlEvents:UIControlEventTouchUpInside];
    UIImage *replayIconWhiteImage = [UIImage imageNamed:@"replayIconWhite.png"];
    [replayIconWhite setBackgroundImage:replayIconWhiteImage forState:UIControlStateNormal];
    [puzzleView addSubview:replayIconWhite];
    [puzzleView bringSubviewToFront:replayIconWhite];

    CGFloat puzzleCompleteLabelCenter = (0.5*rc.screenWidthInPixels)/rc.contentScaleFactor;
    CGFloat puzzleCompleteLabelWidth = 0.9*(appd->optics->_puzzleDisplayWidthInPixels)/rc.contentScaleFactor;
    CGFloat puzzleCompleteLabelHeight = 3.0*puzzleCompleteFontSize;
    puzzleCompleteLabelInitialFrame = CGRectMake(puzzleCompleteLabelCenter-puzzleCompleteLabelWidth/2, puzzleCompleteLabelAnchorPointsY-puzzleCompleteLabelHeight, puzzleCompleteLabelWidth, puzzleCompleteLabelHeight);
    // Set up the frame for the final position of puzzleCompleteLabel in normal puzzle play
    puzzleCompleteLabelFinalFrame = CGRectMake(puzzleCompleteLabelCenter-puzzleCompleteLabelWidth/2, rc.topPaddingInPoints+(0.4*rc.screenHeightInPixels)/rc.contentScaleFactor-puzzleCompleteLabelHeight/2, puzzleCompleteLabelWidth, puzzleCompleteLabelHeight);
    puzzleCompleteLabel = [[UILabel alloc] initWithFrame:puzzleCompleteLabelInitialFrame];
    puzzleCompleteLabel.text = @"Puzzle Solved.";
    puzzleCompleteLabel.font = [UIFont fontWithName:@"PingFang SC Semibold" size:puzzleCompleteFontSize];
    puzzleCompleteLabel.adjustsFontSizeToFitWidth = NO;
    puzzleCompleteLabel.textColor = [UIColor cyanColor];
    puzzleCompleteLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.65];
    puzzleCompleteLabel.layer.masksToBounds = YES;
    puzzleCompleteLabel.layer.cornerRadius = 15;
    puzzleCompleteLabel.textAlignment = NSTextAlignmentCenter;
    puzzleCompleteLabel.hidden = YES;
    [puzzleView addSubview:puzzleCompleteLabel];
    [puzzleView bringSubviewToFront:puzzleCompleteLabel];

    //
    // wholeScreenButton
    //
    // Create a transparent button covering the entire screen
    wholeScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
    CGRect wholeScreenButtonRect = CGRectMake(0,
                                              0,
                                              rc.screenWidthInPixels/rc.contentScaleFactor,
                                              rc.screenHeightInPixels/rc.contentScaleFactor);
    wholeScreenButton.frame = wholeScreenButtonRect;
    wholeScreenButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    wholeScreenButton.layer.borderColor = [UIColor blackColor].CGColor;
    wholeScreenButton.layer.borderWidth = 0.0;
    wholeScreenButton.enabled = NO;
    wholeScreenButton.hidden = YES;
    [wholeScreenButton addTarget:self action:@selector(wholeScreenButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [puzzleView addSubview:wholeScreenButton];
    [puzzleView bringSubviewToFront:wholeScreenButton];

}

- (void)buildButtonsAndLabelsForEdit {
    DLog("buildButtonsAndLabelsForEdit");
    // Setup control buttons and information view at the top of the screen
    CGFloat width, height, posX, posY;
    // Font sizes
    int puzzleTitleLabelFontSize,
    numberOfPuzzlesLabelFontSize,
    hintButtonFontSize,
    packAndPuzzlesLabelFontSize,
    todaysDateLabelFontSize,
    puzzleCompleteFontSize,
    puzzleCompleteMessageFontSize,
    numberOfPointsLabelFontSize;
    CGFloat gameTitleLabelAnchorPointsX, gameTitleLabelAnchorPointsY;
    CGFloat puzzleCompleteLabelAnchorPointsY;
    CGFloat prevHomeNextFontSize;
    
    switch (rc.displayAspectRatio) {
        case ASPECT_4_3:
            // iPad (9th generation)
        case ASPECT_10_7:
            // iPad Air (5th generation)
        case ASPECT_3_2: {
            // Handle iPads
            //
            // Font sizes
            puzzleTitleLabelFontSize = 36;
            todaysDateLabelFontSize = 20;
            numberOfPointsLabelFontSize = 20;
            numberOfPuzzlesLabelFontSize = 20;
            hintButtonFontSize = 36;
            prevHomeNextFontSize = 36;
            
            packAndPuzzlesLabelFontSize = 18;
            puzzleCompleteFontSize = 32;
            puzzleCompleteMessageFontSize = 36;
            
            gameTitleLabelAnchorPointsX = 20.0;
            gameTitleLabelAnchorPointsY = rc.topPaddingInPoints/2.0;
//            gameTitleLabelAnchorPointsY = appd->optics->_tileVerticalOffsetInPixels/rc.contentScaleFactor - 4.5*puzzleTitleLabelFontSize;
            puzzleCompleteLabelAnchorPointsY = rc.topPaddingInPoints+(0.7*rc.screenHeightInPixels)/rc.contentScaleFactor;
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            //
            // Font sizes
            puzzleTitleLabelFontSize = 22;
            todaysDateLabelFontSize = 12;
            numberOfPointsLabelFontSize = 12;
            numberOfPuzzlesLabelFontSize = 12;
            hintButtonFontSize = 18;
            prevHomeNextFontSize = 18;
            
            packAndPuzzlesLabelFontSize = 14;
            puzzleCompleteFontSize = 28;
            puzzleCompleteMessageFontSize = 20;
            
            gameTitleLabelAnchorPointsX = 20.0;
            gameTitleLabelAnchorPointsY = appd->optics->_tileVerticalOffsetInPixels/rc.contentScaleFactor - 4.0*puzzleTitleLabelFontSize;
            puzzleCompleteLabelAnchorPointsY = rc.topPaddingInPoints+(0.7*rc.screenHeightInPixels)/rc.contentScaleFactor;
            break;
        }
        default:
        case ASPECT_13_6: {
            // iPhone 14
            //
            // Font sizes
            puzzleTitleLabelFontSize = 26;
            todaysDateLabelFontSize = 16;
            numberOfPointsLabelFontSize = 16;
            numberOfPuzzlesLabelFontSize = 16;
            hintButtonFontSize = 26;
            prevHomeNextFontSize = 26;
            
            packAndPuzzlesLabelFontSize = 16;
            puzzleCompleteFontSize = 28;
            puzzleCompleteMessageFontSize = 20;
            
            gameTitleLabelAnchorPointsX = 5.0;
            gameTitleLabelAnchorPointsY = appd->optics->_tileVerticalOffsetInPixels/rc.contentScaleFactor - 4.5*puzzleTitleLabelFontSize;
            puzzleCompleteLabelAnchorPointsY = rc.topPaddingInPoints+(0.775*rc.screenHeightInPixels)/rc.contentScaleFactor;
            break;
        }
    }
    
    //
    // puzzleTitleLabel
    //
    width = 0.5*rc.screenWidthInPixels/rc.contentScaleFactor;
    height = puzzleTitleLabelFontSize;
    posX = gameTitleLabelAnchorPointsX;
    posY = gameTitleLabelAnchorPointsY;
    CGRect labelFrame = CGRectMake(posX, posY, width, height);
    puzzleTitleLabel = [[UILabel alloc] initWithFrame:labelFrame];
    UIFont *puzzleTitleLabelFont = [UIFont fontWithName:@"PingFang SC Semibold" size:puzzleTitleLabelFontSize];
    puzzleTitleLabel.textColor = [UIColor whiteColor];
    puzzleTitleLabel.layer.borderWidth = 0.0;
    [puzzleTitleLabel setFont:puzzleTitleLabelFont];
    puzzleTitleLabel.textAlignment = NSTextAlignmentLeft;
    [puzzleView addSubview:puzzleTitleLabel];
    [puzzleView bringSubviewToFront:puzzleTitleLabel];
    
    //
    // clearButton
    //
    clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [clearButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:prevHomeNextFontSize]];
    width = 0.25*rc.screenWidthInPixels/rc.contentScaleFactor;
    height = puzzleTitleLabelFontSize;
    posX = (appd->optics->_puzzleScreenHorizontalOffsetInPixels +
            appd->optics->_safeAreaScreenWidthInPixels)/(2.0*rc.contentScaleFactor) - width;
    posY = gameTitleLabelAnchorPointsY + height;
    labelFrame = CGRectMake(posX, posY, width, height);
    clearButton.frame = labelFrame;
    clearButton.layer.borderWidth = buttonBorderWidth;
    clearButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [clearButton setTitle:[NSString stringWithFormat:@"Clear"] forState:UIControlStateNormal];
    [clearButton addTarget:self action:@selector(clearButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    clearButton.showsTouchWhenHighlighted = YES;
    clearButton.hidden = NO;
    [clearButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [clearButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    clearButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [puzzleView addSubview:clearButton];
    [puzzleView bringSubviewToFront:clearButton];

    
    //
    // gridSizeLabel
    //
//    width = 0.25*rc.screenWidthInPixels/rc.contentScaleFactor;
//    height = puzzleTitleLabelFontSize;
//    posX = (appd->optics->_puzzleScreenHorizontalOffsetInPixels +
//            appd->optics->_safeAreaScreenWidthInPixels)/(2.0*rc.contentScaleFactor) - width;
//    posY = gameTitleLabelAnchorPointsY;
//    labelFrame = CGRectMake(posX, posY, width, height);
//    gridSizeLabel = [[UILabel alloc] initWithFrame:labelFrame];
//    UIFont *gridSizeLabelFont = [UIFont fontWithName:@"PingFang SC Semibold" size:puzzleTitleLabelFontSize];
//    gridSizeLabel.text = [NSString stringWithFormat:@"Grid Size:"];
//    gridSizeLabel.textColor = [UIColor whiteColor];
//    gridSizeLabel.layer.borderWidth = 0.0;
//    [gridSizeLabel setFont:gridSizeLabelFont];
//    gridSizeLabel.textAlignment = NSTextAlignmentLeft;
//    [puzzleView addSubview:gridSizeLabel];
//    [puzzleView bringSubviewToFront:gridSizeLabel];

    //
    // gridSizeStepper
    //
    width = 0.15*rc.screenWidthInPixels/rc.contentScaleFactor;
    height = puzzleTitleLabelFontSize;
    posX = (appd->optics->_puzzleScreenHorizontalOffsetInPixels +
            appd->optics->_safeAreaScreenWidthInPixels)/(2.0*rc.contentScaleFactor);
    posY = gameTitleLabelAnchorPointsY + height;
    labelFrame = CGRectMake(posX, posY, width, height);
    gridSizeStepper = [[UIStepper alloc] initWithFrame:labelFrame];
    gridSizeStepper.continuous = NO;
    gridSizeStepper.autorepeat = NO;
    gridSizeStepper.wraps = NO;
    gridSizeStepper.backgroundColor = [UIColor whiteColor];
    gridSizeStepper.value = gridSizeStepperInitialValue;
    gridSizeStepper.minimumValue = kDefaultGridMinSizeX;
    gridSizeStepper.maximumValue = kDefaultGridMaxSizeX;
    gridSizeStepper.stepValue = 1;
    [gridSizeStepper addTarget:self action:@selector(gridSizeStepperPressed) forControlEvents:UIControlEventValueChanged];
    [puzzleView addSubview:gridSizeStepper];
    [puzzleView bringSubviewToFront:gridSizeStepper];

    //
    // todaysDateLabelPuzzle - exists but not added to view
    //
    width = 0.5*rc.screenWidthInPixels/rc.contentScaleFactor;
    height = todaysDateLabelFontSize;
    posX = gameTitleLabelAnchorPointsX;
    posY = posY + height*2.0;
    labelFrame = CGRectMake(posX, posY, width, height);
    todaysDateLabelPuzzle = [[UILabel alloc]initWithFrame:labelFrame];
    [todaysDateLabelPuzzle setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:todaysDateLabelFontSize]];
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateStyle:NSDateFormatterFullStyle];
    NSString *dateString = [formatter stringFromDate:date];
    todaysDateLabelPuzzle.text = dateString;
    todaysDateLabelPuzzle.textColor = [UIColor whiteColor];
    todaysDateLabelPuzzle.textAlignment = NSTextAlignmentLeft;
    todaysDateLabelPuzzle.hidden = NO;
//    [puzzleView addSubview:todaysDateLabelPuzzle];
//    [puzzleView bringSubviewToFront:todaysDateLabelPuzzle];
    
    //
    // numberOfPointsLabel - exists but not added to view
    //
    width = 0.25*rc.screenWidthInPixels/rc.contentScaleFactor;
    height = numberOfPointsLabelFontSize;
    posX = appd->optics->_tileHorizontalOffsetInPixels/rc.contentScaleFactor;
    posY = posY + height*2.0;
    labelFrame = CGRectMake(posX, posY, width, height);
    numberOfPointsLabel = [[UILabel alloc] initWithFrame:labelFrame];
    [numberOfPointsLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:numberOfPointsLabelFontSize]];
//    numberOfPointsLabel.text = [NSString stringWithFormat:@"Points: %d", [appd countTotalPoints]];
    numberOfPointsLabel.textColor = [UIColor whiteColor];
    numberOfPointsLabel.layer.borderWidth = 0.0;
    numberOfPointsLabel.textAlignment = NSTextAlignmentLeft;
//    [puzzleView addSubview:numberOfPointsLabel];
//    [puzzleView bringSubviewToFront:numberOfPointsLabel];
    
    //
    // numberOfPuzzlesLabel
    //
    width = 0.5*rc.screenWidthInPixels/rc.contentScaleFactor;
    height = puzzleTitleLabelFontSize;
    posX = (appd->optics->_puzzleScreenHorizontalOffsetInPixels +
            appd->optics->_safeAreaScreenWidthInPixels)/rc.contentScaleFactor - width;
    posY = gameTitleLabelAnchorPointsY;
    labelFrame = CGRectMake(posX, posY, width, height);
    numberOfPuzzlesLabel = [[UILabel alloc] initWithFrame:labelFrame];
    [numberOfPuzzlesLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:puzzleTitleLabelFontSize]];
    numberOfPuzzlesLabel.textColor = [UIColor whiteColor];
    numberOfPuzzlesLabel.layer.borderWidth = 0.0;
    numberOfPuzzlesLabel.textAlignment = NSTextAlignmentRight;
    [puzzleView addSubview:numberOfPuzzlesLabel];
    [puzzleView bringSubviewToFront:numberOfPuzzlesLabel];
    
    //
    // hintButton (use one hint to correctly position an unplaced tile)
    //
    hintButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [hintButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:hintButtonFontSize]];
    width = 0.4*rc.screenWidthInPixels/rc.contentScaleFactor;
    height = hintButtonFontSize;
    posX = (appd->optics->_puzzleScreenHorizontalOffsetInPixels +
            appd->optics->_safeAreaScreenWidthInPixels)/rc.contentScaleFactor - width;
    posY = gameTitleLabelAnchorPointsY;
    CGRect buttonRect = CGRectMake(posX, posY, width, height);
    hintButton.frame = buttonRect;
    hintButton.layer.borderWidth = buttonBorderWidth;
    hintButton.layer.borderColor = [UIColor cyanColor].CGColor;
    hintButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self setHintButtonLabel:appd.numberOfHintsRemaining];
    [hintButton addTarget:self action:@selector(hintButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    hintButton.showsTouchWhenHighlighted = YES;
    hintButton.hidden = [appd->optics allTilesArePlaced] || (rc.appCurrentGamePackType == PACKTYPE_DEMO);
    hintBulb.hidden = [appd->optics allTilesArePlaced] || (rc.appCurrentGamePackType == PACKTYPE_DEMO);
    [hintButton setTitleColor:[UIColor colorWithRed:251.0/255.0
                                              green:212.0/255.0
                                               blue:12.0/255.0
                                              alpha:1.0]
                                forState:UIControlStateNormal];
//    [hintButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    hintButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [self enableFlash:hintButton];
//    [puzzleView addSubview:hintButton];
//    [puzzleView bringSubviewToFront:hintButton];
    
    //
    // editPlayButton
    //
    editPlayButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [editPlayButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:prevHomeNextFontSize]];
    width = 0.25*rc.screenWidthInPixels/rc.contentScaleFactor;
    height = prevHomeNextFontSize*2.0;
    posX = gameTitleLabelAnchorPointsX;
    posY = gameTitleLabelAnchorPointsY + height;
    buttonRect = CGRectMake(posX, posY, width, height);
    editPlayButton.frame = buttonRect;
    editPlayButton.layer.borderWidth = buttonBorderWidth;
    editPlayButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [editPlayButton setTitle:[NSString stringWithFormat:@"Edit Mode"] forState:UIControlStateNormal];
    [editPlayButton addTarget:self action:@selector(editPlayButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    editPlayButton.showsTouchWhenHighlighted = YES;
    editPlayButton.hidden = NO;
    editPlayButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [editPlayButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [editPlayButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    if ([appd editModeIsEnabled])
        [[editPlayButton layer] setBackgroundColor:[UIColor blackColor].CGColor];
    else
        [[editPlayButton layer] setBackgroundColor:[UIColor blackColor].CGColor];
    [puzzleView addSubview:editPlayButton];
    
    //
    // duplicateButton
    //
    duplicateButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [duplicateButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:prevHomeNextFontSize]];
    width = 0.25*(appd->optics->_puzzleScreenHorizontalOffsetInPixels +
            appd->optics->_safeAreaScreenWidthInPixels)/rc.contentScaleFactor;
    height = prevHomeNextFontSize*2.0;
    posX = gameTitleLabelAnchorPointsX + width;
    posY = gameTitleLabelAnchorPointsY + height;
    buttonRect = CGRectMake(posX, posY, width, height);
    duplicateButton.frame = buttonRect;
    duplicateButton.layer.borderWidth = buttonBorderWidth;
    duplicateButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [duplicateButton setTitle:[NSString stringWithFormat:@"Copy"] forState:UIControlStateNormal];
    [duplicateButton addTarget:self action:@selector(duplicateButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    duplicateButton.showsTouchWhenHighlighted = YES;
    duplicateButton.hidden = NO;
    duplicateButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [duplicateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [duplicateButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    if ([appd editModeIsEnabled])
        [[duplicateButton layer] setBackgroundColor:[UIColor blackColor].CGColor];
    else
        [[duplicateButton layer] setBackgroundColor:[UIColor blackColor].CGColor];
    [puzzleView addSubview:duplicateButton];
    
    //
    // saveButton
    //
    saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [saveButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:prevHomeNextFontSize]];
    width = 0.25*rc.screenWidthInPixels/rc.contentScaleFactor;
    height = prevHomeNextFontSize*2.0;
    posX = gameTitleLabelAnchorPointsX + 2.0*width;
    posY = gameTitleLabelAnchorPointsY + height;
    buttonRect = CGRectMake(posX, posY, width, height);
    saveButton.frame = buttonRect;
    saveButton.layer.borderWidth = buttonBorderWidth;
    saveButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [saveButton setTitle:[NSString stringWithFormat:@"Save"] forState:UIControlStateNormal];
    [saveButton addTarget:self action:@selector(saveButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    saveButton.showsTouchWhenHighlighted = YES;
    saveButton.hidden = NO;
    saveButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [saveButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    if ([appd editModeIsEnabled])
        [[saveButton layer] setBackgroundColor:[UIColor blackColor].CGColor];
    else
        [[saveButton layer] setBackgroundColor:[UIColor blackColor].CGColor];
    [puzzleView addSubview:saveButton];
    
    //
    // deleteButton
    //
    deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    width = 0.25*rc.screenWidthInPixels/rc.contentScaleFactor;
    height = prevHomeNextFontSize*2.0;
    posX = (appd->optics->_puzzleScreenHorizontalOffsetInPixels +
            appd->optics->_safeAreaScreenWidthInPixels)/rc.contentScaleFactor - width;
    posY = gameTitleLabelAnchorPointsY + height;
    buttonRect = CGRectMake(posX, posY, width, height);
    deleteButton.frame = buttonRect;
    deleteButton.layer.borderWidth = buttonBorderWidth;
    deleteButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [deleteButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:prevHomeNextFontSize]];
    [deleteButton setTitle:[NSString stringWithFormat:@"Delete"] forState:UIControlStateNormal];
    [deleteButton addTarget:self action:@selector(deleteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    deleteButton.showsTouchWhenHighlighted = YES;
    deleteButton.hidden = NO;
    deleteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [deleteButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    if ([appd editModeIsEnabled])
        [[deleteButton layer] setBackgroundColor:[UIColor blackColor].CGColor];
    else
        [[deleteButton layer] setBackgroundColor:[UIColor blackColor].CGColor];
    [puzzleView addSubview:deleteButton];
    
    //
    // prevButton
    //
    prevButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [prevButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:prevHomeNextFontSize]];
    width = 0.2*rc.screenWidthInPixels/rc.contentScaleFactor;
    height = prevHomeNextFontSize;
    posX = (appd->optics->_puzzleScreenHorizontalOffsetInPixels)/rc.contentScaleFactor;
    posY = (CGFloat)(rc.safeFrame.origin.y + rc.safeFrame.size.height) - height*2.0;
    prevButtonRectEdit = CGRectMake(posX, posY, width, height);
    prevButtonRectPlay = CGRectMake(posX, posY, width, height);
    if ([appd editModeIsEnabled]){
        prevButton.frame = prevButtonRectEdit;
    }
    else {
        prevButton.frame = prevButtonRectPlay;
    }
    prevButton.layer.borderWidth = buttonBorderWidth;
    prevButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [prevButton setTitle:[NSString stringWithFormat:@"Prev"] forState:UIControlStateNormal];
    [prevButton addTarget:self action:@selector(prevButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    prevButton.showsTouchWhenHighlighted = YES;
    prevButton.hidden = NO;
    [prevButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [prevButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    prevButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [puzzleView addSubview:prevButton];
    [puzzleView bringSubviewToFront:prevButton];
    
    //
    // autoManualButton
    //
    autoManualButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [autoManualButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:prevHomeNextFontSize]];
    width = 0.2*rc.screenWidthInPixels/rc.contentScaleFactor;
    height = prevHomeNextFontSize;
    posX = (appd->optics->_puzzleScreenHorizontalOffsetInPixels)/rc.contentScaleFactor + width;
    posY = (CGFloat)(rc.safeFrame.origin.y + rc.safeFrame.size.height) - height*2.0;
    CGRect autoManualButtonRect = CGRectMake(posX, posY, width, height);
    autoManualButton.frame = autoManualButtonRect;
    autoManualButton.layer.borderWidth = buttonBorderWidth;
    autoManualButton.layer.borderColor = [UIColor whiteColor].CGColor;
    if ([appd autoGenIsEnabled]){
        [autoManualButton setTitle:[NSString stringWithFormat:@"Auto"] forState:UIControlStateNormal];
    }
    else {
        [autoManualButton setTitle:[NSString stringWithFormat:@"Manual"] forState:UIControlStateNormal];
    }
    [autoManualButton addTarget:self action:@selector(autoManualButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    autoManualButton.showsTouchWhenHighlighted = YES;
    autoManualButton.hidden = NO;
    [autoManualButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [autoManualButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    autoManualButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [puzzleView addSubview:autoManualButton];
    [puzzleView bringSubviewToFront:autoManualButton];
    
    //
    // backButton
    //
    backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:prevHomeNextFontSize]];
    // width unchanged
    // height unchanged
    // posY unchanged
    posX = 0.5*rc.screenWidthInPixels/rc.contentScaleFactor - width/2.0;
    posY = (CGFloat)(rc.safeFrame.origin.y + rc.safeFrame.size.height) - height*2.0;
    backButtonRectEdit = CGRectMake(posX, posY, width, height);
    backButtonRectPlay = CGRectMake(posX, posY, width, height);
    if ([appd editModeIsEnabled]){
        backButton.frame = backButtonRectEdit;
    }
    else {
        backButton.frame = backButtonRectPlay;
    }
    backButton.layer.borderWidth = buttonBorderWidth;
    backButton.layer.borderColor = [UIColor whiteColor].CGColor;
    if ([appd autoGenIsEnabled] == NO){
        [backButton setTitle:[NSString stringWithFormat:@"Back"]
                    forState:UIControlStateNormal];
    }
    else {
        [backButton setTitle:[NSString stringWithFormat:@"Gen"]
                    forState:UIControlStateNormal];
    }
    [backButton addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    backButton.showsTouchWhenHighlighted = YES;
    backButton.hidden = NO;
    [backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [backButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    [puzzleView addSubview:backButton];
    [puzzleView bringSubviewToFront:backButton];
    
    //
    // verifyButton
    //
    verifyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [verifyButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:prevHomeNextFontSize]];
    // width unchanged
    // height unchanged
    // posY unchanged
    posX = 0.5*rc.screenWidthInPixels/rc.contentScaleFactor + width/2.0;
    posY = (CGFloat)(rc.safeFrame.origin.y + rc.safeFrame.size.height) - height*2.0;
    backButtonRectEdit = CGRectMake(posX, posY, width, height);
    backButtonRectPlay = CGRectMake(posX, posY, width, height);
    if ([appd editModeIsEnabled]){
        verifyButton.frame = backButtonRectEdit;
    }
    else {
        verifyButton.frame = backButtonRectPlay;
    }
    verifyButton.layer.borderWidth = buttonBorderWidth;
    verifyButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [verifyButton setTitle:[NSString stringWithFormat:@"Verify"]
                forState:UIControlStateNormal];
    [verifyButton addTarget:self action:@selector(verifyButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    verifyButton.showsTouchWhenHighlighted = YES;
    verifyButton.hidden = NO;
    [verifyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [verifyButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    if (ENABLE_PUZZLE_VERIFY == YES){
        [puzzleView addSubview:verifyButton];
        [puzzleView bringSubviewToFront:verifyButton];
    }
    
    //
    // nextButton
    //
    nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [nextButton.titleLabel setFont:[UIFont fontWithName:@"PingFang SC Semibold" size:prevHomeNextFontSize]];
    // width unchanged
    // posY unchanged
    height = prevHomeNextFontSize;
    posX = (appd->optics->_puzzleScreenHorizontalOffsetInPixels +
            appd->optics->_safeAreaScreenWidthInPixels)/rc.contentScaleFactor - width;
    nextButtonRectPlay = CGRectMake(posX, posY, width, height);
    nextButtonRectEdit = CGRectMake(posX, posY, width, height);
    if ([appd editModeIsEnabled]){
        nextButton.frame = nextButtonRectEdit;
    }
    else {
        nextButton.frame = nextButtonRectPlay;
    }
    nextButton.layer.borderWidth = buttonBorderWidth;
    nextButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [nextButton setTitle:[NSString stringWithFormat:@"Next"] forState:UIControlStateNormal];
    [nextButton addTarget:self action:@selector(nextButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    nextButton.showsTouchWhenHighlighted = YES;
    nextButton.hidden = YES;
    nextArrow.hidden = YES;
    [nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [nextButton setTitleColor:[UIColor orangeColor] forState:UIControlStateHighlighted];
    nextButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [puzzleView addSubview:nextButton];
    [puzzleView bringSubviewToFront:nextButton];
    
    //
    // puzzleCompleteLabel
    //
    CGFloat puzzleCompleteLabelCenter = (0.5*rc.screenWidthInPixels)/rc.contentScaleFactor;
    CGFloat puzzleCompleteLabelWidth = (rc.screenWidthInPixels)/rc.contentScaleFactor;
    CGFloat puzzleCompleteLabelHeight = (0.3*rc.screenHeightInPixels)/rc.contentScaleFactor;
    puzzleCompleteLabelInitialFrame = CGRectMake(puzzleCompleteLabelCenter-puzzleCompleteLabelWidth/2, puzzleCompleteLabelAnchorPointsY-puzzleCompleteLabelHeight, puzzleCompleteLabelWidth, puzzleCompleteLabelHeight);
    // Set up the frame for the final position of puzzleCompleteLabel in normal puzzle play
    puzzleCompleteLabelFinalFrame = CGRectMake(puzzleCompleteLabelCenter-puzzleCompleteLabelWidth/2, rc.topPaddingInPoints+(0.4*rc.screenHeightInPixels)/rc.contentScaleFactor-puzzleCompleteLabelHeight/2, puzzleCompleteLabelWidth, puzzleCompleteLabelHeight);
    // Set up the frame for the final position of puzzleCompleteLabel in demo puzzle play
    switch (rc.displayAspectRatio) {
        case ASPECT_4_3:
            // iPad (9th generation)
        case ASPECT_10_7:
            // iPad Air (5th generation)
        case ASPECT_3_2: {
            // iPad Mini (6th generation)
            puzzleCompleteLabelDemoFinalFrame = CGRectMake(puzzleCompleteLabelCenter-puzzleCompleteLabelWidth/2, rc.topPaddingInPoints+(-0.015*rc.screenHeightInPixels)/rc.contentScaleFactor-puzzleCompleteLabelHeight/2, puzzleCompleteLabelWidth, puzzleCompleteLabelHeight);
            break;
        }
        case ASPECT_16_9: {
            // iPhone 8
            puzzleCompleteLabelDemoFinalFrame = CGRectMake(puzzleCompleteLabelCenter-puzzleCompleteLabelWidth/2, rc.topPaddingInPoints+(-0.015*rc.screenHeightInPixels)/rc.contentScaleFactor-puzzleCompleteLabelHeight/2, puzzleCompleteLabelWidth, puzzleCompleteLabelHeight);
            break;
        }
        default:
        case ASPECT_13_6: {
            // iPhone 14
            puzzleCompleteLabelDemoFinalFrame = CGRectMake(puzzleCompleteLabelCenter-puzzleCompleteLabelWidth/2, rc.topPaddingInPoints+(0.15*rc.screenHeightInPixels)/rc.contentScaleFactor-puzzleCompleteLabelHeight/2, puzzleCompleteLabelWidth, puzzleCompleteLabelHeight);
            break;
        }
    }
    puzzleCompleteLabel = [[UILabel alloc] initWithFrame:puzzleCompleteLabelInitialFrame];
    puzzleCompleteLabel.text = @"Puzzle Solved.";
    puzzleCompleteLabel.font = [UIFont fontWithName:@"PingFang SC Semibold" size:puzzleCompleteFontSize];
    puzzleCompleteLabel.adjustsFontSizeToFitWidth = NO;
    puzzleCompleteLabel.textColor = [UIColor whiteColor];
    puzzleCompleteLabel.textAlignment = NSTextAlignmentCenter;
    puzzleCompleteLabel.hidden = YES;
    [puzzleView addSubview:puzzleCompleteLabel];
    [puzzleView bringSubviewToFront:puzzleCompleteLabel];
}

- (void)removeButtonsAndLabels {
    // Remove puzzleTitleLabel
    if (puzzleTitleLabel != nil){
        [puzzleView sendSubviewToBack:puzzleTitleLabel];
        [puzzleTitleLabel removeFromSuperview];
    }
    
    // Remove numberOfPuzzlesLabel
    if (numberOfPuzzlesLabel != nil){
        [puzzleView sendSubviewToBack:numberOfPuzzlesLabel];
        [numberOfPuzzlesLabel removeFromSuperview];
    }
    
    // Remove numberOfPointsLabel
    if (numberOfPointsLabel != nil){
        [puzzleView sendSubviewToBack:numberOfPointsLabel];
        [numberOfPointsLabel removeFromSuperview];
    }
    
    // Remove hintButton
    if (hintButton != nil){
        [puzzleView sendSubviewToBack:hintButton];
        [hintButton removeFromSuperview];
    }
    
    // Remove todaysDateLabelPuzzle
    if (todaysDateLabelPuzzle != nil){
        [puzzleView sendSubviewToBack:todaysDateLabelPuzzle];
        [todaysDateLabelPuzzle removeFromSuperview];
    }
    
    // Remove deleteButton
    if (deleteButton != nil){
        [puzzleView sendSubviewToBack:deleteButton];
        [deleteButton removeFromSuperview];
    }
    
    // Remove duplicateButton
    if (duplicateButton != nil){
        [puzzleView sendSubviewToBack:duplicateButton];
        [duplicateButton removeFromSuperview];
    }
    
    // Remove saveButton
    if (saveButton != nil){
        [puzzleView sendSubviewToBack:saveButton];
        [saveButton removeFromSuperview];
    }
    
    // Remove nextButton
    if (nextButton != nil){
        [puzzleView sendSubviewToBack:nextButton];
        [nextButton removeFromSuperview];
    }
    
    // Remove nextArrow
    if (nextArrow != nil){
        [puzzleView sendSubviewToBack:nextArrow];
        [nextArrow removeFromSuperview];
    }
    
    // Remove prevButton
    if (prevButton != nil){
        [puzzleView sendSubviewToBack:prevButton];
        [prevButton removeFromSuperview];
    }
    
    // Remove prevArrowWhite
    if (prevArrowWhite != nil){
        [puzzleView sendSubviewToBack:prevArrowWhite];
        [prevArrowWhite removeFromSuperview];
    }
    
    // Remove homeArrow
    if (homeArrow != nil){
        [puzzleView sendSubviewToBack:homeArrow];
        [homeArrow removeFromSuperview];
    }
    
    // Remove autoManualButton
    if (autoManualButton != nil){
        [puzzleView sendSubviewToBack:autoManualButton];
        [autoManualButton removeFromSuperview];
    }
    
    // Remove backButton
    if (backButton != nil){
        [puzzleView sendSubviewToBack:backButton];
        [backButton removeFromSuperview];
    }
    
    // Remove puzzleSolvedView
    if (puzzleSolvedView != nil){
        [puzzleView sendSubviewToBack:puzzleSolvedView];
        [puzzleSolvedView removeFromSuperview];
    }
    
    // Remove puzzleCompleteLabel
    if (puzzleCompleteLabel != nil){
        [puzzleView sendSubviewToBack:puzzleCompleteLabel];
        [puzzleCompleteLabel removeFromSuperview];
    }
    
    // Remove hintButton
    if (hintButton != nil){
        [puzzleView sendSubviewToBack:hintButton];
        [hintButton removeFromSuperview];
    }
    
    // Remove hintBulb
    if (hintBulb != nil){
        [puzzleView sendSubviewToBack:hintBulb];
        [hintBulb removeFromSuperview];
    }
    
    // Remove puzzlePacksButton
    if (puzzlePacksButton != nil){
        [puzzleView sendSubviewToBack:puzzlePacksButton];
        [puzzlePacksButton removeFromSuperview];
    }
    
    // Remove helpButton
    if (helpButton != nil){
        [puzzleView sendSubviewToBack:helpButton];
        [helpButton removeFromSuperview];
    }
    
    // Remove settingsGearButton
    if (settingsGearButton != nil){
        [puzzleView sendSubviewToBack:settingsGearButton];
        [settingsGearButton removeFromSuperview];
    }
}

- (void)setHintButtonLabel:(unsigned int)hintsRemaining {
    if ([appd checkForEndlessHintsPurchased]){
        [hintButton setTitle:[NSString stringWithFormat:@"Endless Hints"] forState:UIControlStateNormal];
    }
    else {
        int numberOfHintsRemaining = [[appd getObjectFromDefaults:@"numberOfHintsRemaining"] intValue];
        if (numberOfHintsRemaining > 0){
            [hintButton setTitle:[NSString stringWithFormat:@"Hints %d", numberOfHintsRemaining] forState:UIControlStateNormal];
        }
        else {
            [hintButton setTitle:[NSString stringWithFormat:@"Get Hints"] forState:UIControlStateNormal];
        }
    }
}

- (void)enableFlash:(UIButton *)button {
    button.hidden = NO;
    button.alpha = 1.0f;
    [button setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithRed:251.0/255.0
                                              green:212.0/255.0
                                               blue:12.0/255.0
                                              alpha:1.0]
                                forState:UIControlStateNormal];
    button.layer.borderColor = [UIColor clearColor].CGColor;
    [UIView animateWithDuration:0.8 delay:0.0 options:
     UIViewAnimationOptionCurveEaseInOut |
     UIViewAnimationOptionRepeat |
     UIViewAnimationOptionAutoreverse |
     UIViewAnimationOptionAllowUserInteraction
                     animations:^{button.alpha = 0.1f;}
                     completion:^(BOOL finished){
    }];
}

- (void)disableFlash:(UIButton *)button {
    button.alpha = 1.0;
    [button.layer removeAllAnimations];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.layer.borderColor = [UIColor whiteColor].CGColor;
}

- (NSString *)fetchTodaysDateAsString {
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateStyle:NSDateFormatterFullStyle];
    NSString *dateString = [formatter stringFromDate:date];
    return dateString;
}

- (void)startNewPuzzleInCurrentPack {
    long startTime = [[NSNumber numberWithLong: [[NSDate date] timeIntervalSince1970]] integerValue];
    int currentPackNumber = -1;
    int currentPuzzleNumber = 0;
    currentPackNumber = [appd fetchCurrentPackNumber];
    currentPuzzleNumber = [appd fetchCurrentPuzzleNumber];
    NSMutableDictionary *emptyJewelCountDictionary = [appd buildEmptyJewelCountDictionary];
    [appd updatePuzzleScoresArray:currentPackNumber
                     puzzleNumber:currentPuzzleNumber
                   numberOfJewels:emptyJewelCountDictionary
                        startTime:startTime
                          endTime:-1
                           solved:NO];
    appd->optics = [Optics alloc];
    NSMutableDictionary *dict = [appd fetchCurrentPuzzleFromPackGameProgress:currentPackNumber];
    [appd->optics initWithDictionary:dict viewController:self];
}

- (void)startNewPuzzleFromDictionary:(unsigned int)puzzleNumber dictionaryName:(NSString *)name {
    if ([self queryPuzzleExists:name puzzle:puzzleNumber]) {
        // Choose the new puzzle and start game play
        unsigned int currentPackNumber = [appd fetchCurrentPackNumber];
        if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
            [appd saveDemoPuzzleNumber:puzzleNumber];
            appd->optics = [Optics alloc];
            NSMutableDictionary *currentGamePuzzleDictionary = [appd fetchGamePuzzle:currentPackNumber puzzleIndex:puzzleNumber];
            [appd->optics initWithDictionary:currentGamePuzzleDictionary viewController:self];
        }
        else if (rc.appCurrentGamePackType == PACKTYPE_DAILY) {
            [appd saveCurrentPuzzleNumber:puzzleNumber];
            long startTime = [[NSNumber numberWithLong: [[NSDate date] timeIntervalSince1970]] integerValue];
            int currentPackNumber = -1;
            int currentPuzzleNumber = 0;
            currentPackNumber = -1;
            currentPuzzleNumber = [appd fetchDailyPuzzleNumber];
            NSMutableDictionary *emptyJewelCountDictionary = [appd buildEmptyJewelCountDictionary];
            [appd updatePuzzleScoresArray:currentPackNumber
                             puzzleNumber:currentPuzzleNumber
                           numberOfJewels:emptyJewelCountDictionary
                                startTime:startTime
                                  endTime:-1
                                   solved:NO];
            appd->optics = [Optics alloc];
            NSMutableDictionary *currentGamePuzzleDictionary = [appd fetchGamePuzzle:currentPackNumber puzzleIndex:puzzleNumber];
            [appd->optics initWithDictionary:currentGamePuzzleDictionary viewController:self];
        }
    }
}

- (BOOL)appendGeneratedPuzzle {
    BOOL success = NO;
    NSMutableDictionary *pack = nil;
    pack = [appd fetchEditedPack];
    if (pack){
        NSMutableDictionary *puzzle = [NSMutableDictionary dictionaryWithCapacity:1];
        puzzle = [appd->optics encodeCurrentPuzzleAsMutableDictionary:puzzle];
        int currentIndex = [appd fetchEditedPuzzleIndexFromDefaults];
        if (currentIndex < 0){
            currentIndex = 0;
        }
        NSMutableArray *puzzleArray = [NSMutableArray arrayWithArray:[pack objectForKey:@"puzzles"]];
        if (puzzleArray){
            [puzzleArray addObject:puzzle];
        }
        [pack setObject:puzzleArray forKey:@"puzzles"];
        // Save to Defaults and fileManager
        success = [appd saveEditedPack:pack];
        // Update all buttons and labels
        [self displayButtonsAndLabels];
    }
    return success;
}

- (BOOL)saveCurrentEditedPuzzle {
    BOOL success = NO;
    NSMutableDictionary *pack = nil;
    pack = [appd fetchEditedPack];
    if (pack){
        NSMutableDictionary *puzzle = [NSMutableDictionary dictionaryWithCapacity:1];
        puzzle = [appd->optics encodeCurrentPuzzleAsMutableDictionary:puzzle];
        int currentIndex = [appd fetchEditedPuzzleIndexFromDefaults];
        if (currentIndex < 0){
            currentIndex = 0;
        }
        NSMutableArray *puzzleArray = [NSMutableArray arrayWithArray:[pack objectForKey:@"puzzles"]];
        if (puzzleArray){
            if ([puzzleArray count] == 0){
                [puzzleArray addObject:puzzle];
            }
            else if (currentIndex < [puzzleArray count]){
                [puzzleArray replaceObjectAtIndex:currentIndex withObject:puzzle];
            }
        }
        [pack setObject:puzzleArray forKey:@"puzzles"];
        // Save to Defaults and fileManager
        success = [appd saveEditedPack:pack];
        // Update all buttons and labels
        [self displayButtonsAndLabels];
    }
    return success;
}

- (void)nextPuzzle {
    NSString *dictionaryName = [[NSString alloc] init];
    switch (rc.appCurrentGamePackType) {
        case PACKTYPE_MAIN:{
            unsigned int nextPuzzleNumber = [appd fetchCurrentPuzzleNumberForPack:[appd fetchCurrentPackNumber]];
            if (nextPuzzleNumber <= [appd fetchCurrentPackLength]){
                [appd playMusicLoop:appd.loop2Player];
                [self setPuzzleLabel];
                [self startNewPuzzleInCurrentPack];
            }
            break;
        }
        case PACKTYPE_DEMO:{
            dictionaryName = @"demoPuzzlePackDictionary.plist";
            NSMutableDictionary *demoPuzzlePackDictionary = [appd fetchPackDictionaryFromPlist:dictionaryName];
            int maxGamePuzzle = [appd countPuzzlesWithinPack:demoPuzzlePackDictionary];
            int currentDemoPuzzleNumber = [appd fetchDemoPuzzleNumber];
            if (currentDemoPuzzleNumber <= maxGamePuzzle && [self queryPuzzleExists:dictionaryName puzzle:[appd fetchDemoPuzzleNumber]]) {
                [appd playMusicLoop:appd.loop3Player];
                [self setPuzzleLabel];
                [self startNewPuzzleFromDictionary:[appd fetchDemoPuzzleNumber] dictionaryName:dictionaryName];
                break;
            }
        }
        default:{
            break;
        }
    }
}

//
// Button Press and Gesture Handler Methods Go Here
//
- (void)settingsButtonPressed {
    [appd playSound:appd.tapPlayer];
    DLog("BMDPuzzleViewController.settingsButtonPressed");
    
    // Save progress before exiting
    [appd->optics savePuzzleProgressToDefaults];
    
    // If not yet solved then store endTime for timeSegment
    long endTime = [[NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970]] longValue];
    int currentPackNumber = -1;
    int currentPuzzleNumber = 0;
    NSMutableDictionary *emptyJewelCountDictionary = [appd buildEmptyJewelCountDictionary];
    if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
        currentPackNumber = [appd fetchCurrentPackNumber];
        currentPuzzleNumber = [appd fetchCurrentPuzzleNumber];
        if ([appd puzzleSolutionStatus:currentPackNumber
                          puzzleNumber:currentPuzzleNumber] == -1){
            [appd updatePuzzleScoresArray:currentPackNumber
                             puzzleNumber:currentPuzzleNumber
                           numberOfJewels:emptyJewelCountDictionary
                                startTime:-1        // Do not change startTime
                                  endTime:endTime
                                   solved:NO];
        }
    }
    else if (rc.appCurrentGamePackType == PACKTYPE_DAILY) {
        currentPackNumber = -1;
        currentPuzzleNumber = [appd fetchDailyPuzzleNumber];
        if ([appd puzzleSolutionStatus:currentPackNumber
                          puzzleNumber:currentPuzzleNumber] == -1){
            [appd updatePuzzleScoresArray:currentPackNumber
                             puzzleNumber:currentPuzzleNumber
                           numberOfJewels:emptyJewelCountDictionary
                                startTime:-1        // Do not change startTime
                                  endTime:endTime
                                   solved:NO];
        }
    }
    
    // Pause loop2Player
    [appd.loop2Player pause];

    // Transfer control to settingsViewController
    rc.settingsViewController = [[BMDSettingsViewController alloc] init];
    [self addChildViewController:rc.settingsViewController];
    [self.view addSubview:rc.settingsViewController.view];
    [rc.settingsViewController didMoveToParentViewController:self];
}

- (void)morePuzzlePacksButtonPressed {
    [appd playSound:appd.tapPlayer];
    DLog("BMDPuzzleViewController.morePuzzlePacksButtonPressed");
    
    // Save progress before exiting
    [appd->optics savePuzzleProgressToDefaults];
    
    // If not yet solved then store endTime for timeSegment
    long endTime = [[NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970]] longValue];
    int currentPackNumber = -1;
    int currentPuzzleNumber = 0;
    NSMutableDictionary *emptyJewelCountDictionary = [appd buildEmptyJewelCountDictionary];
    if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
        currentPackNumber = [appd fetchCurrentPackNumber];
        currentPuzzleNumber = [appd fetchCurrentPuzzleNumber];
        if ([appd puzzleSolutionStatus:currentPackNumber
                          puzzleNumber:currentPuzzleNumber] == -1){
            [appd updatePuzzleScoresArray:currentPackNumber
                             puzzleNumber:currentPuzzleNumber
                           numberOfJewels:emptyJewelCountDictionary
                                startTime:-1        // Do not change startTime
                                  endTime:endTime
                                   solved:NO];
        }
    }
    else if (rc.appCurrentGamePackType == PACKTYPE_DAILY) {
        currentPackNumber = -1;
        currentPuzzleNumber = [appd fetchDailyPuzzleNumber];
        if ([appd puzzleSolutionStatus:currentPackNumber
                          puzzleNumber:currentPuzzleNumber] == -1){
            [appd updatePuzzleScoresArray:currentPackNumber
                             puzzleNumber:currentPuzzleNumber
                           numberOfJewels:emptyJewelCountDictionary
                                startTime:-1        // Do not change startTime
                                  endTime:endTime
                                   solved:NO];
        }
    }
    
    // Pause loop2Player
    [appd.loop2Player pause];

    // Transfer control to settingsViewController
    rc.packsViewController = [[BMDPacksViewController alloc] init];
    [self addChildViewController:rc.packsViewController];
    [self.view addSubview:rc.packsViewController.view];
    [rc.packsViewController didMoveToParentViewController:self];
}

- (void)nextButtonPressed {
    [appd playSound:appd.tapPlayer];
    // Puzzle Editor
    if ([appd editModeIsEnabled]){
        // Save the current puzzle before switching to the next puzzle in the pack
        [self saveCurrentEditedPuzzle];
        
        // Fetch the pack that was just saved
        int index = [appd fetchEditedPuzzleIndexFromDefaults];
        if (index < 0){
            index = 0;
        }
        NSMutableDictionary *pack = nil;
        pack = [appd fetchEditedPack];
        if (pack){
            NSMutableDictionary *puzzle = nil;
            NSMutableArray *puzzleArray = [NSMutableArray arrayWithArray:[pack objectForKey:@"puzzles"]];
            if (index < [puzzleArray count]){
                index++;
                if (index >= [puzzleArray count]){
                    index = (int)[puzzleArray count]-1;
                }
                puzzle = [puzzleArray objectAtIndex:index];
                if (puzzle != nil){
                    [appd saveEditedPuzzleIndexToDefaults:index];
                    appd->optics = [Optics alloc];
                    [appd->optics initWithDictionary:puzzle viewController:self];
                }
            }
        }
    }
    // PACKTYPE_DEMO
    else if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
        self->appd->optics->puzzleHasBeenCompletedCelebration = NO;
        self.puzzleSolvedView.hidden = YES;
        self->homeArrowWhite.hidden = YES;
        self->replayIconWhite.hidden = YES;
        
        if (![appd packHasBeenCompleted]){
            [self->appd->optics saveNextPuzzleToDefaults];
            [self nextPuzzle];
        }
        else {
            self->nextArrow.hidden = YES;
        }
    }
    // PACKTYPE_DAILY and PACKTYPE_MAIN
    else {
        self->appd->optics->puzzleHasBeenCompletedCelebration = NO;
        [self->appd->optics dropAllTilesOffScreen];
        
        nextArrow.enabled = NO;
        replayIconWhite.enabled = NO;
        homeArrowWhite.enabled = NO;
        
        NSTimeInterval delayTime = 1.0;
        NSTimer *timer = [NSTimer timerWithTimeInterval:delayTime repeats:NO block:^(NSTimer *time){
            self.puzzleSolvedView.hidden = YES;
            NSString *adFree = [self->appd getObjectFromDefaults:@"AD_FREE_PUZZLES"];
            if (![adFree isEqualToString:@"YES"] &&
                self->rc.appCurrentGamePackType != PACKTYPE_DEMO){
                [self->puzzleView addSubview:self->rc.bannerAdView];
                [self->puzzleView bringSubviewToFront:self->rc.bannerAdView];
            }
            unsigned int currentPack = 0, currentPuzzleNumber = 0, currentPackLength = 0;
            if (self->rc.appCurrentGamePackType == PACKTYPE_MAIN){
                currentPack = [self->appd fetchCurrentPackNumber];
                currentPuzzleNumber = [self->appd fetchCurrentPuzzleNumberForPack:currentPack];
            }
            else if (self->rc.appCurrentGamePackType == PACKTYPE_DEMO){
                currentPuzzleNumber = [self->appd fetchDemoPuzzleNumber];
            }
            else {
                DLog("nextButton should not be visible, and yet here we are 1.");
            }
            currentPackLength = [self->appd fetchCurrentPackLength];
            if (currentPuzzleNumber < currentPackLength){
                [self nextPuzzle];
            }
            else {
                DLog("nextButton should not be visible, and yet here we are 2.");
            }
            self->nextButton.hidden = YES;
            self->nextArrow.hidden = YES;
            self->homeArrowWhite.hidden = YES;
            self->replayIconWhite.hidden = YES;
            
            self->nextArrow.enabled = YES;
            self->replayIconWhite.enabled = YES;
            self->homeArrowWhite.enabled = YES;

        }];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    }
}

- (void)prevButtonPressed {
    [appd playSound:appd.tapPlayer];
    DLog("prevButtonPressed");
    if ([appd editModeIsEnabled] && rc.appCurrentGamePackType == PACKTYPE_EDITOR){
        // Save the current puzzle before switching to the prev
        [self saveCurrentEditedPuzzle];
        NSMutableDictionary *pack = nil;
        pack = [appd fetchEditedPack];
        int index = [appd fetchEditedPuzzleIndexFromDefaults];
        if (index > 0){
            if (pack){
                NSMutableArray *puzzleArray = [NSMutableArray arrayWithArray:[pack objectForKey:@"puzzles"]];
                if (index < [puzzleArray count]){
                    index--;
                    if (index < 0){
                        index = 0;
                    }
                    NSMutableDictionary *puzzle = nil;
                    puzzle = [puzzleArray objectAtIndex:index];
                    if (puzzle != nil){
                        [appd saveEditedPuzzleIndexToDefaults:index];
                        appd->optics = [Optics alloc];
                        [appd->optics initWithDictionary:puzzle viewController:self];
                    }
                }
            }
        }
    }
    else if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
        DLog("previous puzzle");
        unsigned int demoPuzzleNumber = [appd fetchDemoPuzzleNumber];
        NSMutableDictionary *puzzle = nil;
        if (demoPuzzleNumber > 0){
            demoPuzzleNumber--;
            if ([self queryPuzzleExists:kDemoPuzzlePackDictionary puzzle:demoPuzzleNumber]){
                puzzle = [appd fetchGamePuzzle:0 puzzleIndex:demoPuzzleNumber];
                if (puzzle != nil){
                    if (demoPuzzleNumber > 0){
                        prevArrowWhite.hidden = NO;
                    }
                    else {
                        prevArrowWhite.hidden = YES;
                    }
                    [appd saveDemoPuzzleNumber:demoPuzzleNumber];
                    appd->optics = [Optics alloc];
                    [appd->optics initWithDictionary:puzzle viewController:self];
                }
            }
        }
    }
}

- (void)verifyPuzzles {
    DLog("verifyPuzzles");
    NSMutableArray *puzzlePacksArray = nil, *puzzleArray = nil, *arrayOfFailingPuzzles;
    NSMutableDictionary *packDictionary = nil, *puzzleDictionary = nil;
    NSMutableDictionary *puzzleToVerify;
    unsigned int packIndex = 0, puzzleIndex = 0;
    if (appd.gameDictionaries != nil){
        // Verify all puzzles in puzzlePacksArray.plist
        puzzlePacksArray = [appd.gameDictionaries objectForKey:kPuzzlePacksArray];
        if (puzzlePacksArray != nil && [puzzlePacksArray count] > 0){
            NSEnumerator *puzzlePacksArrayEnum = [puzzlePacksArray objectEnumerator];
            arrayOfFailingPuzzles = [NSMutableArray arrayWithCapacity:1];
            while (packDictionary = [puzzlePacksArrayEnum nextObject]){
                if (packDictionary != nil && [packDictionary count] > 0){
                    puzzleArray = [packDictionary objectForKey:@"puzzles"];
                    if (puzzleArray != nil && [puzzleArray count] > 0){
                        NSEnumerator *puzzleArrayEnum = [puzzleArray objectEnumerator];
                        puzzleIndex = 0;
                        while (puzzleDictionary = [puzzleArrayEnum nextObject]){
                            if (puzzleDictionary != nil && [puzzleDictionary count] > 0){
                                puzzleToVerify = [NSMutableDictionary dictionaryWithDictionary:puzzleDictionary];
                                appd->optics = [Optics alloc];
                                BOOL puzzleValid = [appd->optics initWithDictionary:puzzleToVerify viewController:self];
                                if (!puzzleValid){
                                    DLog("Pack: %d. Puzzle: %d NOT valid", packIndex, puzzleIndex);
                                    [puzzleToVerify setObject:[NSNumber numberWithInt:packIndex] forKey:@"packIndex"];
                                    [puzzleToVerify setObject:[NSNumber numberWithInt:puzzleIndex] forKey:@"puzzleIndex"];
                                    [arrayOfFailingPuzzles addObject:puzzleToVerify];
                                }
                            }
                            puzzleIndex++;
                        }
                    }
                }
                packIndex++;
            }
        }
        // Verify all puzzles in dailyPuzzlePacksDictionary.plist
        packDictionary = nil;
        puzzleArray = nil;
        puzzleDictionary = nil;
        packDictionary = [appd fetchPackDictionaryFromPlist:kDailyPuzzlesPackDictionary];
        if (packDictionary != nil && [packDictionary count] > 0){
            puzzleArray = [packDictionary objectForKey:@"puzzles"];
            if (puzzleArray != nil && [puzzleArray count] > 0){
                NSEnumerator *puzzleArrayEnum = [puzzleArray objectEnumerator];
                puzzleIndex = 0;
                while (puzzleDictionary = [puzzleArrayEnum nextObject]){
                    if (puzzleDictionary != nil && [puzzleDictionary count] > 0){
                        puzzleToVerify = [NSMutableDictionary dictionaryWithDictionary:puzzleDictionary];
                        appd->optics = [Optics alloc];
                        BOOL puzzleValid = [appd->optics initWithDictionary:puzzleToVerify viewController:self];
                        if (!puzzleValid){
                            DLog("Daily Puzzle: %d NOT valid", puzzleIndex);
                            [puzzleToVerify setObject:[NSNumber numberWithInt:puzzleIndex] forKey:@"dailyPuzzleIndex"];
                            [arrayOfFailingPuzzles addObject:puzzleToVerify];
                        }
                    }
                    puzzleIndex++;
                }
                if ([arrayOfFailingPuzzles count] > 0){
                    NSMutableDictionary *failedPuzzleDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
                    [failedPuzzleDictionary setObject:@"Failed Puzzles" forKey:@"pack_name"];
                    [failedPuzzleDictionary setObject:[NSNumber numberWithInt:0] forKey:@"AppStorePackCost"];
                    [failedPuzzleDictionary setObject:arrayOfFailingPuzzles forKey:@"puzzles"];
                    [appd savePuzzlePackDictionaryToFile:failedPuzzleDictionary fileName:@"failedPuzzleDictionary.plist"];
                }
                else {
                    DLog("All puzzles are correctly formed.");
                }
            }
        }
    }
}

- (void)autoGeneratePuzzle {
    id batchStartTag1 = [puzzleDictionary objectForKey:@"batchStart1"];
    id batchEndTag1 = [puzzleDictionary objectForKey:@"batchEnd1"];
    id batchStartTag2 = [puzzleDictionary objectForKey:@"batchStart2"];
    id batchEndTag2 = [puzzleDictionary objectForKey:@"batchEnd2"];

    if (batchStartTag1 == nil && batchEndTag1 == nil &&
        batchStartTag2 == nil && batchEndTag2 == nil){
        
        // If the puzzle currently being edited is not empty then use it
        // as the starting point for puzzle generation
        NSMutableDictionary *currentPuzzle = [NSMutableDictionary dictionaryWithCapacity:1];
        currentPuzzle = [appd->optics encodeCurrentPuzzleAsMutableDictionary:currentPuzzle];
        BOOL usingExistingPuzzle = [[currentPuzzle objectForKey:@"arrayOfLasersDictionaries"] count] > 0;
        if (usingExistingPuzzle){
            puzzleDictionary = [NSMutableDictionary dictionaryWithDictionary:currentPuzzle];
        }
        else {
            // Initialize an empty puzzleDictionary
            puzzleDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
        }
        
    
        // Enter batch processing parameters
        //
        // Game Grid Size
        if (!usingExistingPuzzle){
            [puzzleDictionary setObject:[NSNumber numberWithInt:gridSizeStepper.value] forKey:@"gridSizeX"];
            [puzzleDictionary setObject:[NSNumber numberWithInt:
                                         [self gridSizeYfromGridSizeX:gridSizeStepper.value]
                                        ] forKey:@"gridSizeY"];
        }
        //
        // Beams
        if (!usingExistingPuzzle){
            [puzzleDictionary setObject:[NSNumber numberWithInt:1] forKey:@"redBeam"];
            [puzzleDictionary setObject:[NSNumber numberWithInt:0] forKey:@"greenBeam"];
            [puzzleDictionary setObject:[NSNumber numberWithInt:0] forKey:@"blueBeam"];
        }
        //
        // Splitters
        [puzzleDictionary setObject:[NSNumber numberWithInt:0] forKey:@"redSplitterCount"];
        [puzzleDictionary setObject:[NSNumber numberWithInt:0] forKey:@"greenSplitterCount"];
        [puzzleDictionary setObject:[NSNumber numberWithInt:0] forKey:@"blueSplitterCount"];
        //
        // Mirrors
        [puzzleDictionary setObject:[NSNumber numberWithInt:4] forKey:@"redMirrorCount"];
        [puzzleDictionary setObject:[NSNumber numberWithInt:0] forKey:@"greenMirrorCount"];
        [puzzleDictionary setObject:[NSNumber numberWithInt:0] forKey:@"blueMirrorCount"];
        //
        // Opaque Tiles
        [puzzleDictionary setObject:[NSNumber numberWithInt:1] forKey:@"opaqueTiles"];
        //
        // Translucent Tiles
        [puzzleDictionary setObject:[NSNumber numberWithInt:0] forKey:@"translucentTiles"];
        //
        // Puzzle Generation Count
        [puzzleDictionary setObject:[NSNumber numberWithInt:5] forKey:@"generationCount"];

        // Run a set of batch commands
        [puzzleDictionary setObject:[NSNumber numberWithInt:1] forKey:@"batchStart1"];
        appd->optics = [Optics alloc];
        [appd->optics initWithDictionary:puzzleDictionary viewController:self];
    }
    else if (batchStartTag2 != nil && batchEndTag2 != nil){
        [puzzleDictionary removeObjectForKey:@"batchStart2"];
        [puzzleDictionary removeObjectForKey:@"batchEnd2"];
        appd->optics = [Optics alloc];
        [appd->optics initWithDictionary:puzzleDictionary viewController:self];
    }
}

- (void)replayIconPressed {
    [appd->optics savePreviousPuzzleToDefaults];
    
    // Update puzzle startTime tracking
    long startTime = [[NSNumber numberWithLong: [[NSDate date] timeIntervalSince1970]] integerValue];
    int currentPackNumber = -1;
    int currentPuzzleNumber = 0;
    NSMutableDictionary *emptyJewelCountDictionary = [appd buildEmptyJewelCountDictionary];
    if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
        currentPackNumber = [appd fetchCurrentPackNumber];
        currentPuzzleNumber = [appd fetchCurrentPuzzleNumber];
        [appd updatePuzzleScoresArray:currentPackNumber
                         puzzleNumber:currentPuzzleNumber
                       numberOfJewels:emptyJewelCountDictionary
                            startTime:startTime
                              endTime:-1
                               solved:NO];
    }
    else if (rc.appCurrentGamePackType == PACKTYPE_DAILY) {
        currentPackNumber = -1;
        currentPuzzleNumber = [appd fetchDailyPuzzleNumber];
        [appd updatePuzzleScoresArray:currentPackNumber
                         puzzleNumber:currentPuzzleNumber
                       numberOfJewels:emptyJewelCountDictionary
                            startTime:startTime
                              endTime:-1
                               solved:NO];
    }

    // Create replayPuzzleDictionary and begin the Puzzle
    NSMutableDictionary *replayPuzzleDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
    replayPuzzleDictionary = [appd->optics resetPuzzleDictionary:self.inputPuzzleDictionary];
    DLog("replayIconPressed");
    appd->optics = [Optics alloc];
    [appd->optics initWithDictionary:replayPuzzleDictionary viewController:self];
}

- (void)backButtonPressed {
    [appd playSound:appd.tapPlayer];
    // In autoGen the backButton generates new Puzzles
        
    if ([appd autoGenIsEnabled] == YES){
        [self autoGeneratePuzzle];
     }

    // Otherwise the usual backButton functionality
    else {
        [appd playSound:appd.tapPlayer];
        
        
        // Save progress before exiting only if the puzzle has not been completed
        if ([appd->optics queryPuzzleCompleted] == NO){
            [appd->optics savePuzzleProgressToDefaults];
        }
        
        // If exiting How to Play Guide then indicate that demo has been completed
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@"YES" forKey:@"demoHasBeenCompleted"];
        
        // If not yet solved then store endTime for timeSegment
        long endTime = [[NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970]] longValue];
        int currentPackNumber = -1;
        int currentPuzzleNumber = 0;
        NSMutableDictionary *emptyJewelCountDictionary = [appd buildEmptyJewelCountDictionary];
        if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
            currentPackNumber = [appd fetchCurrentPackNumber];
            currentPuzzleNumber = [appd fetchCurrentPuzzleNumber];
            if ([appd puzzleSolutionStatus:currentPackNumber
                              puzzleNumber:currentPuzzleNumber] == -1){
                // Only puzzleSolutionStatus if Unsolved
                [appd updatePuzzleScoresArray:currentPackNumber
                                 puzzleNumber:currentPuzzleNumber
                               numberOfJewels:emptyJewelCountDictionary
                                    startTime:-1        // Do not change startTime
                                      endTime:endTime
                                       solved:NO];
            }
        }
        else if (rc.appCurrentGamePackType == PACKTYPE_DAILY) {
            currentPackNumber = -1;
            currentPuzzleNumber = [appd fetchDailyPuzzleNumber];
            if ([appd puzzleSolutionStatus:currentPackNumber
                              puzzleNumber:currentPuzzleNumber] == -1){
                // Only puzzleSolutionStatus if Unsolved
                [appd updatePuzzleScoresArray:currentPackNumber
                                 puzzleNumber:currentPuzzleNumber
                               numberOfJewels:emptyJewelCountDictionary
                                    startTime:-1        // Do not change startTime
                                      endTime:endTime
                                       solved:NO];
            }
        }
        
        
        
        if ([self.parentViewController isKindOfClass:[BMDViewController class]]){
            DLog("backButtonPressed parentViewController is BMDViewController");
            [puzzleView releaseDrawables];
            [self willMoveToParentViewController:self.parentViewController];
            [puzzleView removeFromSuperview];
            [self removeFromParentViewController];
            rc.renderPuzzleON = NO;
            rc.renderOverlayON = NO;
            [rc refreshHomeView];
            [rc loadAppropriateSizeBannerAd];
            [rc startMainScreenMusicLoop];
        }
        else {
            DLog("backButtonPressed parentViewController is unknown");
            puzzleView.paused = YES;
            [puzzleView releaseDrawables];
            [self willMoveToParentViewController:self.parentViewController];
            [puzzleView removeFromSuperview];
            [self removeFromParentViewController];
            rc.renderPuzzleON = NO;
            rc.renderOverlayON = NO;
        }
        
        // Always switch to PACKTYPE_MAIN when leaving BMDPuzzleViewController
        rc.appCurrentGamePackType = PACKTYPE_MAIN;
        [rc refreshHomeView];
        
//        if ([appd packHasBeenCompleted]){
//            // Pack is complete
//            if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
//                rc.appCurrentGamePackType = PACKTYPE_MAIN;
//            }
//        }

    }
}

- (void)verifyButtonPressed {
    DLog("verifyButtonPressed");
    [self verifyPuzzles];
}

- (void)saveButtonPressed {
    DLog("saveButtonPressed");
    [self saveCurrentEditedPuzzle];
}

- (void)autoManualButtonPressed {
    if (FORCE_PUZZLE_EDITOR_AUTOGEN == YES){
        [appd setObjectInDefaults:@"YES" forKey:@"autoGenEnabled"];
        [autoManualButton setTitle:[NSString stringWithFormat:@"Auto"] forState:UIControlStateNormal];
        [backButton setTitle:[NSString stringWithFormat:@"Gen"] forState:UIControlStateNormal];
    }
    else {
        // Currently in ManGen mode,switch to AutoGen mode
        if ([appd autoGenIsEnabled] == NO){
            // Puzzle Auto Generation Mode
            [appd setObjectInDefaults:@"YES" forKey:@"autoGenEnabled"];
            [autoManualButton setTitle:[NSString stringWithFormat:@"Auto"] forState:UIControlStateNormal];
            [backButton setTitle:[NSString stringWithFormat:@"Gen"] forState:UIControlStateNormal];
        }
        // Currently in AutoGen mode, switch to ManGen mode and activate editMode
        else {
            // Puzzle Manual Generation Mode
            [appd setObjectInDefaults:@"NO" forKey:@"autoGenEnabled"];
            [autoManualButton setTitle:[NSString stringWithFormat:@"Manual"] forState:UIControlStateNormal];
            [backButton setTitle:[NSString stringWithFormat:@"Back"] forState:UIControlStateNormal];
        }
    }
    [appd playSound:appd.tapPlayer];
}

- (void)editPlayButtonPressed {
    // Currently in Edit Mode, switch to Play Mode
    if ([appd editModeIsEnabled]){
        // Switch to Play Mode
        [appd setObjectInDefaults:@"NO" forKey:@"editModeEnabled"];
        [editPlayButton setTitle:[NSString stringWithFormat:@"Play Mode"] forState:UIControlStateNormal];
        // Save the current puzzle
        [self saveCurrentEditedPuzzle];
        // Now get ready to Play
        NSMutableDictionary *puzzle = [NSMutableDictionary dictionaryWithCapacity:1];
        puzzle = [appd->optics encodeCurrentPuzzleAsMutableDictionary:puzzle];
        appd->optics->puzzleViewControllerObjectsInitialized = NO;
        appd->optics = [Optics alloc];
        [appd->optics initWithDictionary:puzzle viewController:self];
    }
    // Currently in Play Mode, switch to Edit Mode
    else {
        [appd setObjectInDefaults:@"YES" forKey:@"editModeEnabled"];
        [editPlayButton setTitle:[NSString stringWithFormat:@"Edit Mode"] forState:UIControlStateNormal];
        NSMutableDictionary *pack = [appd fetchEditedPack];
        if (pack){
            int puzzleIndex = [appd fetchEditedPuzzleIndexFromDefaults];
            if (puzzleIndex < 0){
                puzzleIndex = 0;
            }
            NSMutableArray *puzzleArray = [NSMutableArray arrayWithArray:[pack objectForKey:@"puzzles"]];
            NSMutableDictionary *puzzle = [NSMutableDictionary dictionaryWithCapacity:1];
            if ([puzzleArray count] != 0){
                puzzle = [puzzleArray objectAtIndex:puzzleIndex];
            }
            appd->optics = [Optics alloc];
            [appd->optics initWithDictionary:puzzle viewController:self];
        }
    }
    [appd playSound:appd.tapPlayer];
}

- (void)clearButtonPressed {
    // Replace the current puzzle with an empty puzzle
    DLog("clearButtonPressed");
    if ([appd editModeIsEnabled] && rc.appCurrentGamePackType == PACKTYPE_EDITOR){
        NSMutableDictionary *pack = nil;
        pack = [appd fetchEditedPack];
        if (pack){
            int currentIndex = [appd fetchEditedPuzzleIndexFromDefaults];
            if (currentIndex < 0){
                currentIndex = 0;
            }
            // Return an empty puzzle encoded as an NSMutableDictionary
            NSMutableDictionary *puzzle = [NSMutableDictionary dictionaryWithCapacity:1];
            puzzle = [appd->optics encodeAnEmptyPuzzleAsMutableDictionary:puzzle];
            if (puzzle){
                // Replace the current puzzle with an empty puzzle
                NSMutableArray *puzzleArray = [NSMutableArray arrayWithArray:[pack objectForKey:@"puzzles"]];
                if ([puzzleArray count] > 0){
                    [puzzleArray replaceObjectAtIndex:currentIndex withObject:puzzle];
                    [pack setObject:puzzleArray forKey:@"puzzles"];
                    // Save the pack to Defaults and the fileManager
                    [appd saveEditedPack:pack];
                    // Restart the PE with a new pack and puzzle
                    appd->optics = [Optics alloc];
                    [appd->optics initWithDictionary:puzzle viewController:self];
                }
            }
        }
    }
}

- (void)duplicateButtonPressed {
    // Make a copy of the current puzzle and insert the copy into the array of puzzles just before the current puzzle
    DLog("duplicateButtonPressed");
    if ([appd editModeIsEnabled] && rc.appCurrentGamePackType == PACKTYPE_EDITOR){
        NSMutableDictionary *pack = nil;
        pack = [appd fetchEditedPack];
        if (pack){
            int currentIndex = [appd fetchEditedPuzzleIndexFromDefaults];
            if (currentIndex < 0){
                currentIndex = 0;
            }
            // Return the current puzzle encoded as an NSMutableDictionary
            NSMutableDictionary *puzzle = [NSMutableDictionary dictionaryWithCapacity:1];
            puzzle = [appd->optics encodeCurrentPuzzleAsMutableDictionary:puzzle];
            if (puzzle){
                // Insert the puzzle into the array of puzzles in the pack
                NSMutableArray *puzzleArray = [NSMutableArray arrayWithArray:[pack objectForKey:@"puzzles"]];
                if (puzzleArray){
                    [puzzleArray insertObject:puzzle atIndex:currentIndex];
                    [pack setObject:puzzleArray forKey:@"puzzles"];
                    // Save the pack to Defaults and the fileManager
                    [appd saveEditedPack:pack];
                    // Restart the PE with a new pack and puzzle
                    appd->optics = [Optics alloc];
                    [appd->optics initWithDictionary:puzzle viewController:self];
                }
            }
        }
    }
}

- (void)deleteButtonPressed {
    // Delete the current puzzle from the array within the pack and restart PE
    DLog("deleteButtonPressed");
    if ([appd editModeIsEnabled] && rc.appCurrentGamePackType == PACKTYPE_EDITOR){
        NSMutableDictionary *pack = nil;
        pack = [appd fetchEditedPack];
        if (pack){
            int currentIndex = [appd fetchEditedPuzzleIndexFromDefaults];
            if (currentIndex < 0){
                currentIndex = 0;
            }
            // Access the puzzle array within pack
            NSMutableArray *puzzleArray = [NSMutableArray arrayWithArray:[pack objectForKey:@"puzzles"]];
            if (puzzleArray){
                if ([puzzleArray count] > 0){
                    // Delete the current puzzle from the array of puzzles in the pack
                    [puzzleArray removeObjectAtIndex:currentIndex];
                    // Update the puzzleArray within pack
                    [pack setObject:puzzleArray forKey:@"puzzles"];
                    // Save the pack to Defaults and the fileManager
                    [appd saveEditedPack:pack];
                    // Save the current edited puzzle index
                    if ([puzzleArray count] == 0){
                        currentIndex = 0;
                    }
                    else {
                        currentIndex--;
                        if (currentIndex < 0){
                            currentIndex = 0;
                        }
                    }
                    [appd saveEditedPuzzleIndexToDefaults:currentIndex];
                    
                    // Restart PE with existing puzzle or nil if all edited puzzles deleted
                    NSMutableDictionary *puzzle = [NSMutableDictionary dictionaryWithCapacity:1];
                    if ([puzzleArray count] != 0){
                        puzzle = [puzzleArray objectAtIndex:currentIndex];
                    }
                    appd->optics = [Optics alloc];
                    [appd->optics initWithDictionary:puzzle viewController:self];
                }
           }
        }
    }
}

- (void)hintButtonPressed {
    [appd playSound:appd.tapPlayer];
    appd.numberOfHintsRemaining = [[appd getObjectFromDefaults:@"numberOfHintsRemaining"] intValue];
    
    if (ENABLE_GA == YES){
        int currentPackNumber = [appd fetchCurrentPackNumber];
        int currentPuzzleNumber = [appd fetchCurrentPuzzleNumber];
        [FIRAnalytics logEventWithName:@"hintButtonPressed"
                            parameters:@{
            @"hintsRemaining":@(appd.numberOfHintsRemaining),
            @"packNumber":@(currentPackNumber),
            @"puzzleNumber":@(currentPuzzleNumber)
        }];
    }

    
    if ([appd checkForEndlessHintsPurchased]){
        [appd->optics startPositionTileForHint];
        [appd playSound:appd.tapPlayer];
    }
    else if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
        [appd->optics startPositionTileForHint];
        [appd playSound:appd.tapPlayer];
    }
    else if (appd.numberOfHintsRemaining > 0){
        if (![appd editModeIsEnabled] && rc.appCurrentGamePackType == PACKTYPE_EDITOR){
            // Don't decrement appd.numberOfHintsRemaining
        }
        else {
            appd.numberOfHintsRemaining--;
        }
        [appd setObjectInDefaults:[NSNumber numberWithInt:appd.numberOfHintsRemaining] forKey:@"numberOfHintsRemaining"];
        [rc updateMoreHintPacksButton];
        [self setHintButtonLabel:appd.numberOfHintsRemaining];
        [appd->optics startPositionTileForHint];
        [appd playSound:appd.tapPlayer];
    }
    else {
        // Save progress before exiting
        [appd->optics savePuzzleProgressToDefaults];

        
        // If not yet solved then store endTime for timeSegment
        long endTime = [[NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970]] longValue];
        int currentPackNumber = -1;
        int currentPuzzleNumber = 0;
        NSMutableDictionary *emptyJewelCountDictionary = [appd buildEmptyJewelCountDictionary];
        if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
            currentPackNumber = [appd fetchCurrentPackNumber];
            currentPuzzleNumber = [appd fetchCurrentPuzzleNumber];
            if ([appd puzzleSolutionStatus:currentPackNumber
                              puzzleNumber:currentPuzzleNumber] == -1){
                [appd updatePuzzleScoresArray:currentPackNumber
                                 puzzleNumber:currentPuzzleNumber
                               numberOfJewels:emptyJewelCountDictionary
                                    startTime:-1        // Do not change startTime
                                      endTime:endTime
                                       solved:NO];
            }
        }
        else if (rc.appCurrentGamePackType == PACKTYPE_DAILY) {
            currentPackNumber = -1;
            currentPuzzleNumber = [appd fetchDailyPuzzleNumber];
            if ([appd puzzleSolutionStatus:currentPackNumber
                              puzzleNumber:currentPuzzleNumber] == -1){
                [appd updatePuzzleScoresArray:currentPackNumber
                                 puzzleNumber:currentPuzzleNumber
                               numberOfJewels:emptyJewelCountDictionary
                                    startTime:-1        // Do not change startTime
                                      endTime:endTime
                                       solved:NO];
            }
        }
        
        // Pause loop2Player
        [appd.loop2Player pause];

        // Transfer control to hintsViewController
        self.hintsViewController = [[BMDHintsViewController alloc] init];
        [self addChildViewController:self.hintsViewController];
        [puzzleView addSubview:self.hintsViewController.view];
        [self.hintsViewController didMoveToParentViewController:self];
    }
}

- (void)helpButtonPressed {
    [appd playSound:appd.tapPlayer];
    wholeScreenButton.enabled = YES;
    wholeScreenButton.hidden = NO;
    rc.renderOverlayON = YES;
}

- (void)wholeScreenButtonPressed {
    wholeScreenButton.enabled = NO;
    wholeScreenButton.hidden = YES;
    helpImageView.hidden = YES;
    rc.renderOverlayON = NO;
}

- (void)wholeScreenFilterPressed {
    DLog("wholeScreenFilterPressed");
    wholeScreenFilter.enabled = NO;
}

- (void)gridSizeStepperPressed {
    gridSizeStepperInitialValue = [[NSNumber numberWithInt:gridSizeStepper.value]doubleValue];   // Save initial value
    appd->optics->gameGrid.sizeX = gridSizeStepper.value;
    appd->optics->gameGrid.sizeY = gridSizeStepper.value;
    NSMutableDictionary *pack = nil;
    pack = [appd fetchEditedPack];
    if (pack){
        int currentIndex = [appd fetchEditedPuzzleIndexFromDefaults];
        if (currentIndex < 0){
            currentIndex = 0;
        }
        // Return the current puzzle encoded as an NSMutableDictionary
        NSMutableDictionary *puzzle = [NSMutableDictionary dictionaryWithCapacity:1];
        puzzle = [appd->optics encodeCurrentPuzzleAsMutableDictionary:puzzle];
        if (puzzle){
            NSMutableArray *puzzleArray = [NSMutableArray arrayWithArray:[pack objectForKey:@"puzzles"]];
            // Overwrite grid size keys in puzzle
            [puzzle setObject:[NSNumber numberWithInt:gridSizeStepper.value] forKey:@"gridSizeX"];
            [puzzle setObject:[NSNumber numberWithInt:
                                         [self gridSizeYfromGridSizeX:gridSizeStepper.value]
                                        ] forKey:@"gridSizeY"];
            [puzzle setObject:[NSNumber numberWithInt:kDefaultGridMaxSizeX] forKey:@"masterGridSizeX"];
            [puzzle setObject:[NSNumber numberWithInt:kDefaultGridMaxSizeY] forKey:@"masterGridSizeY"];
            if ([puzzleArray count] > 0){
                [puzzleArray replaceObjectAtIndex:currentIndex withObject:puzzle];
            }
            else {
                [puzzleArray addObject:puzzle];
            }
            [pack setObject:puzzleArray forKey:@"puzzles"];
            // Save the pack to Defaults and the fileManager
            [appd saveEditedPack:pack];
            // Restart the PE with a new pack and puzzle
            appd->optics = [Optics alloc];
            [appd->optics initWithDictionary:puzzle viewController:self];
        }
    }
}

- (unsigned int)gridSizeYfromGridSizeX:(unsigned int)gridSizeX{
    switch(gridSizeX){
        case 4:{
            return 6;
            break;
        }
        case 5:{
            return 7;
            break;
        }
        case 6:{
            return 8;
            break;
        }
        case 7:{
            return 10;
            break;
        }
        case 8:{
            return 11;
            break;
        }
        case 9:{
            return 12;
            break;
        }
        case 10:{
            return 13;
            break;
        }
        case 11:{
            return 14;
            break;
        }
        case 12:{
            return 16;
            break;
        }
    }
    return gridSizeX;
}

// Handle tap gesture here
- (void)tapGestureDetected:(UITapGestureRecognizer *)gesture{
    if (gesture.state == UIGestureRecognizerStateEnded){
        CGPoint position = [gesture locationInView:nil];
        position.x = rc.contentScaleFactor*position.x;
        position.y = rc.contentScaleFactor*position.y;
        vector_int2 lp;
        lp.x = position.x;
        lp.y = position.y;
        [appd.optics handleTapGesture:lp];
    }
}

// Handle long gesture press here
- (void)longPressDetected:(UILongPressGestureRecognizer *)gesture{
    if (gesture.state == UIGestureRecognizerStateBegan){
        CGPoint position = [gesture locationInView:nil];
        position.x = rc.contentScaleFactor*position.x;
        position.y = rc.contentScaleFactor*position.y;
        vector_int2 lp;
        lp.x = position.x;
        lp.y = position.y;
        [appd.optics handleTileLongPress:lp];
    }
}

- (void)handleUIApplicationDidBecomeActiveNotification {
    DLog("DEBUG2: BMDPuzzleViewController handling handleUIApplicationDidBecomeActiveNotification");
    
    // If not yet solved then store startTime for timeSegment
    long startTime = [[NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970]] longValue];
    int currentPackNumber = -1;
    int currentPuzzleNumber = 0;
    NSMutableDictionary *emptyJewelCountDictionary = [appd buildEmptyJewelCountDictionary];
    if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
        currentPackNumber = [appd fetchCurrentPackNumber];
        currentPuzzleNumber = [appd fetchCurrentPuzzleNumber];
        if ([appd puzzleSolutionStatus:currentPackNumber
                          puzzleNumber:currentPuzzleNumber] == -1){
            [appd updatePuzzleScoresArray:currentPackNumber
                             puzzleNumber:currentPuzzleNumber
                           numberOfJewels:emptyJewelCountDictionary
                                startTime:startTime        // New segment startTime
                                  endTime:-1
                                   solved:NO];
        }
    }
    else if (rc.appCurrentGamePackType == PACKTYPE_DAILY) {
        currentPackNumber = -1;
        currentPuzzleNumber = [appd fetchDailyPuzzleNumber];
        if ([appd puzzleSolutionStatus:currentPackNumber
                          puzzleNumber:currentPuzzleNumber] == -1){
            [appd updatePuzzleScoresArray:currentPackNumber
                             puzzleNumber:currentPuzzleNumber
                           numberOfJewels:emptyJewelCountDictionary
                                startTime:startTime        // New segment startTime
                                  endTime:-1
                                   solved:NO];
        }
    }
    
    if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
        [appd playMusicLoop:appd.loop3Player];
    }
    else {
        [appd playMusicLoop:appd.loop2Player];
    }

}

- (void)handleUIApplicationWillResignActiveNotification {
    [appd.loop1Player pause];
    [appd.loop2Player pause];
    [appd.loop3Player pause];
    DLog("DEBUG2: BMDPuzzleViewController handling UIApplicationWillResignActiveNotification");
    
    // Save progress before exiting
    [appd->optics savePuzzleProgressToDefaults];
    
    // If not yet solved then store endTime for timeSegment
    long endTime = [[NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970]] longValue];
    int currentPackNumber = -1;
    int currentPuzzleNumber = 0;
    NSMutableDictionary *emptyJewelCountDictionary = [appd buildEmptyJewelCountDictionary];
    if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
        currentPackNumber = [appd fetchCurrentPackNumber];
        currentPuzzleNumber = [appd fetchCurrentPuzzleNumber];
        if ([appd puzzleSolutionStatus:currentPackNumber
                          puzzleNumber:currentPuzzleNumber] == -1){
            [appd updatePuzzleScoresArray:currentPackNumber
                             puzzleNumber:currentPuzzleNumber
                           numberOfJewels:emptyJewelCountDictionary
                                startTime:-1        // Do not change startTime
                                  endTime:endTime
                                   solved:NO];
        }
    }
    else if (rc.appCurrentGamePackType == PACKTYPE_DAILY) {
        currentPackNumber = -1;
        currentPuzzleNumber = [appd fetchDailyPuzzleNumber];
        if ([appd puzzleSolutionStatus:currentPackNumber
                          puzzleNumber:currentPuzzleNumber] == -1){
            [appd updatePuzzleScoresArray:currentPackNumber
                             puzzleNumber:currentPuzzleNumber
                           numberOfJewels:emptyJewelCountDictionary
                                startTime:-1        // Do not change startTime
                                  endTime:endTime
                                   solved:NO];
        }
    }
    
}

- (BOOL)puzzleIsEmpty:(NSMutableDictionary *)puzzle {
    BOOL retVal = YES;
    return retVal;
}


@end

