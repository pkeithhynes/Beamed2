//
//  Optics.m
//  Beamed
//
//  Created by pkeithhynes on 7/18/10.
//  Copyright 2010 glimmerWave software. All rights reserved.
//

#import "Optics.h"
#import "Firebase.h"

@import UIKit;


@implementation Optics{
    BMDViewController *rc;
    BMDAppDelegate *appd;
    unsigned int initialNumberOfUnplacedTiles;
}

@synthesize vc;
@synthesize parentDictionaryKey;
@synthesize tiles;
@synthesize hints;
@synthesize tileRenderArray;
@synthesize backgroundRenderArray;
@synthesize ringRenderArray;
@synthesize puzzleCompleteRenderArray;
@synthesize puzzleViewControllerObjectsInitialized;

extern void playSound(AVAudioPlayer *PLAYER);

//***********************************************************************
// Initialization Methods
//***********************************************************************

// May be called with puzzleDictionary == nil in order to set up grid, foreground, background etc.
- (BOOL)initWithDictionary:(NSMutableDictionary *)puzzleDictionary viewController:(BMDPuzzleViewController *)puzzleViewController {
    
    self.vc = puzzleViewController;
    rc = (BMDViewController*)[[(BMDAppDelegate *)[[UIApplication sharedApplication]delegate] window] rootViewController];
    appd = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // Save a copy of the input puzzle dictionary in the BMDPuzzleViewController instance
    vc.inputPuzzleDictionary = [NSMutableDictionary dictionaryWithDictionary:puzzleDictionary];
    
    // Initialize the puzzle grid dimensions and screen size
    [self setGridBasedOnPuzzleDictionary:puzzleDictionary];
    
    initialNumberOfUnplacedTiles = 0;
    puzzleDifficulty = 3;
    
    // Initialize screen dimensions and bounds
    [self setScreenDimensionsAndBounds];
    
    // Initialize the Background object
    background = [[Background alloc] init];
    
    // Initialize the Foreground object
    foreground = [[Foreground alloc] init];
    
    // Create gameControls object for use in editMode
    gameControls = [[GameControls alloc] init];
    
    // Prepare for the occasional light sweep
    animationFrame = 0;
    lightSweepCounter = 0;
    hintWasRequested = NO;
    

    // Set up to promptUserAboutHintButton
    if ((rc.appCurrentGamePackType == PACKTYPE_MAIN || rc.appCurrentGamePackType == PACKTYPE_DAILY) &&
        ![appd editModeIsEnabled]){
        NSNumber *todayLocal = [NSNumber numberWithUnsignedInt:[appd getLocalDaysSinceReferenceDate]];
        NSNumber *hintUsedDay = [self->appd getObjectFromDefaults:@"hintUsedDay"];
        if (hintUsedDay == nil ||
            hintUsedDay != todayLocal){
            // Set up NSTimer to trigger method promptUserAboutHintButton
            [self.vc clearPromptUserAboutHintButtonTimer];
            NSTimeInterval delayTime = 10.0;
            vc.promptUserAboutHintButtonTimer = [NSTimer timerWithTimeInterval:delayTime repeats:NO block:^(NSTimer *time){
                [self.vc promptUserAboutHintButton];
            }];
            [[NSRunLoop currentRunLoop] addTimer:vc.promptUserAboutHintButtonTimer forMode:NSRunLoopCommonModes];
        }
        
    }
    
    // Clear any existing demoMessageButtonsAndLabels
    if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
        [self hideDemoTileTapLabel];
        [self hideDemoTileDragLabel];
        [self hideDemoPuzzleCompleteLabel];
        [self hideDemoPuzzleNextButton];
        // Hide and remove all labels from previous infoScreen
        UIDemoLabel *label;
        NSEnumerator *arrayEnum = [vc.infoScreenLabelArray objectEnumerator];
        while (label = [arrayEnum nextObject]){
            label.hidden = YES;
        }
        [vc.infoScreenLabelArray removeAllObjects];
    }
    
    // Initialization when in Puzzle Play or Puzzle Editing
    if (ENABLE_PUZZLE_VERIFY == NO){
        // Build all Puzzle components from puzzleDictionary
        [self buildPuzzleFromDictionary:puzzleDictionary showAllTiles:NO allTilesFixed:NO];
        
        tileCurrentlyBeingEdited = nil;
        tileForRotation = nil;
        tileUsedForDemoPlacement = nil;
        
        // Initialize Beams
        [self updateAllBeams];
        
        puzzleHasBeenCompleted = NO;
        packHasBeenCompleted = NO;
        puzzleHasBeenCompletedCelebration = NO;
        puzzleCompletedButtonFlash = NO;
        puzzleViewControllerObjectsInitialized = NO;
        
        // Handle batch processing for Puzzle Generation here
        id batchStartTag1 = [puzzleDictionary objectForKey:@"batchStart1"];
        if ([batchStartTag1 intValue] == 1){
            [self batchProcessor];
        }
        
        // Check if the puzzle that was just loaded is already completed.
        [self updateEnergizedStateForAllTiles];
        if ([self queryPuzzleCompleted]){
            if (!infoScreen)
                [self saveNextPuzzleToDefaults];
            if ([appd packHasBeenCompleted]){
                // Pack is complete
                vc.nextButton.hidden = YES;
                vc.nextArrow.hidden = YES;
                vc.homeArrowWhite.hidden = YES;
                vc.replayIconWhite.hidden = YES;
                packHasBeenCompleted = YES;
            }
            else {
                vc.nextButton.hidden = NO;
                vc.nextArrow.hidden = NO;
                vc.homeArrowWhite.hidden = (rc.appCurrentGamePackType == PACKTYPE_DEMO);
                vc.replayIconWhite.hidden = (rc.appCurrentGamePackType == PACKTYPE_DEMO);
                packHasBeenCompleted = NO;
            }
        }
        
        // If we are in PACKTYPE_DEMO and the puzzle is of type infoScreen then show the nextArrow and
        // the homeArrowWhite buttons
        //
        // If not of type infoScreen then just show nextArrow
        if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
            vc.homeArrowWhite.hidden = YES;
            vc.homeArrow.hidden = NO;
            vc.replayIconWhite.hidden = YES;
            if ([appd packHasBeenCompleted]){
                vc.nextArrow.hidden = YES;
            }
            else {
                vc.nextArrow.hidden = NO;
            }
        }
        return YES;
    }
    // Do Puzzle Verification
    else {
        // Build all Puzzle components from puzzleDictionary
        [self buildPuzzleFromDictionary:puzzleDictionary showAllTiles:NO allTilesFixed:YES];
        [self updateAllBeams];
        [self updateEnergizedStateForAllTiles];
        BOOL verified = [self checkIfAllJewelsAreEnergized];
        return verified;
    }
    
}

- (void)setGridBasedOnPuzzleDictionary:(NSMutableDictionary *)puzzleDictionary {
    vector_int2 gridSize;
    // If puzzleDictionary is nil set gridSize to default
    if (puzzleDictionary == nil || [puzzleDictionary count] == 0){
        gridSize.x = kDefaultGridStartingSizeX;
        gridSize.y = kDefaultGridStartingSizeY;
    }
    else {
        // Grid Configuration may be defined in puzzleDictionary
        // BOTH gridSizeX and gridSizeY must be defined
        if ([puzzleDictionary objectForKey:@"gridSizeX"] && [puzzleDictionary objectForKey:@"gridSizeY"]){
            gridSize.x = [[puzzleDictionary objectForKey:@"gridSizeX"] intValue];
            gridSize.y = [[puzzleDictionary objectForKey:@"gridSizeY"] intValue];
        }
        else {
            gridSize.x = kDefaultGridStartingSizeX;
            gridSize.y = kDefaultGridStartingSizeY;
        }
    }
    // Enforce acceptable range of values for grid size
    if (gridSize.x < kDefaultGridMinSizeX){
        gridSize.x = kDefaultGridMinSizeX;
    }
    if (gridSize.x > kDefaultGridMaxSizeX){
        gridSize.x = kDefaultGridMaxSizeX;
    }
    if (gridSize.y < kDefaultGridMinSizeY){
        gridSize.y = kDefaultGridMinSizeY;
    }
    if (gridSize.y > kDefaultGridMaxSizeY){
        gridSize.y = kDefaultGridMaxSizeY;
    }
    
    gameGrid.sizeX = gridSize.x;
    gameGrid.sizeY = gridSize.y;
    masterGrid.sizeX = gameGrid.sizeX + 2;
    masterGrid.sizeY = gameGrid.sizeY + 2;
}

- (void)setScreenDimensionsAndBounds {
    // Display area values that are related to the physical device are managed by the Root UIViewController
    CGFloat contentScaleFactor = rc.contentScaleFactor;
    CGFloat topPaddingInPoints = rc.topPaddingInPoints;
    _screenWidthInPixels = rc.screenWidthInPixels;
    _screenHeightInPixels = rc.screenHeightInPixels;
    _safeAreaScreenWidthInPixels = rc.safeAreaScreenWidthInPixels;
    _safeAreaScreenHeightInPixels = rc.safeAreaScreenHeightInPixels;
    
    _puzzleScreenHorizontalOffsetInPixels = 0;
    _puzzleScreenVerticalOffsetInPixels = topPaddingInPoints*contentScaleFactor;       // Convert Points to Pixels
    
    // The size of the App screen image including various ratios of screen height to width and any dependence
    // on the grid size in tiles is handled here
    CGFloat masterGridHeightToWidthRatio = (float)masterGrid.sizeY/(float)masterGrid.sizeX;
//    CGFloat verticalOffsetcompensationFactor;
    
    switch (rc.displayAspectRatio) {
        case ASPECT_4_3:
            // iPad (9th generation)
        case ASPECT_10_7:
            // iPad Air (5th generation)
        case ASPECT_3_2:{
            // iPad Mini (6th generation)
            //
            // Case 1: Aspect ratios 4:3, 10:7, 3:2 - puzzle masterGrid is vertically constrained
            //
            // Shrink the puzzle area height to 90% of full _safeAreaScreenHeightInPixels.  This will allow for a "Unplaced
            //   Tiles Area" one grid width below the puzzle play area
            _masterGridHeightInPixels = 0.90*_safeAreaScreenHeightInPixels;
            _masterGridWidthInPixels = _masterGridHeightInPixels/masterGridHeightToWidthRatio;
            _masterGridVerticalOffsetInPixels = _puzzleScreenVerticalOffsetInPixels;
            _masterGridHorizontalOffsetInPixels = _puzzleScreenHorizontalOffsetInPixels + (_safeAreaScreenWidthInPixels - _masterGridWidthInPixels)/2.0;
            break;
        }
        case ASPECT_16_9:{
            // iPhone 8
            //
            // Case 2: Aspect ratio 16:9 - puzzle masterGrid is horizontally constrained
            _masterGridWidthInPixels = 0.90*_safeAreaScreenWidthInPixels;
            _masterGridHeightInPixels = _masterGridWidthInPixels*masterGridHeightToWidthRatio;
            _masterGridHorizontalOffsetInPixels = _puzzleScreenHorizontalOffsetInPixels + (_safeAreaScreenWidthInPixels-_masterGridWidthInPixels)/2.0;
            _masterGridVerticalOffsetInPixels = _puzzleScreenVerticalOffsetInPixels + 0.7000*(_safeAreaScreenHeightInPixels - _masterGridHeightInPixels);
            break;
        }
        case ASPECT_13_6:
        default:{
            // iPhones
            // Case 2: Aspect ratio 13:6 - puzzle masterGrid is horizontally constrained
            _masterGridWidthInPixels = _safeAreaScreenWidthInPixels;
            _masterGridHeightInPixels = _masterGridWidthInPixels*masterGridHeightToWidthRatio;
            _masterGridHorizontalOffsetInPixels = _puzzleScreenHorizontalOffsetInPixels;
            _masterGridVerticalOffsetInPixels = _puzzleScreenVerticalOffsetInPixels + 0.4000*(_safeAreaScreenHeightInPixels - _masterGridHeightInPixels);
            break;
        }
    }
    
    //
    // Set the size of the borders between the puzzle area and the Tile grid
    //
    _puzzleGridLeftAndRightBorderWidthInPixels = kDefaultPuzzleGridLeftAndRightBorderWidthInPixels;
    _puzzleGridTopAndBottomBorderWidthInPixels = kDefaultPuzzleGridTopAndBottomBorderWidthInPixels;
    
    //
    // Set the size of the tile images in pixels
    //
    // Set the size of the gameGrid (the area where players can position Tiles) in pixels
    //
    _squareTileSideLengthInPixels = _masterGridWidthInPixels/(float)masterGrid.sizeX;
    _puzzleDisplayWidthInPixels = _squareTileSideLengthInPixels * gameGrid.sizeX;
    _puzzleDisplayHeightInPixels = _squareTileSideLengthInPixels * gameGrid.sizeY;
    
    //
    // Calculate Tile vertical and horizontal offsets
    //
    _tileHorizontalOffsetInPixels = _masterGridHorizontalOffsetInPixels + _puzzleGridLeftAndRightBorderWidthInPixels;
    _tileVerticalOffsetInPixels = _masterGridVerticalOffsetInPixels + _puzzleGridTopAndBottomBorderWidthInPixels;

    // Set the gridTouchGestures Puzzle region boundaries
    gridTouchGestures.minPuzzleBoundary.x = _tileHorizontalOffsetInPixels + _squareTileSideLengthInPixels*(float)(masterGrid.sizeX-gameGrid.sizeX)/2.0;
    gridTouchGestures.maxPuzzleBoundary.x = gridTouchGestures.minPuzzleBoundary.x + _puzzleDisplayWidthInPixels;
    gridTouchGestures.minPuzzleBoundary.y = _tileVerticalOffsetInPixels  + _squareTileSideLengthInPixels*(float)(masterGrid.sizeX-gameGrid.sizeX)/2.0;
    gridTouchGestures.maxPuzzleBoundary.y = _tileVerticalOffsetInPixels + _squareTileSideLengthInPixels + _puzzleDisplayHeightInPixels;
    
    // Set the GridTouchGestures Editor region boundaries
    gridTouchGestures.minEditorBoundary.x = _tileHorizontalOffsetInPixels;
    gridTouchGestures.maxEditorBoundary.x = gridTouchGestures.minEditorBoundary.x + _squareTileSideLengthInPixels * masterGrid.sizeX;
    gridTouchGestures.minEditorBoundary.y = _tileVerticalOffsetInPixels;
    gridTouchGestures.maxEditorBoundary.y = gridTouchGestures.minEditorBoundary.y + _squareTileSideLengthInPixels * masterGrid.sizeY;
    
    // Set the GridTouchGestures controls region bounds
    gridTouchGestures.minControlsBoundary.x = _tileHorizontalOffsetInPixels;
    // The gameControls is always 8 grid elements wide
    gridTouchGestures.maxControlsBoundary.x = gridTouchGestures.minPuzzleBoundary.x + 8*_squareTileSideLengthInPixels;
    gridTouchGestures.minControlsBoundary.y = gridTouchGestures.maxEditorBoundary.y;
    gridTouchGestures.maxControlsBoundary.y = gridTouchGestures.minControlsBoundary.y + _squareTileSideLengthInPixels;
    
    // Set the GridTouchGestures Unused Tiles region bounds
    gridTouchGestures.minUnplacedTilesBoundary.x = gridTouchGestures.minPuzzleBoundary.x;
    // The Unused Tile region is gameGrid.sizeX elements wide
    gridTouchGestures.maxUnplacedTilesBoundary.x = gridTouchGestures.maxPuzzleBoundary.x;
    gridTouchGestures.minUnplacedTilesBoundary.y = gridTouchGestures.maxEditorBoundary.y;
    gridTouchGestures.maxUnplacedTilesBoundary.y = gridTouchGestures.minUnplacedTilesBoundary.y + _squareTileSideLengthInPixels;
}

- (void)initializeVcObjects {
    // Set currentPackPuzzleNumber in status screen
    [vc setPuzzleLabel];
    
    [vc disableFlash:vc.nextButton];
    [vc disableFlash:vc.backButton];
    vc.nextButton.hidden = YES;
    vc.nextArrow.hidden = YES;
    vc.homeArrowWhite.hidden = YES;
    vc.replayIconWhite.hidden = YES;
    if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
        vc.backButton.hidden = YES;
        vc.replayIconWhite.hidden = YES;
        vc.homeArrow.hidden = NO;
        if ([appd packHasBeenCompleted]){
            vc.nextArrow.hidden = YES;
        }
        else {
            vc.nextArrow.hidden = NO;
        }
    }
    else {
        vc.backButton.hidden = NO;
    }
    
    puzzleViewControllerObjectsInitialized = YES;
}

//***********************************************************************
// Rendering
//***********************************************************************
- (NSMutableDictionary *)renderPuzzle
{
    // Set up any needed BMDPuzzleViewController display objects
    if (puzzleViewControllerObjectsInitialized == NO){
        [vc removeButtonsAndLabels];
        if ([appd editModeIsEnabled]){
            [vc buildButtonsAndLabelsForEdit];
        }
        else {
            [vc buildButtonsAndLabelsForPlay];
        }
        [vc displayButtonsAndLabels];
        [self initializeVcObjects];
    }
    
    // Don't render puzzle during puzzle verification
    if (ENABLE_PUZZLE_VERIFY == NO){
        // Allocate and initialize render arrays and dictionaries
        renderDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
        renderArray = [[NSMutableArray alloc] initWithCapacity:1];
        tileRenderArray = [[NSMutableArray alloc] initWithCapacity:1];
        backgroundRenderArray = [[NSMutableArray alloc] initWithCapacity:1];
        beamsRenderArray = [[NSMutableArray alloc] initWithCapacity:1];
        gridPositionsCrossedByMultipleCoincidentBeams = [[NSMutableArray alloc] initWithCapacity:1];
        ringRenderArray = [[NSMutableArray alloc] initWithCapacity:1];
        puzzleCompleteRenderArray = [[NSMutableArray alloc] initWithCapacity:1];
        
        // Handle arrow from demo puzzle showing where Tile should be placed
        arrowRenderData = [[TextureRenderData alloc] init];
        
        // Set up the background render data
        borderRenderData = [[TextureRenderData alloc] init];
        
        // Update animationFrame and lightSweep
        animationFrame++;
        BOOL lightSweep = YES;
        
        // Fetch a render array of Tiles
        Tile *myTile;
        TextureRenderData *tileRenderData;
        TextureRenderData *movableTileRenderData, *tapDemoTilePromptRenderData, *tapDemoTilePromptTextRenderData;
        NSEnumerator *tilesEnum = [tiles objectEnumerator];
        BOOL movableTileDragTextDisplayed = NO;
        unsigned int numberOfUnplacedTiles = 0;
        while (myTile = [tilesEnum nextObject]) {
            //
            // Count unplaced Tiles so that you can generate a correct sized background grid
            //
            if (!myTile->fixed && !(myTile->placedUsingHint || myTile->placedManuallyMatchesHint)){
                // Arrange unplaced Tiles within the unplaced tiles area
                if (myTile->gridPosition.y == masterGrid.sizeY){
                    // Organize tile placement here
                    myTile->gridPosition.x = numberOfUnplacedTiles+1;
                    myTile->tilePositionInPixels = [self gridPositionToIntPixelPosition:myTile->gridPosition];
                    numberOfUnplacedTiles++;
                    // Get rid of rotation prompt if present
                    if (myTile == tileForRotation){
                        tileForRotation = nil;
                    }
                }
            }
            
            // If a JEWEL is energized then draw the JEWEL background first, then add the activation animation atop that
            if (myTile->tileShape == JEWEL) {
                tileRenderData = [myTile renderTileBackground];
                [tileRenderArray addObject:tileRenderData];
            }
            
            // Render Tiles
            if (myTile->tileShape != JEWEL ||
                (myTile->tileShape == JEWEL && myTile->energized)){
                // DO NOT RENDER a JEWEL that is not energized because it is handled by renderTileBackground
                tileRenderData = [myTile renderTile:1.0 paused:NO lightSweep:lightSweep puzzleCompleted:puzzleHasBeenCompleted puzzleCompletedCelebration:puzzleHasBeenCompletedCelebration];
                if (tileRenderData){
                    [tileRenderArray addObject:tileRenderData];
                }
            }
            
            // Certain Tiles with demoTile == YES are used to demonstrate correct Tile positioning and include an arrow from their current grid position to their final grid position
            //
            // Show drag arrow and associated label
            if (myTile->demoTile == YES &&
                myTile->demoTileAtFinalGridPosition == NO &&
                dragTile == YES){
                arrowRenderData = [background renderTutorialTilePathArrow:myTile->gridPosition end:myTile->finalGridPosition textureRenderData:arrowRenderData];
                [self showDemoTileDragLabel];
                [self hideDemoTileTapLabel];
                [self hideDemoPuzzleCompleteLabel];
                [self hideDemoPuzzleNextButton];
            }
            // Show rotate image and associated label
            else if (myTile->demoTile == YES &&
                     myTile->demoTileAtFinalGridPosition == YES &&
                     tapTile == YES &&
                     !myTile->placed &&
                     !myTile->placedManuallyMatchesHint &&
                     !myTile->placedUsingHint){
                // Tile occupies finalGridPosition
                myTile->gridPosition = myTile->finalGridPosition;
                tapDemoTilePromptRenderData = [background renderTapToRotatePrompt:myTile->tilePositionInPixels angle:myTile->tileAngle];
                [tileRenderArray addObject:tapDemoTilePromptRenderData];
                tapDemoTilePromptTextRenderData = [background renderTapToRotatePromptText:myTile->tilePositionInPixels angle:ANGLE180];
                [tileRenderArray addObject:tapDemoTilePromptTextRenderData];
                [self hideDemoTileDragLabel];
                [self showDemoTileTapLabel];
                [self hideDemoPuzzleCompleteLabel];
                [self hideDemoPuzzleNextButton];
            }
            else if (myTile->demoTile == YES &&
                     myTile->demoTileAtFinalGridPosition == YES &&
                     (myTile->placed || myTile->placedManuallyMatchesHint || myTile->placedUsingHint)){
                [self hideDemoTileDragLabel];
                [self hideDemoTileTapLabel];
                [self showDemoPuzzleCompleteLabel];
                [self showDemoPuzzleNextButton];
            }
            
            // The Tile that has most recently been dragged to a nonfinal position-angle has TAP_TO_ROTATE guide
            if (rc.appCurrentGamePackType != PACKTYPE_DEMO &&
                rc.appCurrentGamePackType != PACKTYPE_EDITOR &&
                myTile == tileForRotation){
                tapDemoTilePromptRenderData = [background renderTapToRotatePrompt:myTile->tilePositionInPixels angle:myTile->tileAngle];
                [tileRenderArray addObject:tapDemoTilePromptRenderData];
            }
            
            // Certain objects are wrapped in circles to indicate that they are moveable
            if (!myTile->fixed && puzzleHasBeenCompleted == YES){
                movableTileRenderData = [background renderMovableTile:myTile->tilePositionInPixels placedUsingHint:myTile->placedUsingHint placedManuallyMatchesHint:YES];
                [tileRenderArray addObject:movableTileRenderData];
            }
            else if (!myTile->fixed ||
                (([appd editModeIsEnabled] && !myTile->fixed && myTile != tileForRotation) ||
                 (rc.appCurrentGamePackType == PACKTYPE_DEMO && !myTile->fixed & !myTile->demoTileAtFinalGridPosition))){
                movableTileRenderData = [background renderMovableTile:myTile->tilePositionInPixels placedUsingHint:myTile->placedUsingHint placedManuallyMatchesHint:myTile->placedManuallyMatchesHint];
                [tileRenderArray addObject:movableTileRenderData];
            }
            else if (![appd editModeIsEnabled] && (myTile->tileShape == PRISM ||
                                                   myTile->tileShape == MIRROR ||
                                                   myTile->tileShape == BEAMSPLITTER ||
                                                   myTile->tileShape == LASER) &&
                     ((!myTile->fixed && myTile->demoTileAtFinalGridPosition == NO) || myTile->placedUsingHint || myTile->placedManuallyMatchesHint)  && myTile != tileForRotation){
                if (puzzleHasBeenCompleted == NO || puzzleHasBeenCompletedCelebration == YES){
                    if (!movableTileDragTextDisplayed &&
                        !myTile->fixed &&
                        myTile->gridPosition.y == masterGrid.sizeY+1){
                        // Yellow circle around one tile
                        movableTileRenderData = [background renderMovableTile:myTile->tilePositionInPixels placedUsingHint:myTile->placedUsingHint placedManuallyMatchesHint:myTile->placedManuallyMatchesHint];
                        [tileRenderArray addObject:movableTileRenderData];
                        // Finger pointing at one unplaced Tile
                        //                    pointingFingerRenderData = [background renderPointingFinger:myTile->tilePositionInPixels angle:ANGLE135];
                        //                    [tileRenderArray addObject:pointingFingerRenderData];
                        movableTileDragTextDisplayed = YES;
                    }
                    else if (myTile->placedUsingHint || myTile->placedManuallyMatchesHint){
                        // Mark a Tile as either placed using a Hint or placed manually in a correct position
                        movableTileRenderData = [background renderMovableTile:myTile->tilePositionInPixels placedUsingHint:myTile->placedUsingHint placedManuallyMatchesHint:myTile->placedManuallyMatchesHint];
                        [tileRenderArray addObject:movableTileRenderData];
                    }
                }
            }
        }
        
        if (initialNumberOfUnplacedTiles == 0){
            initialNumberOfUnplacedTiles = numberOfUnplacedTiles;
        }
        
        //
        // Fetch the Puzzle background image
        //
        if (displayBackgroundImage == YES){
            backgroundRenderDataImage = [background renderBackgroundImage:7];
            //
            // Fetch the translucent filter image
            //
            backgroundRenderDataFilterImage = nil;
            backgroundRenderDataFilterImage = [background renderFilterImage:FILTER_IMAGE color:7];
        }
        
        //
        // Fetch the help image
        //
        overlayRenderDataImage = nil;
        if (rc.renderOverlayON){
            overlayRenderDataImage = [background renderOverlayImage:HELP_IMAGE color:7];
        }
        
        //
        // Fetch the Gameplay inner and outer background colors
        //
        //    backgroundRenderDataOuter = [background renderBackgroundOuter:COLOR_BLUE];
        backgroundRenderDataInner = [background renderBackgroundInner:COLOR_GRAY];
        
        //
        // Fetch the Unused Tile background
        //
        unusedTileBackgroundRenderData = nil;
        if (![appd autoGenIsEnabled] && numberOfUnplacedTiles > 0){
            unusedTileBackgroundRenderData = [background renderUnusedTileBackground:COLOR_GRAY numberOfUnplacedTiles:numberOfUnplacedTiles initialNumberOfUnplacedTiles:initialNumberOfUnplacedTiles];
        }
        
        // Handle changes to Gameplay and Tutorial screen when puzzleHasBeenCompleted
        //
        // Fetch the Gameplay border
        //
        if (puzzleCompletionCondition == ALL_JEWELS_ENERGIZED || puzzleCompletionCondition == INFO_SCREEN){
            // Gameplay Mode
            if (![appd editModeIsEnabled]){
                vc.hintButton.hidden = [self allTilesArePlaced] ||
                ((rc.appCurrentGamePackType == PACKTYPE_DEMO) && !circleAroundHintsButton);
                vc.hintBulb.hidden = [self allTilesArePlaced] ||
                ((rc.appCurrentGamePackType == PACKTYPE_DEMO) && !circleAroundHintsButton);
            }
            if (puzzleHasBeenCompleted){
                if (rc->appCurrentGamePackType == PACKTYPE_DAILY){
                    [vc.backButton setTitleColor:[UIColor cyanColor] forState:UIControlStateNormal];
                    vc.backButton.layer.borderColor = [UIColor cyanColor].CGColor;
                }
                else if (rc->appCurrentGamePackType == PACKTYPE_MAIN){
                    [vc.nextButton setTitleColor:[UIColor cyanColor] forState:UIControlStateNormal];
                    vc.nextButton.layer.borderColor = [UIColor cyanColor].CGColor;
                }
                else if (rc->appCurrentGamePackType == PACKTYPE_DEMO){
                    vc.backButton.hidden = YES;
                    vc.homeArrowWhite.hidden = YES;
                    vc.homeArrow.hidden = NO;
                    if (infoScreen){
                        vc.nextButton.hidden = NO;
                    }
                    vc.replayIconWhite.hidden = YES;
                }
                if (!puzzleCompletedButtonFlash){
                    //  Play a confirmation sound and start flashing the nextButton or backButton
                    puzzleCompletedButtonFlash = YES;
                    if (rc->appCurrentGamePackType == PACKTYPE_DAILY){
                        [vc enableFlash:vc.backButton];
                    }
                    else if (rc.appCurrentGamePackType == PACKTYPE_MAIN && ([appd queryNumberOfPuzzlesLeftInCurrentPack] == 0)){
                        [vc enableFlash:vc.nextButton];
                    }
                    else if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
                        vc.replayIconWhite.hidden = YES;
                        // DO NOT enableFlash:vc.backButton
                        // DO NOT enableFlash:vc.nextButton
                    }
                    else {
                        if (rc.appCurrentGamePackType == PACKTYPE_MAIN && !packHasBeenCompleted){
                            [vc enableFlash:vc.nextButton];
                            vc.nextButton.hidden = NO;
                            vc.nextArrow.hidden = NO;
                            vc.homeArrowWhite.hidden = NO;
                            vc.replayIconWhite.hidden = NO;
                        }
                        else {
                            [vc enableFlash:vc.backButton];
                            vc.nextButton.hidden = YES;
                            vc.nextArrow.hidden = YES;
                            vc.homeArrowWhite.hidden = NO;
                            vc.replayIconWhite.hidden = NO;
                        }
                    }
                }
            }
            else {
                if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
                    vc.homeArrowWhite.hidden = YES;
                    vc.homeArrow.hidden = NO;
                    vc.replayIconWhite.hidden = YES;
                    if ([appd packHasBeenCompleted]){
                        vc.nextArrow.hidden = YES;
                    }
                    else {
                        vc.nextArrow.hidden = NO;
                    }
                }
                else {
                    vc.nextArrow.hidden = YES;
                    vc.homeArrowWhite.hidden = YES;
                    vc.replayIconWhite.hidden = YES;
                    [vc.nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                    vc.nextButton.layer.borderColor = [UIColor whiteColor].CGColor;
                }
            }
        }
        else if (puzzleCompletionCondition == USER_TOUCH){
            vc.hintButton.hidden = YES;
            vc.hintBulb.hidden = YES;
            [vc.nextButton setTitleColor:[UIColor cyanColor] forState:UIControlStateNormal];
            vc.nextButton.layer.borderColor = [UIColor cyanColor].CGColor;
            if (!puzzleCompletedButtonFlash && !packHasBeenCompleted){
                puzzleCompletedButtonFlash = YES;
                [vc enableFlash:vc.nextButton];
                vc.nextButton.hidden = NO;
                vc.nextArrow.hidden = NO;
                vc.homeArrowWhite.hidden = NO;
                vc.replayIconWhite.hidden = NO;
            }
            else {
                vc.nextButton.hidden = YES;
                vc.nextArrow.hidden = YES;
                vc.homeArrowWhite.hidden = NO;
                vc.replayIconWhite.hidden = NO;
            }
        }
        else {
            vc.hintButton.hidden = YES;
            vc.hintBulb.hidden = YES;
            [vc.nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            vc.nextButton.layer.borderColor = [UIColor whiteColor].CGColor;
        }
        
        // Fetch an array of Background Tile-sized Textures to render behind the Puzzle
        if (displayBackgroundArray){
            if (puzzleHasBeenCompleted) {
                backgroundRenderArray = [background renderBackgroundArray:backgroundRenderArray tileColor:7 numberOfUnplacedTiles:numberOfUnplacedTiles
                                                          puzzleCompleted:YES];
            }
            else {
                backgroundRenderArray = [background renderBackgroundArray:backgroundRenderArray tileColor:0 numberOfUnplacedTiles:numberOfUnplacedTiles
                                                          puzzleCompleted:NO];
            }
        }
        
        // Fetch beamsRenderArray that combines all beams of each RGB color into at most one beam BeamTextureRenderObject between each pair of tiles
        //
        // Stop rendering beams when puzzle completed
        if (!puzzleHasBeenCompleted || puzzleHasBeenCompletedCelebration == YES){
            Beam *myBeam;
            for (int ii=0; ii<3; ii++) {
                NSEnumerator *beamsEnum = [beams[ii] objectEnumerator];
                while (myBeam = [beamsEnum nextObject]) {
                    [myBeam renderBeam:beamsRenderArray frameCounter:animationFrame];
                }
            }
        }
        
        
        // Fetch an array of various animations to render atop other screen elements.  For example expanding rings for
        // energized jewels.
        ringRenderArray = [foreground renderIdleJewelRingArray:ringRenderArray];
        
        // Check if we should mark the pack as complete
        if (packHasBeenCompleted &&
            rc.appCurrentGamePackType != PACKTYPE_DEMO){
            puzzleCompleteRenderArray = [foreground renderPackCompletedMarker:puzzleCompleteRenderArray];
            vc.nextButton.hidden = YES;
            vc.nextArrow.hidden = YES;
            vc.homeArrowWhite.hidden = NO;
            if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
                vc.replayIconWhite.hidden = YES;
                vc.homeArrowWhite.hidden = YES;
            }
            else {
                vc.replayIconWhite.hidden = NO;
            }
            vc.backButton.hidden = NO;
            vc.homeArrow.hidden = NO;
            vc.hintButton.hidden = YES;
            vc.hintBulb.hidden = YES;
        }
        // Else check if we should mark the puzzle as complete
        else if (puzzleHasBeenCompleted){
            puzzleCompleteRenderArray = [foreground renderPuzzleCompletedMarker:puzzleCompleteRenderArray];
            if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
                vc.nextButton.hidden = NO;
                vc.nextArrow.hidden = NO;
                vc.homeArrowWhite.hidden = NO;
                vc.replayIconWhite.hidden = NO;
                vc.backButton.hidden = NO;
                vc.hintButton.hidden = YES;
                vc.hintBulb.hidden = YES;
            }
            else if (rc.appCurrentGamePackType == PACKTYPE_DAILY){
                vc.nextButton.hidden = YES;
                vc.nextArrow.hidden = YES;
                vc.homeArrowWhite.hidden = NO;
                vc.replayIconWhite.hidden = NO;
                vc.backButton.hidden = NO;
                vc.homeArrow.hidden = NO;
                vc.hintButton.hidden = YES;
                vc.hintBulb.hidden = YES;
            }
            else if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
                vc.nextButton.hidden = NO;
                if ([appd packHasBeenCompleted]){
                    vc.nextArrow.hidden = YES;
                }
                else {
                    vc.nextArrow.hidden = NO;
                }
                vc.homeArrow.hidden = NO;
                vc.homeArrowWhite.hidden = YES;
                vc.replayIconWhite.hidden = YES;
                vc.backButton.hidden = YES;
                vc.hintButton.hidden = [self allTilesArePlaced] ||
                ((rc.appCurrentGamePackType == PACKTYPE_DEMO) && !circleAroundHintsButton);
                vc.hintBulb.hidden = [self allTilesArePlaced] ||
                ((rc.appCurrentGamePackType == PACKTYPE_DEMO) && !circleAroundHintsButton);
            }
        }
        // Puzzle is not complete
        else {
            if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
                vc.nextButton.hidden = YES;
                vc.nextArrow.hidden = YES;
                vc.homeArrowWhite.hidden = YES;
                vc.replayIconWhite.hidden = YES;
                vc.backButton.hidden = NO;
                vc.homeArrow.hidden = NO;
                vc.hintButton.hidden = NO;
                vc.hintBulb.hidden = NO;
            }
            else if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
                vc.nextButton.hidden = YES;
                if ([appd packHasBeenCompleted]){
                    vc.nextArrow.hidden = YES;
                }
                else {
                    vc.nextArrow.hidden = NO;
                }
                vc.homeArrowWhite.hidden = YES;
                vc.replayIconWhite.hidden = YES;
                vc.backButton.hidden = YES;
                vc.homeArrow.hidden = NO;
                vc.hintButton.hidden = [self allTilesArePlaced] ||
                ((rc.appCurrentGamePackType == PACKTYPE_DEMO) && !circleAroundHintsButton);
                vc.hintBulb.hidden = [self allTilesArePlaced] ||
                ((rc.appCurrentGamePackType == PACKTYPE_DEMO) && !circleAroundHintsButton);
            }
            else if (rc.appCurrentGamePackType == PACKTYPE_DAILY){
                vc.nextButton.hidden = YES;
                vc.nextArrow.hidden = YES;
                vc.homeArrowWhite.hidden = YES;
                vc.replayIconWhite.hidden = YES;
                vc.backButton.hidden = NO;
                vc.homeArrow.hidden = NO;
                vc.hintButton.hidden = NO;
                vc.hintBulb.hidden = NO;
            }
        }
        
        // Set nextButton and backButton visibity in PE
        if ([appd editModeIsEnabled]){
            vc.nextButton.hidden = NO;
            vc.nextArrow.hidden = YES;
            vc.homeArrowWhite.hidden = YES;
            vc.replayIconWhite.hidden = YES;
            vc.backButton.hidden = NO;
        }
        
        
        // Once the rendering is done update the Jewel counts in the View Controller
        //    if (!puzzleHasBeenCompleted)
        //        [rc setJewelCounts];
        
        // Return an array of game control tile images
        gameControlTiles = [[NSMutableArray alloc] initWithCapacity:1];
        if ([appd editModeIsEnabled] && ![appd autoGenIsEnabled]){
            gameControlTiles = [gameControls renderGameControls:gameControlTiles];
        }
        
        // Add render arrays into the master renderDictionary
        if (displayBackgroundImage == YES){
            [renderDictionary setObject:backgroundRenderDataImage forKey:@"backgroundImage"];
            [renderDictionary setObject:backgroundRenderDataFilterImage forKey:@"backgroundFilterImage"];
        }
        if (overlayRenderDataImage != nil){
            [renderDictionary setObject:overlayRenderDataImage forKey:@"overlayImage"];
        }
        if (displayBackgroundArray){
            [renderDictionary setObject:backgroundRenderDataInner forKey:@"backgroundRenderDataInner"];
        }
        if (![appd autoGenIsEnabled] && unusedTileBackgroundRenderData != nil){
            [renderDictionary setObject:unusedTileBackgroundRenderData forKey:@"unusedTileBackgroundRenderData"];
        }
        [renderDictionary setObject:borderRenderData forKey:@"borderRenderData"];
        [renderDictionary setObject:backgroundRenderArray forKey:@"backgroundRenderArray"];
        [renderDictionary setObject:tileRenderArray forKey:@"tileRenderArray"];
        [renderDictionary setObject:ringRenderArray forKey:@"ringRenderArray"];
        [renderDictionary setObject:beamsRenderArray forKey:@"beamsRenderArray"];
        [renderDictionary setObject:arrowRenderData forKey:@"arrowRenderData"];
        [renderDictionary setObject:puzzleCompleteRenderArray forKey:@"puzzleCompleteRenderArray"];
        if ([appd editModeIsEnabled]){
            [renderDictionary setObject:gameControlTiles forKey:@"gameControlTiles"];
        }
        return renderDictionary;
    }
    else {
        return nil;
    }
}

