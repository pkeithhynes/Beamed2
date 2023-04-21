//
//  BMDPuzzleViewController.h
//  Beamed
//
//  Created by Patrick Keith-Hynes on 8/15/22.
//  Copyright © 2022 Apple. All rights reserved.
//

@import UIKit;
@import MetalKit;

#import <UIKit/UIKit.h>
#import "BMDHintsViewController.h"

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0))
@interface BMDPuzzleViewController : UIViewController <UIGestureRecognizerDelegate>{
    @public
    //
    // Store view controller information here
    //
    BMDHintsViewController *hintsViewController;
    //
    // Main View
    //
    MTKView *puzzleView;
    //
    // Page subViews
    //
    UIVisualEffectView *puzzlePageBlurView;
    UIImageView *puzzleSolvedView;
    //
    // Puzzle Editing Buttons
    //
    UIButton *editPlayButton;
    UIButton *autoManualButton;
    UIButton *deleteButton;
    UIButton *saveButton;
    UIButton *duplicateButton;
    UIButton *clearButton;
    //
    // Puzzle Play Buttons
    //
    UIButton *wholeScreenButton;
    UIButton *helpButton;
    UIButton *settingsGearButton;
    UIButton *puzzlePacksButton;
    UIButton *robotDinerButton;
    UIButton *hintButton;
    UIButton *hintBulb;
    UIButton *nextButton;
    UIButton *prevButton;
    UIButton *backButton;
    UIButton *verifyButton;
    UIButton *homeArrow;
    UIButton *nextArrow;
    UIButton *homeArrowWhite;
    UIButton *prevArrowWhite;
    UIButton *replayIconWhite;
    //
    // Prev, Back, Next buttons have different locations in edit mode or playback mode
    //
    CGRect prevButtonRectEdit;
    CGRect prevButtonRectPlay;
    CGRect backButtonRectEdit;
    CGRect backButtonRectPlay;
    CGRect nextButtonRectEdit;
    CGRect nextButtonRectPlay;
    //
    // Labels
    //
    UILabel *helpLabel;
    UIImageView *helpImageView;
    UILabel *puzzleTitleLabel;
    UILabel *numberOfPuzzlesLabel;
    UILabel *puzzleSolvedLabel;
    UILabel *todaysDateLabelPuzzle;
    UILabel *puzzleCompleteLabel;
    UILabel *puzzleCompleteMessage;
    UILabel *packAndPuzzlesLabel;
    CGRect  puzzleSolvedLabelFrame;
    CGRect  puzzleCompleteLabelInitialFrame;
    CGRect  puzzleCompleteMessageInitialFrame;
    CGRect  puzzleCompleteLabelFinalFrame;
    CGRect  puzzleCompleteLabelDemoFinalFrame;
    CGRect  puzzleCompleteMessageFinalFrame;
    UILabel *numberOfPointsLabel;
    UILabel *puzzlesSolvedLabelStats;
    UILabel *pointsLabelStats;
    
    // Array of labels in PACKTYPE_DEMO infoScreen
    NSMutableArray *infoScreenLabelArray;
    
    //
    // Supports UIStepper for setting gridSize
    //
    UILabel *gridSizeLabel;
    UIStepper *gridSizeStepper;
    double gridSizeStepperInitialValue;
    
    NSMutableArray *demoMessageButtonsAndLabels;
    
    NSMutableArray *allowableLaserGridPositionArray;
    NSMutableArray *allowableTileGridPositionArray;
    NSMutableDictionary *puzzleDictionary;
    
    NSMutableDictionary     *inputPuzzleDictionary;
    
    NSTimer *promptUserAboutHintButtonTimer;
    
}

@property (nonatomic, retain) BMDHintsViewController *hintsViewController;

@property (nonatomic, retain) MTKView *puzzleView;
@property (nonatomic, retain) UIVisualEffectView *puzzlePageBlurView;
@property (nonatomic, retain) UIImageView *puzzleSolvedView;


@property (nonatomic, retain) UIButton *editPlayButton;
@property (nonatomic, retain) UIButton *autoManualButton;
@property (nonatomic, retain) UIButton *deleteButton;
@property (nonatomic, retain) UIButton *saveButton;
@property (nonatomic, retain) UIButton *duplicateButton;
@property (nonatomic, retain) UIButton *clearButton;

