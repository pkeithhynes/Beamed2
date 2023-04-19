//
//  Optics.h
//  Beamed
//
//  Created by pkeithhynes on 7/18/10.
//  Copyright 2010 glimmerWave software. All rights reserved.
//

@import MetalKit;

#include <stdlib.h>

#import "Definitions.h"
#import "Tile.h"
#import "TileHint.h"
#import "Background.h"
#import "Foreground.h"
#import "TextureRenderData.h"
#import "TextureData.h"
#import "GameControls.h"
#import "BMDViewController.h"
#import "BMDPuzzleViewController.h"
#import "BeamTextureRenderData.h"
#import "UIDemoLabel.h"
#import "UIDemoButton.h"


@class BMDAppDelegate;
@class BMDViewController;
@class Tile;
@class TileHint;
@class Background;
@class Foreground;
@class Beam;
@class TextureRenderData;
@class GameControls;
@class UIDemoLabel;

typedef struct {
	int			sizeX;
	int			sizeY;
} Grid;

typedef    struct {
    vector_int2     minPuzzleBoundary;
    vector_int2     maxPuzzleBoundary;
    vector_int2     minEditorBoundary;
    vector_int2     maxEditorBoundary;
    vector_int2     minControlsBoundary;
    vector_int2     maxControlsBoundary;
    vector_int2     minUnplacedTilesBoundary;
    vector_int2     maxUnplacedTilesBoundary;
    vector_int2     pixelPosition;
    vector_int2     gridPosition;
    vector_int2     initialGridPosition;     // Set by touchesBegan
    vector_int2     previousGridPosition;    // Set by saveTouchEvent to determine when a tile
                                           // has moved to a new gridPosition
    BOOL            active;
    BOOL            ended;
    BOOL            moved;
} GridTouchGestures;

API_AVAILABLE(ios(13.0))
@interface Optics : NSObject {
@public
    BMDPuzzleViewController    *vc;
    uint                     puzzleCompletionCondition;     // If 0 then all Jewels must be energized
                                                            // If !=0 then the Tile with the matching tag
                                                            //      must be located at grid position
                                                            //      (finalX, finalY)
    unsigned int            puzzleDifficulty;           // 1-10 with 10 being most difficult
    BOOL                     puzzleHasBeenCompleted;
    BOOL                     packHasBeenCompleted;
    BOOL                    puzzleHasBeenCompletedCelebration;
    BOOL                     puzzleCompletedButtonFlash;
    BOOL                     hintWasRequested;
    BOOL                    puzzleViewControllerObjectsInitialized;
    Grid                     masterGrid;
    Grid						gameGrid;
    unsigned int					lightSweepCounter;
    GridTouchGestures			gridTouchGestures;
    
    NSString                *parentDictionaryKey;
    NSMutableArray				*tiles;
    NSMutableArray             *hints;
    NSMutableArray             *beams[3];
    NSMutableArray             *renderArray;
    NSMutableDictionary         *renderDictionary;
    NSMutableArray             *tileRenderArray;
    BOOL                        displayBackgroundArray;
    BOOL                        displayBackgroundImage;
    BOOL                        infoScreen;
    BOOL                        circleAroundHintsButton;
    BOOL                        dragTile;
    BOOL                        tapTile;
    NSMutableArray             *backgroundRenderArray;
    NSMutableArray             *beamsRenderArray;
    NSMutableArray             *gridPositionsCrossedByMultipleCoincidentBeams;
    NSMutableArray             *ringRenderArray;
    NSMutableArray             *puzzleCompleteRenderArray;
    NSMutableArray             *gameControlTiles;
    Tile					    *tileCurrentlyBeingEdited;
    Tile                        *tileForRotation;
    Tile                     *tileUsedForDemoPlacement;
    vector_int2               demoArrowStart;
    vector_int2               demoArrowEnd;
    BOOL		                toggleShowWhenPuzzleStartsTileFlag;
    Background                *background;
    Foreground                *foreground;
    TextureRenderData          *backgroundRenderDataImage;
    TextureRenderData          *overlayRenderDataImage;
    TextureRenderData          *backgroundRenderDataFilterImage;
    TextureRenderData          *backgroundRenderDataInner;
    TextureRenderData          *backgroundRenderDataOuter;
    TextureRenderData          *unusedTileBackgroundRenderData;
    TextureRenderData          *borderRenderData;
    TextureRenderData          *arrowRenderData;
    