//***********************************************************************
// Puzzle Handling Methods
//***********************************************************************
- (void)showDemoTileDragLabel {
    UIDemoLabel *label = nil;
    id arrayObject;
    NSEnumerator *buttonAndlabelEnum = [vc.demoMessageButtonsAndLabels objectEnumerator];
    while (arrayObject = [buttonAndlabelEnum nextObject]){
        if ([arrayObject isKindOfClass:[UIDemoLabel class]]){
            label = (UIDemoLabel *)arrayObject;
            if (label.dragTile){
                label.hidden = NO;
            }
        }
    }
}

- (void)hideDemoTileDragLabel {
    UIDemoLabel *label = nil;
    id arrayObject;
    NSEnumerator *buttonAndlabelEnum = [vc.demoMessageButtonsAndLabels objectEnumerator];
    while (arrayObject = [buttonAndlabelEnum nextObject]){
        if ([arrayObject isKindOfClass:[UIDemoLabel class]]){
            label = (UIDemoLabel *)arrayObject;
            if (label.dragTile){
                label.hidden = YES;
            }
        }
    }
}

- (void)showDemoTileTapLabel {
    UIDemoLabel *label = nil;
    id arrayObject;
    NSEnumerator *buttonAndlabelEnum = [vc.demoMessageButtonsAndLabels objectEnumerator];
    while (arrayObject = [buttonAndlabelEnum nextObject]){
        if ([arrayObject isKindOfClass:[UIDemoLabel class]]){
            label = (UIDemoLabel *)arrayObject;
            if (label.tapTile){
                label.hidden = NO;
            }
        }
    }
}

- (void)hideDemoTileTapLabel {
    UIDemoLabel *label = nil;
    id arrayObject;
    NSEnumerator *buttonAndlabelEnum = [vc.demoMessageButtonsAndLabels objectEnumerator];
    while (arrayObject = [buttonAndlabelEnum nextObject]){
        if ([arrayObject isKindOfClass:[UIDemoLabel class]]){
            label = (UIDemoLabel *)arrayObject;
            if (label.tapTile){
                label.hidden = YES;
            }
        }
    }
}

- (void)showDemoPuzzleCompleteLabel {
    UIDemoLabel *label = nil;
    id arrayObject;
    NSEnumerator *buttonAndlabelEnum = [vc.demoMessageButtonsAndLabels objectEnumerator];
    while (arrayObject = [buttonAndlabelEnum nextObject]){
        if ([arrayObject isKindOfClass:[UIDemoLabel class]]){
            label = (UIDemoLabel *)arrayObject;
            if (label.puzzleComplete){
                label.hidden = NO;
            }
        }
    }
}

- (void)hideDemoPuzzleCompleteLabel {
    UIDemoLabel *label = nil;
    id arrayObject;
    NSEnumerator *buttonAndlabelEnum = [vc.demoMessageButtonsAndLabels objectEnumerator];
    while (arrayObject = [buttonAndlabelEnum nextObject]){
        if ([arrayObject isKindOfClass:[UIDemoLabel class]]){
            label = (UIDemoLabel *)arrayObject;
            if (label.puzzleComplete){
                label.hidden = YES;
            }
        }
    }
}

- (void)showDemoPuzzleNextButton {
    UIDemoButton *button = nil;
    id arrayObject;
    NSEnumerator *buttonAndlabelEnum = [vc.demoMessageButtonsAndLabels objectEnumerator];
    while (arrayObject = [buttonAndlabelEnum nextObject]){
        if ([arrayObject isKindOfClass:[UIDemoButton class]]){
            button = (UIDemoButton *)arrayObject;
            if (button.nextPuzzle || button.finalPuzzle){
                button.hidden = NO;
            }
        }
    }
}

- (void)hideDemoPuzzleNextButton {
    UIDemoButton *button = nil;
    id arrayObject;
    NSEnumerator *buttonAndlabelEnum = [vc.demoMessageButtonsAndLabels objectEnumerator];
    while (arrayObject = [buttonAndlabelEnum nextObject]){
        if ([arrayObject isKindOfClass:[UIDemoButton class]]){
            button = (UIDemoButton *)arrayObject;
            if (button.nextPuzzle || button.finalPuzzle){
                button.hidden = YES;
            }
        }
    }
}