@property (nonatomic, retain) UIButton *wholeScreenButton;
@property (nonatomic, retain) UIButton *settingsGearButton;
@property (nonatomic, retain) UIButton *puzzlePacksButton;
@property (nonatomic, retain) UIButton *robotDinerButton;
@property (nonatomic, retain) UIButton *helpButton;
@property (nonatomic, retain) UIButton *hintButton;
@property (nonatomic, retain) UIButton *hintBulb;
@property (nonatomic, retain) UIButton *nextButton;
@property (nonatomic, retain) UIButton *prevButton;
@property (nonatomic, retain) UIButton *backButton;
@property (nonatomic, retain) UIButton *verifyButton;
@property (nonatomic, retain) UIButton *homeArrow;
@property (nonatomic, retain) UIButton *nextArrow;
@property (nonatomic, retain) UIButton *homeArrowWhite;
@property (nonatomic, retain) UIButton *prevArrowWhite;
@property (nonatomic, retain) UIButton *replayIconWhite;

@property (nonatomic) CGRect prevButtonRectEdit;
@property (nonatomic) CGRect prevButtonRectPlay;
@property (nonatomic) CGRect backButtonRectEdit;
@property (nonatomic) CGRect backButtonRectPlay;
@property (nonatomic) CGRect nextButtonRectEdit;
@property (nonatomic) CGRect nextButtonRectPlay;

@property (nonatomic, retain) UIImageView *helpImageView;
@property (nonatomic, retain) UILabel *helpLabel;
@property (nonatomic, retain) UILabel *puzzleTitleLabel;
@property (nonatomic, retain) UILabel *numberOfPuzzlesLabel;
@property (nonatomic, retain) UILabel *puzzleSolvedLabel;
@property (nonatomic, retain) UILabel *todaysDateLabelPuzzle;
@property (nonatomic, retain) UILabel *puzzleCompleteLabel;
@property (nonatomic, retain) UILabel *puzzleCompleteMessage;
@property (nonatomic, retain) UILabel *packAndPuzzlesLabel;

@property (nonatomic) CGRect puzzleSolvedLabelFrame;
@property (nonatomic) CGRect puzzleCompleteLabelInitialFrame;
@property (nonatomic) CGRect puzzleCompleteMessageInitialFrame;
@property (nonatomic) CGRect puzzleCompleteLabelFinalFrame;
@property (nonatomic) CGRect puzzleCompleteLabelDemoFinalFrame;
@property (nonatomic) CGRect puzzleCompleteMessageFinalFrame;
@property (nonatomic, retain) UILabel *numberOfPointsLabel;
@property (nonatomic, retain) UILabel *puzzlesSolvedLabelStats;
@property (nonatomic, retain) UILabel *pointsLabelStats;

@property (nonatomic, retain) UILabel *gridSizeLabel;
@property (nonatomic, retain) NSNumber *gridSize;
@property (nonatomic, retain) UIStepper *gridSizeStepper;

@property (nonatomic, retain) NSMutableArray *demoMessageButtonsAndLabels;
@property (nonatomic, retain) NSMutableArray *infoScreenLabelArray;


@property (nonatomic, retain) NSMutableArray * _Nonnull allowableLaserGridPositionArray;
@property (nonatomic, retain) NSMutableArray * _Nonnull allowableTileGridPositionArray;
@property (nonatomic, retain) NSMutableDictionary * _Nullable puzzleDictionary;

@property (nonatomic, retain) NSMutableDictionary * _Nonnull inputPuzzleDictionary;

@property (nonatomic, retain) NSTimer *promptUserAboutHintButtonTimer;



- (void)buildButtonsAndLabelsForEdit;
- (void)buildButtonsAndLabelsForPlay;
- (void)displayButtonsAndLabels;
- (void)removeButtonsAndLabels;
- (void)setPuzzleLabel;
- (void)setHintButtonLabel:(unsigned int)hintsRemaining;
- (void)enableFlash:(UIButton *)button;
- (void)disableFlash:(UIButton *)button;
- (void)nextPuzzle;
- (void)nextButtonPressed;
- (void)backButtonPressed;
- (BOOL)queryPuzzleExists:(NSString *)dictionaryName puzzle:(unsigned int)puzzleIndex;
- (BOOL)appendGeneratedPuzzle;
- (void)promptUserAboutHintButton;
- (void)clearPromptUserAboutHintButtonTimer;

@end

NS_ASSUME_NONNULL_END