    uint16_t                animationFrame;

    // Device screen dimensions are determined by the root UIViewController and cached here
    CGFloat _screenWidthInPixels;
    CGFloat _screenHeightInPixels;
    CGFloat _safeAreaScreenWidthInPixels;
    CGFloat _safeAreaScreenHeightInPixels;
    
    // Puzzle screen vertical and horizontal grid offsets allow for symmetrical and more
    // visually appealing Tile grid separators
    CGFloat _puzzleGridTopAndBottomBorderWidthInPixels;
    CGFloat _puzzleGridLeftAndRightBorderWidthInPixels;

    // puzzleScreen Horizontal and Vertical Offsets
    CGFloat _puzzleScreenHorizontalOffsetInPixels;
    CGFloat _puzzleScreenVerticalOffsetInPixels;

    // Application masterGrid display window size calculated at runtime
    CGFloat _masterGridHeightInPixels;
    CGFloat _masterGridWidthInPixels;
    CGFloat _masterGridHorizontalOffsetInPixels;
    CGFloat _masterGridVerticalOffsetInPixels;

    // Application gameGrid display window size calculated at runtime
    CGFloat _puzzleDisplayHeightInPixels;
    CGFloat _puzzleDisplayWidthInPixels;
    CGFloat _squareTileSideLengthInPixels;
    CGFloat _tileVerticalOffsetInPixels;
    CGFloat _tileHorizontalOffsetInPixels;
    CGFloat _gridRegionLengthProportion;
    
    // Puzzle-specific quantities
    unsigned int puzzleFontSize;

	// Count of optical element tiles that can be manipulated by the user: MIRROR, PRISM, BEAMSPLITTER
	int						prismMax;
	int						mirrorMax;
	int						beamsplitterMax;
	int						prismCount;
	int						mirrorCount;
	int						beamsplitterCount;
	// Laser tiles
	Tile						*laserTile[3];
	int						laserTileCX[3];
	int						laserTileCY[3];
	int						laserTileCZ[3];
	int						laserTileDirection[3];
	// Root beams originate from the Red, Green and Blue Laser tiles
	Beam					*rootBeam[3];
	int						rootBeamSX[3];
	int						rootBeamSY[3];
	int						rootBeamSZ[3];
	int						rootBeamEX[3];
	int						rootBeamEY[3];
	int						rootBeamEZ[3];
	enum eObjectAngle			rooteBeamAngle[3];
    // Tutorial arrow that indicates where a user should drag a Tile
    vector_int2               tutorialArrowStartPositionGrid;
    vector_int2               tutorialArrowEndPositionGrid;
    vector_int2               tutorialArrowStartPositionPixels;
    vector_int2               tutorialArrowEndPositionPixels;

	
	// Determines the way that prisms refract beams
	// - index 0 is eBeamColors: BEAM_RED, BEAM_GREEN, BEAM_BLUE
	// - index 1 is eBeamDirection
	// - index 2 is eObjectAngle
	int	prismRefractionArray[3][8][8];
    
    GameControls    *gameControls;
    

    
}

@property (nonatomic, retain) BMDPuzzleViewController * _Nonnull vc;
@property (nonatomic, retain) NSString * _Nonnull parentDictionaryKey;
@property (nonatomic, retain) NSMutableArray * _Nonnull tiles;
@property (nonatomic, retain) NSMutableArray * _Nonnull hints;
@property (nonatomic, retain) NSMutableArray * _Nonnull tileRenderArray;
@property (nonatomic, retain) NSMutableArray * _Nonnull backgroundRenderArray;
@property (nonatomic, retain) NSMutableArray * _Nonnull ringRenderArray;
@property (nonatomic, retain) NSMutableArray * _Nonnull puzzleCompleteRenderArray;
@property (nonatomic, retain) NSMutableArray * _Nonnull beams;
@property (nonatomic) BOOL puzzleViewControllerObjectsInitialized;