- (NSMutableDictionary *)resetPuzzleDictionary:(NSMutableDictionary *)puzzleDictionary {
    NSMutableDictionary *resetDictionary = nil;
    if (puzzleDictionary != nil) {
        resetDictionary = [NSMutableDictionary dictionaryWithDictionary:puzzleDictionary];
        //
        // Read-Write arrayOfMessageLabels associated with a Demo Puzzle
        //
        if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
            NSArray *arrayOfMessageButtonsAndLabels = [[NSArray alloc] init];
            arrayOfMessageButtonsAndLabels = [puzzleDictionary objectForKey:@"arrayOfMessageButtonsAndLabels"];
            [resetDictionary setObject:arrayOfMessageButtonsAndLabels forKey:@"arrayOfMessageButtonsAndLabels"];
        }
        
        // Fetch Jewels
        NSArray *jewelDictionaryArray = [puzzleDictionary objectForKey:@"arrayOfJewelsDictionaries"];
        [resetDictionary setObject:jewelDictionaryArray forKey:@"arrayOfJewelsDictionaries"];

        // Fetch Rectangles
        NSArray *rectangleDictionaryArray = [puzzleDictionary objectForKey:@"arrayOfRectanglesDictionaries"];
        [resetDictionary setObject:rectangleDictionaryArray forKey:@"arrayOfRectanglesDictionaries"];
        
        // Fetch Lasers
        NSArray *laserDictionaryArray = [puzzleDictionary objectForKey:@"arrayOfLasersDictionaries"];
        [resetDictionary setObject:laserDictionaryArray forKey:@"arrayOfLasersDictionaries"];
        
        // Fetch Mirrors
        NSMutableArray *mirrorDictionaryArray = [NSMutableArray arrayWithArray:[puzzleDictionary objectForKey:@"arrayOfMirrorsDictionaries"]];
        NSMutableDictionary *mirrorDictionary;
        NSEnumerator *puzzleDictionaryEnum = [mirrorDictionaryArray objectEnumerator];
        int tileIndex = 0;
        id currentObject;
        while (currentObject = [puzzleDictionaryEnum nextObject]) {
            mirrorDictionary = [NSMutableDictionary dictionaryWithDictionary:currentObject];
            BOOL fixed = [[mirrorDictionary objectForKey:@"fixed"] isEqualToNumber:[NSNumber numberWithInt:1]];
            if (!fixed){
                // If the Tile is not fixed then set all placed fields to zero
                [mirrorDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placed"];
                [mirrorDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedUsingHint"];
                [mirrorDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedManuallyMatchesHint"];
                [mirrorDictionaryArray replaceObjectAtIndex:tileIndex withObject:mirrorDictionary];
            }
            tileIndex++;
        }
        [resetDictionary setObject:mirrorDictionaryArray forKey:@"arrayOfMirrorsDictionaries"];
        
        // Fetch Prisms
        NSMutableArray *prismDictionaryArray = [NSMutableArray arrayWithArray:[puzzleDictionary objectForKey:@"arrayOfPrismsDictionaries"]];
        NSMutableDictionary *prismDictionary;
        puzzleDictionaryEnum = [prismDictionaryArray objectEnumerator];
        tileIndex = 0;
        while (currentObject = [puzzleDictionaryEnum nextObject]) {
            prismDictionary = [NSMutableDictionary dictionaryWithDictionary:currentObject];
            BOOL fixed = [[prismDictionary objectForKey:@"fixed"] isEqualToNumber:[NSNumber numberWithInt:1]];
            if (!fixed){
                // If the Tile is not fixed then set all placed fields to zero
                [prismDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placed"];
                [prismDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedUsingHint"];
                [prismDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedManuallyMatchesHint"];
                [prismDictionaryArray replaceObjectAtIndex:tileIndex withObject:prismDictionary];
            }
            tileIndex++;
        }
        [resetDictionary setObject:prismDictionaryArray forKey:@"arrayOfPrismsDictionaries"];

        // Fetch Beamsplitters
        NSMutableArray *beamsplitterDictionaryArray = [NSMutableArray arrayWithArray:[puzzleDictionary objectForKey:@"arrayOfBeamsplittersDictionaries"]];
        NSMutableDictionary *beamsplitterDictionary;
        puzzleDictionaryEnum = [beamsplitterDictionaryArray objectEnumerator];
        tileIndex = 0;
        while (currentObject = [puzzleDictionaryEnum nextObject]) {
            beamsplitterDictionary = [NSMutableDictionary dictionaryWithDictionary:currentObject];
            BOOL fixed = [[beamsplitterDictionary objectForKey:@"fixed"] isEqualToNumber:[NSNumber numberWithInt:1]];
            if (!fixed){
                // If the Tile is not fixed then set all placed fields to zero
                [beamsplitterDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placed"];
                [beamsplitterDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedUsingHint"];
                [beamsplitterDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedManuallyMatchesHint"];
                [beamsplitterDictionaryArray replaceObjectAtIndex:tileIndex withObject:beamsplitterDictionary];
            }
            tileIndex++;
        }
        [resetDictionary setObject:beamsplitterDictionaryArray forKey:@"arrayOfBeamsplittersDictionaries"];
    }
    return resetDictionary;
}

- (void)buildPuzzleFromDictionary:(NSMutableDictionary *)puzzleDictionary
                     showAllTiles:(BOOL)showAll
                    allTilesFixed:(BOOL)allTilesFixed {
    if (puzzleDictionary != nil) {
        // Load the puzzleCompletionCondition value if present
        if ([puzzleDictionary objectForKey:@"puzzleCompletionCondition"]){
            puzzleCompletionCondition = [[puzzleDictionary objectForKey:@"puzzleCompletionCondition"] intValue];
        }
        else {
            puzzleCompletionCondition = ALL_JEWELS_ENERGIZED;
        }
        
        // Normally display background array
        displayBackgroundArray = YES;
        displayBackgroundImage = YES;
        circleAroundHintsButton = NO;
        //
        // Fetch arrayOfMessageLabels associated with a Demo Puzzle
        //
        if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
            NSArray *arrayOfMessageButtonsAndLabels = [[NSArray alloc] init];
            arrayOfMessageButtonsAndLabels = [puzzleDictionary objectForKey:@"arrayOfMessageButtonsAndLabels"];
            
            if ([[puzzleDictionary objectForKey:@"displayBackgroundArray"]boolValue] == NO){
                displayBackgroundArray = NO;
            }

            if ([[puzzleDictionary objectForKey:@"displayBackgroundImage"]boolValue] == NO){
                displayBackgroundImage = NO;
            }
            
            if ([[puzzleDictionary objectForKey:@"circleAroundHintsButton"]boolValue] == YES){
                circleAroundHintsButton = YES;
            }
            
            infoScreen = [[puzzleDictionary objectForKey:@"infoScreen"]boolValue];
            
            dragTile = NO;
            tapTile = NO;


            if ([arrayOfMessageButtonsAndLabels count] > 0){
                vc.demoMessageButtonsAndLabels = [[NSMutableArray alloc] initWithCapacity:1];
                
                // Retrieve messageLabelDictionary - the Dictionary associated with this label
                NSDictionary *messageLabelDictionary, *messageLabelAspectRatioDictionary;
                vc.infoScreenLabelArray = [NSMutableArray arrayWithCapacity:1];
                unsigned int labelIndex = 0;
                NSEnumerator *arrayEnum = [arrayOfMessageButtonsAndLabels objectEnumerator];
                while (messageLabelDictionary = [arrayEnum nextObject]){
                    // Retrieve aspectRatioDictionary - Dictionary associated with this aspect ratio
                    switch (rc->displayAspectRatio) {
                        case ASPECT_4_3: {
                            // iPad (9th generation)
                            messageLabelAspectRatioDictionary = [messageLabelDictionary objectForKey:@"ASPECT_4_3"];
                            break;
                        }
                        case ASPECT_10_7: {
                            // iPad Air (5th generation)
                            messageLabelAspectRatioDictionary = [messageLabelDictionary objectForKey:@"ASPECT_10_7"];
                            break;
                        }
                        case ASPECT_3_2: {
                            // iPad Mini (6th generation)
                            messageLabelAspectRatioDictionary = [messageLabelDictionary objectForKey:@"ASPECT_3_2"];
                            break;
                        }
                        case ASPECT_16_9: {
                            // iPhone 8
                            messageLabelAspectRatioDictionary = [messageLabelDictionary objectForKey:@"ASPECT_16_9"];
                            break;
                        }
                        case ASPECT_13_6: {
                            // iPhone 14
                            messageLabelAspectRatioDictionary = [messageLabelDictionary objectForKey:@"ASPECT_13_6"];
                            break;
                        }
                    }

                    CGFloat labelWidthPoints, labelHeightPoints, labelPosXPoints, labelPosYPoints, propX, propY;
                    
                    // Set label dimensions
                    if ([messageLabelAspectRatioDictionary objectForKey:@"labelSizeXPoints"] != nil &&
                        [messageLabelAspectRatioDictionary objectForKey:@"labelSizeYPoints"] != nil){
                        // If keys exist then use @"labelSizeXPoints" and @"labelSizeYPoints"
                        labelWidthPoints = [[messageLabelAspectRatioDictionary objectForKey:@"labelSizeXPoints"] floatValue];
                        labelHeightPoints = [[messageLabelAspectRatioDictionary objectForKey:@"labelSizeYPoints"] floatValue];
                    }
                    else {
                        // else choose sizes based on display and tile sizes
                        labelWidthPoints = (_puzzleDisplayWidthInPixels-0.3*_squareTileSideLengthInPixels)/rc.contentScaleFactor;
                        labelHeightPoints = (2.5*_squareTileSideLengthInPixels)/rc.contentScaleFactor;
                    }
                    
                    // Set label position
                    if ([messageLabelAspectRatioDictionary objectForKey:@"labelOffsetXPoints"] != nil &&
                        [messageLabelAspectRatioDictionary objectForKey:@"labelOffsetYPoints"] != nil){
                        labelPosXPoints = [[messageLabelAspectRatioDictionary objectForKey:@"labelOffsetXPoints"] floatValue];
                        labelPosYPoints = [[messageLabelAspectRatioDictionary objectForKey:@"labelOffsetYPoints"] floatValue];
                    }
                    else {
                        propX = [[messageLabelAspectRatioDictionary objectForKey:@"labelOffsetXProportion"] floatValue];
                        propY = [[messageLabelAspectRatioDictionary objectForKey:@"labelOffsetYProportion"] floatValue];
                        labelPosXPoints = propX*rc->screenWidthInPixels/rc->contentScaleFactor;
                        labelPosYPoints = propY*rc->screenHeightInPixels/rc->contentScaleFactor;
                    }
                    
                    // Build labelFrame
                    CGRect labelFrame;
                    if ([[messageLabelAspectRatioDictionary objectForKey:@"centerLabel"]boolValue]){
                        labelFrame = CGRectMake((rc->screenWidthInPixels/rc->contentScaleFactor)/2.0-labelWidthPoints/2.0,
                                                labelPosYPoints,
                                                labelWidthPoints,
                                                labelHeightPoints);
                    }
                    else {
                        labelFrame = CGRectMake(labelPosXPoints,
                                                labelPosYPoints,
                                                labelWidthPoints,
                                                labelHeightPoints);
                    }
                    
                    // Build UIDemoLabel
                    UIDemoLabel *label = [[UIDemoLabel alloc]initWithFrame:labelFrame];
                    [vc.infoScreenLabelArray addObject:label];
                    // Fetch booleans that determine how this label is used
                    label.nextPuzzle = [[messageLabelDictionary objectForKey:@"nextPuzzle"]boolValue];
                    label.dragTile = [[messageLabelDictionary objectForKey:@"dragTile"]boolValue];
                    if (label.dragTile){
                        dragTile = YES;
                    }
                    label.tapTile = [[messageLabelDictionary objectForKey:@"tapTile"]boolValue];
                    if (label.tapTile){
                        tapTile = YES;
                    }
                    label.puzzleComplete = [[messageLabelDictionary objectForKey:@"puzzleComplete"]boolValue];
                    label.finalPuzzle = [[messageLabelDictionary objectForKey:@"finalPuzzle"]boolValue];
                    // Fetch booleans that determine how this label is displayed
                    label.centerTextInLabel = [[messageLabelAspectRatioDictionary objectForKey:@"centerTextInLabel"]boolValue];
                    label.leftAlignTextInLabel = [[messageLabelAspectRatioDictionary objectForKey:@"leftAlignTextInLabel"]boolValue];
                    if (label.centerTextInLabel){
                        [label setTextAlignment:NSTextAlignmentCenter];
                    }
                    else if (label.leftAlignTextInLabel){
                        [label setTextAlignment:NSTextAlignmentLeft];
                    }
                    else {
                        [label setTextAlignment:NSTextAlignmentNatural];
                    }
                    puzzleFontSize = [[messageLabelAspectRatioDictionary objectForKey:@"labelFontSize"] floatValue];
                    BOOL labelBold = [[messageLabelAspectRatioDictionary objectForKey:@"labelBold"] boolValue];
                    if (labelBold){
                        label.font = [UIFont fontWithName:@"PingFang SC Semibold" size:puzzleFontSize];
                    }
                    else {
                        label.font = [UIFont fontWithName:@"PingFang SC Regular" size:puzzleFontSize];
                    }
                    label.text = [messageLabelAspectRatioDictionary objectForKey:@"labelText"];
                    label.textColor = [self getUIColorfromStringColor:[messageLabelAspectRatioDictionary objectForKey:@"labelColor"]];
                    label.numberOfLines = 0;
                    if (label.dragTile || label.tapTile || label.puzzleComplete){
                        label.hidden = YES;
                    }
                    else {
                        label.hidden = NO;
                    }
                    [vc.demoMessageButtonsAndLabels addObject:label];
                    [vc.view addSubview:label];
                    labelIndex++;
                }
            }
        }
        //
        // End Demo-Specific Puzzle fetch
        //
        
        // Initialize the prism beam refracting matrices
        [self setupBeamHandlingMachinery];
        
        // Fetch tiles data from the plist and initialize the tiles and hints arrays
        tiles = [[NSMutableArray alloc] initWithCapacity:1];
        hints = [[NSMutableArray alloc] initWithCapacity:1];
        
        // Start placing movable Tiles (fixed==NO) in the left side of the Unused Tiles Area
        int movableTileX = 1;
        int movableTileY = masterGrid.sizeY;
        
        // Used to manipulate current working tile
        Tile *tile;
        
        vector_int2 dimensions;
        
        
        // Fetch Jewels
        NSArray *jewelDictionaryArray = [puzzleDictionary objectForKey:@"arrayOfJewelsDictionaries"];
        NSEnumerator *puzzleDictionaryEnum = [jewelDictionaryArray objectEnumerator];
        NSMutableDictionary *jewelDictionary;
        while (jewelDictionary = [puzzleDictionaryEnum nextObject]) {
            BOOL placed = [[jewelDictionary objectForKey:@"placed"] isEqualToNumber:[NSNumber numberWithInt:1]];
            BOOL placedUsingHint = [[jewelDictionary objectForKey:@"placedUsingHint"] isEqualToNumber:[NSNumber numberWithInt:1]];
            BOOL placedManuallyMatchesHint = [[jewelDictionary objectForKey:@"placedManuallyMatchesHint"] isEqualToNumber:[NSNumber numberWithInt:1]];
            BOOL fixed = [[jewelDictionary objectForKey:@"fixed"] isEqualToNumber:[NSNumber numberWithInt:1]]
                            || allTilesFixed;
            
            int finalX = [[jewelDictionary objectForKey:@"finalX"] intValue];
            int finalY = [[jewelDictionary objectForKey:@"finalY"] intValue];
            dimensions.x = _squareTileSideLengthInPixels;
            dimensions.y = _squareTileSideLengthInPixels;
            tile = [self buildOneTileFromDictionary:jewelDictionary tileShape:JEWEL movableTileX:(int)movableTileX movableTileY:(int)movableTileY];
            if (!fixed && !placed && !placedUsingHint && !placedManuallyMatchesHint){
                if (++movableTileX > masterGrid.sizeX-1) {
                    movableTileX = 0;
                    movableTileY--;
                }
            }
            if (puzzleCompletionCondition == USER_TOUCH){
                // If waiting for USER_TOUCH then Tile should be in finalGridPosition and finalTileAngle
                tile->gridPosition.x = finalX;
                tile->gridPosition.y = finalY;
                tile->tilePositionInPixels.x = (CGFloat)finalX*_squareTileSideLengthInPixels + _tileHorizontalOffsetInPixels;
                tile->tilePositionInPixels.y = (CGFloat)finalY*_squareTileSideLengthInPixels + _tileVerticalOffsetInPixels;
                tile->tileAngle = tile->finalTileAngle;
            }
            
            if (![self searchForTileAtSameGridPosition:tile array:tiles]){
                [self putOpticsTile:tile array:tiles];
            }
            
            // Allow Jewels to be initialized in the energized state for demonstration purposes
            if (rc.appCurrentGamePackType == PACKTYPE_DEMO &&
                [[jewelDictionary objectForKey:@"showEnergized"]boolValue] == YES){
                tile->showEnergized = YES;
            }
        }
        
        // Fetch Rectangles
        NSArray *rectangleDictionaryArray = [puzzleDictionary objectForKey:@"arrayOfRectanglesDictionaries"];
        NSMutableDictionary *rectangleDictionary;
        puzzleDictionaryEnum = [rectangleDictionaryArray objectEnumerator];
        while (rectangleDictionary = [puzzleDictionaryEnum nextObject]) {
            BOOL placed = [[rectangleDictionary objectForKey:@"placed"] isEqualToNumber:[NSNumber numberWithInt:1]];
            BOOL placedUsingHint = [[rectangleDictionary objectForKey:@"placedUsingHint"] isEqualToNumber:[NSNumber numberWithInt:1]];
            BOOL placedManuallyMatchesHint = [[rectangleDictionary objectForKey:@"placedManuallyMatchesHint"] isEqualToNumber:[NSNumber numberWithInt:1]];
            BOOL fixed = [[rectangleDictionary objectForKey:@"fixed"] isEqualToNumber:[NSNumber numberWithInt:1]]
            || allTilesFixed;

            
            int finalX = [[rectangleDictionary objectForKey:@"finalX"] intValue];
            int finalY = [[rectangleDictionary objectForKey:@"finalY"] intValue];
            dimensions.x = _squareTileSideLengthInPixels;
            dimensions.y = _squareTileSideLengthInPixels;
            tile = [self buildOneTileFromDictionary:rectangleDictionary tileShape:RECTANGLE movableTileX:(int)movableTileX movableTileY:(int)movableTileY];
            if (!fixed && !placed && !placedUsingHint && !placedManuallyMatchesHint){
                if (++movableTileX > masterGrid.sizeX-1) {
                    movableTileX = 0;
                    movableTileY--;
                }
            }
            if (puzzleCompletionCondition == USER_TOUCH){
                // If waiting for USER_TOUCH then Tile should be in finalGridPosition and finalTileAngle
                tile->gridPosition.x = finalX;
                tile->gridPosition.y = finalY;
                tile->tilePositionInPixels.x = (CGFloat)finalX*_squareTileSideLengthInPixels + _tileHorizontalOffsetInPixels;
                tile->tilePositionInPixels.y = (CGFloat)finalY*_squareTileSideLengthInPixels + _tileVerticalOffsetInPixels;
                tile->tileAngle = tile->finalTileAngle;
            }
            
            if (![self searchForTileAtSameGridPosition:tile array:tiles]){
                [self putOpticsTile:tile array:tiles];
            }
        }
        
        // Fetch Lasers
        NSArray *laserDictionaryArray = [puzzleDictionary objectForKey:@"arrayOfLasersDictionaries"];
        NSMutableDictionary *laserDictionary;
        puzzleDictionaryEnum = [laserDictionaryArray objectEnumerator];
        while (laserDictionary = [puzzleDictionaryEnum nextObject]) {
            
            BOOL placed = [[laserDictionary objectForKey:@"placed"] isEqualToNumber:[NSNumber numberWithInt:1]];
            BOOL placedUsingHint = [[laserDictionary objectForKey:@"placedUsingHint"] isEqualToNumber:[NSNumber numberWithInt:1]];
            BOOL placedManuallyMatchesHint = [[laserDictionary objectForKey:@"placedManuallyMatchesHint"] isEqualToNumber:[NSNumber numberWithInt:1]];
            BOOL fixed = [[laserDictionary objectForKey:@"fixed"] isEqualToNumber:[NSNumber numberWithInt:1]]
                        || allTilesFixed;

            int finalX = [[laserDictionary objectForKey:@"finalX"] intValue];
            int finalY = [[laserDictionary objectForKey:@"finalY"] intValue];
            dimensions.x = _squareTileSideLengthInPixels;
            dimensions.y = _squareTileSideLengthInPixels;
            tile = [self buildOneTileFromDictionary:laserDictionary tileShape:LASER movableTileX:(int)movableTileX movableTileY:(int)movableTileY];
            if (!fixed && !placed && !placedUsingHint && !placedManuallyMatchesHint){
                if (++movableTileX > masterGrid.sizeX-1) {
                    movableTileX = 0;
                    movableTileY--;
                }
            }
            if (puzzleCompletionCondition == USER_TOUCH){
                // If waiting for USER_TOUCH then Tile should be in finalGridPosition and finalTileAngle
                tile->gridPosition.x = finalX;
                tile->gridPosition.y = finalY;
                tile->tilePositionInPixels.x = (CGFloat)finalX*_squareTileSideLengthInPixels + _tileHorizontalOffsetInPixels;
                tile->tilePositionInPixels.y = (CGFloat)finalY*_squareTileSideLengthInPixels + _tileVerticalOffsetInPixels;
                tile->tileAngle = tile->finalTileAngle;
            }
            // Handle hidden Laser
            BOOL hidden = [[laserDictionary objectForKey:@"hidden"] boolValue];
            tile->hidden = hidden;
            [self putOpticsTile:tile array:tiles];
        }
        
        // Fetch Mirrors
        NSArray *mirrorDictionaryArray = [puzzleDictionary objectForKey:@"arrayOfMirrorsDictionaries"];
        NSMutableDictionary *mirrorDictionary;
        puzzleDictionaryEnum = [mirrorDictionaryArray objectEnumerator];
        mirrorCount = 0;
        while (mirrorDictionary = [puzzleDictionaryEnum nextObject]) {
            
            BOOL placed = [[mirrorDictionary objectForKey:@"placed"] isEqualToNumber:[NSNumber numberWithInt:1]];
            BOOL placedUsingHint = [[mirrorDictionary objectForKey:@"placedUsingHint"] isEqualToNumber:[NSNumber numberWithInt:1]];
            BOOL placedManuallyMatchesHint = [[mirrorDictionary objectForKey:@"placedManuallyMatchesHint"] isEqualToNumber:[NSNumber numberWithInt:1]];
            BOOL fixed = [[mirrorDictionary objectForKey:@"fixed"] isEqualToNumber:[NSNumber numberWithInt:1]]
                        || allTilesFixed;

            
            int finalX = [[mirrorDictionary objectForKey:@"finalX"] intValue];
            int finalY = [[mirrorDictionary objectForKey:@"finalY"] intValue];
            dimensions.x = _squareTileSideLengthInPixels;
            dimensions.y = _squareTileSideLengthInPixels;
            tile = [self buildOneTileFromDictionary:mirrorDictionary tileShape:MIRROR movableTileX:(int)movableTileX movableTileY:(int)movableTileY];
            if (!fixed && !placed && !placedUsingHint && !placedManuallyMatchesHint){
                if (++movableTileX > masterGrid.sizeX-1) {
                    movableTileX = 0;
                    movableTileY--;
                }
            }
            if (puzzleCompletionCondition == USER_TOUCH){
                // If waiting for USER_TOUCH then Tile should be in finalGridPosition and finalTileAngle
                tile->gridPosition.x = finalX;
                tile->gridPosition.y = finalY;
                tile->tilePositionInPixels.x = (CGFloat)finalX*_squareTileSideLengthInPixels + _tileHorizontalOffsetInPixels;
                tile->tilePositionInPixels.y = (CGFloat)finalY*_squareTileSideLengthInPixels + _tileVerticalOffsetInPixels;
                tile->tileAngle = tile->finalTileAngle;
            }
            
            if (![self searchForTileAtSameGridPosition:tile array:tiles]){
                [self putOpticsTile:tile array:tiles];
            }
        }
        
        // Fetch Prisms
        NSArray *prismDictionaryArray = [puzzleDictionary objectForKey:@"arrayOfPrismsDictionaries"];
        NSMutableDictionary *prismDictionary;
        puzzleDictionaryEnum = [prismDictionaryArray objectEnumerator];
        prismCount = 0;
        while (prismDictionary = [puzzleDictionaryEnum nextObject]) {
            BOOL placed = [[prismDictionary objectForKey:@"placed"] isEqualToNumber:[NSNumber numberWithInt:1]];
            BOOL placedUsingHint = [[prismDictionary objectForKey:@"placedUsingHint"] isEqualToNumber:[NSNumber numberWithInt:1]];
            BOOL placedManuallyMatchesHint = [[prismDictionary objectForKey:@"placedManuallyMatchesHint"] isEqualToNumber:[NSNumber numberWithInt:1]];
            BOOL fixed = [[prismDictionary objectForKey:@"fixed"] isEqualToNumber:[NSNumber numberWithInt:1]]
                        || allTilesFixed;

            
            int finalX = [[prismDictionary objectForKey:@"finalX"] intValue];
            int finalY = [[prismDictionary objectForKey:@"finalY"] intValue];
            dimensions.x = _squareTileSideLengthInPixels;
            dimensions.y = _squareTileSideLengthInPixels;
            
            tile = [self buildOneTileFromDictionary:prismDictionary tileShape:PRISM movableTileX:(int)movableTileX movableTileY:(int)movableTileY];
            
            if (!fixed && !placed && !placedUsingHint && !placedManuallyMatchesHint){
                if (++movableTileX > masterGrid.sizeX-1) {
                    movableTileX = 0;
                    movableTileY--;
                }
            }
            
            if (puzzleCompletionCondition == USER_TOUCH){
                // If waiting for USER_TOUCH then Tile should be in finalGridPosition and finalTileAngle
                tile->gridPosition.x = finalX;
                tile->gridPosition.y = finalY;
                tile->tilePositionInPixels.x = (CGFloat)finalX*_squareTileSideLengthInPixels + _tileHorizontalOffsetInPixels;
                tile->tilePositionInPixels.y = (CGFloat)finalY*_squareTileSideLengthInPixels + _tileVerticalOffsetInPixels;
                tile->tileAngle = tile->finalTileAngle;
            }
            
            if (![self searchForTileAtSameGridPosition:tile array:tiles]){
                [self putOpticsTile:tile array:tiles];
            }
        }
        
        // Fetch Beamsplitters
        NSArray *beamsplitterDictionaryArray = [puzzleDictionary objectForKey:@"arrayOfBeamsplittersDictionaries"];
        NSMutableDictionary *beamsplitterDictionary;
        puzzleDictionaryEnum = [beamsplitterDictionaryArray objectEnumerator];
        beamsplitterCount = 0;
        while (beamsplitterDictionary = [puzzleDictionaryEnum nextObject]) {
            BOOL placed = [[beamsplitterDictionary objectForKey:@"placed"] isEqualToNumber:[NSNumber numberWithInt:1]];
            BOOL placedUsingHint = [[beamsplitterDictionary objectForKey:@"placedUsingHint"] isEqualToNumber:[NSNumber numberWithInt:1]];
            BOOL placedManuallyMatchesHint = [[beamsplitterDictionary objectForKey:@"placedManuallyMatchesHint"] isEqualToNumber:[NSNumber numberWithInt:1]];
            BOOL fixed = [[beamsplitterDictionary objectForKey:@"fixed"] isEqualToNumber:[NSNumber numberWithInt:1]]
                        || allTilesFixed;

            
            int finalX = [[beamsplitterDictionary objectForKey:@"finalX"] intValue];
            int finalY = [[beamsplitterDictionary objectForKey:@"finalY"] intValue];
            dimensions.x = _squareTileSideLengthInPixels;
            dimensions.y = _squareTileSideLengthInPixels;
            
            tile = [self buildOneTileFromDictionary:beamsplitterDictionary tileShape:BEAMSPLITTER movableTileX:(int)movableTileX movableTileY:(int)movableTileY];
            
            if (!fixed && !placed && !placedUsingHint && !placedManuallyMatchesHint){
                if (++movableTileX > masterGrid.sizeX-1) {
                    movableTileX = 0;
                    movableTileY--;
                }
            }
            
            if (puzzleCompletionCondition == USER_TOUCH){
                // If waiting for USER_TOUCH then Tile should be in finalGridPosition and finalTileAngle
                tile->gridPosition.x = finalX;
                tile->gridPosition.y = finalY;
                tile->tilePositionInPixels.x = (CGFloat)finalX*_squareTileSideLengthInPixels + _tileHorizontalOffsetInPixels;
                tile->tilePositionInPixels.y = (CGFloat)finalY*_squareTileSideLengthInPixels + _tileVerticalOffsetInPixels;
                tile->tileAngle = tile->finalTileAngle;
            }
            
            if (![self searchForTileAtSameGridPosition:tile array:tiles]){
                [self putOpticsTile:tile array:tiles];
            }
        }
    }
}

- (Tile *)buildOneTileFromDictionary:(NSMutableDictionary *)tileDictionary tileShape:(enum eTileShape)tileShape movableTileX:(int)movableTileX movableTileY:(int)movableTileY {
    Tile *tile;
    vector_int2 center, dimensions;
    int color = [[tileDictionary objectForKey:@"Color"] intValue];
    int angle = [[tileDictionary objectForKey:@"Angle"] intValue];
    int finalX = [[tileDictionary objectForKey:@"finalX"] intValue];
    int finalY = [[tileDictionary objectForKey:@"finalY"] intValue];
    int placedX = [[tileDictionary objectForKey:@"placedX"] intValue];
    int placedY = [[tileDictionary objectForKey:@"placedY"] intValue];
    int finalTileAngle = [[tileDictionary objectForKey:@"finalTileAngle"] intValue];
    dimensions.x = _squareTileSideLengthInPixels;
    dimensions.y = _squareTileSideLengthInPixels;
    int displayGridPositionX, displayGridPositionY;
    
    if ([[tileDictionary objectForKey:@"placed"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
        angle = [[tileDictionary objectForKey:@"placedTileAngle"] intValue];
        if ([appd editModeIsEnabled]){
            displayGridPositionX = finalX;
            displayGridPositionY = finalY;
        }
        else {
            displayGridPositionX = placedX;
            displayGridPositionY = placedY;
        }
        center.x = (CGFloat)displayGridPositionX*_squareTileSideLengthInPixels + _tileHorizontalOffsetInPixels;
        center.y = (CGFloat)displayGridPositionY*_squareTileSideLengthInPixels + _tileVerticalOffsetInPixels;
        tile = [[Tile alloc] initWithGridParameters:self  cx:displayGridPositionX cy:displayGridPositionY cz:0 shape:tileShape angle:angle visible:YES  color:color fixed:NO  centerPositionInPixels:center dimensionsInPixels:dimensions];
        tile->finalTileAngle = finalTileAngle;
        tile->finalGridPosition.x = finalX;
        tile->finalGridPosition.y = finalY;
        tile->placed = YES;
        tile->placedUsingHint = NO;
        tile->placedManuallyMatchesHint = NO;
        [self createHintFromTile:tile];
    }
    else if ([[tileDictionary objectForKey:@"placedUsingHint"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
        angle = [[tileDictionary objectForKey:@"placedTileAngle"] intValue];
        if ([appd editModeIsEnabled]){
            displayGridPositionX = finalX;
            displayGridPositionY = finalY;
        }
        else {
            displayGridPositionX = placedX;
            displayGridPositionY = placedY;
        }
        center.x = (CGFloat)displayGridPositionX*_squareTileSideLengthInPixels + _tileHorizontalOffsetInPixels;
        center.y = (CGFloat)displayGridPositionY*_squareTileSideLengthInPixels + _tileVerticalOffsetInPixels;        tile = [[Tile alloc] initWithGridParameters:self  cx:displayGridPositionX cy:displayGridPositionY cz:0 shape:tileShape angle:angle visible:YES  color:color fixed:NO  centerPositionInPixels:center dimensionsInPixels:dimensions];
        tile->placedTileAngle = angle;
        tile->placedGridPosition.x = placedX;
        tile->placedGridPosition.y = placedY;
        tile->finalTileAngle = finalTileAngle;
        tile->finalGridPosition.x = finalX;
        tile->finalGridPosition.y = finalY;
        tile->placed = NO;
        tile->placedUsingHint = YES;
        tile->placedManuallyMatchesHint = NO;
        [self createHintFromTile:tile];
    }
    else if ([[tileDictionary objectForKey:@"placedManuallyMatchesHint"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
        angle = [[tileDictionary objectForKey:@"placedTileAngle"] intValue];
        if ([appd editModeIsEnabled]){
            displayGridPositionX = finalX;
            displayGridPositionY = finalY;
        }
        else {
            displayGridPositionX = placedX;
            displayGridPositionY = placedY;
        }
        center.x = (CGFloat)displayGridPositionX*_squareTileSideLengthInPixels + _tileHorizontalOffsetInPixels;
        center.y = (CGFloat)displayGridPositionY*_squareTileSideLengthInPixels + _tileVerticalOffsetInPixels;        tile = [[Tile alloc] initWithGridParameters:self  cx:displayGridPositionX cy:displayGridPositionY cz:0 shape:tileShape angle:angle visible:YES  color:color fixed:NO  centerPositionInPixels:center dimensionsInPixels:dimensions];
        tile->placedTileAngle = angle;
        tile->placedGridPosition.x = placedX;
        tile->placedGridPosition.y = placedY;
        tile->finalTileAngle = finalTileAngle;
        tile->finalGridPosition.x = finalX;
        tile->finalGridPosition.y = finalY;
        tile->placed = NO;
        tile->placedUsingHint = NO;
        tile->placedManuallyMatchesHint = YES;
        [self createHintFromTile:tile];
    }
    else if ([[tileDictionary objectForKey:@"fixed"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
        angle = [[tileDictionary objectForKey:@"finalTileAngle"] intValue];
        center.x = (CGFloat)finalX*_squareTileSideLengthInPixels + _tileHorizontalOffsetInPixels;
        center.y = (CGFloat)finalY*_squareTileSideLengthInPixels + _tileVerticalOffsetInPixels;
        tile = [[Tile alloc] initWithGridParameters:self  cx:finalX cy:finalY cz:0 shape:tileShape angle:angle visible:YES  color:color fixed:YES  centerPositionInPixels:center dimensionsInPixels:dimensions];
        int tileShape = [[tileDictionary objectForKey:@"tileShape"] intValue];
        if (tileShape == RECTANGLE && color == COLOR_OPAQUE){
            angle = 2*((arc4random_uniform(8))/2);
        }
        tile->finalGridPosition.x = finalX;
        tile->finalGridPosition.y = finalY;
        tile->finalTileAngle = angle;
        tile->placed = NO;
        tile->placedUsingHint = NO;
        tile->placedManuallyMatchesHint = NO;
    }
    else {
        if ([appd editModeIsEnabled]){
            displayGridPositionX = finalX;
            displayGridPositionY = finalY;
            angle = [[tileDictionary objectForKey:@"Angle"] intValue];
        }
        else {
            displayGridPositionX = movableTileX;
            displayGridPositionY = movableTileY;
            if (tileShape == BEAMSPLITTER){
                angle = ANGLE135;
            }
            else if (tileShape == MIRROR){
                angle = ANGLE45;
            }
            else {
                angle = ANGLE135;
            }
        }
        center.x = (CGFloat)displayGridPositionX*_squareTileSideLengthInPixels + _tileHorizontalOffsetInPixels;
        center.y = (CGFloat)displayGridPositionY*_squareTileSideLengthInPixels + _tileVerticalOffsetInPixels;
        tile = [[Tile alloc] initWithGridParameters:self  cx:displayGridPositionX cy:displayGridPositionY cz:0 shape:tileShape angle:angle visible:YES  color:color fixed:NO  centerPositionInPixels:center dimensionsInPixels:dimensions];
        tile->finalTileAngle = [[tileDictionary objectForKey:@"finalTileAngle"] intValue];
        tile->finalGridPosition.x = finalX;
        tile->finalGridPosition.y = finalY;
        tile->placed = NO;
        tile->placedUsingHint = NO;
        tile->placedManuallyMatchesHint = NO;
        [self createHintFromTile:tile];
    }
    
    tile->tileAngle = angle;
    
    if ([[tileDictionary objectForKey:@"demoTile"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
        tile->demoTile = YES;
    }
    else {
        tile->demoTile = NO;
    }
    
    if ([[tileDictionary objectForKey:@"demoTileAtFinalGridPosition"] isEqualToNumber:[NSNumber numberWithInt:1]]
        && tile->demoTile) {
        tile->demoTileAtFinalGridPosition = YES;
    }
    else {
        tile->demoTileAtFinalGridPosition = NO;
    }
    
    return tile;
}

- (NSMutableDictionary *)encodeAnEmptyPuzzleAsMutableDictionary:(NSMutableDictionary *)dictionary {
    // Clear out dictionaryName in case it already contains some objects
    [dictionary removeAllObjects];
    [dictionary setObject:[[NSNumber alloc] initWithInt:100] forKey:kPuzzlePointValueKey];
    // Build arrays for each tileShape
    NSMutableArray *jewels = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *lasers = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *prisms = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *mirrors = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *beamsplitters = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *rectangles = [NSMutableArray arrayWithCapacity:1];
    [dictionary setObject:beamsplitters forKey:@"arrayOfBeamsplittersDictionaries"];
    [dictionary setObject:prisms forKey:@"arrayOfPrismsDictionaries"];
    [dictionary setObject:mirrors forKey:@"arrayOfMirrorsDictionaries"];
    [dictionary setObject:jewels forKey:@"arrayOfJewelsDictionaries"];
    [dictionary setObject:lasers forKey:@"arrayOfLasersDictionaries"];
    [dictionary setObject:rectangles forKey:@"arrayOfRectanglesDictionaries"];
    [dictionary setObject:[NSNumber numberWithInt:ALL_JEWELS_ENERGIZED] forKey:@"puzzleCompletionCondition"];
    
    [dictionary setObject:[NSNumber numberWithInt:gameGrid.sizeX] forKey:@"gridSizeX"];
    [dictionary setObject:[NSNumber numberWithInt:gameGrid.sizeY] forKey:@"gridSizeY"];
    
    // Return the modified dictionary to the caller
    return dictionary;
}

- (NSMutableDictionary *)encodeCurrentPuzzleAsMutableDictionary:(NSMutableDictionary *)dictionary {
    // Clear out dictionaryName in case it already contains some objects
    [dictionary removeAllObjects];
    // Store the NSNumber representing the value of this puzzle in points (default is 100)
    [dictionary setObject:[[NSNumber alloc] initWithInt:100] forKey:kPuzzlePointValueKey];
    // Build arrays for each tileShape
    NSMutableArray *jewels = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *lasers = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *prisms = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *mirrors = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *beamsplitters = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *rectangles = [NSMutableArray arrayWithCapacity:1];
    Tile *myTile;
    NSEnumerator *tileArrayEnum = [tiles objectEnumerator];
    int gridPositionMaxX = 0, gridPositionMaxY = 0;
    while (myTile = [tileArrayEnum nextObject]){
        
        if ([appd editModeIsEnabled]){
            // If dictionary created by editor then size the grid to just hold all of the Tiles
            //            if (myTile->gridPosition.x > gridPositionMaxX){
            //                gridPositionMaxX = myTile->gridPosition.x;
            //            }
            //            if (myTile->gridPosition.y > gridPositionMaxY){
            //                gridPositionMaxY = myTile->gridPosition.y;
            //            }
        }
        
        switch(myTile->tileShape){
            case JEWEL:
            {
                NSMutableDictionary *jewelDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
                [self encodeOneTileInDictionary:jewelDictionary tile:myTile];
                [jewels addObject:jewelDictionary];
            }
                break;
            case LASER:
            {
                NSMutableDictionary *laserDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
                [self encodeOneTileInDictionary:laserDictionary tile:myTile];
                [lasers addObject:laserDictionary];
            }
                break;
            case MIRROR:
            {
                NSMutableDictionary *mirrorDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
                [self encodeOneTileInDictionary:mirrorDictionary tile:myTile];
                [mirrors addObject:mirrorDictionary];
            }
                break;
            case PRISM:
            {
                NSMutableDictionary *prismDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
                [self encodeOneTileInDictionary:prismDictionary tile:myTile];
                [prisms addObject:prismDictionary];
            }
                break;
            case BEAMSPLITTER:
            {
                NSMutableDictionary *beamsplitterDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
                [self encodeOneTileInDictionary:beamsplitterDictionary tile:myTile];
                [beamsplitters addObject:beamsplitterDictionary];
            }
                break;
            case RECTANGLE:
            {
                NSMutableDictionary *rectangleDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
                [rectangleDictionary setObject:[NSNumber numberWithInt:myTile->tileColor] forKey:@"Color"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:myTile->finalGridPosition.x] forKey:@"finalX"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:myTile->finalGridPosition.y] forKey:@"finalY"];
                if (myTile->fixed) {
                    [rectangleDictionary setObject:[NSNumber numberWithInt:1] forKey:@"fixed"];
                }
                else {
                    [rectangleDictionary setObject:[NSNumber numberWithInt:0] forKey:@"fixed"];
                }
                [rectangles addObject:rectangleDictionary];
                break;
            }
            default:
            {
                DLog("Unrecognized tileShape: %d", myTile->tileShape);
                break;
            }
        }
    }
    [dictionary setObject:beamsplitters forKey:@"arrayOfBeamsplittersDictionaries"];
    [dictionary setObject:prisms forKey:@"arrayOfPrismsDictionaries"];
    [dictionary setObject:mirrors forKey:@"arrayOfMirrorsDictionaries"];
    [dictionary setObject:jewels forKey:@"arrayOfJewelsDictionaries"];
    [dictionary setObject:lasers forKey:@"arrayOfLasersDictionaries"];
    [dictionary setObject:rectangles forKey:@"arrayOfRectanglesDictionaries"];
    [dictionary setObject:[NSNumber numberWithInt:ALL_JEWELS_ENERGIZED] forKey:@"puzzleCompletionCondition"];
    
    [dictionary setObject:[NSNumber numberWithInt:gameGrid.sizeX] forKey:@"gridSizeX"];
    [dictionary setObject:[NSNumber numberWithInt:gameGrid.sizeY] forKey:@"gridSizeY"];
    
    // Return the modified dictionary to the caller
    return dictionary;
}

- (NSMutableDictionary *)encodeOneTileInDictionary:(NSMutableDictionary *)tileDictionary tile:(Tile *)tile {
    [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->tileColor] forKey:@"Color"];
    [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->tileAngle] forKey:@"Angle"];
    [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->tileShape] forKey:@"tileShape"];
    [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->gridPosition.x] forKey:@"gridPositionX"];
    [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->gridPosition.y] forKey:@"gridPositionY"];
    if (tile->demoTile == YES){
        [tileDictionary setObject:[NSNumber numberWithInt:1] forKey:@"demoTile"];
    }
    else {
        [tileDictionary setObject:[NSNumber numberWithInt:0] forKey:@"demoTile"];
    }
    if (tile->demoTileAtFinalGridPosition == YES){
        [tileDictionary setObject:[NSNumber numberWithInt:1] forKey:@"demoTileAtFinalGridPosition"];
    }
    else {
        [tileDictionary setObject:[NSNumber numberWithInt:0] forKey:@"demoTileAtFinalGridPosition"];
    }
    if (tile->placed) {
        [tileDictionary setObject:[NSNumber numberWithInt:1] forKey:@"placed"];
        [tileDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedUsingHint"];
        [tileDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedManuallyMatchesHint"];
        [tileDictionary setObject:[NSNumber numberWithInt:0] forKey:@"fixed"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->gridPosition.x] forKey:@"placedX"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->gridPosition.y] forKey:@"placedY"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->placedTileAngle] forKey:@"placedTileAngle"];
        //        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->tileAngle] forKey:@"placedTileAngle"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->finalGridPosition.x] forKey:@"finalX"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->finalGridPosition.y] forKey:@"finalY"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->finalTileAngle] forKey:@"finalTileAngle"];
    }
    else if (tile->placedUsingHint){
        [tileDictionary setObject:[NSNumber numberWithInt:1] forKey:@"placedUsingHint"];
        [tileDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placed"];
        [tileDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedManuallyMatchesHint"];
        [tileDictionary setObject:[NSNumber numberWithInt:0] forKey:@"fixed"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->placedGridPosition.x] forKey:@"placedX"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->placedGridPosition.y] forKey:@"placedY"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->placedTileAngle] forKey:@"placedTileAngle"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->finalGridPosition.x] forKey:@"finalX"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->finalGridPosition.y] forKey:@"finalY"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->finalTileAngle] forKey:@"finalTileAngle"];
    }
    else if (tile->placedManuallyMatchesHint){
        [tileDictionary setObject:[NSNumber numberWithInt:1] forKey:@"placedManuallyMatchesHint"];
        [tileDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedUsingHint"];
        [tileDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placed"];
        [tileDictionary setObject:[NSNumber numberWithInt:0] forKey:@"fixed"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->placedGridPosition.x] forKey:@"placedX"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->placedGridPosition.y] forKey:@"placedY"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->placedTileAngle] forKey:@"placedTileAngle"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->finalGridPosition.x] forKey:@"finalX"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->finalGridPosition.y] forKey:@"finalY"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->finalTileAngle] forKey:@"finalTileAngle"];
    }
    else if (tile->fixed) {
        [tileDictionary setObject:[NSNumber numberWithInt:1] forKey:@"fixed"];
        [tileDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placed"];
        [tileDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedUsingHint"];
        [tileDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedManuallyMatchesHint"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->finalGridPosition.x] forKey:@"finalX"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->finalGridPosition.y] forKey:@"finalY"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->tileAngle] forKey:@"finalTileAngle"];
        //        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->finalTileAngle] forKey:@"finalTileAngle"];
    }
    else {
        [tileDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedManuallyMatchesHint"];
        [tileDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedUsingHint"];
        [tileDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placed"];
        [tileDictionary setObject:[NSNumber numberWithInt:0] forKey:@"fixed"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->finalGridPosition.x] forKey:@"finalX"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->finalGridPosition.y] forKey:@"finalY"];
        [tileDictionary setObject:[NSNumber numberWithInt:(int)tile->finalTileAngle] forKey:@"finalTileAngle"];
    }
    return tileDictionary;
}

//
// This is used to load the next puzzle into the puzzle progress data in defaults
//
- (void)saveNextPuzzleToDefaults {
    DLog("saveNextPuzzleToDefaults");
    BMDAppDelegate *appd = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    BMDViewController *rc = (BMDViewController*)[[(BMDAppDelegate *)[[UIApplication sharedApplication]delegate] window] rootViewController];
    NSMutableDictionary *nextPuzzleDictionary;
    unsigned int currentPack, currentPuzzleNumber, nextPuzzleNumber, currentPackLength;
    
    if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
        currentPack = [appd fetchCurrentPackNumber];
        currentPuzzleNumber = [appd fetchCurrentPuzzleNumberForPack:currentPack];
        nextPuzzleNumber = currentPuzzleNumber+1;
        currentPackLength = [appd fetchCurrentPackLength];
        
        if (nextPuzzleNumber >= currentPackLength){
            [appd saveCurrentPuzzleNumberForPack:currentPack puzzleNumber:currentPackLength];
            DLog("Pack %d completed.  %d puzzles solved.", currentPack, currentPackLength);
        }
        else {
            [appd saveCurrentPuzzleNumberForPack:currentPack puzzleNumber:nextPuzzleNumber];
            nextPuzzleDictionary = [appd fetchCurrentPuzzleFromPackDictionary:currentPack];
            [appd saveCurrentPuzzleToPackGameProgress:currentPack puzzle:nextPuzzleDictionary];
        }
        // Update labels with pack and puzzle information
        [vc setPuzzleLabel];
        vc.packAndPuzzlesLabel.text = [NSString stringWithFormat:@"Pack: %d, Puzzle: %d",
                                       [appd fetchCurrentPackNumber],
                                       [appd fetchCurrentPuzzleNumber]
        ];
    }
    else if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *demoPackDictionary = [appd fetchPackDictionaryFromPlist:kDemoPuzzlePackDictionary];
        currentPackLength = [appd countPuzzlesWithinPack:demoPackDictionary];
        currentPuzzleNumber = [appd fetchDemoPuzzleNumber];
        nextPuzzleNumber = currentPuzzleNumber+1;
        
        [appd saveDemoPuzzleNumber:nextPuzzleNumber];
        if (nextPuzzleNumber >= currentPackLength){
            [defaults setObject:@"YES" forKey:@"demoHasBeenCompleted"];
            if (ENABLE_GA == YES){
                [FIRAnalytics logEventWithName:kFIREventTutorialComplete
                                    parameters:@{
                }];
            }
        }
    }
}

- (void)savePreviousPuzzleToDefaults {
    DLog("savePreviousPuzzleToDefaults");
    BMDAppDelegate *appd = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    BMDViewController *rc = (BMDViewController*)[[(BMDAppDelegate *)[[UIApplication sharedApplication]delegate] window] rootViewController];
    NSMutableDictionary *previousPuzzleDictionary;
    unsigned int currentPack, currentPuzzleNumber, previousPuzzleNumber;
    
    if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
        currentPack = [appd fetchCurrentPackNumber];
        currentPuzzleNumber = [appd fetchCurrentPuzzleNumberForPack:currentPack];
        previousPuzzleNumber = currentPuzzleNumber-1;
        
        if (previousPuzzleNumber <= 1){
            [appd saveCurrentPuzzleNumberForPack:currentPack puzzleNumber:1];
        }
        else {
            [appd saveCurrentPuzzleNumberForPack:currentPack puzzleNumber:previousPuzzleNumber];
            previousPuzzleDictionary = [appd fetchCurrentPuzzleFromPackDictionary:currentPack];
            [appd saveCurrentPuzzleToPackGameProgress:currentPack puzzle:previousPuzzleDictionary];
        }
        // Update labels with pack and puzzle information
        [vc setPuzzleLabel];
        vc.packAndPuzzlesLabel.text = [NSString stringWithFormat:@"Pack: %d, Puzzle: %d",
                                       [appd fetchCurrentPackNumber],
                                       [appd fetchCurrentPuzzleNumber]
        ];
    }
}

//***********************************************************************
// Puzzle Generation Methods
//***********************************************************************
- (void)batchProcessor {
    DLog("batchProcessor");
    //
    // ************* Fetch batch processing parameters *************
    //
    // Puzzle Generation Count
    int generationCount = 5;
    if ([vc.puzzleDictionary objectForKey:@"generationCount"] != nil){
        generationCount = [[vc.puzzleDictionary objectForKey:@"generationCount"]intValue];
    }
//    generationCount = 400;
    //
    // Grid Size
    if ([vc.puzzleDictionary objectForKey:@"gridSizeX"] && [vc.puzzleDictionary objectForKey:@"gridSizeY"]){
        gameGrid.sizeX = [[vc.puzzleDictionary objectForKey:@"gridSizeX"]intValue];
        gameGrid.sizeY = [[vc.puzzleDictionary objectForKey:@"gridSizeY"]intValue];
    }
    else {
        gameGrid.sizeX = kDefaultGridStartingSizeX;
        gameGrid.sizeY = kDefaultGridStartingSizeY;
    }
    masterGrid.sizeX = gameGrid.sizeX + 2;
    masterGrid.sizeY = gameGrid.sizeY + 2;
    //
    // Puzzle Difficulty
//    puzzleDifficulty = 2;       // Easy
    puzzleDifficulty = 6;       // Medium
//    puzzleDifficulty = 10;      // Difficult
    if ([vc.puzzleDictionary objectForKey:@"puzzleDifficulty"] != nil){
        puzzleDifficulty = (unsigned int)[[vc.puzzleDictionary objectForKey:@"puzzleDifficulty"]intValue];
    }

    //
    // Beams
    BOOL redBeam = NO;
    BOOL greenBeam = NO;
    BOOL blueBeam = NO;
    BOOL yellowBeam = NO;
    BOOL magentaBeam = NO;
    BOOL cyanBeam = NO;
    BOOL whiteBeam = NO;
    BOOL manuallyPlacedRedBeam = NO;
    BOOL manuallyPlacedGreenBeam = NO;
    BOOL manuallyPlacedBlueBeam = NO;
    NSMutableArray *laserDictionaryArray = [vc.puzzleDictionary objectForKey:@"arrayOfLasersDictionaries"];
    if ([laserDictionaryArray count] > 0){
        for (int ii=0; ii<[laserDictionaryArray count]; ii++){
            if ([[[laserDictionaryArray objectAtIndex:ii] objectForKey:@"Color"]intValue] == COLOR_RED){
                manuallyPlacedRedBeam = YES;
            }
            else if ([[[laserDictionaryArray objectAtIndex:ii] objectForKey:@"Color"]intValue] == COLOR_GREEN){
                manuallyPlacedGreenBeam = YES;
            }
            else if ([[[laserDictionaryArray objectAtIndex:ii] objectForKey:@"Color"]intValue] == COLOR_BLUE){
                manuallyPlacedBlueBeam = YES;
            }
        }
    }
    else {
        if ([[vc.puzzleDictionary objectForKey:@"whiteBeam"]intValue] == 1){
            whiteBeam = YES;
        }
        else if ([[vc.puzzleDictionary objectForKey:@"cyanBeam"]intValue] == 1){
            cyanBeam = YES;
            redBeam = YES;
        }
        else if ([[vc.puzzleDictionary objectForKey:@"magentaBeam"]intValue] == 1){
            magentaBeam = YES;
            greenBeam = YES;
        }
        else if ([[vc.puzzleDictionary objectForKey:@"magentaBeam"]intValue] == 1){
            yellowBeam = YES;
            blueBeam = YES;
        }
        else {
            if ([[vc.puzzleDictionary objectForKey:@"redBeam"]intValue] == 1){
                redBeam = YES;
            }
            if ([[vc.puzzleDictionary objectForKey:@"greenBeam"]intValue] == 1){
                greenBeam = YES;
            }
            if ([[vc.puzzleDictionary objectForKey:@"blueBeam"]intValue] == 1){
                blueBeam = YES;
            }
        }
    }
    //
    // Splitter Counts
    int redSplitterCount = 0, greenSplitterCount = 0, blueSplitterCount = 0;
    if ([vc.puzzleDictionary objectForKey:@"redSplitterCount"]){
        redSplitterCount = [[vc.puzzleDictionary objectForKey:@"redSplitterCount"]intValue];
    }
    else {
        redSplitterCount = [self calculateSplitterCount:gameGrid.sizeX];
    }
    
    if ([vc.puzzleDictionary objectForKey:@"greenSplitterCount"]){
        greenSplitterCount = [[vc.puzzleDictionary objectForKey:@"greenSplitterCount"]intValue];
    }
    else {
        greenSplitterCount = [self calculateSplitterCount:gameGrid.sizeX];
    }
    
    if ([vc.puzzleDictionary objectForKey:@"blueSplitterCount"]){
        blueSplitterCount = [[vc.puzzleDictionary objectForKey:@"blueSplitterCount"]intValue];
    }
    else {
        blueSplitterCount = [self calculateSplitterCount:gameGrid.sizeX];
    }
    
    //
    // Prism Count
    int prismCount = 0;
    if ([vc.puzzleDictionary objectForKey:@"prismCount"]){
        prismCount = [[vc.puzzleDictionary objectForKey:@"prismCount"]intValue];
    }
    else {
        prismCount = [self calculatePrismCount:gameGrid.sizeX];
    }
    //
    // Mirrors
    int redMirrorCount = 0, greenMirrorCount = 0, blueMirrorCount = 0;
    if ([vc.puzzleDictionary objectForKey:@"redMirrorCount"]){
        redMirrorCount = [[vc.puzzleDictionary objectForKey:@"redMirrorCount"]intValue];
    }
    else {
        redMirrorCount = [self calculateMirrorCount:gameGrid.sizeX];
    }
    if ([vc.puzzleDictionary objectForKey:@"greenMirrorCount"]){
        greenMirrorCount = [[vc.puzzleDictionary objectForKey:@"greenMirrorCount"]intValue];
    }
    else {
        greenMirrorCount = [self calculateMirrorCount:gameGrid.sizeX];
    }
    if ([vc.puzzleDictionary objectForKey:@"blueMirrorCount"]){
        blueMirrorCount = [[vc.puzzleDictionary objectForKey:@"blueMirrorCount"]intValue];
    }
    else {
        blueMirrorCount = [self calculateMirrorCount:gameGrid.sizeX];
    }

    //
    // Opaque Tiles
    BOOL opaqueTiles = NO;
    if ([[vc.puzzleDictionary objectForKey:@"opaqueTiles"]intValue] == 1){
        opaqueTiles = YES;
    }
    //
    // Translucent Tiles
    BOOL translucentTiles = NO;
    if ([[vc.puzzleDictionary objectForKey:@"translucentTiles"]intValue] == 1){
        translucentTiles = YES;
    }
    
    for (int jj=0; jj<generationCount; jj++){
        //
        // ************* Generate a new puzzle *************
        //
        BOOL puzzleCandidateIsAcceptable = NO;
        unsigned int puzzleCandidateCount = 0;
        unsigned int puzzleCandidateCountMax = 100;
        while (!puzzleCandidateIsAcceptable &&
               puzzleCandidateCount < puzzleCandidateCountMax){
            
            // Build all Puzzle components from puzzleDictionary
            //
            [self buildPuzzleFromDictionary:vc.puzzleDictionary showAllTiles:NO allTilesFixed:NO];
            tileCurrentlyBeingEdited = nil;
            tileForRotation = nil;
            tileUsedForDemoPlacement = nil;
            [self updateAllBeams];
            puzzleHasBeenCompleted = NO;
            packHasBeenCompleted = NO;
            puzzleHasBeenCompletedCelebration = NO;
            puzzleCompletedButtonFlash = NO;
            puzzleViewControllerObjectsInitialized = NO;

            // Run batch processing commands
            //
//            if (blueBeam){
//                vc.puzzleDictionary = [self generatePuzzleBeams:vc.puzzleDictionary beamColor:BEAM_BLUE];
//                [self resetAllColorBeams];
//            }
//            if (redBeam){
//                vc.puzzleDictionary = [self generatePuzzleBeams:vc.puzzleDictionary beamColor:BEAM_RED];
//                [self resetAllColorBeams];
//            }
//            if (greenBeam){
//                vc.puzzleDictionary = [self generatePuzzleBeams:vc.puzzleDictionary beamColor:BEAM_GREEN];
//                [self resetAllColorBeams];
//            }
//            if (manuallyPlacedRedBeam || manuallyPlacedGreenBeam || manuallyPlacedBlueBeam){
//                [self resetAllColorBeams];
//            }
            
            // Try out stackPuzzleLaser to see if it works
            //
            // First add a blue laser
//            vc.puzzleDictionary = [self generatePuzzleBeams:vc.puzzleDictionary beamColor:BEAM_BLUE];
            // Add a green laser on top of the blue laser to get cyan
//            vc.puzzleDictionary = [self stackPuzzleLaser:BEAM_GREEN onTo:BEAM_BLUE inDictionary:vc.puzzleDictionary];
            // Add a red laser on top of the blue laser to get white overall
//            vc.puzzleDictionary = [self stackPuzzleLaser:BEAM_RED onTo:BEAM_BLUE inDictionary:vc.puzzleDictionary];
            // Finally add a red laser
//            vc.puzzleDictionary = [self generatePuzzleBeams:vc.puzzleDictionary beamColor:BEAM_RED];

            // Use Laser configurations with the following probabilities
            //  WHITE               10%
            //  YELLOW + BLUE       15%
            //  MAGENTA + GREEN     15%
            //  CYAN + RED          15%
            //  RED + GREEN + BLUE  45%
            BOOL multiColorBeam = YES;
            int uniformRandomIntegerLessThan100 = arc4random_uniform(100);
            if (uniformRandomIntegerLessThan100 < 10){
                // WHITE
                vc.puzzleDictionary = [self generatePuzzleBeams:vc.puzzleDictionary beamColor:BEAM_BLUE];
                vc.puzzleDictionary = [self stackPuzzleLaser:BEAM_GREEN onTo:BEAM_BLUE inDictionary:vc.puzzleDictionary];
                vc.puzzleDictionary = [self stackPuzzleLaser:BEAM_RED onTo:BEAM_BLUE inDictionary:vc.puzzleDictionary];
            }
            else if (uniformRandomIntegerLessThan100 < 25){
                // YELLOW + BLUE
                vc.puzzleDictionary = [self generatePuzzleBeams:vc.puzzleDictionary beamColor:BEAM_RED];
                vc.puzzleDictionary = [self stackPuzzleLaser:BEAM_GREEN onTo:BEAM_RED inDictionary:vc.puzzleDictionary];
                vc.puzzleDictionary = [self generatePuzzleBeams:vc.puzzleDictionary beamColor:BEAM_BLUE];
            }
            else if (uniformRandomIntegerLessThan100 < 40){
                // MAGENTA + GREEN
                vc.puzzleDictionary = [self generatePuzzleBeams:vc.puzzleDictionary beamColor:BEAM_RED];
                vc.puzzleDictionary = [self stackPuzzleLaser:BEAM_BLUE onTo:BEAM_RED inDictionary:vc.puzzleDictionary];
                vc.puzzleDictionary = [self generatePuzzleBeams:vc.puzzleDictionary beamColor:BEAM_GREEN];
            }
            else if (uniformRandomIntegerLessThan100 < 55){
                // CYAN + RED
                vc.puzzleDictionary = [self generatePuzzleBeams:vc.puzzleDictionary beamColor:BEAM_BLUE];
                vc.puzzleDictionary = [self stackPuzzleLaser:BEAM_GREEN onTo:BEAM_BLUE inDictionary:vc.puzzleDictionary];
                vc.puzzleDictionary = [self generatePuzzleBeams:vc.puzzleDictionary beamColor:BEAM_RED];
            }
            else {
                // RED + GREEN + BLUE
                multiColorBeam = NO;
                vc.puzzleDictionary = [self generatePuzzleBeams:vc.puzzleDictionary beamColor:BEAM_RED];
                vc.puzzleDictionary = [self generatePuzzleBeams:vc.puzzleDictionary beamColor:BEAM_GREEN];
                vc.puzzleDictionary = [self generatePuzzleBeams:vc.puzzleDictionary beamColor:BEAM_BLUE];
            }
            [self resetAllColorBeams];
            [self updateEnergizedStateForAllTiles];

            // Add Prisms BEFORE Beamsplitters when multiColorBeam present
            if (multiColorBeam){
                for (int ii=0; ii<prismCount; ii++){
                    vc.puzzleDictionary = [self generatePuzzlePrisms:vc.puzzleDictionary];
                    [self resetAllColorBeams];
                    [self updateEnergizedStateForAllTiles];
                }
            }

            // Finish up batch processing
            [vc.puzzleDictionary setObject:[NSNumber numberWithInt:1] forKey:@"batchStart1"];
            [vc.puzzleDictionary setObject:[NSNumber numberWithInt:1] forKey:@"batchEnd1"];
            
            // Add Splitters into the Red, Geen and Blue Beams
            for (int ii=0; ii<redSplitterCount; ii++){
                vc.puzzleDictionary = [self generatePuzzleSplitters:vc.puzzleDictionary beamColor:BEAM_BLUE];
                [self resetAllColorBeams];
                [self updateEnergizedStateForAllTiles];
                vc.puzzleDictionary = [self generatePuzzleSplitters:vc.puzzleDictionary beamColor:BEAM_RED];
                [self resetAllColorBeams];
                [self updateEnergizedStateForAllTiles];
                vc.puzzleDictionary = [self generatePuzzleSplitters:vc.puzzleDictionary beamColor:BEAM_GREEN];
                [self resetAllColorBeams];
                [self updateEnergizedStateForAllTiles];
            }
            
            // Add Prisms AFTER Beamsplitters when multiColorBeam present
            if (!multiColorBeam){
                for (int ii=0; ii<prismCount; ii++){
                    vc.puzzleDictionary = [self generatePuzzlePrisms:vc.puzzleDictionary];
                    [self resetAllColorBeams];
                    [self updateEnergizedStateForAllTiles];
                }
            }

            // Add Mirrors into the Red Beam
            for (int ii=0; ii<redMirrorCount; ii++){
                vc.puzzleDictionary = [self generatePuzzleMirrors:vc.puzzleDictionary beamColor:BEAM_RED];
                [self resetAllColorBeams];
                [self updateEnergizedStateForAllTiles];
            }
            
            // Add Mirrors into the Green Beam
            for (int ii=0; ii<greenMirrorCount; ii++){
                vc.puzzleDictionary = [self generatePuzzleMirrors:vc.puzzleDictionary beamColor:BEAM_GREEN];
                [self resetAllColorBeams];
                [self updateEnergizedStateForAllTiles];
            }
            
            // Add Mirrors into the Blue Beam
            for (int ii=0; ii<blueMirrorCount; ii++){
                vc.puzzleDictionary = [self generatePuzzleMirrors:vc.puzzleDictionary beamColor:BEAM_BLUE];
                [self resetAllColorBeams];
                [self updateEnergizedStateForAllTiles];
            }
            
            // Fill some blanks with opaque Tiles
            if (opaqueTiles){
                vc.puzzleDictionary = [self generateOpaqueTiles:vc.puzzleDictionary];
                [self resetAllColorBeams];
            }
            
            // Fill some blanks with translucent Tiles
            if (translucentTiles){
                vc.puzzleDictionary = [self generateTranslucentTiles:vc.puzzleDictionary];
                [self resetAllColorBeams];
            }
            
            // Set Tiles as fixed based upon puzzleDifficulty
            // puzzleDifficulty <=3 sets 3/4 tiles as fixed
            // 4 <= puzzleDifficulty <=7 sets 2/3 tiles as fixed
            // 8 <= puzzleDifficulty <=10 sets 1/2 tiles as fixed
            [self markTilesFixedBasedOnPuzzleDifficulty:puzzleDifficulty];
            vc.puzzleDictionary = [self encodeCurrentPuzzleAsMutableDictionary:vc.puzzleDictionary];
            
            // Add Jewels if Possible
            vc.puzzleDictionary = [self generatePuzzleJewels:vc.puzzleDictionary color:COLOR_RED];
            [self resetAllColorBeams];
            vc.puzzleDictionary = [self generatePuzzleJewels:vc.puzzleDictionary color:COLOR_GREEN];
            [self resetAllColorBeams];
            vc.puzzleDictionary = [self generatePuzzleJewels:vc.puzzleDictionary color:COLOR_BLUE];
            [self resetAllColorBeams];
            vc.puzzleDictionary = [self generatePuzzleJewels:vc.puzzleDictionary color:COLOR_YELLOW];
            [self resetAllColorBeams];
            vc.puzzleDictionary = [self generatePuzzleJewels:vc.puzzleDictionary color:COLOR_CYAN];
            [self resetAllColorBeams];
            vc.puzzleDictionary = [self generatePuzzleJewels:vc.puzzleDictionary color:COLOR_MAGENTA];
            [self resetAllColorBeams];
            vc.puzzleDictionary = [self generatePuzzleJewels:vc.puzzleDictionary color:COLOR_WHITE];
            [self resetAllColorBeams];
            
            // Remove any Jewels that are not energized (should not be any)
            [self updateEnergizedStateForAllTiles];
            [self removeNonEnergizedJewels];
            vc.puzzleDictionary = [self encodeCurrentPuzzleAsMutableDictionary:vc.puzzleDictionary];
            
            // Remove any tiles that do not contribute to the solution
            [self updateEnergizedStateForAllTiles];
            [self cleanPuzzle];
            vc.puzzleDictionary = [self encodeCurrentPuzzleAsMutableDictionary:vc.puzzleDictionary];
            
            puzzleCandidateIsAcceptable = [self testWhetherPuzzleCandidateIsAcceptable:vc.puzzleDictionary];
            if (!puzzleCandidateIsAcceptable){
                puzzleCandidateCount++;
                vc.puzzleDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
                // If lasers were placed manually then put them back into puzzleDictionary
                if (manuallyPlacedRedBeam || manuallyPlacedGreenBeam || manuallyPlacedBlueBeam){
                    [vc.puzzleDictionary setValue:laserDictionaryArray forKey:@"arrayOfLasersDictionaries"];
                }
            }
        }
        
        if (!puzzleCandidateIsAcceptable &&
            puzzleCandidateCount >= puzzleCandidateCountMax){
            DLog("Puzzle Generation Failed after %d attempts", puzzleCandidateCountMax);
            vc.puzzleDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
        }
        else {
            DLog("New puzzle %d generated", jj);
        }

        // Append puzzle to editedPack
        [vc appendGeneratedPuzzle];
    }

    // Finish up batch processing
    [vc.puzzleDictionary setObject:[NSNumber numberWithInt:1] forKey:@"batchStart2"];
    [vc.puzzleDictionary setObject:[NSNumber numberWithInt:1] forKey:@"batchEnd2"];
    [vc backButtonPressed];
}

- (unsigned int)calculatePrismCount:(unsigned int)gridSizeX{
    unsigned int retVal = 1;
    switch(gridSizeX){
        case 6:
        case 7:{
            retVal = 1;
            break;
        }
        case 8:
        case 9:{
            retVal = 2;
            break;
        }
        case 10:
        case 11:{
            retVal = 3;
            break;
        }
        case 12:
        case 13:
        case 14:{
            retVal = 4;
            break;
        }
        default:{
            retVal = 2;
            break;
        }
    }
    return retVal;
}

- (unsigned int)calculateSplitterCount:(unsigned int)gridSizeX{
    unsigned int retVal = 1;
    switch(gridSizeX){
        case 8:
        case 9:{
            retVal = 2;
            break;
        }
        case 10:
        case 11:{
            retVal = 4;
            break;
        }
        case 12:
        case 13:
        case 14:{
            retVal = 6;
            break;
        }
        default:{
            retVal = 8;
            break;
        }
    }
    return retVal;
}

- (unsigned int)calculateMirrorCount:(unsigned int)gridSizeX{
    unsigned int retVal = 1;
    switch(gridSizeX){
        case 8:
        case 9:{
            retVal = 1;
            break;
        }
        case 10:
        case 11:{
            retVal = 2;
            break;
        }
        case 12:
        case 13:
        case 14:{
            retVal = 3;
            break;
        }
        default:{
            retVal = 4;
            break;
        }
    }
    return retVal;
}

- (BOOL)gridPositionIsOnPeriphery:(vector_int2)gridPosition{
    if (gridPosition.x == 0 ||
        gridPosition.x == masterGrid.sizeX-1 ||
        gridPosition.y == 0 ||
        gridPosition.y == masterGrid.sizeY -1){
        return YES;
    }
    return NO;
}

- (NSMutableDictionary *)generatePuzzleJewels:(NSMutableDictionary *)puzzleDictionary color:(enum eTileColors)color{
    // Get an array containing the final unoccupied gridPosition for each beamColor,
    // understanding that there can me more than one per beam color
    NSMutableArray *arrayOfFinalGridPositions = [self generateArrayOfFinalBeamUnoccupiedGridPositions];
    NSEnumerator *gridPositionEnum = [arrayOfFinalGridPositions objectEnumerator];
    NSMutableDictionary *gridPositionDictionary = nil;
    while (gridPositionDictionary = [gridPositionEnum nextObject]){
        vector_int2 gridPosition;
        gridPosition.x = -1;
        gridPosition.y = -1;
        gridPosition.x = [[gridPositionDictionary objectForKey:@"x"] intValue];
        gridPosition.y = [[gridPositionDictionary objectForKey:@"y"] intValue];
        
        // Determine the appropriate jewelColor
        enum eTileColors jewelColor = COLOR_WHITE;
        BOOL hasRed = [gridPositionDictionary objectForKey:@"BEAM_RED"];
        BOOL hasGreen = [gridPositionDictionary objectForKey:@"BEAM_GREEN"];
        BOOL hasBlue = [gridPositionDictionary objectForKey:@"BEAM_BLUE"];
        if (hasRed && !hasGreen && !hasBlue){
            jewelColor = COLOR_RED;
        }
        else if (!hasRed && hasGreen && !hasBlue){
            jewelColor = COLOR_GREEN;
        }
        else if (!hasRed && !hasGreen && hasBlue){
            jewelColor = COLOR_BLUE;
        }
        else if (hasRed && hasGreen && !hasBlue){
            jewelColor = COLOR_YELLOW;
        }
        else if (!hasRed && hasGreen && hasBlue){
            jewelColor = COLOR_CYAN;
        }
        else if (hasRed && !hasGreen && hasBlue){
            jewelColor = COLOR_MAGENTA;
        }
        else if (hasRed && hasGreen && hasBlue){
            jewelColor = COLOR_WHITE;
        }

        // Check that there are one or more beams coming into the gridPosition where
        // you plan to place a Jewel
        if (![self existsPassthroughBeam:gridPosition]){
            if ([self countBeamsIntersectingGridPosition:gridPosition] >= 1){
                if (color == jewelColor ||
                    color == COLOR_ALL){
                    if ([self gridPositionIsOnPeriphery:gridPosition]){
//                    if (gridPosition.x >= 0 && gridPosition.y >= 0){
                        // Build jewelDictionary
                        NSMutableDictionary *jewelDictionary = [[NSMutableDictionary alloc] initWithCapacity:1];
                        [jewelDictionary setObject:[NSNumber numberWithInt:ANGLE0] forKey:@"Angle"];
                        [jewelDictionary setObject:[NSNumber numberWithInt:ANGLE0] forKey:@"finalTileAngle"];
                        [jewelDictionary setObject:[NSNumber numberWithInt:jewelColor] forKey:@"Color"];
                        [jewelDictionary setObject:[NSNumber numberWithInt:0] forKey:@"demoTile"];
                        [jewelDictionary setObject:[NSNumber numberWithInt:0] forKey:@"demoTileAtFinalGridPosition"];
                        [jewelDictionary setObject:[NSNumber numberWithInt:gridPosition.x] forKey:@"finalX"];
                        [jewelDictionary setObject:[NSNumber numberWithInt:gridPosition.y] forKey:@"finalY"];
                        [jewelDictionary setObject:[NSNumber numberWithInt:1] forKey:@"fixed"];
                        [jewelDictionary setObject:[NSNumber numberWithInt:gridPosition.x] forKey:@"gridPositionX"];
                        [jewelDictionary setObject:[NSNumber numberWithInt:gridPosition.y] forKey:@"gridPositionY"];
                        [jewelDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placed"];
                        [jewelDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedManuallyMatchesHint"];
                        [jewelDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedUsingHint"];
                        [jewelDictionary setObject:[NSNumber numberWithInt:JEWEL] forKey:@"tileShape"];
                        Tile *tile = [self buildOneTileFromDictionary:jewelDictionary tileShape:JEWEL movableTileX:gridPosition.x  movableTileY:gridPosition.y];
                        tile->tileAngle = ANGLE0;
                        tile->finalTileAngle = ANGLE0;
                        [self putOpticsTile:tile array:tiles];
                        //
                        // Encode the current puzzle into a dictionary
                        //
                        puzzleDictionary = [self encodeCurrentPuzzleAsMutableDictionary:puzzleDictionary];
                    }
                }
            }
        }
    }
    return puzzleDictionary;
}

- (NSMutableDictionary *)generatePuzzleMirrors:(NSMutableDictionary *)puzzleDictionary beamColor:(enum eBeamColors)beamColor {
    //
    // Generate one Mirror for each color beam
    //
    Tile *tile;
    vector_int2 dimensions;
    
    // Identify allowable grid positions for placing a mirror
    [vc.allowableTileGridPositionArray removeAllObjects];
    vc.allowableTileGridPositionArray = [self generateArrayOfAllowableGridPositionsForTiles:vc.allowableTileGridPositionArray color:(enum eBeamColors)beamColor];

    // If there are any allowable grid positions then randomly select one of the allowableGridPosition objects from allowableGridPositionArray
    NSMutableDictionary *allowableGridPosition = nil;
    if (vc.allowableTileGridPositionArray != nil &&
        (int)[vc.allowableTileGridPositionArray count] > 0){
        int index = (int)arc4random_uniform((int)[vc.allowableTileGridPositionArray count]);
        allowableGridPosition = [vc.allowableTileGridPositionArray objectAtIndex:index];
        
        // Select a tile angle that is equal to the beam angle +/- 45 degrees
        unsigned int mirrorAngle, beamAngle;
        beamAngle = [[allowableGridPosition objectForKey:@"beamAngle"]intValue];
        if (arc4random_uniform(2) > 1){
            mirrorAngle = (beamAngle + 1) % 8;
        }
        else {
            mirrorAngle = (beamAngle - 1) % 8;
        }
        
        int xValue = [[allowableGridPosition objectForKey:@"x"] intValue];
        int yValue = [[allowableGridPosition objectForKey:@"y"] intValue];
        vector_int2 gridPosition;
        gridPosition.x = xValue;
        gridPosition.y = yValue;
        
        // DEBUG
        if (gridPosition.x == 0 && gridPosition.y == 0){
            DLog("DEBUG");
        }
        
        // Build mirrorDictionary
        NSMutableDictionary *mirrorDictionary = [[NSMutableDictionary alloc] initWithCapacity:1];
        [mirrorDictionary setObject:[NSNumber numberWithInt:mirrorAngle] forKey:@"Angle"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:mirrorAngle] forKey:@"finalTileAngle"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:7] forKey:@"Color"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:0] forKey:@"demoTile"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:0] forKey:@"demoTileAtFinalGridPosition"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:mirrorAngle] forKey:@"finalTileAngle"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:xValue] forKey:@"finalX"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:yValue] forKey:@"finalY"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:1] forKey:@"fixed"];
//        if (arc4random_uniform(8) < puzzleDifficulty){
//            [mirrorDictionary setObject:[NSNumber numberWithInt:0] forKey:@"fixed"];
//        }
//        else {
//            [mirrorDictionary setObject:[NSNumber numberWithInt:1] forKey:@"fixed"];
//        }
        [mirrorDictionary setObject:[NSNumber numberWithInt:xValue] forKey:@"gridPositionX"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:yValue] forKey:@"gridPositionY"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placed"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedManuallyMatchesHint"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedUsingHint"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:MIRROR] forKey:@"tileShape"];
        dimensions.x = _squareTileSideLengthInPixels;
        dimensions.y = _squareTileSideLengthInPixels;
        tile = [self buildOneTileFromDictionary:mirrorDictionary tileShape:MIRROR movableTileX:xValue  movableTileY:yValue];
        tile->tileAngle = mirrorAngle;
        tile->finalTileAngle = mirrorAngle;
        
        // Only save the mirror if it will reflect the beam into the grid
        if ([self checkIfBeamHeadingIntoGridAfterStrikingMirror:gridPosition
                                                      beamAngle:beamAngle
                                                    mirrorAngle:mirrorAngle]){
            [self putOpticsTile:tile array:tiles];
        }
        else {
            DLog("checkIfBeamHeadingIntoGridAfterStrikingMirror failed");
        }
        //
        // Encode the current puzzle into a dictionary
        //
        puzzleDictionary = [self encodeCurrentPuzzleAsMutableDictionary:puzzleDictionary];
        
//        [puzzleDictionary removeObjectForKey:@"Beams"];
//        [puzzleDictionary setObject:[NSNumber numberWithInt:1] forKey:@"Tiles"];
    }
    return puzzleDictionary;
}