// Puzzle Generation
- (NSMutableDictionary *_Nonnull)generatePuzzleBeams:(NSMutableDictionary *_Nonnull)puzzleDictionary beamColor:(enum eBeamColors)beamColor;
- (NSMutableDictionary *_Nonnull)generatePuzzleBeams:(NSMutableDictionary *_Nonnull)puzzleDictionary;
- (NSMutableDictionary *_Nonnull)generatePuzzleMirrors:(NSMutableDictionary *_Nonnull)puzzleDictionary beamColor:(enum eBeamColors)beamColor;
- (NSMutableDictionary *_Nonnull)generatePuzzleMirrors:(NSMutableDictionary *_Nonnull)puzzleDictionary;

- (NSMutableDictionary *_Nullable)resetPuzzleDictionary:(NSMutableDictionary *_Nonnull)puzzleDictionary;
- (void)buildPuzzleFromDictionary:(NSMutableDictionary *)puzzleDictionary
                     showAllTiles:(BOOL)showAll
                    allTilesFixed:(BOOL)allTilesFixed;
- (NSMutableDictionary *_Nonnull)encodeAnEmptyPuzzleAsMutableDictionary:(NSMutableDictionary *_Nonnull)dictionary;
- (NSMutableDictionary *_Nonnull)encodeCurrentPuzzleAsMutableDictionary:(NSMutableDictionary *_Nonnull)dictionary;
- (void)savePuzzleProgressToDefaults;

- (void)initRootBeam:(enum eBeamColors)COLOR rootBeam:(Beam *_Nonnull)rootBeam;

- (BOOL)initWithDictionary:(NSMutableDictionary *_Nullable)puzzleDictionary viewController:(BMDPuzzleViewController *_Nonnull)puzzleViewController;
//- (void)initWithDictionary:(NSMutableDictionary *_Nullable)puzzleDictionary;

- (void)putOpticsTile:(Tile *_Nonnull)tile array:(NSMutableArray *_Nonnull)array;
- (void)removeOpticsTile:(Tile *_Nonnull)tile array:(NSMutableArray *_Nonnull)array;
- (Tile *_Nonnull)getOpticsTile:(int)index;
- (int)getOpticsTileCount;

- (void)putOpticsBeam:(enum eBeamColors)color beam:(Beam *_Nonnull)beam;
- (Beam *_Nonnull)getOpticsBeam:(NSMutableArray *_Nonnull)beams index:(int)index;
- (int)getOpticsBeamCount:(NSMutableArray *_Nonnull)beams;
- (BOOL)checkIfCurrentPuzzleIsEmpty;

- (void)resetAllBeams:(enum eBeamColors)color;
- (Tile *_Nullable)tileOccupiesGridPosition:(vector_int2)gridPosition;

//- (void)saveGridTouchCoordinates:(CGFloat)X y:(CGFloat)Y;
- (void)handleTileRotation;
- (void)checkForTileTouched;
- (void)resetAllColorBeams;

// Methods to support hints
- (BOOL)startPositionTileForHint;
- (void)finishPositionTileForHint:(Tile *_Nonnull)tile;
- (void)updateTileHintArray:(Tile *_Nonnull)tile hint:(TileHint *_Nonnull)hint;

- (NSMutableDictionary * _Nonnull)renderPuzzle;
//- (NSMutableDictionary * _Nonnull)renderHome;
- (void)touchesBegan;
- (void)touchesMoved;
- (void)touchesEnded;
- (void)handleTileLongPress:(vector_int2)position;
- (void)handleTapGesture:(vector_int2)position;
- (BOOL)checkIfTouchInPuzzleRegion;
- (void)saveTouchEvent:(vector_int2)p;
- (void)updateAllBeams;
- (void)clearPuzzle;

- (void)saveEditedPuzzleToDefaults;

- (vector_float2)gridPositionToPixelPosition:(vector_int2)g;
- (vector_int2)gridPositionToIntPixelPosition:(vector_int2)g;
- (vector_int2)pixelPositionToGridPosition:(vector_int2)p;
- (BOOL)allTilesArePlaced;

- (BOOL)queryPuzzleCompleted;
- (void)savePreviousPuzzleToDefaults;
- (void)saveNextPuzzleToDefaults;

- (void)startPuzzleCompleteCelebration;
- (void)dropAllTilesOffScreen;

@end