- (NSMutableDictionary *)generatePuzzlePrisms:(NSMutableDictionary *)puzzleDictionary {
    //
    // Generate one Prism
    //
    Tile *tile;
    vector_int2 dimensions;
    
    // Fetch beamsRenderArray that combines all beams of each RGB color into at most one beam BeamTextureRenderObject between each pair of tiles
    Beam *myBeam;
    beamsRenderArray = [[NSMutableArray alloc] initWithCapacity:1];
    for (int ii=0; ii<3; ii++) {
        NSEnumerator *beamsEnum = [beams[ii] objectEnumerator];
        while (myBeam = [beamsEnum nextObject]) {
            [myBeam renderBeam:beamsRenderArray frameCounter:animationFrame];
        }
    }
    
    // - Use beamsRenderArray to generate gridPositionsCrossedByMultipleCoincidentBeams
    // - Use this as a guide for placement of PRISMS during puzzle autogeneration
    gridPositionsCrossedByMultipleCoincidentBeams = [[NSMutableArray alloc] initWithCapacity:1];
    if ([appd editModeIsEnabled]){
        BeamTextureRenderData *bgd;
        NSEnumerator *bgdEnum = [beamsRenderArray objectEnumerator];
        while (bgd = [bgdEnum nextObject]) {
            if ([self beamRenderIsMulticolor:bgd]){
                gridPositionsCrossedByMultipleCoincidentBeams = [self gridPositionsCrossedByRenderedBeam:bgd gridPositionsArray:gridPositionsCrossedByMultipleCoincidentBeams];
            }
        }
//        DLog("%d grid positions crossed by multiple coincident beams", (int)[gridPositionsCrossedByMultipleCoincidentBeams count]);
    }


    // If there are any allowable grid positions then randomly select one of the allowableGridPosition objects from allowableGridPositionArray
    NSMutableDictionary *allowableGridPosition = nil;
    if (gridPositionsCrossedByMultipleCoincidentBeams != nil &&
        (int)[gridPositionsCrossedByMultipleCoincidentBeams count] > 0){
        DLog("generatePuzzlePrisms");
        int index = (int)arc4random_uniform((int)[gridPositionsCrossedByMultipleCoincidentBeams count]);
        allowableGridPosition = [gridPositionsCrossedByMultipleCoincidentBeams objectAtIndex:index];
        
        // Select a Prism angle that is equal to the beam angle +/- 90 degrees
        unsigned int prismAngle, beamAngle;
        beamAngle = [[allowableGridPosition objectForKey:@"beamAngle"]intValue];
        if (arc4random_uniform(2) > 1){
            prismAngle = (beamAngle + 2) % 8;
        }
        else {
            prismAngle = (beamAngle - 2) % 8;
        }
        
        int xValue = [[allowableGridPosition objectForKey:@"x"] intValue];
        int yValue = [[allowableGridPosition objectForKey:@"y"] intValue];
        vector_int2 gridPosition;
        gridPosition.x = xValue;
        gridPosition.y = yValue;
        
        // Build prismDictionary
        NSMutableDictionary *prismDictionary = [[NSMutableDictionary alloc] initWithCapacity:1];
        [prismDictionary setObject:[NSNumber numberWithInt:prismAngle] forKey:@"Angle"];
        [prismDictionary setObject:[NSNumber numberWithInt:prismAngle] forKey:@"finalTileAngle"];
        [prismDictionary setObject:[NSNumber numberWithInt:7] forKey:@"Color"];
        [prismDictionary setObject:[NSNumber numberWithInt:0] forKey:@"demoTile"];
        [prismDictionary setObject:[NSNumber numberWithInt:0] forKey:@"demoTileAtFinalGridPosition"];
        [prismDictionary setObject:[NSNumber numberWithInt:xValue] forKey:@"finalX"];
        [prismDictionary setObject:[NSNumber numberWithInt:yValue] forKey:@"finalY"];
        [prismDictionary setObject:[NSNumber numberWithInt:1] forKey:@"fixed"];
        [prismDictionary setObject:[NSNumber numberWithInt:xValue] forKey:@"gridPositionX"];
        [prismDictionary setObject:[NSNumber numberWithInt:yValue] forKey:@"gridPositionY"];
        [prismDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placed"];
        [prismDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedManuallyMatchesHint"];
        [prismDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedUsingHint"];
        [prismDictionary setObject:[NSNumber numberWithInt:PRISM] forKey:@"tileShape"];
        dimensions.x = _squareTileSideLengthInPixels;
        dimensions.y = _squareTileSideLengthInPixels;
        tile = [self buildOneTileFromDictionary:prismDictionary tileShape:PRISM movableTileX:xValue  movableTileY:yValue];
        tile->tileAngle = prismAngle;
        tile->finalTileAngle = prismAngle;
        
        // Only save the Prism if it will reflect the beam into the grid
        if ([self checkIfBeamHeadingIntoGridAfterStrikingMirror:gridPosition
                                                      beamAngle:beamAngle
                                                    mirrorAngle:prismAngle]){
            [self putOpticsTile:tile array:tiles];
        }
        else {
            DLog("checkIfBeamHeadingIntoGridAfterStrikingMirror failed");
        }
        //
        // Encode the current puzzle into a dictionary
        //
        puzzleDictionary = [self encodeCurrentPuzzleAsMutableDictionary:puzzleDictionary];
    }
    return puzzleDictionary;
}

- (NSMutableDictionary *)generatePuzzleSplitters:(NSMutableDictionary *)puzzleDictionary beamColor:(enum eBeamColors)beamColor {
    //
    // Generate one Beam Splitter for this beamColor
    //
    Tile *tile;
    vector_int2 dimensions;
    
    // Identify allowable grid positions for placing a Splitter
    [vc.allowableTileGridPositionArray removeAllObjects];
    vc.allowableTileGridPositionArray = [self generateArrayOfAllowableGridPositionsForSplitters:vc.allowableTileGridPositionArray color:(enum eBeamColors)beamColor];

    // If there are any allowable grid positions then randomly select one of the allowableGridPosition objects from allowableGridPositionArray
    NSMutableDictionary *allowableGridPosition = nil;
    if (vc.allowableTileGridPositionArray != nil &&
        (int)[vc.allowableTileGridPositionArray count] > 0){
        int index = (int)arc4random_uniform((int)[vc.allowableTileGridPositionArray count]);
        allowableGridPosition = [vc.allowableTileGridPositionArray objectAtIndex:index];
        
        // Select a tile angle that is equal to the beam angle +/- 45 degrees
        unsigned int splitterAngle, beamAngle;
        beamAngle = [[allowableGridPosition objectForKey:@"beamAngle"]intValue];
        if (arc4random_uniform(2) > 1){
            splitterAngle = (beamAngle + 1) % 8;
        }
        else {
            splitterAngle = (beamAngle - 1) % 8;
        }
        
        int xValue = [[allowableGridPosition objectForKey:@"x"] intValue];
        int yValue = [[allowableGridPosition objectForKey:@"y"] intValue];
        vector_int2 gridPosition;
        gridPosition.x = xValue;
        gridPosition.y = yValue;
        
        // DEBUG
        if (gridPosition.x == 0 && gridPosition.y == 0){
            DLog("DEBUG");
        }
        
        // Build splitterDictionary
        NSMutableDictionary *splitterDictionary = [[NSMutableDictionary alloc] initWithCapacity:1];
        [splitterDictionary setObject:[NSNumber numberWithInt:splitterAngle] forKey:@"Angle"];
        [splitterDictionary setObject:[NSNumber numberWithInt:splitterAngle] forKey:@"finalTileAngle"];
        [splitterDictionary setObject:[NSNumber numberWithInt:7] forKey:@"Color"];
        [splitterDictionary setObject:[NSNumber numberWithInt:0] forKey:@"demoTile"];
        [splitterDictionary setObject:[NSNumber numberWithInt:0] forKey:@"demoTileAtFinalGridPosition"];
        [splitterDictionary setObject:[NSNumber numberWithInt:xValue] forKey:@"finalX"];
        [splitterDictionary setObject:[NSNumber numberWithInt:yValue] forKey:@"finalY"];
        [splitterDictionary setObject:[NSNumber numberWithInt:1] forKey:@"fixed"];
        [splitterDictionary setObject:[NSNumber numberWithInt:xValue] forKey:@"gridPositionX"];
        [splitterDictionary setObject:[NSNumber numberWithInt:yValue] forKey:@"gridPositionY"];
        [splitterDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placed"];
        [splitterDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedManuallyMatchesHint"];
        [splitterDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedUsingHint"];
        [splitterDictionary setObject:[NSNumber numberWithInt:BEAMSPLITTER] forKey:@"tileShape"];
        dimensions.x = _squareTileSideLengthInPixels;
        dimensions.y = _squareTileSideLengthInPixels;
        tile = [self buildOneTileFromDictionary:splitterDictionary tileShape:BEAMSPLITTER movableTileX:xValue  movableTileY:yValue];
        tile->tileAngle = splitterAngle;
        tile->finalTileAngle = splitterAngle;
        
        // Only save the mirror if it will reflect the beam into the grid
        if ([self checkIfBeamHeadingIntoGridAfterStrikingMirror:gridPosition
                                                      beamAngle:beamAngle
                                                    mirrorAngle:splitterAngle]){
            [self putOpticsTile:tile array:tiles];
        }
        else {
            DLog("checkIfBeamHeadingIntoGridAfterStrikingMirror failed");
        }
        //
        // Encode the current puzzle into a dictionary
        //
        puzzleDictionary = [self encodeCurrentPuzzleAsMutableDictionary:puzzleDictionary];
    }
    return puzzleDictionary;
}

- (NSMutableDictionary *)stackPuzzleLaser:(enum eBeamColors)newBeamColor onTo:(enum eBeamColors)originalBeamColor inDictionary:(NSMutableDictionary *)puzzleDictionary{
    Tile *oldLaser, *newLaser;
    NSEnumerator *tileEnum = [tiles objectEnumerator];
    while (oldLaser = [tileEnum nextObject]){
        if (oldLaser->tileShape == LASER &&
            oldLaser->tileColor == (enum eTileColors)originalBeamColor){
            //
            // Build laserDictionary of newBeamColor by copying the values from originalBeamColor
            // except for the newBeamColor
            //
            NSMutableDictionary *laserDictionary = [[NSMutableDictionary alloc] initWithCapacity:1];
            [laserDictionary setObject:[NSNumber numberWithInt:oldLaser->tileAngle] forKey:@"Angle"];
            [laserDictionary setObject:[NSNumber numberWithInt:oldLaser->finalTileAngle] forKey:@"finalTileAngle"];
            [laserDictionary setObject:[NSNumber numberWithInt:newBeamColor] forKey:@"Color"];
            [laserDictionary setObject:[NSNumber numberWithInt:0] forKey:@"demoTile"];
            [laserDictionary setObject:[NSNumber numberWithInt:0] forKey:@"demoTileAtFinalGridPosition"];
            [laserDictionary setObject:[NSNumber numberWithInt:1] forKey:@"fixed"];
            [laserDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placed"];
            [laserDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedManuallyMatchesHint"];
            [laserDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedUsingHint"];
            [laserDictionary setObject:[NSNumber numberWithInt:oldLaser->gridPosition.x] forKey:@"finalX"];
            [laserDictionary setObject:[NSNumber numberWithInt:oldLaser->gridPosition.y] forKey:@"finalY"];
            [laserDictionary setObject:[NSNumber numberWithInt:oldLaser->gridPosition.x] forKey:@"gridPositionX"];
            [laserDictionary setObject:[NSNumber numberWithInt:oldLaser->gridPosition.y] forKey:@"gridPositionY"];
            [laserDictionary setObject:[NSNumber numberWithInt:LASER] forKey:@"tileShape"];
            newLaser = [self buildOneTileFromDictionary:laserDictionary tileShape:LASER movableTileX:oldLaser->gridPosition.x  movableTileY:oldLaser->gridPosition.y];
            newLaser->tileAngle = oldLaser->tileAngle;
            newLaser->finalTileAngle = oldLaser->tileAngle;
            [self putOpticsTile:newLaser array:tiles];
            //
            // Encode the current puzzle into a dictionary
            //
            puzzleDictionary = [self encodeCurrentPuzzleAsMutableDictionary:puzzleDictionary];
            break;
        }
    }
    return puzzleDictionary;
}

- (NSMutableDictionary *)generatePuzzleBeams:(NSMutableDictionary *)puzzleDictionary beamColor:(enum eBeamColors)beamColor {
    // Used to manipulate current working tile
    Tile *tile;
    vector_int2 dimensions;
    NSMutableDictionary *allowableGridPosition;
    vc.allowableLaserGridPositionArray = [[NSMutableArray alloc] initWithCapacity:1];
    vc.allowableTileGridPositionArray = [[NSMutableArray alloc] initWithCapacity:1];
    NSMutableArray *allowableAngleArray = [[NSMutableArray alloc] initWithCapacity:1];
    //
    // Generate Laser of beamColor
    //
    
    // Generate an array of allowable gridPositions
    vc.allowableLaserGridPositionArray = [self generateArrayOfAllowableGridPositionsForLasers:vc.allowableLaserGridPositionArray];
    
    // Randomly select one of the allowableGridPosition objects from allowableGridPositionArray
    int index;
    if ((int)[vc.allowableLaserGridPositionArray count] > 0){
        index = (int)arc4random_uniform((int)[vc.allowableLaserGridPositionArray count]);
        allowableGridPosition = [vc.allowableLaserGridPositionArray objectAtIndex:index];
    }
    
    // Randomly select one of the allowable angles based on the allowableGridPosition
    vector_int2 allowableGrid;
    allowableGrid.x = [[allowableGridPosition objectForKey:@"x"]intValue];
    allowableGrid.y = [[allowableGridPosition objectForKey:@"y"]intValue];
    allowableAngleArray = [self generateArrayOfAllowableAnglesForLaser:allowableAngleArray gridPosition:allowableGrid];
    unsigned int angle;
    if ((int)[allowableAngleArray count] > 0){
        index = (int)arc4random_uniform((int)[allowableAngleArray count]);
        angle = [[allowableAngleArray objectAtIndex:index] intValue];
        int xValue = [[allowableGridPosition objectForKey:@"x"] intValue];
        int yValue = [[allowableGridPosition objectForKey:@"y"] intValue];
        // Build laserDictionary
        NSMutableDictionary *laserDictionary = [[NSMutableDictionary alloc] initWithCapacity:1];
        [laserDictionary setObject:[NSNumber numberWithInt:angle] forKey:@"Angle"];
        [laserDictionary setObject:[NSNumber numberWithInt:angle] forKey:@"finalTileAngle"];
        [laserDictionary setObject:[NSNumber numberWithInt:beamColor] forKey:@"Color"];
        [laserDictionary setObject:[NSNumber numberWithInt:0] forKey:@"demoTile"];
        [laserDictionary setObject:[NSNumber numberWithInt:0] forKey:@"demoTileAtFinalGridPosition"];
        [laserDictionary setObject:[NSNumber numberWithInt:angle] forKey:@"finalTileAngle"];
        [laserDictionary setObject:[NSNumber numberWithInt:xValue] forKey:@"finalX"];
        [laserDictionary setObject:[NSNumber numberWithInt:yValue] forKey:@"finalY"];
        [laserDictionary setObject:[NSNumber numberWithInt:1] forKey:@"fixed"];
        [laserDictionary setObject:[NSNumber numberWithInt:xValue] forKey:@"gridPositionX"];
        [laserDictionary setObject:[NSNumber numberWithInt:yValue] forKey:@"gridPositionY"];
        [laserDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placed"];
        [laserDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedManuallyMatchesHint"];
        [laserDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedUsingHint"];
        [laserDictionary setObject:[NSNumber numberWithInt:LASER] forKey:@"tileShape"];
        dimensions.x = _squareTileSideLengthInPixels;
        dimensions.y = _squareTileSideLengthInPixels;
        tile = [self buildOneTileFromDictionary:laserDictionary tileShape:LASER movableTileX:xValue  movableTileY:yValue];
        tile->tileAngle = angle;
        tile->finalTileAngle = angle;
        [self putOpticsTile:tile array:tiles];
        //
        // Encode the current puzzle into a dictionary
        //
        puzzleDictionary = [self encodeCurrentPuzzleAsMutableDictionary:puzzleDictionary];
    //    [puzzleDictionary setObject:[NSNumber numberWithInt:1] forKey:@"Beams"];
    }
    return puzzleDictionary;
}

- (NSMutableDictionary *)generatePuzzleMirrors:(NSMutableDictionary *)puzzleDictionary {
    //
    // Generate one Mirror for each color beam
    //
    Tile *tile;
    vector_int2 dimensions;
    for (enum eTileColors beamColor=COLOR_RED; beamColor<=COLOR_BLUE; beamColor++){
        
        // Identify grid positions crossed by beams of each color
        vc.allowableTileGridPositionArray = [self generateArrayOfAllowableGridPositionsForTiles:vc.allowableTileGridPositionArray color:(enum eBeamColors)beamColor];
        // Randomly select one of the allowableGridPosition objects from allowableGridPositionArray
        NSMutableDictionary *allowableGridPosition = nil;
        if ((int)[vc.allowableTileGridPositionArray count] > 0){
            int index = (int)arc4random_uniform((int)[vc.allowableTileGridPositionArray count]);
            allowableGridPosition = [vc.allowableTileGridPositionArray objectAtIndex:index];
        }

        // Select a tile angle that is equal to the beam angle +/- 45 degrees
        unsigned int mirrorAngle, beamAngle;
        beamAngle = [[allowableGridPosition objectForKey:@"beamAngle"]intValue];
        if (arc4random_uniform(2) > 1){
            mirrorAngle = (beamAngle + 1) % 8;
        }
        else {
            mirrorAngle = (beamAngle - 1) % 8;
        }
        
        int xValue = [[allowableGridPosition objectForKey:@"x"] intValue];
        int yValue = [[allowableGridPosition objectForKey:@"y"] intValue];
        vector_int2 gridPosition;
        gridPosition.x = xValue;
        gridPosition.y = yValue;
        
        // Build mirrorDictionary
        NSMutableDictionary *mirrorDictionary = [[NSMutableDictionary alloc] initWithCapacity:1];
        [mirrorDictionary setObject:[NSNumber numberWithInt:mirrorAngle] forKey:@"Angle"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:mirrorAngle] forKey:@"finalTileAngle"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:7] forKey:@"Color"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:0] forKey:@"demoTile"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:0] forKey:@"demoTileAtFinalGridPosition"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:mirrorAngle] forKey:@"finalTileAngle"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:xValue] forKey:@"finalX"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:yValue] forKey:@"finalY"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:1] forKey:@"fixed"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:xValue] forKey:@"gridPositionX"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:yValue] forKey:@"gridPositionY"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placed"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedManuallyMatchesHint"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedUsingHint"];
        [mirrorDictionary setObject:[NSNumber numberWithInt:MIRROR] forKey:@"tileShape"];
        dimensions.x = _squareTileSideLengthInPixels;
        dimensions.y = _squareTileSideLengthInPixels;
        tile = [self buildOneTileFromDictionary:mirrorDictionary tileShape:MIRROR movableTileX:xValue  movableTileY:yValue];
        tile->tileAngle = mirrorAngle;
        tile->finalTileAngle = mirrorAngle;
        
        // Only save the mirror if it will reflect the beam into the grid
        if ([self checkIfBeamHeadingIntoGridAfterStrikingMirror:gridPosition
                                   beamAngle:beamAngle
                                 mirrorAngle:mirrorAngle]){
            [self putOpticsTile:tile array:tiles];
        }
        else {
            DLog("checkIfBeamHeadingIntoGridAfterStrikingMirror failed");
        }
    }
    //
    // Encode the current puzzle into a dictionary
    //
    puzzleDictionary = [self encodeCurrentPuzzleAsMutableDictionary:puzzleDictionary];

//    [puzzleDictionary removeObjectForKey:@"Beams"];
//    [puzzleDictionary setObject:[NSNumber numberWithInt:1] forKey:@"Tiles"];
    return puzzleDictionary;
}

- (NSMutableDictionary *)generatePuzzleBeams:(NSMutableDictionary *)puzzleDictionary {
    // Clear out the tiles and hints arrays
    tiles = [[NSMutableArray alloc] initWithCapacity:1];
    hints = [[NSMutableArray alloc] initWithCapacity:1];
    
    // Used to manipulate current working tile
    Tile *tile;
    vector_int2 dimensions;
    NSMutableDictionary *allowableGridPosition;
    vc.allowableLaserGridPositionArray = [[NSMutableArray alloc] initWithCapacity:1];
    vc.allowableTileGridPositionArray = [[NSMutableArray alloc] initWithCapacity:1];
    NSMutableArray *allowableAngleArray = [[NSMutableArray alloc] initWithCapacity:1];
    //
    // Generate Lasers
    //
    for (enum eTileColors beamColor=COLOR_RED; beamColor<=COLOR_BLUE; beamColor++){
        // Randomly select one of the allowableGridPosition objects from allowableGridPositionArray
        vc.allowableLaserGridPositionArray = [self generateArrayOfAllowableGridPositionsForLasers:vc.allowableLaserGridPositionArray];
        int index;
        if ((int)[vc.allowableLaserGridPositionArray count] > 0){
            index = (int)arc4random_uniform((int)[vc.allowableLaserGridPositionArray count]);
            allowableGridPosition = [vc.allowableLaserGridPositionArray objectAtIndex:index];
        }
        
        // Randomly select one of the allowable angles based on the allowableGridPosition
        vector_int2 allowableGrid;
        unsigned int angle = 0;
        allowableGrid.x = [[allowableGridPosition objectForKey:@"x"]intValue];
        allowableGrid.y = [[allowableGridPosition objectForKey:@"y"]intValue];
        allowableAngleArray = [self generateArrayOfAllowableAnglesForLaser:allowableAngleArray gridPosition:allowableGrid];
        if ((int)[allowableAngleArray count] > 0){
            index = (int)arc4random_uniform((int)[allowableAngleArray count]);
            angle = [[allowableAngleArray objectAtIndex:index] intValue];
        }
        
        int xValue = [[allowableGridPosition objectForKey:@"x"] intValue];
        int yValue = [[allowableGridPosition objectForKey:@"y"] intValue];
        // Build laserDictionary
        NSMutableDictionary *laserDictionary = [[NSMutableDictionary alloc] initWithCapacity:1];
        [laserDictionary setObject:[NSNumber numberWithInt:angle] forKey:@"Angle"];
        [laserDictionary setObject:[NSNumber numberWithInt:angle] forKey:@"finalTileAngle"];
        [laserDictionary setObject:[NSNumber numberWithInt:beamColor] forKey:@"Color"];
        [laserDictionary setObject:[NSNumber numberWithInt:0] forKey:@"demoTile"];
        [laserDictionary setObject:[NSNumber numberWithInt:0] forKey:@"demoTileAtFinalGridPosition"];
        [laserDictionary setObject:[NSNumber numberWithInt:xValue] forKey:@"finalX"];
        [laserDictionary setObject:[NSNumber numberWithInt:yValue] forKey:@"finalY"];
        [laserDictionary setObject:[NSNumber numberWithInt:1] forKey:@"fixed"];
        [laserDictionary setObject:[NSNumber numberWithInt:xValue] forKey:@"gridPositionX"];
        [laserDictionary setObject:[NSNumber numberWithInt:yValue] forKey:@"gridPositionY"];
        [laserDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placed"];
        [laserDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedManuallyMatchesHint"];
        [laserDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedUsingHint"];
        [laserDictionary setObject:[NSNumber numberWithInt:LASER] forKey:@"tileShape"];
        dimensions.x = _squareTileSideLengthInPixels;
        dimensions.y = _squareTileSideLengthInPixels;
        tile = [self buildOneTileFromDictionary:laserDictionary tileShape:LASER movableTileX:xValue  movableTileY:yValue];
        tile->tileAngle = angle;
        tile->finalTileAngle = angle;
        [self putOpticsTile:tile array:tiles];
    }
    //
    // Encode the current puzzle into a dictionary
    //
    puzzleDictionary = [self encodeCurrentPuzzleAsMutableDictionary:puzzleDictionary];
//    [puzzleDictionary setObject:[NSNumber numberWithInt:1] forKey:@"Beams"];
    return puzzleDictionary;
}

- (NSMutableDictionary *)generateTranslucentTiles:(NSMutableDictionary *)puzzleDictionary {
    vector_int2 gridPosition;
    for (gridPosition.x = 2; gridPosition.x < masterGrid.sizeX-2; gridPosition.x++){
        for (gridPosition.y = 2; gridPosition.y < masterGrid.sizeY-2; gridPosition.y++){
                if ([self existsPassthroughBeam:gridPosition] &&
                    ![self tileOccupiesGridPosition:gridPosition] &&
                    arc4random_uniform(4) < 2){
                // Build rectangleDictionary
                enum eTileColors tileColor = [self getCombinedBeamColorForGridPosition:gridPosition];
                NSMutableDictionary *rectangleDictionary = [[NSMutableDictionary alloc] initWithCapacity:1];
                [rectangleDictionary setObject:[NSNumber numberWithInt:ANGLE0] forKey:@"Angle"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:ANGLE0] forKey:@"finalTileAngle"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:tileColor] forKey:@"Color"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:0] forKey:@"demoTile"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:0] forKey:@"demoTileAtFinalGridPosition"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:gridPosition.x] forKey:@"finalX"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:gridPosition.y] forKey:@"finalY"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:1] forKey:@"fixed"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:gridPosition.x] forKey:@"gridPositionX"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:gridPosition.y] forKey:@"gridPositionY"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placed"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedManuallyMatchesHint"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedUsingHint"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:RECTANGLE] forKey:@"tileShape"];
                Tile *tile = [self buildOneTileFromDictionary:rectangleDictionary tileShape:RECTANGLE movableTileX:gridPosition.x  movableTileY:gridPosition.y];
                tile->tileAngle = ANGLE0;
                tile->finalTileAngle = ANGLE0;
                [self putOpticsTile:tile array:tiles];
            }
        }
    }
    //
    // Encode the current puzzle into a dictionary
    //
    puzzleDictionary = [self encodeCurrentPuzzleAsMutableDictionary:puzzleDictionary];
    return puzzleDictionary;
}

- (NSMutableDictionary *)generateOpaqueTiles:(NSMutableDictionary *)puzzleDictionary {
    vector_int2 gridPosition;
    for (gridPosition.x = 2; gridPosition.x < masterGrid.sizeX-2; gridPosition.x++){
        for (gridPosition.y = 2; gridPosition.y < masterGrid.sizeY-2; gridPosition.y++){
            if (![self existsPassthroughBeam:gridPosition] &&
                ![self beamTouchesButDoesNotPassThrough:gridPosition] &&
                ![self tileOccupiesGridPosition:gridPosition] &&
                arc4random_uniform(4) < 2){
                // Build rectangleDictionary
                NSMutableDictionary *rectangleDictionary = [[NSMutableDictionary alloc] initWithCapacity:1];
                [rectangleDictionary setObject:[NSNumber numberWithInt:ANGLE0] forKey:@"Angle"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:ANGLE0] forKey:@"finalTileAngle"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:COLOR_OPAQUE] forKey:@"Color"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:0] forKey:@"demoTile"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:0] forKey:@"demoTileAtFinalGridPosition"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:gridPosition.x] forKey:@"finalX"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:gridPosition.y] forKey:@"finalY"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:1] forKey:@"fixed"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:gridPosition.x] forKey:@"gridPositionX"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:gridPosition.y] forKey:@"gridPositionY"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placed"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedManuallyMatchesHint"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:0] forKey:@"placedUsingHint"];
                [rectangleDictionary setObject:[NSNumber numberWithInt:RECTANGLE] forKey:@"tileShape"];
                Tile *tile = [self buildOneTileFromDictionary:rectangleDictionary tileShape:RECTANGLE movableTileX:gridPosition.x  movableTileY:gridPosition.y];
                tile->tileAngle = ANGLE0;
                tile->finalTileAngle = ANGLE0;
                [self putOpticsTile:tile array:tiles];
            }
        }
    }
    //
    // Encode the current puzzle into a dictionary
    //
    puzzleDictionary = [self encodeCurrentPuzzleAsMutableDictionary:puzzleDictionary];
    return puzzleDictionary;
}

//***********************************************************************
// Puzzle Generation Utilities
//***********************************************************************
- (BOOL)testWhetherPuzzleCandidateIsAcceptable:(NSMutableDictionary *)puzzleCandidate{
    BOOL retVal = YES;
    // Reject any puzzle with a beam that ends in an empty gridPosition
    NSMutableArray *arrayOfFinalBeamUnoccupiedGridPositions = [self generateArrayOfFinalBeamUnoccupiedGridPositions];
    if ([arrayOfFinalBeamUnoccupiedGridPositions count] > 0){
        DLog("Puzzle Candidate Rejected.  Dangling beams in %lu gridPositions.", (unsigned long)[arrayOfFinalBeamUnoccupiedGridPositions count]);
        return NO;
    }
    // Scan the number and placement of lasers to reject unsuitable candidate puzzles
//    if (![self checkWhetherLasersAreAcceptable]){
//        DLog("Puzzle Candidate Rejected.  Unacceptable laser beam configuration.");
//        return NO;
//    }
    // Make sure that there are at least gameGrid.sizeY Jewels, else reject
//    if ([self jewelCount] < gameGrid.sizeY){
//        DLog("Puzzle Candidate Rejected.  Only %d Jewels.  Minumum allowed number is %d", [self jewelCount], gameGrid.sizeY);
//        return NO;
//    }
    // Scan for non-energized Jewels to reject unsuitable candidate puzzles
    if ([self checkForNonEnergizedJewels]){
        DLog("Puzzle Candidate Rejected.  Non-energized Jewel.");
        return NO;
    }
    // Scan for dangling Tiles, i.e. Mirrors or Beamsplitters with no beam intersecting them
    if ([self checkForDanglingTiles]){
        DLog("Puzzle Candidate Rejected.  Dangling Tile.");
        return NO;
    }
    return retVal;
}

- (unsigned int)jewelCount{
    unsigned int jewelCount = 0;
    Tile *thisTile = nil;
    NSEnumerator *tileEnum = [tiles objectEnumerator];
    while (thisTile = [tileEnum nextObject]){
        if (thisTile->tileShape == JEWEL){
            jewelCount++;
        }
    }
    return jewelCount;
}

- (BOOL)checkForNonEnergizedJewels{
    BOOL retVal = NO;
    Tile *thisTile = nil;
    NSEnumerator *tileEnum = [tiles objectEnumerator];
    while (thisTile = [tileEnum nextObject]){
        if (thisTile->tileShape == JEWEL &&
            thisTile->energized == NO){
            return YES;
        }
    }
    return retVal;
}

- (BOOL)checkForDanglingTiles{
    BOOL retVal = NO;
    Tile *thisTile = nil;
    NSEnumerator *tileEnum = [tiles objectEnumerator];
    while (thisTile = [tileEnum nextObject]){
        if (thisTile->tileShape == MIRROR ||
            thisTile->tileShape == BEAMSPLITTER){
            if (![self checkIfAnyBeamIntersectsGridPosition:thisTile->gridPosition]){
                return YES;
            }
        }
    }
    return retVal;
}

- (BOOL)checkWhetherLasersAreAcceptable {
    Tile *thisTile = nil;
    Tile *laserRed = nil, *laserGreen = nil, *laserBlue = nil;
    unsigned int laserCountRed = 0, laserCountGreen = 0, laserCountBlue = 0;
    NSEnumerator *tileEnum = [tiles objectEnumerator];
    // Fetch the red, green and blue Laser gun tiles
    while (thisTile = [tileEnum nextObject]){
        if (thisTile->tileShape == LASER && thisTile->tileColor == COLOR_RED){
            laserRed = thisTile;
            laserCountRed++;
        }
        else if (thisTile->tileShape == LASER && thisTile->tileColor == COLOR_GREEN){
            laserGreen = thisTile;
            laserCountGreen++;
        }
        else if (thisTile->tileShape == LASER && thisTile->tileColor == COLOR_BLUE){
            laserBlue = thisTile;
            laserCountBlue++;
        }
    }
    // Make sure that all 3 lasers are present
    if (laserCountRed != 1 ||
        laserCountGreen != 1 ||
        laserCountBlue != 1){
        // Must have exactly 1 of all 3 colors of laser or we discard the puzzle candidate
        return NO;
    }
    
    // Consider each laser pair to see if they oppose one another.  If so, reject this candidate.
    if ([self lasersAreOpposing:laserRed laser2:laserGreen]){
        return NO;
    }
    else if ([self lasersAreOpposing:laserGreen laser2:laserRed]){
        return NO;
    }
    else if ([self lasersAreOpposing:laserRed laser2:laserBlue]){
        return NO;
    }
    else if ([self lasersAreOpposing:laserBlue laser2:laserRed]){
        return NO;
    }
    else if ([self lasersAreOpposing:laserGreen laser2:laserBlue]){
        return NO;
    }
    else if ([self lasersAreOpposing:laserBlue laser2:laserGreen]){
        return NO;
    }
    return YES;
}

- (BOOL)lasersAreOpposing:(Tile *)laser1 laser2:(Tile*)laser2{
    BOOL retVal = NO;
    if (laser1->tileAngle == (laser2->tileAngle + 4) % 8){
        // Horizontal beam
        if (laser1->gridPosition.x == 0 &&
            laser2->gridPosition.x == masterGrid.sizeX-1 &&
            laser1->gridPosition.y == laser2->gridPosition.y){
            return YES;
        }
        // Vertical beam
        else if (laser1->gridPosition.y == 0 &&
            laser2->gridPosition.y == masterGrid.sizeX-1 &&
            laser1->gridPosition.x == laser2->gridPosition.x){
            return YES;
        }
        // Diagonal beam, case 1
        else if (laser1->gridPosition.x == 0 &&
                 laser2->gridPosition.y == masterGrid.sizeY-1 &&
                 laser1->gridPosition.y == masterGrid.sizeY-1 - laser2->gridPosition.x){
            return YES;
        }
        // Diagonal beam, case 2
        else if (laser1->gridPosition.x == 0 &&
                 laser2->gridPosition.y == 0 &&
                 laser1->gridPosition.y == laser2->gridPosition.x){
            return YES;
        }
        // Diagonal beam, case 3
        else if (laser1->gridPosition.x == masterGrid.sizeX-1 &&
                 laser2->gridPosition.y == masterGrid.sizeY-1 &&
                 laser1->gridPosition.y == laser2->gridPosition.x){
            return YES;
        }
        // Diagonal beam, case 4
        else if (laser1->gridPosition.x == masterGrid.sizeX-1 &&
                 laser2->gridPosition.y == 0 &&
                 laser1->gridPosition.y == masterGrid.sizeX-1 - laser2->gridPosition.x){
            return YES;
        }
    }
    return retVal;
}

- (void)markTilesFixedBasedOnPuzzleDifficulty:(unsigned int)puzzleDifficulty {
    // Set the tile modulus to use for setting fixed=YES based on puzzleDifficulty
    unsigned int tileModulus;
    if (puzzleDifficulty <= 3){
        tileModulus = 4;
    }
    else if (puzzleDifficulty <= 7){
        tileModulus = 3;
    }
    else {
        tileModulus = 2;
    }
    // Go through all of the existing tiles and set an appropriate number of them as fixed
    Tile *myTile = nil;
    NSEnumerator *tileEnum = [tiles objectEnumerator];
    unsigned int tileIndex = 0;
    unsigned int unfixedTileCount = 0;
    while (myTile = [tileEnum nextObject]){
        if (myTile->tileShape == MIRROR ||
            myTile->tileShape == BEAMSPLITTER ||
            myTile->tileShape == PRISM){
//            if (tileIndex % tileModulus == 0){
            if (tileIndex % tileModulus == 0 &&
                unfixedTileCount < gameGrid.sizeX){
                myTile->fixed = NO;
                unfixedTileCount++;            }
            tileIndex++;
        }
    }
}

- (NSMutableArray *)generateArrayOfAllowableGridPositionsForLasers:(NSMutableArray *)allowableGridPositionArray {
    // Initialize in case not empty
    NSMutableDictionary *allowableGridPosition;
    allowableGridPositionArray = [NSMutableArray arrayWithCapacity:1];
    vector_int2 gridPosition;
    for (gridPosition.x=0; gridPosition.x<masterGrid.sizeX; gridPosition.x++){
        for (gridPosition.y=0; gridPosition.y<masterGrid.sizeY; gridPosition.y++){
            // No corners
            if ( !(gridPosition.x == 0 && gridPosition.y == 0) &&
                !(gridPosition.x == 0 && gridPosition.y == masterGrid.sizeY-1) &&
                !(gridPosition.x == masterGrid.sizeX-1 && gridPosition.y == masterGrid.sizeY-1) &&
                !(gridPosition.x == masterGrid.sizeX-1 && gridPosition.y == 0)){
                if ( (gridPosition.x == 0 ||
                    gridPosition.x == masterGrid.sizeX-1 ||
                    gridPosition.y == 0 ||
                    gridPosition.y == masterGrid.sizeY-1) &&
                    ([self tileOccupiesGridPosition:gridPosition] == nil)){
                    allowableGridPosition = [[NSMutableDictionary alloc] initWithCapacity:1];
                    [allowableGridPosition setObject:[NSNumber numberWithInt:gridPosition.x] forKey:@"x"];
                    [allowableGridPosition setObject:[NSNumber numberWithInt:gridPosition.y] forKey:@"y"];
                    [allowableGridPositionArray addObject:allowableGridPosition];
                }
            }
        }
    }
    return allowableGridPositionArray;
}

- (NSMutableArray *)generateArrayOfPeripheralGridPositions:(NSMutableArray *)allowableGridPositionArray {
    // Initialize in case not empty
    NSMutableDictionary *allowableGridPosition;
    allowableGridPositionArray = [NSMutableArray arrayWithCapacity:1];
    vector_int2 gridPosition;
    for (gridPosition.x=0; gridPosition.x<masterGrid.sizeX; gridPosition.x++){
        for (gridPosition.y=0; gridPosition.y<masterGrid.sizeY; gridPosition.y++){
            if ( (gridPosition.x == 0 ||
                  gridPosition.x == masterGrid.sizeX-1 ||
                  gridPosition.y == 0 ||
                  gridPosition.y == masterGrid.sizeY-1)){
                allowableGridPosition = [[NSMutableDictionary alloc] initWithCapacity:1];
                [allowableGridPosition setObject:[NSNumber numberWithInt:gridPosition.x] forKey:@"x"];
                [allowableGridPosition setObject:[NSNumber numberWithInt:gridPosition.y] forKey:@"y"];
                [allowableGridPositionArray addObject:allowableGridPosition];
            }
        }
    }
    return allowableGridPositionArray;
}

- (NSMutableArray *)generateArrayOfAllowableAnglesForLaser:(NSMutableArray *)array gridPosition:(vector_int2)gridPosition {
    // Initialize in case not empty
    array = [NSMutableArray arrayWithCapacity:1];
    // First handle corner (0, 0) and adjacent
    if (gridPosition.x == 0 && gridPosition.y == 0){
        [array addObject:[NSNumber numberWithInt:ANGLE45]];
    }
    else if (gridPosition.x == 1 && gridPosition.y == 0){
        [array addObject:[NSNumber numberWithInt:ANGLE45]];
    }
    else if (gridPosition.x == 0 && gridPosition.y == 1){
        [array addObject:[NSNumber numberWithInt:ANGLE45]];
    }

    // Next handle (0, masterGrid.sizeY-1) and adjacent
    else if (gridPosition.x == 0 && gridPosition.y == masterGrid.sizeY-1){
        [array addObject:[NSNumber numberWithInt:ANGLE315]];
    }
    else if (gridPosition.x == 1 && gridPosition.y == masterGrid.sizeY-1){
        [array addObject:[NSNumber numberWithInt:ANGLE315]];
    }
    else if (gridPosition.x == 0 && gridPosition.y == masterGrid.sizeY-2){
        [array addObject:[NSNumber numberWithInt:ANGLE315]];
    }

    // Next handle (masterGrid.sizeX-1, 0) and adjacent
    else if (gridPosition.x == masterGrid.sizeX-1  && gridPosition.y == 0){
        [array addObject:[NSNumber numberWithInt:ANGLE135]];
    }
    else if (gridPosition.x == masterGrid.sizeX-1  && gridPosition.y == 1){
        [array addObject:[NSNumber numberWithInt:ANGLE135]];
    }
    else if (gridPosition.x == masterGrid.sizeX-2 && gridPosition.y == 0){
        [array addObject:[NSNumber numberWithInt:ANGLE135]];
    }

    // Next handle (masterGrid.sizeX-1, masterGrid.sizeY-1) and adjacent
    else if (gridPosition.x == masterGrid.sizeX-1 && gridPosition.y == masterGrid.sizeY-1){
        [array addObject:[NSNumber numberWithInt:ANGLE225]];
    }
    else if (gridPosition.x == masterGrid.sizeX-2 && gridPosition.y == masterGrid.sizeY-1){
        [array addObject:[NSNumber numberWithInt:ANGLE225]];
    }
    else if (gridPosition.x == masterGrid.sizeX-1 && gridPosition.y == masterGrid.sizeY-2){
        [array addObject:[NSNumber numberWithInt:ANGLE225]];
    }

    //  Next handle the remaining sides
    else if (gridPosition.x == 0){
        [array addObject:[NSNumber numberWithInt:ANGLE0]];
    }
    else if (gridPosition.x == masterGrid.sizeX-1){
        [array addObject:[NSNumber numberWithInt:ANGLE180]];
    }
    else if (gridPosition.y == 0){
        [array addObject:[NSNumber numberWithInt:ANGLE90]];
    }
    else if (gridPosition.y == masterGrid.sizeY-1){
        [array addObject:[NSNumber numberWithInt:ANGLE270]];
    }
    return array;
}

- (NSMutableArray *)generateArrayOfAllowableGridPositionsForSplitters:(NSMutableArray *)allowableGridPositionArray color:(enum eBeamColors)color {
    // Initialize in case not empty
    NSMutableDictionary *allowableGridPosition;
    allowableGridPositionArray = [NSMutableArray arrayWithCapacity:1];
    vector_int2 gridPosition;
    NSNumber *beamAngle = nil;
    for (gridPosition.x=1; gridPosition.x<masterGrid.sizeX-1; gridPosition.x++){
        for (gridPosition.y=1; gridPosition.y<masterGrid.sizeY-1; gridPosition.y++){
            if (![self tileOccupiesGridPosition:gridPosition]){
                if ((beamAngle = [self anyBeamSegmentIntersectsGridPosition:gridPosition
                                                       beamColor:color]) != nil){
                    if ([self countBeamsIntersectingGridPosition:gridPosition] == 1){
                        allowableGridPosition = [[NSMutableDictionary alloc] initWithCapacity:1];
                        [allowableGridPosition setObject:[NSNumber numberWithInt:gridPosition.x] forKey:@"x"];
                        [allowableGridPosition setObject:[NSNumber numberWithInt:gridPosition.y] forKey:@"y"];
                        [allowableGridPosition setObject:beamAngle forKey:@"beamAngle"];
                        [allowableGridPositionArray addObject:allowableGridPosition];
                    }
                }
            }
        }
    }
    return allowableGridPositionArray;
}

- (NSMutableArray *)generateArrayOfAllowableGridPositionsForTiles:(NSMutableArray *)allowableGridPositionArray color:(enum eBeamColors)color {
    // Initialize in case not empty
    NSMutableDictionary *allowableGridPosition;
    allowableGridPositionArray = [NSMutableArray arrayWithCapacity:1];
    vector_int2 gridPosition;
    NSNumber *beamAngle = nil;
    for (gridPosition.x=1; gridPosition.x<masterGrid.sizeX-1; gridPosition.x++){
        for (gridPosition.y=1; gridPosition.y<masterGrid.sizeY-1; gridPosition.y++){
            if (![self tileOccupiesGridPosition:gridPosition]){
                if ((beamAngle = [self finalBeamSegmentIntersectsGridPosition:gridPosition
                                                       beamColor:color]) != nil){
                    if ([self countBeamsIntersectingGridPosition:gridPosition] == 1){
                        allowableGridPosition = [[NSMutableDictionary alloc] initWithCapacity:1];
                        [allowableGridPosition setObject:[NSNumber numberWithInt:gridPosition.x] forKey:@"x"];
                        [allowableGridPosition setObject:[NSNumber numberWithInt:gridPosition.y] forKey:@"y"];
                        [allowableGridPosition setObject:beamAngle forKey:@"beamAngle"];
                        [allowableGridPositionArray addObject:allowableGridPosition];
                    }
                }
            }
        }
    }
    return allowableGridPositionArray;
}

// Return an array of "final" beam segments for beamColor
- (NSMutableArray *)generateArrayOfFinalBeamSegments:(enum eBeamColors)beamColor{
    NSEnumerator *beamsEnum = [beams[beamColor] objectEnumerator];
    NSMutableArray *arrayOfFinalBeamSegments = [NSMutableArray arrayWithCapacity:1];
    Beam *beamSegment;
    Beam *rootBeam = [self fetchRootBeam:beamColor];
    while (beamSegment = [beamsEnum nextObject]){
        if (beamSegment->endTile == nil &&
            (beamSegment->beamEnd.x != rootBeam->beamStart.x ||
             beamSegment->beamEnd.y != rootBeam->beamStart.y)){
            [arrayOfFinalBeamSegments addObject:beamSegment];
        }
    }
    return arrayOfFinalBeamSegments;
}

// Returns YES if any beam enters and exits this gridPosition.
// Such a "Passthrough" beam means that this is not an appropriate gridPosition for a Jewel
- (BOOL)existsPassthroughBeam:(vector_int2)gridPosition{
    NSMutableDictionary *returnDictionary = nil;
    NSEnumerator *beamsEnum;
    Beam *beamSegment;
    for (enum eBeamColors color=BEAM_RED; color <= BEAM_BLUE; color++){
        beamsEnum = [beams[color] objectEnumerator];
        while (beamSegment = [beamsEnum nextObject]){
            returnDictionary = [beamSegment checkIfBeamIntersectsGridPosition:gridPosition];
            if ([[returnDictionary objectForKey:@"beamPassesThroughGridPoint"] intValue] == 1){
                return YES;
            }
        }
    }
    return NO;
}

// Returns YES if any beam touches this gridPosition but does not pass through it.
- (BOOL)beamTouchesButDoesNotPassThrough:(vector_int2)gridPosition{
    NSMutableDictionary *returnDictionary = nil;
    NSEnumerator *beamsEnum;
    Beam *beamSegment;
    for (enum eBeamColors color=BEAM_RED; color <= BEAM_BLUE; color++){
        beamsEnum = [beams[color] objectEnumerator];
        while (beamSegment = [beamsEnum nextObject]){
            returnDictionary = [beamSegment checkIfBeamIntersectsGridPosition:gridPosition];
            if ([[returnDictionary objectForKey:@"beamTouchesGridPoint"] intValue] == 1){
                return YES;
            }
        }
    }
    return NO;
}

- (NSMutableArray *)generateArrayOfFinalBeamUnoccupiedGridPositions {
    vector_int2 gridPosition;
    NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:1];
    NSMutableDictionary *resultArrayElement;
    for (gridPosition.x=0; gridPosition.x<masterGrid.sizeX; gridPosition.x++){
        for (gridPosition.y=0; gridPosition.y<masterGrid.sizeY; gridPosition.y++){
            vector_int2 beamEndGridPosition;
            resultArrayElement = [NSMutableDictionary dictionaryWithCapacity:1];
            for (enum eBeamColors beamColor = BEAM_RED; beamColor <= BEAM_BLUE; beamColor++){
                // Check each final beam segment
                NSMutableArray *finalBeamSegments = [self generateArrayOfFinalBeamSegments:beamColor];
                NSEnumerator *beamsEnum = [finalBeamSegments objectEnumerator];
                Beam *beamSegment;
                while (beamSegment = [beamsEnum nextObject]){
                    if (![self tileOccupiesGridPosition:beamSegment->beamEnd]){
                        beamEndGridPosition = beamSegment->beamEnd;
                    }
                    else {
                        beamEndGridPosition = beamSegment->beamEnd;
                        switch (beamSegment->beamAngle){
                            case ANGLE0:{
                                beamEndGridPosition.x--;
                                break;
                            }
                            case ANGLE45:{
                                beamEndGridPosition.x--;
                                beamEndGridPosition.y--;
                                break;
                            }
                            case ANGLE90:{
                                beamEndGridPosition.y--;
                                break;
                            }
                            case ANGLE135:{
                                beamEndGridPosition.x++;
                                beamEndGridPosition.y--;
                                break;
                            }
                            case ANGLE180:{
                                beamEndGridPosition.x++;
                                break;
                            }
                            case ANGLE225:{
                                beamEndGridPosition.x++;
                                beamEndGridPosition.y++;
                                break;
                            }
                            case ANGLE270:{
                                beamEndGridPosition.y++;
                                break;
                            }
                            case ANGLE315:
                            default:{
                                beamEndGridPosition.x--;
                                beamEndGridPosition.y++;
                                break;
                            }
                        }
                    }
                    if (gridPosition.x == beamEndGridPosition.x &&
                        gridPosition.y == beamEndGridPosition.y &&
                        [self existsPassthroughBeam:gridPosition] == NO){
                        [resultArrayElement setObject:[NSNumber numberWithInt:beamEndGridPosition.x] forKey:@"x"];
                        [resultArrayElement setObject:[NSNumber numberWithInt:beamEndGridPosition.y] forKey:@"y"];
                        switch (beamColor){
                            case BEAM_RED:{
                                [resultArrayElement setObject:[NSNumber numberWithInt:1] forKey:@"BEAM_RED"];
                                break;
                            }
                            case BEAM_GREEN:{
                                [resultArrayElement setObject:[NSNumber numberWithInt:1] forKey:@"BEAM_GREEN"];
                                break;
                            }
                            case BEAM_BLUE:{
                                [resultArrayElement setObject:[NSNumber numberWithInt:1] forKey:@"BEAM_BLUE"];
                                break;
                            }
                        }
                    }
                }
            }
            if ([resultArrayElement objectForKey:@"x"] != nil){
                [resultArray addObject:resultArrayElement];
            }
        }
    }
    return resultArray;
}

- (enum eTileColors)getCombinedBeamColorForGridPosition:(vector_int2)gridPosition {
    NSMutableDictionary *returnDictionary = nil;
    NSEnumerator *beamsEnum;
    Beam *beamSegment;
    enum eTileColors combinedColor = COLOR_OPAQUE;
    int redCount = 0;
    int greenCount = 0;
    int blueCount = 0;
    for (enum eBeamColors color=BEAM_RED; color <= BEAM_BLUE; color++){
        beamsEnum = [beams[color] objectEnumerator];
        while (beamSegment = [beamsEnum nextObject]){
            returnDictionary = [beamSegment checkIfBeamIntersectsGridPosition:gridPosition];
            if ([[returnDictionary objectForKey:@"beamTouchesGridPoint"] intValue] == 1 ||
                [[returnDictionary objectForKey:@"beamPassesThroughGridPoint"] intValue] == 1){
                switch (color){
                    case BEAM_RED:{
                        redCount = 1;
                        break;
                    }
                    case BEAM_GREEN:{
                        greenCount = 1;
                        break;
                    }
                    case BEAM_BLUE:{
                        blueCount = 1;
                        break;
                    }
                }
            }
        }
    }
    // Combine colors
    if (redCount == 0 && greenCount == 0 && blueCount == 0){
        combinedColor = COLOR_OPAQUE;
    }
    else if (redCount == 1 && greenCount == 0 && blueCount == 0){
        combinedColor = COLOR_RED;
    }
    else if (redCount == 0 && greenCount == 1 && blueCount == 0){
        combinedColor = COLOR_GREEN;
    }
    else if (redCount == 0 && greenCount == 0 && blueCount == 1){
        combinedColor = COLOR_BLUE;
    }
    else if (redCount == 1 && greenCount == 1 && blueCount == 0){
        combinedColor = COLOR_YELLOW;
    }
    else if (redCount == 0 && greenCount == 1 && blueCount == 1){
        combinedColor = COLOR_CYAN;
    }
    else if (redCount == 1 && greenCount == 0 && blueCount == 1){
        combinedColor = COLOR_MAGENTA;
    }
    else if (redCount == 1 && greenCount == 1 && blueCount == 1){
        combinedColor = COLOR_WHITE;
    }
    return combinedColor;
}

// Check to see if any of the segments of a beam intersects a particular gridPoint
- (NSNumber *)anyBeamSegmentIntersectsGridPosition:(vector_int2)gridPosition
                                           beamColor:(enum eBeamColors)beamColor {
    NSNumber *beamAngle = nil;
    NSMutableDictionary *returnDictionary = nil;
    // Check all of the beams of beamColor to see if any of them intersect gridPosition
    NSEnumerator *beamsEnum = [beams[beamColor] objectEnumerator];
    Beam *beamSegment = nil;
    while (beamSegment = [beamsEnum nextObject]){
        returnDictionary = [beamSegment checkIfBeamIntersectsGridPosition:gridPosition];
        if ([[returnDictionary objectForKey:@"beamTouchesGridPoint"] intValue] == 1){
            int angle = [[returnDictionary objectForKey:@"beamAngle"]intValue];
            beamAngle = [NSNumber numberWithInt:angle];
        }
    }
    return beamAngle;
}

// Check to see if any of the final segments of a beam intersects a particular gridPoint
- (NSNumber *)finalBeamSegmentIntersectsGridPosition:(vector_int2)gridPosition
                                           beamColor:(enum eBeamColors)beamColor {
    NSNumber *beamAngle = nil;
    NSMutableDictionary *returnDictionaryFinalBeamSegment = nil;
    
    // Build an array with all "final" beam segments for beamColor
    NSMutableArray *arrayOfFinalBeamSegments = [self generateArrayOfFinalBeamSegments:beamColor];
    
    // Check all "final" beams of beamColor to see if any of them intersect gridPosition
    NSEnumerator *beamsEnum = [arrayOfFinalBeamSegments objectEnumerator];
    Beam *beamSegment;
    while (beamSegment = [beamsEnum nextObject]){
        returnDictionaryFinalBeamSegment = [beamSegment checkIfBeamIntersectsGridPosition:gridPosition];
        if ([[returnDictionaryFinalBeamSegment objectForKey:@"beamTouchesGridPoint"] intValue] == 1){
            int angle = [[returnDictionaryFinalBeamSegment objectForKey:@"beamAngle"]intValue];
            beamAngle = [NSNumber numberWithInt:angle];
        }
    }
    return beamAngle;
}

// Count how many beams of any color intersects a gridPosition
- (int)countBeamsIntersectingGridPosition:(vector_int2)gridPosition{
    NSMutableDictionary *returnDictionary = nil;
    NSEnumerator *beamsEnum;
    Beam *beamSegment;
    int intersectCount = 0;
    for (enum eBeamColors color=BEAM_RED; color <= BEAM_BLUE; color++){
        beamsEnum = [beams[color] objectEnumerator];
        while (beamSegment = [beamsEnum nextObject]){
            returnDictionary = [beamSegment checkIfBeamIntersectsGridPosition:gridPosition];
            if ([[returnDictionary objectForKey:@"beamTouchesGridPoint"] intValue] == 1){
                intersectCount++;
            }
        }
    }
    return intersectCount;
}

- (vector_int2)beamEndGridPosition:(enum eBeamColors)beamColor {
    vector_int2 retVal;
    retVal.x = -1;
    retVal.y = -1;
    Beam *beamSegment;
    NSEnumerator *beamsEnum;
    beamsEnum = [beams[beamColor] objectEnumerator];
    // Fetch the final beam segment
    beamSegment = [beamsEnum nextObject];
    if (beamSegment != nil){
        return beamSegment->beamEnd;
    }
    return retVal;
}

- (BOOL)checkIfAnyBeamIntersectsGridPosition:(vector_int2)gridPosition{
    for (enum eBeamColors beamColor = BEAM_RED; beamColor <= BEAM_BLUE; beamColor++){
        NSEnumerator *beamsEnum = [beams[beamColor] objectEnumerator];
        Beam *thisBeam;
        NSMutableDictionary *returnDictionary;
        while (thisBeam = [beamsEnum nextObject]){
            returnDictionary = [thisBeam checkIfBeamIntersectsGridPosition:gridPosition];
            if ([[returnDictionary objectForKey:@"beamTouchesGridPoint"]intValue] > 0){
                return YES;
            }
        }
    }
    return NO;
}

// If the final beam segment crosses the gridPosition then return an NSMutableDictionary with 2 elements:
//      (object=1, tag=@"beamTouchesGridPoint")
//      (object=angle, tag=@"beamAngle")
// If the final beam segment does not cross the gridPosition then return nil
// If both the final beam segment (of beamColor) and a prior beam segment (of ANY color) cross the gridPosition then return nil
- (NSMutableDictionary *)checkIfBeamTouchesGridPosition:(vector_int2)gridPosition beamColor:(enum eBeamColors)beamColor {
    NSMutableDictionary *returnDictionaryFinalSegment = nil;
    NSMutableDictionary *returnDictionaryPriorSegment = nil;
    Beam *beamSegment;
    NSEnumerator *beamsEnum, *beamsEnumAll;
    enum eBeamColors allBeamColors;
    for (allBeamColors = BEAM_RED; allBeamColors <= BEAM_BLUE; allBeamColors++){
        if (allBeamColors == beamColor){
            // Check to see if the the beam segment furthest from the laser (the first
            // element of the Array) intersects this gridPosition.
            beamsEnum = [beams[allBeamColors] objectEnumerator];
            beamSegment = [beamsEnum nextObject];
            returnDictionaryFinalSegment = [beamSegment checkIfBeamIntersectsGridPosition:gridPosition];
            // Next check to see if any of the prior beam segments (closer to the laser)
            // of this beamColor cross this gridPosition.
            while (beamSegment = [beamsEnum nextObject]){
                returnDictionaryPriorSegment = [beamSegment checkIfBeamIntersectsGridPosition:gridPosition];
                if ([[returnDictionaryPriorSegment objectForKey:@"beamTouchesGridPoint"]intValue] > 0){
                    break;
                }
            }
        }
        else {
            beamsEnumAll = [beams[allBeamColors] objectEnumerator];
            // Check to see if any of beam segment (closer to the laser)
            // of this color crosses this gridPosition.
            while (beamSegment = [beamsEnumAll nextObject]){
                returnDictionaryPriorSegment = [beamSegment checkIfBeamIntersectsGridPosition:gridPosition];
                if ([[returnDictionaryPriorSegment objectForKey:@"beamTouchesGridPoint"]intValue] > 0){
                    break;
                }
            }
        }
    }

    if(([[returnDictionaryFinalSegment objectForKey:@"beamTouchesGridPoint"] intValue] == 1) &&
       ([[returnDictionaryPriorSegment objectForKey:@"beamTouchesGridPoint"] intValue] == 0)){
        return returnDictionaryFinalSegment;
    }
    else if (([[returnDictionaryFinalSegment objectForKey:@"beamTouchesGridPoint"] intValue] == 1) &&
              ([[returnDictionaryPriorSegment objectForKey:@"beamTouchesGridPoint"] intValue] == 1)){
        return nil;
    }
    return nil;
}

- (BOOL)checkIfBeamHeadingIntoGridAfterStrikingMirror:(vector_int2)position
                      beamAngle:(int)beamAngle
                      mirrorAngle:(int)mirrorAngle{
    BOOL retVal = NO;
    unsigned int reflectedBeamAngle = [self calculateBeamAngleAfterStrikingMirror:beamAngle mirrorAngle:mirrorAngle];
    // Interior points are all acceptable
    if (position.x > 1 &&
         position.x < gameGrid.sizeX &&
         position.y > 0 &&
         position.y < gameGrid.sizeY){
        retVal = YES;
    }
    // Handle corners first
    else if (position.x == 1 && position.y == 1 &&
        (reflectedBeamAngle == ANGLE0 ||
         reflectedBeamAngle == ANGLE45 ||
         reflectedBeamAngle == ANGLE90)){
        retVal = YES;
    }
    else if (position.x == 1 && position.y == gameGrid.sizeY &&
        (reflectedBeamAngle == ANGLE0 ||
         reflectedBeamAngle == ANGLE315 ||
         reflectedBeamAngle == ANGLE270)){
        retVal = YES;
    }
    else if (position.x == gameGrid.sizeX && position.y == 1 &&
        (reflectedBeamAngle == ANGLE180 ||
         reflectedBeamAngle == ANGLE135 ||
         reflectedBeamAngle == ANGLE90)){
        retVal = YES;
    }
    else if (position.x == gameGrid.sizeX && position.y == gameGrid.sizeY &&
        (reflectedBeamAngle == ANGLE180 ||
         reflectedBeamAngle == ANGLE225 ||
         reflectedBeamAngle == ANGLE270)){
        retVal = YES;
    }
    // Now handle the sides
    else if (position.x == 1 &&
        (reflectedBeamAngle >= ANGLE270 ||
         reflectedBeamAngle <= ANGLE90)){
        retVal = YES;
    }
    else if (position.x == gameGrid.sizeX &&
        (reflectedBeamAngle <= ANGLE270 ||
         reflectedBeamAngle >= ANGLE90)){
        retVal = YES;
    }
    else if (position.y == 1 &&
        (reflectedBeamAngle >= 0 ||
         reflectedBeamAngle <= ANGLE180)){
        retVal = YES;
    }
    else if (position.y == gameGrid.sizeY &&
        (reflectedBeamAngle >= ANGLE180 ||
         reflectedBeamAngle == ANGLE0)){
        retVal = YES;
    }
    return retVal;
}

- (unsigned int)calculateBeamAngleAfterStrikingMirror:(int)beamAngle
                                          mirrorAngle:(int)mirrorAngle{
    unsigned int reflectedBeamAngle = beamAngle;
    if ( ((mirrorAngle == beamAngle) || ( (mirrorAngle+4)%8 == beamAngle) )) {
        reflectedBeamAngle = (beamAngle + 4) % 8;
    }
    else if ( beamAngle == (mirrorAngle+1)%8 ) {
        reflectedBeamAngle = (beamAngle + 2) % 8;
    }
    else if ( beamAngle == (mirrorAngle-1)%8 ) {
        reflectedBeamAngle = (beamAngle - 2) % 8;
    }
    else if ( beamAngle == (mirrorAngle+3)%8 ) {
        reflectedBeamAngle = (beamAngle - 2) % 8;
    }
    else if ( beamAngle == (mirrorAngle-3)%8 ) {
        reflectedBeamAngle = (beamAngle + 2) % 8;
    }
    return reflectedBeamAngle;
}

- (void)removeNonEnergizedJewels {
    Tile *thisTile = nil;
    NSEnumerator *tileEnum = [tiles objectEnumerator];
    // Check that there is at least one Jewel in the puzzle
    if ([self jewelCount] > 0){
        // Remove any Jewels that are not energized
        if (![self checkIfAllJewelsAreEnergized]){
            while (thisTile = [tileEnum nextObject]){
                if (thisTile->tileShape == JEWEL &&
                    thisTile->energized == NO){
                    [self removeOpticsTile:thisTile array:tiles];
                    [self resetAllColorBeams];
                    [self updateEnergizedStateForAllTiles];
                }
            }
        }
    }
    else {
        DLog("removeNonEnergizedJewels did not run - no Jewels in puzzle");
    }
}

- (void)cleanPuzzle {
    Tile *thisTile = nil;
    if (tiles != nil && [tiles count] > 0){
        NSEnumerator *tileEnum = [tiles objectEnumerator];
        // If there are one or more Jewels and all Jewels are energized
        // remove any tiles that do not contribute to the puzzle solution
        if ([self jewelCount] > 0){
            if ([self checkIfAllJewelsAreEnergized]){
                tileEnum = [tiles objectEnumerator];
                thisTile = nil;
                while (thisTile = [tileEnum nextObject]){
                    if (thisTile->tileShape == MIRROR ||
                        thisTile->tileShape == BEAMSPLITTER ||
                        thisTile->tileShape == PRISM){
                        // Try removing each tile from tiles array in turn.  If removing a tile does not affect puzzle
                        // completion then leave it out, otherwise put it back.
                        [self removeOpticsTile:thisTile array:tiles];
                        [self resetAllColorBeams];
                        [self updateEnergizedStateForAllTiles];
                        if (![self checkIfAllJewelsAreEnergized]){
                            [self putOpticsTile:thisTile array:tiles];
                        }
                        else {
                            DLog("cleanPuzzle removed tile of shape %d at gridPosition (%d, %d)",
                                  thisTile->tileShape,
                                  thisTile->gridPosition.x,
                                  thisTile->gridPosition.y);
                        }
                    }
                }
            }
            else {
                DLog("cleanPuzzle did not run - puzzle not complete");
            }
        }
        else {
            DLog("cleanPuzzle did not run - no Jewels left in puzzle");
        }
    }
    else {
        DLog("cleanPuzzle failed");
    }
}

- (NSMutableArray *)generateArrayOfAllowableGridPositionsForTiles:(NSMutableArray *)allowableGridPositionArray {
    // Initialize in case not empty
    NSMutableDictionary *allowableGridPosition, *returnDictionary;
    allowableGridPositionArray = [NSMutableArray arrayWithCapacity:1];
    vector_int2 gridPosition;
    for (gridPosition.x=0; gridPosition.x<masterGrid.sizeX; gridPosition.x++){
        for (gridPosition.y=0; gridPosition.y<masterGrid.sizeY; gridPosition.y++){
            for (enum eBeamColors color=BEAM_RED; color <= BEAM_BLUE; color++){
                returnDictionary = [self checkIfBeamTouchesGridPosition:gridPosition beamColor:color];
                if (returnDictionary != nil &&
                    [self tileOccupiesGridPosition:gridPosition] == nil){
                    allowableGridPosition = [[NSMutableDictionary alloc] initWithCapacity:1];
                    [allowableGridPosition setObject:[NSNumber numberWithInt:gridPosition.x] forKey:@"x"];
                    [allowableGridPosition setObject:[NSNumber numberWithInt:gridPosition.y] forKey:@"y"];
                    [allowableGridPosition setObject:[NSNumber numberWithInt:[[returnDictionary objectForKey:@"beamAngle"]intValue]] forKey:@"beamAngle"];
                    [allowableGridPositionArray addObject:allowableGridPosition];
                }
            }
        }
    }
    return allowableGridPositionArray;
}

- (BOOL)checkForOpposingBeams {
    BOOL retVal = 0;
    return retVal;
}

//***********************************************************************
// Puzzle Completion Methods
//***********************************************************************
- (BOOL)queryPuzzleCompleted {
    BOOL puzzleCompleted = NO;
    if (puzzleCompletionCondition == ALL_JEWELS_ENERGIZED){
        // Main puzzles
        if (rc.appCurrentGamePackType == PACKTYPE_MAIN ||
            (rc.appCurrentGamePackType == PACKTYPE_EDITOR &&
             ![appd editModeIsEnabled])){
            if ([self checkIfAllJewelsAreEnergized]) {
                puzzleCompleted = YES;
                if (!puzzleHasBeenCompleted) {
                    [appd playPuzzleCompleteSoundEffect];
                }
                [self handlePuzzleCompletion:nil];
                vc.hintButton.hidden = YES;
                vc.hintBulb.hidden = YES;
                vc.nextArrow.hidden = NO;
                vc.homeArrowWhite.hidden = NO;
                vc.replayIconWhite.hidden = NO;
            }
            else {
                vc.puzzleCompleteLabel.hidden = YES;
                vc.puzzleCompleteMessage.hidden = YES;
                puzzleHasBeenCompleted = NO;
                puzzleHasBeenCompletedCelebration = NO;
                vc.nextArrow.hidden = YES;
                vc.homeArrowWhite.hidden = YES;
                vc.replayIconWhite.hidden = YES;
            }
        }
        // Daily puzzle
        else if (rc.appCurrentGamePackType == PACKTYPE_DAILY){
            if ([self checkIfAllJewelsAreEnergized]) {
                puzzleCompleted = YES;
                if (!puzzleHasBeenCompleted) {
                    [appd playPuzzleCompleteSoundEffect];
                }
                [self handlePuzzleCompletion:nil];
                vc.hintButton.hidden = YES;
                vc.hintBulb.hidden = YES;
                vc.nextButton.hidden = YES;
                vc.nextArrow.hidden = YES;
                vc.homeArrowWhite.hidden = NO;
                vc.replayIconWhite.hidden = NO;
            }
            else {
                vc.puzzleCompleteLabel.hidden = YES;
                vc.puzzleCompleteMessage.hidden = YES;
                puzzleHasBeenCompleted = NO;
                puzzleHasBeenCompletedCelebration = NO;
                vc.nextButton.hidden = YES;
                vc.nextArrow.hidden = YES;
                vc.homeArrowWhite.hidden = YES;
                vc.replayIconWhite.hidden = YES;
            }
        }
        // Demo puzzles
        else if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
            vc.hintButton.hidden = [self allTilesArePlaced] ||
                                ((rc.appCurrentGamePackType == PACKTYPE_DEMO) && !circleAroundHintsButton);
            vc.hintBulb.hidden = [self allTilesArePlaced] ||
                                ((rc.appCurrentGamePackType == PACKTYPE_DEMO) && !circleAroundHintsButton);
            vc.homeArrow.hidden = NO;
            if ([self checkIfAllJewelsAreEnergized]) {
                puzzleCompleted = YES;
                if (!puzzleHasBeenCompleted) {
                    [appd playPuzzleCompleteSoundEffect];
                }
                [self handlePuzzleCompletion:nil];
                vc.homeArrowWhite.hidden = YES;
                if ([appd packHasBeenCompleted]){
                    vc.nextArrow.hidden = YES;
                }
                else {
                    vc.nextArrow.hidden = NO;
                }
                vc.replayIconWhite.hidden = YES;
            }
            else if (infoScreen){
                vc.homeArrowWhite.hidden = YES;
                if ([appd packHasBeenCompleted]){
                    vc.nextArrow.hidden = YES;
                }
                else {
                    vc.nextArrow.hidden = NO;
                }
                vc.puzzleCompleteLabel.hidden = YES;
                vc.puzzleCompleteMessage.hidden = YES;
                puzzleHasBeenCompleted = NO;
                puzzleHasBeenCompletedCelebration = NO;
                vc.nextButton.hidden = YES;
                vc.replayIconWhite.hidden = YES;
                vc.backButton.hidden = YES;
            }
            else {
                vc.puzzleCompleteLabel.hidden = YES;
                vc.puzzleCompleteMessage.hidden = YES;
                puzzleHasBeenCompleted = NO;
                puzzleHasBeenCompletedCelebration = NO;
                vc.nextButton.hidden = YES;
                vc.nextArrow.hidden = YES;
                vc.homeArrowWhite.hidden = YES;
                vc.replayIconWhite.hidden = YES;
                vc.backButton.hidden = YES;
            }
        }
    }
    else {
        // Tutorial instruction puzzle
        DLog("ERROR Unknown puzzleCompletionCondition %d", puzzleCompletionCondition);
    }
    return puzzleCompleted;
}

- (BOOL)checkIfAllJewelsAreEnergized {
    Tile *myTile;
    NSEnumerator *tileEnum = [tiles objectEnumerator];
    if (puzzleCompletionCondition == ALL_JEWELS_ENERGIZED || puzzleCompletionCondition == INFO_SCREEN){
        // Handle gameplay scenario in which all Jewels must be energized to clear a puzzle
        BOOL completed = YES;
        int numberOfJewels = 0;
        while (myTile = [tileEnum nextObject]) {
            if (myTile) {
                if (myTile->tileShape == JEWEL){
                    numberOfJewels++;
                }
                if (myTile->tileShape==JEWEL && !myTile->energized) {
                    completed = NO;
                    break;
                }
            }
        }
        if (completed && numberOfJewels > 0) {
            return YES;
        }
        else{
            return NO;
        }
    }
    else {
        return NO;
    }
}

- (void)handlePuzzleCompletion:(NSString *)message {
    puzzleHasBeenCompleted = YES;
    tileForRotation = nil;
    [self.vc clearPromptUserAboutHintButtonTimer];
    [self startPuzzleCompleteCelebration];
    
    // If this is the Daily Puzzle then make note that it is solved
    if (rc.appCurrentGamePackType == PACKTYPE_DAILY){
        unsigned int localDaysSinceReferenceDate = [appd getLocalDaysSinceReferenceDate];
        [appd setUnsignedIntInDefaults:localDaysSinceReferenceDate forKey:@"dailyPuzzleCompletionDay"];
    }
    
    // Update scores and solved puzzles
    if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
        NSMutableDictionary *jewelCountDictionary = [appd queryPuzzleJewelCountByColor:[appd fetchCurrentPuzzleNumberForPack:[appd fetchCurrentPackNumber]]];
        
        // Puzzle solved so update all scores and timeSegment values
        long endTime = [[NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970]] longValue];
        int currentPackNumber = [appd fetchCurrentPackNumber];
        int currentPuzzleNumber = [appd fetchCurrentPuzzleNumber];
        if ([appd puzzleSolutionStatus:currentPackNumber
                          puzzleNumber:currentPuzzleNumber] == -1){
            
            [appd updatePuzzleScoresArray:currentPackNumber
                             puzzleNumber:currentPuzzleNumber
                           numberOfJewels:jewelCountDictionary
                                startTime:-1        // Do not change startTime
                                  endTime:endTime
                                   solved:YES];
            
            if (ENABLE_GAMECENTER == YES){
                int totalPuzzlesSolved = [appd countPuzzlesSolved];
                [appd.totalPuzzlesLeaderboard submitScore:totalPuzzlesSolved
                                                  context:0
                                                   player:[GKLocalPlayer localPlayer]
                                        completionHandler:
                 ^(NSError *error) {
                    if (!error){
                        DLog("[appd.totalPuzzlesLeaderboard submitScore] %d puzzles success", totalPuzzlesSolved);
                    } else {
                        DLog("[appd.totalPuzzlesLeaderboard submitScore] %d puzzles failed", totalPuzzlesSolved);
                    }
                }];
                
                int totalJewelsCollected = [appd countTotalJewelsCollected];
                [appd.totalJewelsLeaderboard submitScore:totalJewelsCollected
                                                 context:0
                                                  player:[GKLocalPlayer localPlayer]
                                       completionHandler:
                 ^(NSError *error) {
                    if (!error){
                        DLog("[appd.totalJewelsLeaderboard submitScore] %d jewels success", totalJewelsCollected);
                    } else {
                        DLog("[appd.totalJewelsLeaderboard submitScore] %d jewels failed", totalJewelsCollected);
                    }
                }];
            }

            if (ENABLE_GA == YES){
                [FIRAnalytics logEventWithName:@"puzzleSolved"
                                    parameters:@{
                    @"packNumber": @(currentPackNumber),
                    @"puzzleNumber":@(currentPuzzleNumber)
                }];
            }
        }
        
        long solutionTime = [appd calculateSolutionTime:currentPackNumber puzzleNumber:[appd fetchCurrentPuzzleNumber]];
        DLog("solutionTime = %ld", solutionTime);
        vc.puzzleCompleteLabel.text = [NSString stringWithFormat:@"Solved in %02d:%02d", (int)solutionTime/60, (int)solutionTime%60];

    }
    else if (rc.appCurrentGamePackType == PACKTYPE_DAILY){
//        int jewelCount = [appd queryPuzzleJewelCountFromDictionary:[appd fetchDailyPuzzle:[appd fetchDailyPuzzleNumber]]];
        NSMutableDictionary *jewelCountDictionary = [appd queryPuzzleJewelCountByColor:[appd fetchCurrentPuzzleNumberForPack:[appd fetchCurrentPackNumber]]];

        long endTime = [[NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970]] longValue];
        int currentPackNumber = -1;
        int currentPuzzleNumber = [appd fetchDailyPuzzleNumber];
        if ([appd puzzleSolutionStatus:currentPackNumber
                          puzzleNumber:currentPuzzleNumber] == -1){
            [appd updatePuzzleScoresArray:currentPackNumber
                             puzzleNumber:currentPuzzleNumber
                           numberOfJewels:jewelCountDictionary
                                startTime:-1        // Do not change startTime
                                  endTime:endTime
                                   solved:YES];
            
            if (ENABLE_GAMECENTER == YES){
                int totalPuzzlesSolved = [appd countPuzzlesSolved];
                [appd.totalPuzzlesLeaderboard submitScore:totalPuzzlesSolved
                                                  context:0
                                                   player:[GKLocalPlayer localPlayer]
                                        completionHandler:
                 ^(NSError *error) {
                    if (!error){
                        DLog("[appd.totalPuzzlesLeaderboard submitScore] %d puzzles success", totalPuzzlesSolved);
                    } else {
                        DLog("[appd.totalPuzzlesLeaderboard submitScore] %d puzzles failed", totalPuzzlesSolved);
                    }
                }];
                
                int totalJewelsCollected = [appd countTotalJewelsCollected];
                [appd.totalJewelsLeaderboard submitScore:totalJewelsCollected
                                                 context:0
                                                  player:[GKLocalPlayer localPlayer]
                                       completionHandler:
                 ^(NSError *error) {
                    if (!error){
                        DLog("[appd.totalJewelsLeaderboard submitScore] %d jewels success", totalJewelsCollected);
                    } else {
                        DLog("[appd.totalJewelsLeaderboard submitScore] %d jewels failed", totalJewelsCollected);
                    }
                }];
            }
            
            if (ENABLE_GA == YES){
                [FIRAnalytics logEventWithName:@"dailyPuzzleSolved"
                                    parameters:@{
                    @"puzzleNumber":@([appd fetchDailyPuzzleNumber])
                }];
            }

        }
        
        // Test out [appd fetchSolutionTime]
        long solutionTime = [appd calculateSolutionTime:currentPackNumber puzzleNumber:[appd fetchCurrentPuzzleNumber]];
        DLog("solutionTime = %ld", solutionTime);

        [vc buildButtonsAndLabelsForPlay];
    }
    
    // Test out SKStoreReviewController
    if (rc.appCurrentGamePackType == PACKTYPE_MAIN &&
        [appd automatedReviewRequestIsAppropriate]){
        NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
        NSString* versionString = [infoDict objectForKey:@"CFBundleShortVersionString"];
        [SKStoreReviewController requestReviewInScene:vc.view.window.windowScene];
        [appd setObjectInDefaults:versionString forKey:kCFBundleShortVersionStringHasBeenReviewed];
    }
    
}

- (void)startPuzzleCompleteCelebration {
    puzzleHasBeenCompletedCelebration = YES;
    vc.puzzleCompleteLabel.hidden = NO;
//    NSTimer *timer = [NSTimer timerWithTimeInterval:2.0 repeats:NO block:^(NSTimer *time){
//        self->puzzleHasBeenCompletedCelebration = NO;
//        [self dropAllTilesOffScreen];
//    }];
//    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)dropAllTilesOffScreen {
    Tile *thisTile;
    NSEnumerator *tileEnum = [tiles objectEnumerator];
    while (thisTile = [tileEnum nextObject]){
        [thisTile startTileMotionDrop:[self gridPositionToIntPixelPosition:thisTile->gridPosition] dropAcceleration:5.0+(CGFloat)arc4random_uniform(5) timeInFrames:60];
    }
}

//***********************************************************************
// Puzzle Editing Methods
//***********************************************************************
- (void)clearPuzzle {
    Tile *thisTile;
    NSEnumerator *tileEnum = [tiles objectEnumerator];
    while (thisTile = [tileEnum nextObject]){
        [self removeOpticsTile:thisTile array:tiles];
    }
    [self resetAllColorBeams];
}

- (BOOL)checkIfCurrentPuzzleIsEmpty {
    BOOL isEmpty = YES;
    if ([tiles count] > 0){
        isEmpty = NO;
    }
    return isEmpty;
}

//
// This is used to store partially finished puzzles
//
- (void)savePuzzleProgressToDefaults {
    NSMutableDictionary *puzzleDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
    switch (rc.appCurrentGamePackType){
        case PACKTYPE_MAIN:{
            puzzleDictionary = [self encodeCurrentPuzzleAsMutableDictionary:puzzleDictionary];
            unsigned int packNumber = [appd fetchCurrentPackNumber];
            [appd saveCurrentPuzzleToPackGameProgress:packNumber puzzle:puzzleDictionary];
            break;
        }
        case PACKTYPE_DAILY:{
            puzzleDictionary = [self encodeCurrentPuzzleAsMutableDictionary:puzzleDictionary];
            unsigned int dailyPuzzleNumber = [appd fetchDailyPuzzleNumber];
            [appd saveDailyPuzzle:dailyPuzzleNumber puzzle:puzzleDictionary];
            break;
        }
        // Else do nothing
        default:{
            break;
        }
    }

}

//***********************************************************************
// Beam Methods
//***********************************************************************
- (void)updateAllBeams {
    // Update all beams
    for (int ii=(int)BEAM_RED; ii <= (int)BEAM_BLUE; ii++) {
        beams[ii] = [[NSMutableArray alloc] initWithCapacity:1];
        [self resetAllBeams:(enum eBeamColors)ii];
    }
}

- (void)initRootBeam:(enum eBeamColors)color rootBeam:(Beam *)rootBeam {
    // Find the location and direction of the LASER tile for this color
    NSEnumerator *tileEnum = [tiles objectEnumerator];
    Tile *aTile;
    while (aTile = [tileEnum nextObject]) {
        if ((int)aTile->tileShape==(int)LASER && (int)aTile->tileColor==(int)color) {
            rootBeam = [[Beam alloc] initWithStartingTile:aTile->gridPosition
                                direction:(int)aTile->tileAngle
                                visible:YES
                                energy:1.0
                                isRoot:YES
                                color:color
                                beamLevel:0
                                startTile:aTile
                                endTile:nil];
            [self putOpticsBeam:color beam:rootBeam];
        }
    }
}

- (Beam *)fetchRootBeam:(enum eBeamColors)beamColor {
    Beam *beam = nil;
    NSEnumerator *beamEnum = [beams[beamColor] objectEnumerator];
    while (beam = [beamEnum nextObject]){
        if (beam->root == YES){
            return beam;
        }
    }
    return nil;
}

- (void)setupBeamHandlingMachinery {
    toggleShowWhenPuzzleStartsTileFlag = NO;
    
    // Load up the refraction arrays
    int prismRefractionRed [8][8] = {
        { 0, 2, 1, 1, 0, 7, 7, 6 },
        { 7, 1, 3, 2, 2, 1, 0, 0 },
        { 1, 0, 2, 4, 3, 3, 2, 1 },
        { 2, 2, 1, 3, 5, 4, 4, 3 },
        { 4, 3, 3, 2, 4, 6, 5, 5 },
        { 6, 5, 4, 4, 3, 5, 7, 6 },
        { 7, 7, 6, 5, 5, 4, 6, 0 },
        { 1, 0, 0, 7, 6, 6, 5, 7 },
    };
    for (int jj=0; jj<=ANGLE315; jj++) {
        for (int kk=0; kk<=ANGLE315; kk++) {
            prismRefractionArray[BEAM_RED][jj][kk] = prismRefractionRed[jj][kk];
        }
    }
    
    int prismRefractionGreen [8][8] = {
        { 0, 2, 0, 6, 0, 2, 0, 6 },
        { 7, 1, 3, 1, 7, 1, 3, 1 },
        { 2, 0, 2, 4, 2, 0, 2, 4 },
        { 5, 3, 1, 3, 5, 3, 1, 3 },
        { 4, 6, 4, 3, 4, 6, 4, 3 },
        { 3, 5, 7, 5, 3, 5, 7, 5 },
        { 6, 4, 6, 0, 6, 4, 6, 0 },
        { 1, 7, 5, 7, 1, 7, 5, 7 },
    };
    for (int jj=0; jj<=ANGLE315; jj++) {
        for (int kk=0; kk<=ANGLE315; kk++) {
            prismRefractionArray[BEAM_GREEN][jj][kk] = prismRefractionGreen[jj][kk];
        }
    }

    int prismRefractionBlue [8][8] = {
        { 0, 7, 7, 6, 0, 2, 1, 1 },
        { 2, 1, 0, 0, 7, 1, 3, 2 },
        { 3, 3, 2, 1, 1, 0, 2, 4 },
        { 5, 4, 4, 3, 2, 2, 1, 3 },
        { 4, 6, 5, 5, 4, 3, 3, 2 },
        { 3, 5, 7, 6, 6, 5, 4, 4 },
        { 5, 4, 6, 0, 7, 7, 6, 5 },
        { 6, 6, 5, 7, 1, 0, 0, 7 },
    };
    for (int jj=0; jj<=ANGLE315; jj++) {
        for (int kk=0; kk<=ANGLE315; kk++) {
            prismRefractionArray[BEAM_BLUE][jj][kk] = prismRefractionBlue[jj][kk];
        }
    }
}

//***********************************************************************
// Tile Methods
//***********************************************************************
- (BOOL)allTilesArePlaced {
    BOOL retVal = YES;
    Tile *nextTile;
    // Fetch the next tile that is part of the solution but not placed at the start of the puzzle
    NSEnumerator *tilesEnum = [tiles objectEnumerator];
    while (nextTile = [tilesEnum nextObject]) {
        if (!nextTile->fixed){
            retVal = NO;
            break;
        }
    }
    return retVal;
}

-(UIColor *)getUIColorfromStringColor:(NSString *)colorname
{
    if (colorname){
        SEL labelColor = NSSelectorFromString(colorname);
        UIColor *color = [UIColor performSelector:labelColor];
        return color;
    }
    else {
        return [UIColor colorWithWhite:1.0 alpha:1.0];
    }
}

//***********************************************************************
// Hint Methods
//***********************************************************************
// Use the information encoded in a Tile to create a hint for the player
- (void)createHintFromTile:(Tile *)tile {
    TileHint *hint;
    BOOL hintUsed = NO;
    if (tile->placedUsingHint || tile->placedManuallyMatchesHint){
        hintUsed = YES;
    }
    hint = [[TileHint alloc] initWithParameters:tile position:tile->finalGridPosition hintAngle:tile->finalTileAngle hintShape:tile->tileShape hintUsed:hintUsed];
    [hints addObject:hint];
}

// Updates the tiles and hints arrays to be consistent with a newly placed Tile
- (void)updateTileHintArray:(Tile *)tile hint:(TileHint *)hint {
    // Update tile booleans
    tile->placedManuallyMatchesHint = YES;
    tile->placedUsingHint = NO;
    tile->placed = NO;
    tile->fixed = NO;
    // Update hint booleans
    hint.hintUsed = YES;
    // Pointers for swap operation
    Tile *tempTile = nil;
    TileHint *tempHint = nil;
    // If the hint.hintTile is different from the newly positioned Tile then:
    // - Swap tile pointers in the hints
    // - Update tile finalGridPosition and finalTileAngle
    if (![hint.hintTile isEqual:tile]){
        // Swap pointers from hints to tiles
        tempTile = hint.hintTile;
        tempHint = [self findHintForTileInstance:tile];
        hint.hintTile = tile;
        tempHint.hintTile = tempTile;
        // Update finalX, finalY, finalAngle for both tiles based on the hints that now point to them
        tile->finalGridPosition = hint->hintPosition;
        tile->finalTileAngle = hint->hintAngle;
        tempTile->finalGridPosition = tempHint->hintPosition;
        tempTile->finalTileAngle = tempHint->hintAngle;
    }
}

// Checks the shape, position and angle of all placed Tiles to update the information in hints
- (void)updateHintUsedStatusInHintsArray {
    Tile *tile;
    TileHint *hint;
    NSEnumerator *tilesEnum = [tiles objectEnumerator];
    while (tile = [tilesEnum nextObject]){
        NSEnumerator *hintsEnum = [hints objectEnumerator];
        while (hint = [hintsEnum nextObject]){
            if (!hint.hintUsed){
                if ([self tileMatchesSpecificHint:tile hint:hint]) {
                    hint.hintUsed = YES;
                }
            }
        }
    }
}

// Does the Tile shape, position and angle match a particular hint?
- (BOOL)demoTileAtFinalGridPosition:(Tile *)tile {
    BOOL equal = NO;
    if (tile->gridPosition.x == tile->finalGridPosition.x && tile->gridPosition.y == tile->finalGridPosition.y){
        equal = YES;
    }
    return equal;
}

// Does the Tile shape, position and angle match a particular hint?
- (BOOL)tileMatchesSpecificHint:(Tile *)tile hint:(TileHint *)hint {
    BOOL equal = NO;
    switch(hint.hintShape){
        case MIRROR:
        case BEAMSPLITTER:
        {
            if (hint.hintShape == tile->tileShape &&
                hint.hintAngle % 4 == tile->tileAngle % 4 &&
                hint.hintPosition.x == tile->gridPosition.x &&
                hint.hintPosition.y == tile->gridPosition.y){
                equal = YES;
            }
            break;
        }
        case LASER:
        {
            if (hint.hintShape == tile->tileShape &&
                hint.hintTile->tileColor == tile->tileColor &&
                hint.hintAngle == tile->tileAngle &&
                hint.hintPosition.x == tile->gridPosition.x &&
                hint.hintPosition.y == tile->gridPosition.y){
                equal = YES;
            }
            break;
        }
        case PRISM:
        default:
        {
            if (hint.hintShape == tile->tileShape &&
                hint.hintAngle == tile->tileAngle &&
                hint.hintPosition.x == tile->gridPosition.x &&
                hint.hintPosition.y == tile->gridPosition.y){
                equal = YES;
            }
            break;
        }
    }
    return equal;
}

// Returns a reference to TileHint if the shape, position and angle of the provided Tile match any unused item in the hints array
- (TileHint *)tileMatchesAnyUnusedHint:(Tile *)tile {
    TileHint *foundHint = nil;
    TileHint *hint;
    NSEnumerator *hintsEnum = [hints objectEnumerator];
    while (hint = [hintsEnum nextObject]){
        if (!hint.hintUsed){
            if ([self tileMatchesSpecificHint:tile hint:hint]) {
                foundHint = hint;
            }
        }
    }
    return foundHint;
}

// Search the hints array for a Hint that matches a particular Tile instance
- (TileHint *)findHintForTileInstance:(Tile *)tile {
    TileHint *foundHint = nil;
    TileHint *hint;
    NSEnumerator *hintsEnum = [hints objectEnumerator];
    while (hint = [hintsEnum nextObject]){
        if (hint.hintTile == tile) {
            foundHint = hint;
        }
    }
    return foundHint;
}

// How many unused hints remain?
- (unsigned int)countHintsRemaining {
    unsigned int retVal = 0;
    TileHint *hint;
    NSEnumerator *hintsEnum = [hints objectEnumerator];
    while (hint = [hintsEnum nextObject]){
        if (!hint.hintUsed){
            retVal++;
        }
    }
    return retVal;
}

// Position an unplaced or incorrectly placed tile as a user hint.
- (BOOL)startPositionTileForHint {
    BOOL retVal = NO;
    TileHint *hint;
    NSEnumerator *hintsEnum = [hints objectEnumerator];
    Tile *tile;
    
    [self.vc clearPromptUserAboutHintButtonTimer];

    vector_int2 center, dimensions;
    center.x = 0;
    center.y = 0;
    dimensions.x = _squareTileSideLengthInPixels;
    dimensions.y = _squareTileSideLengthInPixels;

    // Fetch the next hint that is still unused
    while (hint = [hintsEnum nextObject]) {
        if (hint.hintUsed == NO){
            NSEnumerator *tilesEnum = [tiles objectEnumerator];
            while (tile = [tilesEnum nextObject]){
                if (!tile->placedUsingHint &&
                    !tile->placedManuallyMatchesHint &&
                    !tile->fixed &&
                    tile->tileShape == hint.hintShape){
                    // If the hintPosition is already occupied then move the Tile currently at hintPosition to the original Tile position
                    Tile *tileAtHintPosition = [self fetchTileAtGridPosition:hint.hintPosition];
                    // Only Lasers can stack - all other shapes require the Tile occupying the target location to move
                    if (tileAtHintPosition != nil && (tile->tileShape != LASER || tileAtHintPosition->tileShape != LASER)){
                        tileAtHintPosition->gridPosition = tile->gridPosition;
                        tileAtHintPosition->tilePositionInPixels = tile->tilePositionInPixels;
                    }

                    // Start moving the Tile to the final hintPosition
                    vector_float2 final = [self gridPositionToPixelPosition:hint.hintPosition];
                    if (ENABLE_GA == YES &&
                        (rc.appCurrentGamePackType == PACKTYPE_MAIN ||
                         rc.appCurrentGamePackType == PACKTYPE_DAILY)){
                        int currentPackNumber, currentPuzzleNumber;
                        if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
                            currentPackNumber = [appd fetchCurrentPackNumber];
                            currentPuzzleNumber = [appd fetchCurrentPuzzleNumber];
                        }
                        else {
                            currentPackNumber = -1;
                            currentPuzzleNumber = [appd fetchDailyPuzzleNumber];
                        }
                        [FIRAnalytics logEventWithName:@"hintUsed"
                                            parameters:@{
                            @"packNumber": @(currentPackNumber),
                            @"puzzleNumber":@(currentPuzzleNumber),
                            @"posX":@(hint.hintPosition.x),
                            @"posY":@(hint.hintPosition.y),
                            @"tileShape":@(tile->tileShape)
                        }];
                    }
                    tile->tileAngle = hint.hintAngle;
                    tile->placedTileAngle = hint.hintAngle;
                    tile->placedUsingHint = YES;
                    tile->placed = NO;
                    tile->fixed = NO;
                    [tile startTileMotionLinear:tile->tilePositionInPixels finalPosition:simd_make_int2((int)final.x, (int)final.y) timeInFrames:8];
                    hint.hintUsed = YES;
                    retVal = YES;
                    break;
                }
            }
        }
        if (retVal){
            break;
        }
    }
    return retVal;
}

// Complete the process of positioning a Tile based on a hint
- (void)finishPositionTileForHint:(Tile *)tile {
    tile->placedUsingHint = YES;
    tile->fixed = YES;
    [appd playSound:appd.tileCorrectlyPlacedPlayer];
    tile->placedGridPosition.x = tile->gridPosition.x;
    tile->placedGridPosition.y = tile->gridPosition.y;
    tile->placedTileAngle = tile->tileAngle;
    
    // If the Tile had been showing a TAP_TO_ROTATE guide then remove the guide
    if (tile == tileForRotation){
        tileForRotation = nil;
    }
    
    // Update the status of all TileHint objects in the array hints
    [self updateHintUsedStatusInHintsArray];
    
    // If a demo Tile is placed using a hint then set the appropriate boolean
    if ([self demoTileAtFinalGridPosition:tile] == YES){
        tile->demoTileAtFinalGridPosition = YES;
    }
    
    // Update @"numberOfMoves" value in puzzleScoresArray
    int currentPackNumber = -1;
    int currentPuzzleNumber = 0;
    if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
        currentPackNumber = [appd fetchCurrentPackNumber];
        currentPuzzleNumber = [appd fetchCurrentPuzzleNumber];
        if ([appd puzzleSolutionStatus:currentPackNumber
                          puzzleNumber:currentPuzzleNumber] == -1){
            [appd incrementNumberOfMovesInPuzzleScoresArray:currentPackNumber
                                               puzzleNumber:currentPuzzleNumber];
        }
    }
    else if (rc.appCurrentGamePackType == PACKTYPE_DAILY) {
        currentPackNumber = -1;
        currentPuzzleNumber = [appd fetchDailyPuzzleNumber];
        if ([appd puzzleSolutionStatus:currentPackNumber
                          puzzleNumber:currentPuzzleNumber] == -1){
            [appd incrementNumberOfMovesInPuzzleScoresArray:currentPackNumber
                                               puzzleNumber:currentPuzzleNumber];
        }
    }

    rc.numberOfMoves++;
    [self resetAllColorBeams];
    [self updateEnergizedStateForAllTiles];
    if (!puzzleHasBeenCompleted){
        if ([self queryPuzzleCompleted]){
            vc.homeArrow.hidden = NO;
            if (!infoScreen)
                [self saveNextPuzzleToDefaults];
            if ([appd packHasBeenCompleted]){
                // Pack is complete
                vc.nextButton.hidden = YES;
                vc.nextArrow.hidden = YES;
                vc.homeArrowWhite.hidden = (rc.appCurrentGamePackType == PACKTYPE_DEMO);
                vc.replayIconWhite.hidden = (rc.appCurrentGamePackType == PACKTYPE_DEMO);
                packHasBeenCompleted = YES;
                if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
                    DLog("Error: no hints in PACKTYPE_DEMO");
                }
            }
            else {
                vc.nextButton.hidden = NO;
                vc.nextArrow.hidden = NO;
                vc.homeArrowWhite.hidden = (rc.appCurrentGamePackType == PACKTYPE_DEMO);
                vc.replayIconWhite.hidden = (rc.appCurrentGamePackType == PACKTYPE_DEMO);
                packHasBeenCompleted = NO;
            }
        }
        else {
//            [self savePuzzleProgressToDefaults];
        }
    }
}

//***********************************************************************
// Tile and Beam handling methods
//***********************************************************************
- (void)resetAllBeams:(enum eBeamColors)color {
	// Go through every tile
	NSEnumerator *tileEnum = [tiles objectEnumerator];
	Tile *aTile;
	while (aTile = [tileEnum nextObject]) {
		// For each tile remove all beams from the incomingBeams array
		[aTile->incomingBeams[color] removeAllObjects];
	}
	[beams[color] removeAllObjects];
	[self initRootBeam:color   rootBeam:rootBeam[(int)color]];
}

- (void)updateEnergizedStateForAllTiles {
    NSEnumerator *tilesEnum = [tiles objectEnumerator];
    Tile *myTile;
    while (myTile = [tilesEnum nextObject]) {
        [myTile updateTileEnergizedState];
    }
}

- (int)signOfNonzeroInteger:(int)num {
    if (num == 0)
        return 0;
    else if (num > 0)
        return 1;
    else
        return -1;
}

- (BOOL)beamRenderIsMulticolor:(BeamTextureRenderData *)bgd {
    BOOL retVal = NO;
    if (((bgd->beamCountsByColor[COLOR_RED] > 0) && ( bgd->beamCountsByColor[COLOR_GREEN] > 0)) ||
        ((bgd->beamCountsByColor[COLOR_RED] > 0) && ( bgd->beamCountsByColor[COLOR_BLUE] > 0)) ||
        ((bgd->beamCountsByColor[COLOR_GREEN] > 0) && ( bgd->beamCountsByColor[COLOR_BLUE] > 0))
        ){
        retVal = YES;
    }
    return retVal;
}

- (NSMutableArray *)gridPositionsCrossedByRenderedBeam:(BeamTextureRenderData *)bgd
                                  gridPositionsArray:(NSMutableArray *)gridPositionsArray {
    // Calculate the length of a beam and generate dx, dy
    int dx = 0, dy = 0;
    // Vertical
    if (bgd->textureStartGridPosition.x == bgd->textureEndGridPosition.x){
        dy = [self signOfNonzeroInteger:(bgd->textureEndGridPosition.y - bgd->textureStartGridPosition.y)];
        for (int y=bgd->textureStartGridPosition.y; y!=bgd->textureEndGridPosition.y; y=y+dy){
            if (y!=bgd->textureStartGridPosition.y){
                NSMutableDictionary *gridPosition = [[NSMutableDictionary alloc]initWithCapacity:1];
                [gridPosition setObject:[NSNumber numberWithInt:bgd->textureStartGridPosition.x] forKey:@"x"];
                [gridPosition setObject:[NSNumber numberWithInt:y] forKey:@"y"];
                [gridPosition setObject:[NSNumber numberWithInt:(int)(bgd->angle)] forKey:@"beamAngle"];
                [gridPositionsArray addObject:gridPosition];
            }
        }
    }
    // Horizontal
    else if (bgd->textureStartGridPosition.y == bgd->textureEndGridPosition.y){
        dx = [self signOfNonzeroInteger:(bgd->textureEndGridPosition.x - bgd->textureStartGridPosition.x)];
        for (int x=bgd->textureStartGridPosition.x; x!=bgd->textureEndGridPosition.x; x=x+dx){
            if (x!=bgd->textureStartGridPosition.x){
                NSMutableDictionary *gridPosition = [[NSMutableDictionary alloc]initWithCapacity:1];
                [gridPosition setObject:[NSNumber numberWithInt:x] forKey:@"x"];
                [gridPosition setObject:[NSNumber numberWithInt:bgd->textureStartGridPosition.y] forKey:@"y"];
                [gridPosition setObject:[NSNumber numberWithInt:(int)(bgd->angle)] forKey:@"beamAngle"];
                [gridPositionsArray addObject:gridPosition];
            }
        }
    }
    // +/- 45 degree angle
    else {
        dx = [self signOfNonzeroInteger:(bgd->textureEndGridPosition.x - bgd->textureStartGridPosition.x)];
        dy = [self signOfNonzeroInteger:(bgd->textureEndGridPosition.y - bgd->textureStartGridPosition.y)];
        int y=bgd->textureStartGridPosition.y;
        for (int x=bgd->textureStartGridPosition.x; x!=bgd->textureEndGridPosition.x; x=x+dx){
            if (x!=bgd->textureStartGridPosition.x){
                NSMutableDictionary *gridPosition = [[NSMutableDictionary alloc]initWithCapacity:1];
                [gridPosition setObject:[NSNumber numberWithInt:x] forKey:@"x"];
                [gridPosition setObject:[NSNumber numberWithInt:y] forKey:@"y"];
                [gridPosition setObject:[NSNumber numberWithInt:(int)(bgd->angle)] forKey:@"beamAngle"];
                [gridPositionsArray addObject:gridPosition];
            }
            y=y+dy;
        }
    }
    return gridPositionsArray;
}

- (BOOL)searchForTileAtSameGridPosition:(Tile *)tile array:(NSMutableArray *)tileArray {
    BOOL tileFound = NO;
    NSEnumerator *tilesEnum = [tileArray objectEnumerator];
    Tile *myTile;
    while (myTile = [tilesEnum nextObject]) {
        if (myTile->gridPosition.x == tile->gridPosition.x &&
            myTile->gridPosition.y == tile->gridPosition.y &&
            !(myTile->tileShape == LASER)){
            tileFound = YES;
            break;
        }
    }
    return tileFound;
}

- (Tile *)fetchTileAtGridPosition:(vector_int2)g {
    Tile *tileFound = nil;
    NSEnumerator *tilesEnum = [tiles objectEnumerator];
    Tile *nextTile;
    while (nextTile = [tilesEnum nextObject]) {
        if (nextTile->gridPosition.x == g.x &&
            nextTile->gridPosition.y == g.y &&
            (nextTile->tileShape == LASER ||
             nextTile->tileShape == MIRROR ||
             nextTile->tileShape == BEAMSPLITTER ||
             nextTile->tileShape == PRISM)){
            tileFound = nextTile;
            break;
        }
    }
    return tileFound;
}

- (void)putOpticsTile:(Tile *)tile array:(NSMutableArray *)array {
	[array addObject:tile];
}

- (void)removeOpticsTile:(Tile *)tile array:(NSMutableArray *)array {
	[array removeObject:tile];
}

- (Tile *)getOpticsTile:(int)index {
    if ([tiles count] > index){
        return [tiles objectAtIndex:index];
    }
    else {
        return nil;
    }
}

- (int)getOpticsTileCount {
	return (int)[tiles count];
}

- (void)putOpticsBeam:(enum eBeamColors)color beam:(Beam *)beam {
	[beams[(int)color] addObject:beam];
}

- (Beam *)getOpticsBeam:(NSMutableArray *)beams index:(int)index {
    if ([beams count] > index){
        return [beams objectAtIndex:index];
    }
    else {
        return nil;
    }
}

- (int)getOpticsBeamCount:(NSMutableArray *)beams {
	return (int)[beams count];
}

- (BOOL)touchGridLocationIsVacant {
    // Go through every tile
    NSEnumerator *tileEnum = [tiles objectEnumerator];
    Tile *aTile = nil;
    BOOL vacant = YES;
    while (aTile = [tileEnum nextObject]) {
        if (aTile != tileCurrentlyBeingEdited)
            if (aTile->gridPosition.x == gridTouchGestures.gridPosition.x &&
                aTile->gridPosition.y == gridTouchGestures.gridPosition.y) {
                vacant = NO;
                break;
            }
    }
    return vacant;
}

- (Tile *)tileOccupiesGridPosition:(vector_int2)gridPosition {
    // Go through every tile
    NSEnumerator *tileEnum = [tiles objectEnumerator];
    Tile *aTile;
    while (aTile = [tileEnum nextObject]) {
        if (aTile->gridPosition.x == gridPosition.x && aTile->gridPosition.y == gridPosition.y) {
            return aTile;
        }
    }
    return nil;
}

- (enum eTileShape)tileTypeAtTouchLocation {
    // Go through every tile
    NSEnumerator *tileEnum = [tiles objectEnumerator];
    Tile *aTile = nil;
    while (aTile = [tileEnum nextObject]) {
        if (aTile != tileCurrentlyBeingEdited)
            if (aTile->gridPosition.x == gridTouchGestures.gridPosition.x &&
                aTile->gridPosition.y == gridTouchGestures.gridPosition.y) {
                break;
            }
    }
    return aTile->tileShape;
}

- (vector_int2)pixelPositionToGridPosition:(vector_int2)p {
    vector_int2 g;
    float epsilon = 0.1;
    g.x = (uint)(((p.x - _tileHorizontalOffsetInPixels)/_squareTileSideLengthInPixels) + epsilon);
    if (g.x >= masterGrid.sizeX){
        g.x = masterGrid.sizeX-1;
    }
    g.y = (uint)(((p.y - _tileVerticalOffsetInPixels)/_squareTileSideLengthInPixels) + epsilon);
    if (g.y > masterGrid.sizeY){
        g.y = masterGrid.sizeY+1;
    }
    return g;
}

- (vector_int2)pixelPositionToGridPosition2:(vector_float2)p {
    vector_int2 g;
    float epsilon = 0.1;
    g.x = (uint)(((p.x - _tileHorizontalOffsetInPixels)/_squareTileSideLengthInPixels) + epsilon);
    if (g.x >= gameGrid.sizeX){
        g.x = gameGrid.sizeX-1;
    }
    g.y = (uint)(((p.y - _tileVerticalOffsetInPixels)/_squareTileSideLengthInPixels) + epsilon);
    if (g.y > gameGrid.sizeY){
        g.y = gameGrid.sizeY+1;
    }
    return g;
}

- (vector_float2)gridPositionToPixelPosition:(vector_int2)g {
    vector_float2 p;
    p.x = (g.x * _squareTileSideLengthInPixels) + _tileHorizontalOffsetInPixels;
    p.y = (g.y * _squareTileSideLengthInPixels) + _tileVerticalOffsetInPixels;
    return p;
}

- (vector_int2)gridPositionToIntPixelPosition:(vector_int2)g {
    vector_int2 p;
    p.x = (g.x * _squareTileSideLengthInPixels) + _tileHorizontalOffsetInPixels;
    p.y = (g.y * _squareTileSideLengthInPixels) + _tileVerticalOffsetInPixels;
    return p;
}

- (void)checkForTileTouched {
    if (tileCurrentlyBeingEdited) {
        if (![self tileOccupiesGridPosition:gridTouchGestures.gridPosition] ||
            [self tileOccupiesGridPosition:gridTouchGestures.gridPosition]->tileShape == LASER) {
            if (tileCurrentlyBeingEdited->tileColor==COLOR_RED ||
                tileCurrentlyBeingEdited->tileColor==COLOR_GREEN ||
                tileCurrentlyBeingEdited->tileColor==COLOR_BLUE){
                [self resetAllBeams:(enum eBeamColors)tileCurrentlyBeingEdited->tileColor];
            }
        }
    }
    else {
        vector_int2 tileGridPosition;
        Tile *myTile;
        NSEnumerator *tileEnum = [tiles objectEnumerator];
        while (myTile = [tileEnum nextObject]) {
            tileGridPosition = myTile->gridPosition;
            if (tileGridPosition.x==gridTouchGestures.gridPosition.x && tileGridPosition.y==gridTouchGestures.gridPosition.y ) {
                if (gridTouchGestures.active && ((!myTile->placedUsingHint && !myTile->placedManuallyMatchesHint && !myTile->fixed) || [appd editModeIsEnabled])) {
                    tileCurrentlyBeingEdited = myTile;
                    break;
                }
                else {
                    if (tileCurrentlyBeingEdited) {
                        [tileCurrentlyBeingEdited snapTileToPreviousGridPosition];
                        tileCurrentlyBeingEdited = nil;
                    }
                }
            }
            else {
                if (tileCurrentlyBeingEdited) {
                    [tileCurrentlyBeingEdited snapTileToPreviousGridPosition];
                    tileCurrentlyBeingEdited = nil;
                }
            }
        }
    }
}

- (BOOL)touchesEndedInNewGridLocation {
    BOOL retVal = NO;
    if (gridTouchGestures.initialGridPosition.x != gridTouchGestures.gridPosition.x ||
        gridTouchGestures.initialGridPosition.y != gridTouchGestures.gridPosition.y) {
        retVal = YES;
    }
    return retVal;
}

- (void)handleTileRotation {
    if (tileCurrentlyBeingEdited != nil) {
        if (![self touchesEndedInNewGridLocation]) {
            if (tileCurrentlyBeingEdited->tileShape == JEWEL || tileCurrentlyBeingEdited->tileShape == RECTANGLE) {
                [tileCurrentlyBeingEdited changeTileColor];
            }
            else {
                // Only toggleShowWhenPuzzleStartsTileFlag if in Edit Mode
                if ([appd editModeIsEnabled]) {
                    if (toggleShowWhenPuzzleStartsTileFlag) {
                        [tileCurrentlyBeingEdited rotateTile];
                        toggleShowWhenPuzzleStartsTileFlag = !toggleShowWhenPuzzleStartsTileFlag;
                    }
                    else {
                        [tileCurrentlyBeingEdited rotateTile];
                        toggleShowWhenPuzzleStartsTileFlag = !toggleShowWhenPuzzleStartsTileFlag;
                    }
                }
                else {
                    [tileCurrentlyBeingEdited rotateTile];
                }
            }
        }
    }
}

- (void)resetAllColorBeams {
	// Reset and sync all of the beams
	int ii;
	for (ii=0; ii<3; ii++) {
		[self resetAllBeams:(enum eBeamColors)ii];
	}
    [vc clearPromptUserAboutHintButtonTimer];
}

- (BOOL)checkIfTouchInEditorRegion {
    BOOL status = NO;
    vector_float2 pixelPosition = [self gridPositionToPixelPosition:gridTouchGestures.gridPosition];
    CGFloat x, y;
    x = pixelPosition.x;
    y = pixelPosition.y;
    if (x >= gridTouchGestures.minEditorBoundary.x &&
        x < gridTouchGestures.maxEditorBoundary.x &&
        y >= gridTouchGestures.minEditorBoundary.y &&
        y < gridTouchGestures.maxEditorBoundary.y) {
        status = YES;
    }
    return status;
}

- (BOOL)checkIfTouchInPuzzleRegion {
    BOOL status = NO;
    vector_float2 pixelPosition = [self gridPositionToPixelPosition:gridTouchGestures.gridPosition];
    CGFloat x, y;
    x = pixelPosition.x;
    y = pixelPosition.y;
    if (x >= gridTouchGestures.minPuzzleBoundary.x &&
        x < gridTouchGestures.maxPuzzleBoundary.x &&
        y >= gridTouchGestures.minPuzzleBoundary.y &&
        y < gridTouchGestures.maxPuzzleBoundary.y) {
        status = YES;
    }
    return status;
}

- (BOOL)checkIfTileInUnplacedTileRegion:(Tile *)tile {
    BOOL status = NO;
    CGFloat x, y;
    x = tile->gridPosition.x;
    y = tile->gridPosition.y;
    if (x >= gridTouchGestures.minUnplacedTilesBoundary.x &&
        x < gridTouchGestures.maxUnplacedTilesBoundary.x &&
        y >= gridTouchGestures.minUnplacedTilesBoundary.y &&
        y < gridTouchGestures.maxUnplacedTilesBoundary.y) {
        status = YES;
    }
    return status;
}

- (BOOL)checkIfTouchInUnplacedTileRegion {
    BOOL status = NO;
    vector_float2 pixelPosition = [self gridPositionToPixelPosition:gridTouchGestures.gridPosition];
    CGFloat x, y;
    x = pixelPosition.x;
    y = pixelPosition.y;
    if (![appd editModeIsEnabled]){
        if (x >= gridTouchGestures.minUnplacedTilesBoundary.x &&
            x < gridTouchGestures.maxUnplacedTilesBoundary.x &&
            y >= gridTouchGestures.minUnplacedTilesBoundary.y &&
            y < gridTouchGestures.maxUnplacedTilesBoundary.y) {
            status = YES;
        }
    }
    return status;
}

- (BOOL)checkIfTouchInControlRegion {
    BOOL status = NO;
    vector_float2 pixelPosition = [self gridPositionToPixelPosition:gridTouchGestures.gridPosition];
    CGFloat x, y;
    x = pixelPosition.x;
    y = pixelPosition.y;
    if ([appd editModeIsEnabled]){
        if (x >= gridTouchGestures.minControlsBoundary.x &&
            x < gridTouchGestures.maxControlsBoundary.x &&
            y >= gridTouchGestures.minControlsBoundary.y &&
            y < gridTouchGestures.maxControlsBoundary.y) {
            status = YES;
        }
    }
    return status;
}

- (BOOL)checkIfPremovePositionInControlRegion:(Tile *)tile {
    BOOL status = NO;
    if (tile->gridPosition.x >= 0 && tile->gridPosition.x <= gameGrid.sizeX && tile->gridPosition.y >= gameGrid.sizeY) {
        status = YES;
    }
    return status;
}

- (void)touchesBegan {
    if ([self checkIfTouchInPuzzleRegion]) {
        DLog("Puzzle Grid Region");
        gridTouchGestures.active = YES;
        gridTouchGestures.ended = NO;
        gridTouchGestures.moved = NO;
        [self checkForTileTouched];
        gridTouchGestures.initialGridPosition = gridTouchGestures.gridPosition;
    }
    else if ([self checkIfTouchInUnplacedTileRegion]){
        DLog("Unplaced Tile Region");
        gridTouchGestures.active = YES;
        gridTouchGestures.ended = NO;
        gridTouchGestures.moved = NO;
        [self checkForTileTouched];
        gridTouchGestures.initialGridPosition = gridTouchGestures.gridPosition;
    }
    else if([self checkIfTouchInEditorRegion] && [appd editModeIsEnabled]){
        DLog("Editor Tile Region");
        gridTouchGestures.active = YES;
        gridTouchGestures.ended = NO;
        gridTouchGestures.moved = NO;
        [self checkForTileTouched];
        gridTouchGestures.initialGridPosition = gridTouchGestures.gridPosition;
    }
    else if([self checkIfTouchInControlRegion] && [appd editModeIsEnabled]){
        DLog("Control Tile Region");
        [gameControls touchesBegan:gridTouchGestures.pixelPosition];
    }
    else {
        DLog("Touch ignored");
    }
}

- (void)touchesMoved {
    // Touch in grid region?
    if (([self checkIfTouchInPuzzleRegion] && ![appd editModeIsEnabled]) ||
        ([self checkIfTouchInUnplacedTileRegion] && ![appd editModeIsEnabled]) ||
        ([self checkIfTouchInEditorRegion] && [appd editModeIsEnabled]) ||
        ([self checkIfTouchInControlRegion] && [appd editModeIsEnabled])) {
        gridTouchGestures.active = YES;
        gridTouchGestures.ended = NO;
        gridTouchGestures.moved = YES;
        if (tileCurrentlyBeingEdited && [self touchGridLocationIsVacant]) {
            if (tileCurrentlyBeingEdited->demoTileAtFinalGridPosition == NO){
                [tileCurrentlyBeingEdited snapTileToNewGridPosition];
                for (int ii=0; ii<3; ii++) {
                    if (gridTouchGestures.gridPosition.x != gridTouchGestures.previousGridPosition.x ||
                        gridTouchGestures.gridPosition.y != gridTouchGestures.previousGridPosition.y) {
                        [self resetAllBeams:(enum eBeamColors)ii];
                    }
                }
            }
        }
    }
}

- (void)saveTouchEvent:(vector_int2)p {
    gridTouchGestures.pixelPosition = p;
    gridTouchGestures.previousGridPosition = gridTouchGestures.gridPosition;
    gridTouchGestures.gridPosition = [self pixelPositionToGridPosition:gridTouchGestures.pixelPosition];
    // Play a click if a Tile is being edited AND the new grid position of the Tile is different than the old grid position of the Tile
    if (tileCurrentlyBeingEdited) {
        if (gridTouchGestures.gridPosition.x != gridTouchGestures.previousGridPosition.x ||
            gridTouchGestures.gridPosition.y != gridTouchGestures.previousGridPosition.y) {
            BMDAppDelegate *appd = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
            [appd playSound:appd.tapPlayer];
        }
    }
}

- (void)handleTileLongPress:(vector_int2)position {
    vector_int2 gridPosition = [self pixelPositionToGridPosition:position];
    [appd playSound:appd.tapPlayer];
    if ((tileCurrentlyBeingEdited = [self tileOccupiesGridPosition:gridPosition]) != nil){
        DLog("Tile Detected at x=%d, y=%d", gridPosition.x, gridPosition.y);
        if (tileCurrentlyBeingEdited->fixed){
            tileCurrentlyBeingEdited->fixed = NO;
        }
        else {
            tileCurrentlyBeingEdited->fixed = YES;
        }
        tileCurrentlyBeingEdited->finalGridPosition.x = tileCurrentlyBeingEdited->gridPosition.x;
        tileCurrentlyBeingEdited->finalGridPosition.y = tileCurrentlyBeingEdited->gridPosition.y;
//        [self handleTileLongPress];
        tileCurrentlyBeingEdited = nil;
    }
}

- (void)handleTapGesture:(vector_int2)position {
    DLog("Tap Gesture Detected at x=%d, y=%d", position.x, position.y);
    vector_int2 gridPosition = [self pixelPositionToGridPosition:position];
    if ((tileCurrentlyBeingEdited = [self tileOccupiesGridPosition:gridPosition]) != nil){
        DLog("Tile Detected at x=%d, y=%d", gridPosition.x, gridPosition.y);
        [self handleTileTap];
        tileCurrentlyBeingEdited = nil;
    }
}

- (void)touchesEnded {
    gridTouchGestures.active = NO;
    gridTouchGestures.ended = YES;
    gridTouchGestures.moved = NO;
    TileHint *hint;
    // Touch in a grid region where it can be placed?
    if (([self checkIfTouchInPuzzleRegion] && ![appd editModeIsEnabled]) ||
        ([self checkIfTouchInUnplacedTileRegion] && ![appd editModeIsEnabled]) ||
        ([self checkIfTouchInEditorRegion] && [appd editModeIsEnabled]) ||
        ([self checkIfTouchInControlRegion] && [appd editModeIsEnabled])) {
        // Currently manipulating a Tile?
        if (tileCurrentlyBeingEdited) {
            // touchesEnded in a new grid location (distinguishes Tile movement from Tile tap)
            //           AND
            // NOT a demoTile locked into its final grid position awaiting correct rotation
            //   (i.e. either NOT a demoTile OR is a demoTile but not yet verified as being at final grid position)
            if ([self touchesEndedInNewGridLocation] && tileCurrentlyBeingEdited->demoTileAtFinalGridPosition == NO) {
                // The touchEnded grid location is not already occupied by another Tile
                if ([self touchGridLocationIsVacant]) {
                    // If NOT a demoTile then check to see if the new position/rotation matches an unused TileHint
                    // If a matching TileHint is found then lock the Tile in place and indicate that it is locked
                    //          AND
                    // Remove the corresponding TileHint from the Array of unused TileHints
                    if ((hint = [self tileMatchesAnyUnusedHint:tileCurrentlyBeingEdited]) != nil
                        && tileCurrentlyBeingEdited->demoTile == NO) {
                        [appd playSound:appd.tileCorrectlyPlacedPlayer];
                        if (rc.appCurrentGamePackType != PACKTYPE_EDITOR ||
                            (![appd editModeIsEnabled] && rc.appCurrentGamePackType == PACKTYPE_EDITOR)){
                            [self updateTileHintArray:tileCurrentlyBeingEdited hint:hint];
                        }
                        tileCurrentlyBeingEdited->placedGridPosition.x = tileCurrentlyBeingEdited->gridPosition.x;
                        tileCurrentlyBeingEdited->placedGridPosition.y = tileCurrentlyBeingEdited->gridPosition.y;
                        tileCurrentlyBeingEdited->placedTileAngle = tileCurrentlyBeingEdited->tileAngle;
                    }
                    // If a demoTile
                    //      OR
                    // NOT a demoTile but with no matching TileHint
                    else {
                        // Play a clink sound to indicate motion to a new grid position
                        if (!appd->laserSoundCurrentlyPlaying){
                            [appd playLaserSound];
                        }
//                        [appd playSound:appd.clinkPlayer];
                        // Are we in editMode?
                        // tile.placed is only set to YES during gamePlay mode so disable placed flag if in editMode
                        if ([appd editModeIsEnabled]){
                            tileCurrentlyBeingEdited->placed = NO;
                            tileCurrentlyBeingEdited->finalGridPosition = tileCurrentlyBeingEdited->gridPosition;
                            tileCurrentlyBeingEdited->placedGridPosition = tileCurrentlyBeingEdited->gridPosition;
                            [tileCurrentlyBeingEdited snapTileToNewGridPosition:tileCurrentlyBeingEdited->finalGridPosition];
                        }
                        // NOT in editMode
                        else {
                            // NOT in editMode
                            // NOT a demoTile
                            if (tileCurrentlyBeingEdited->demoTile == NO) {
                                tileCurrentlyBeingEdited->placed = YES;
                                tileCurrentlyBeingEdited->fixed = NO;
                                [tileCurrentlyBeingEdited snapTileToNewGridPosition:tileCurrentlyBeingEdited->gridPosition];
                            }
                            // NOT in editMode
                            // IS a demoTile
                            else {
                                // NOT in editMode
                                // IS a demoTile
                                // IS in the grid position corresponding to demoTileAtFinalGridPosition
                                if ([self demoTileAtFinalGridPosition:tileCurrentlyBeingEdited] == YES){
                                    tileCurrentlyBeingEdited->demoTileAtFinalGridPosition = YES;
                                    tileCurrentlyBeingEdited->placed = NO;
                                    tileCurrentlyBeingEdited->fixed = NO;
                                    [tileCurrentlyBeingEdited snapTileToNewGridPosition:tileCurrentlyBeingEdited->finalGridPosition];
                                }
                                // NOT in editMode
                                // IS a demoTile
                                // NOT in the grid position corresponding to demoTileAtFinalGridPosition
                                else {
                                    [tileCurrentlyBeingEdited snapTileToNewGridPosition:tileCurrentlyBeingEdited->gridPosition];
                                }
                            }
                        }
                        
                        // NO TileHint was used in either of the four preceding cases so clear corresponding flags
                        tileCurrentlyBeingEdited->placedManuallyMatchesHint = NO;
                        tileCurrentlyBeingEdited->placedUsingHint = NO;
                    }
                    // The tileCurrentlyBeingEdited has moved to a new grid location so update the Tile internal data
//                    [tileCurrentlyBeingEdited snapTileToNewGridPosition];
                    // A new Tile position requires that all Beams be recalculated
                    [self resetAllColorBeams];
                    
                    // Update @"numberOfMoves" value in puzzleScoresArray
                    int currentPackNumber = -1;
                    int currentPuzzleNumber = 0;
                    if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
                        currentPackNumber = [appd fetchCurrentPackNumber];
                        currentPuzzleNumber = [appd fetchCurrentPuzzleNumber];
                        if ([appd puzzleSolutionStatus:currentPackNumber
                                          puzzleNumber:currentPuzzleNumber] == -1){
                            [appd incrementNumberOfMovesInPuzzleScoresArray:currentPackNumber
                                                               puzzleNumber:currentPuzzleNumber];
                        }
                    }
                    else if (rc.appCurrentGamePackType == PACKTYPE_DAILY) {
                        currentPackNumber = -1;
                        currentPuzzleNumber = [appd fetchDailyPuzzleNumber];
                        if ([appd puzzleSolutionStatus:currentPackNumber
                                          puzzleNumber:currentPuzzleNumber] == -1){
                            [appd incrementNumberOfMovesInPuzzleScoresArray:currentPackNumber
                                                               puzzleNumber:currentPuzzleNumber];
                        }
                    }

                    // A new Beam configuration requires that Energized states be recalculated for all Tiles
                    [self updateEnergizedStateForAllTiles];
                    // Check for Puzzle completion
                    if (!puzzleHasBeenCompleted){
                        if ([self queryPuzzleCompleted]){
                            vc.homeArrow.hidden = NO;
                            if (!infoScreen)
                                [self saveNextPuzzleToDefaults];
                            if ([appd packHasBeenCompleted]){
                                // Pack is complete
                                vc.nextButton.hidden = YES;
                                vc.nextArrow.hidden = YES;
                                vc.homeArrowWhite.hidden = (rc.appCurrentGamePackType == PACKTYPE_DEMO);
                                vc.replayIconWhite.hidden = (rc.appCurrentGamePackType == PACKTYPE_DEMO);
                                packHasBeenCompleted = YES;
                            }
                            else {
                                vc.nextButton.hidden = NO;
                                vc.nextArrow.hidden = NO;
                                vc.homeArrowWhite.hidden = (rc.appCurrentGamePackType == PACKTYPE_DEMO);
                                vc.replayIconWhite.hidden = (rc.appCurrentGamePackType == PACKTYPE_DEMO);
                                packHasBeenCompleted = NO;
                            }
                        }
                        else {
//                            [self savePuzzleProgressToDefaults];
                        }
                    }
                    // Increment numberOfMoves
                    rc.numberOfMoves++;
                }
                // The touchEnded grid location IS already occupied by another Tile
                //
                // Check if the Tile you are moving is a Laser
                //       AND
                // That the Tile occupying the new grid location is also a Laser
                //
                // LASER stacking is specifically permitted!
                else if (tileCurrentlyBeingEdited->tileShape == LASER && [self tileTypeAtTouchLocation] == LASER){
                    if ((hint = [self tileMatchesAnyUnusedHint:tileCurrentlyBeingEdited]) != nil) {
                        [appd playSound:appd.tileCorrectlyPlacedPlayer];
                        if (rc.appCurrentGamePackType != PACKTYPE_EDITOR ||
                            (![appd editModeIsEnabled] && rc.appCurrentGamePackType == PACKTYPE_EDITOR)){
                            [self updateTileHintArray:tileCurrentlyBeingEdited hint:hint];
                        }
                        tileCurrentlyBeingEdited->placedGridPosition.x = tileCurrentlyBeingEdited->gridPosition.x;
                        tileCurrentlyBeingEdited->placedGridPosition.y = tileCurrentlyBeingEdited->gridPosition.y;
                        tileCurrentlyBeingEdited->placedTileAngle = tileCurrentlyBeingEdited->tileAngle;
                    }
                    else {
                        // If moved play a clink
                        [appd playSound:appd.clinkPlayer];
                        tileCurrentlyBeingEdited->placedManuallyMatchesHint = NO;
                        tileCurrentlyBeingEdited->placedUsingHint = NO;
                        // tile.placed is only set to YES during gamePlay
                        if ([appd editModeIsEnabled]){
                            tileCurrentlyBeingEdited->placed = NO;
                            tileCurrentlyBeingEdited->fixed = NO;
                            tileCurrentlyBeingEdited->finalGridPosition = tileCurrentlyBeingEdited->gridPosition;
                            tileCurrentlyBeingEdited->placedGridPosition = tileCurrentlyBeingEdited->gridPosition;
                        }
                        else {
                            if (tileCurrentlyBeingEdited->demoTile == NO){
                                tileCurrentlyBeingEdited->placed = YES;
                            }
                            tileCurrentlyBeingEdited->fixed = NO;
                        }
                    }
                    // The tileCurrentlyBeingEdited has moved to a new grid location so update the Tile internal data
                    [tileCurrentlyBeingEdited snapTileToNewGridPosition];
                    // A new Tile position requires that all Beams be recalculated
                    [self resetAllColorBeams];
                    
                    // Update @"numberOfMoves" value in puzzleScoresArray
                    int currentPackNumber = -1;
                    int currentPuzzleNumber = 0;
                    if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
                        currentPackNumber = [appd fetchCurrentPackNumber];
                        currentPuzzleNumber = [appd fetchCurrentPuzzleNumber];
                        if ([appd puzzleSolutionStatus:currentPackNumber
                                          puzzleNumber:currentPuzzleNumber] == -1){
                            [appd incrementNumberOfMovesInPuzzleScoresArray:currentPackNumber
                                                               puzzleNumber:currentPuzzleNumber];
                        }
                    }
                    else if (rc.appCurrentGamePackType == PACKTYPE_DAILY) {
                        currentPackNumber = -1;
                        currentPuzzleNumber = [appd fetchDailyPuzzleNumber];
                        if ([appd puzzleSolutionStatus:currentPackNumber
                                          puzzleNumber:currentPuzzleNumber] == -1){
                            [appd incrementNumberOfMovesInPuzzleScoresArray:currentPackNumber
                                                               puzzleNumber:currentPuzzleNumber];
                        }
                    }

                    // A new Beam configuration requires that Energized states be recalculated for all Tiles
                    [self updateEnergizedStateForAllTiles];
                    // Check for Puzzle completion
                    if (!puzzleHasBeenCompleted){
                        if ([self queryPuzzleCompleted]){
                            vc.homeArrow.hidden = NO;
                            if (!infoScreen)
                                [self saveNextPuzzleToDefaults];
                            if ([appd packHasBeenCompleted]){
                                // Pack is complete
                                vc.nextButton.hidden = YES;
                                vc.nextArrow.hidden = YES;
                                vc.homeArrowWhite.hidden = (rc.appCurrentGamePackType == PACKTYPE_DEMO);
                                vc.replayIconWhite.hidden = (rc.appCurrentGamePackType == PACKTYPE_DEMO);
                                packHasBeenCompleted = YES;
                            }
                            else {
                                vc.nextButton.hidden = NO;
                                vc.nextArrow.hidden = NO;
                                vc.homeArrowWhite.hidden = (rc.appCurrentGamePackType == PACKTYPE_DEMO);
                                vc.replayIconWhite.hidden = (rc.appCurrentGamePackType == PACKTYPE_DEMO);
                                packHasBeenCompleted = NO;
                            }
                        }
                        else {
//                            [self savePuzzleProgressToDefaults];
                        }
                    }
                    // Increment numberOfMoves
                    rc.numberOfMoves++;
                }
                else {
                    [tileCurrentlyBeingEdited snapTileToPreviousGridPosition];
                }
            }
            else {
                // Tile has been tapped
                [self handleTileTap];
            }
            
            
            // If the Tile is not in its final position-angle then show rotation guide
            if (tileCurrentlyBeingEdited->placedUsingHint ||
                tileCurrentlyBeingEdited->placedManuallyMatchesHint ||
                [self checkIfTouchInUnplacedTileRegion]){
                tileForRotation = nil;
            }
            else if (![appd editModeIsEnabled] &&
                     puzzleHasBeenCompleted == NO &&
                     ![self checkIfTouchInUnplacedTileRegion]){
                tileForRotation = tileCurrentlyBeingEdited;
            }
            tileCurrentlyBeingEdited = nil;
            [self resetAllColorBeams];
        }
    }
    // Remove Tile if in Edit Mode and not on the game grid
    else if ([appd editModeIsEnabled]){
        [self removeOpticsTile:tileCurrentlyBeingEdited array:tiles];
        tileCurrentlyBeingEdited = nil;
        [self resetAllColorBeams];
    }
    else {
        // If you drop the Tile off the grid then put it back where it was
        [tileCurrentlyBeingEdited snapTileToPreviousGridPosition];
    }
    tileCurrentlyBeingEdited = nil;
    gridTouchGestures.ended = NO;
}

- (void)handleTileTap {
    TileHint *hint;
    // Touch in grid region?
    if ([self checkIfTouchInPuzzleRegion] ||
        ([self checkIfTouchInEditorRegion] && [appd editModeIsEnabled]) ) {
        if (tileCurrentlyBeingEdited) {
            // Has Tile moved to a new grid location?
            if ([self touchesEndedInNewGridLocation] == NO) {
                // Tile has NOT moved to a new grid location
                if (puzzleHasBeenCompleted == NO){
                    [self handleTileRotation];
                    [self resetAllColorBeams];
                }
                
                // Update @"numberOfMoves" value in puzzleScoresArray
                int currentPackNumber = -1;
                int currentPuzzleNumber = 0;
                if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
                    currentPackNumber = [appd fetchCurrentPackNumber];
                    currentPuzzleNumber = [appd fetchCurrentPuzzleNumber];
                    if ([appd puzzleSolutionStatus:currentPackNumber
                                      puzzleNumber:currentPuzzleNumber] == -1){
                        [appd incrementNumberOfMovesInPuzzleScoresArray:currentPackNumber
                                                           puzzleNumber:currentPuzzleNumber];
                    }
                }
                else if (rc.appCurrentGamePackType == PACKTYPE_DAILY) {
                    currentPackNumber = -1;
                    currentPuzzleNumber = [appd fetchDailyPuzzleNumber];
                    if ([appd puzzleSolutionStatus:currentPackNumber
                                      puzzleNumber:currentPuzzleNumber] == -1){
                        [appd incrementNumberOfMovesInPuzzleScoresArray:currentPackNumber
                                                           puzzleNumber:currentPuzzleNumber];
                    }
                }

                [self updateEnergizedStateForAllTiles];
                if ((hint = [self tileMatchesAnyUnusedHint:tileCurrentlyBeingEdited]) != nil) {
                    [appd playSound:appd.tileCorrectlyPlacedPlayer];
                    if (rc.appCurrentGamePackType != PACKTYPE_EDITOR ||
                        (![appd editModeIsEnabled] && rc.appCurrentGamePackType == PACKTYPE_EDITOR)){
                        [self updateTileHintArray:tileCurrentlyBeingEdited hint:hint];
                    }
                    tileCurrentlyBeingEdited->placedGridPosition.x = tileCurrentlyBeingEdited->gridPosition.x;
                    tileCurrentlyBeingEdited->placedGridPosition.y = tileCurrentlyBeingEdited->gridPosition.y;
                    tileCurrentlyBeingEdited->placedTileAngle = tileCurrentlyBeingEdited->tileAngle;
                }
                else {
                    // If rotated play a tap sound
                    [appd playSound:appd.tapPlayer];
                    tileCurrentlyBeingEdited->placedManuallyMatchesHint = NO;
                    tileCurrentlyBeingEdited->placedUsingHint = NO;
                    // tile.placed is only set to YES during gamePlay
                    if ([appd editModeIsEnabled]){
                        tileCurrentlyBeingEdited->placed = NO;
//                        if ([self checkIfTouchInNonfixedRegion]){
//                            tileCurrentlyBeingEdited->fixed = NO;
//                        }
//                        else {
                            tileCurrentlyBeingEdited->fixed = YES;
                            tileCurrentlyBeingEdited->finalGridPosition = tileCurrentlyBeingEdited->gridPosition;
//                        }
                    }
                    else {
                        if (tileCurrentlyBeingEdited->demoTile == NO){
                            tileCurrentlyBeingEdited->placed = YES;
                        }
                        tileCurrentlyBeingEdited->fixed = NO;
                    }
                }
                // Check for Puzzle completion
                if (!puzzleHasBeenCompleted){
                    if ([self queryPuzzleCompleted]){
                        vc.homeArrow.hidden = NO;
                        if (!infoScreen)
                            [self saveNextPuzzleToDefaults];
                        if ([appd packHasBeenCompleted]){
                            // Pack is complete
                            vc.nextButton.hidden = YES;
                            vc.nextArrow.hidden = YES;
                            vc.homeArrowWhite.hidden = (rc.appCurrentGamePackType == PACKTYPE_DEMO);
                            vc.replayIconWhite.hidden = (rc.appCurrentGamePackType == PACKTYPE_DEMO);
                            packHasBeenCompleted = YES;
                        }
                        else {
                            vc.nextButton.hidden = NO;
                            vc.nextArrow.hidden = NO;
                            vc.homeArrowWhite.hidden = (rc.appCurrentGamePackType == PACKTYPE_DEMO);
                            vc.replayIconWhite.hidden = (rc.appCurrentGamePackType == PACKTYPE_DEMO);
                            packHasBeenCompleted = NO;
                        }
                    }
                    else {
//                        [self savePuzzleProgressToDefaults];
                    }
                }
                [tileCurrentlyBeingEdited snapTileToPreviousGridPosition];
            }
        }
    }
}


@end
