/*
See LICENSE folder for this sample’s licensing information.)

Abstract:
Implementation of the iOS & tvOS application delegate
*/

#import "BMDAppDelegate.h"
#import "BMDViewController.h"
#import "BMDRenderer.h"
#import "Definitions.h"
#import "TextureData.h"
#import "Tile.h"
#import <StoreKit/StoreKit.h>
#import <VungleSDK/VungleSDK.h>
#import "Firebase.h"

@import MetalKit;
@import UIKit;

// Device screen dimensions
CGFloat _screenWidthInPixels;
CGFloat _screenHeightInPixels;

@interface BMDAppDelegate() <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@end


@implementation BMDAppDelegate
{
    // The device (aka GPU) used to render
    id<MTLDevice> _device;
    id<MTLTexture> __strong _texture;
    MTKView *view;
    
    // NSUserDefaults
    NSMutableDictionary *upgrades;
    NSMutableDictionary *puzzleScoreDictionary;

}

@synthesize optics;
@synthesize window;
@synthesize rc;
@synthesize loadedTextureFiles;
@synthesize backgroundAnimationContainers;
@synthesize backgroundTextures;
@synthesize jewelTextures;
@synthesize tileAnimationContainers;
@synthesize beamAnimationContainers;
@synthesize ringAnimationContainers;
@synthesize logoAnimationContainers;
@synthesize gameDictionaries;
@synthesize dailyPuzzleGamePuzzleDictionary;

@synthesize tapSoundFileURLRef;
@synthesize plopSoundFileURLRef;
@synthesize clinkSoundFileURLRef;
@synthesize twinkleSoundFileURLRef;
@synthesize tileCorrectlyPlacedSoundFileURLRef;
@synthesize laser1SoundFileURLRef;
@synthesize laser2SoundFileURLRef;
@synthesize jewelEnergizedSoundFileURLRef;
@synthesize tapSoundFileObject;
@synthesize plopSoundFileObject;
@synthesize clinkSoundFileObject;
@synthesize twinkleSoundFileObject;
@synthesize tileCorrectlyPlacedSoundFileObject;
@synthesize laser1SoundFileObject;
@synthesize laser2SoundFileObject;
@synthesize jewelEnergizedSoundFileObject;
@synthesize view;
@synthesize rootViewControllerHasLoaded;
@synthesize currentiCloudToken;
@synthesize permittedToUseiCloud;
@synthesize puzzleComplete1_SoundFileURLRef;
@synthesize puzzleComplete2_SoundFileURLRef;
@synthesize puzzleComplete3_SoundFileURLRef;
@synthesize puzzleComplete4_SoundFileURLRef;
@synthesize puzzleBegin1_SoundFileURLRef;
@synthesize puzzleBegin1_SoundFileObject;
@synthesize puzzleComplete1_SoundFileObject;
@synthesize puzzleComplete2_SoundFileObject;
@synthesize puzzleComplete3_SoundFileObject;
@synthesize puzzleComplete4_SoundFileObject;
@synthesize loop1Player;
@synthesize loop2Player;
@synthesize loop3Player;

@synthesize laser1Player;
@synthesize laser2Player;
@synthesize tapPlayer;
@synthesize clinkPlayer;
@synthesize tileCorrectlyPlacedPlayer;
@synthesize puzzleComplete1Player;
@synthesize puzzleComplete2Player;
@synthesize puzzleComplete3Player;

@synthesize loopMusic1_SoundFileObject;
@synthesize currentPack;
@synthesize currentTutorialPuzzle;
@synthesize currentDailyPuzzleNumber;
@synthesize numberOfHintsRemaining;

@synthesize totalPuzzlesLeaderboard;
@synthesize totalJewelsLeaderboard;

@synthesize storeKitPurchaseRequested;
@synthesize productsRequestEnum;
@synthesize arrayOfPaidHintPacksInfo;
@synthesize arrayOfPuzzlePacksInfo;
@synthesize arrayOfAltIconsInfo;


//
// Methods to handle app life cycle
//
- (BOOL)application:(UIApplication *)application willFinishLaunchingWithSettings:(NSDictionary *)launchSettings {
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchSettings {
    DLog(">>> Calling didFinishLaunchingWithOptions");
    
    // Begin monitoring the Network and sending Notifications when changes in connectivity occur
    [self startNetworkMonitoring];
    
    // Register to receive notifications regarding changes in connectivity
    [[NSNotificationCenter defaultCenter]
     addObserver: self
     selector: @selector (handleNetworkConnectivityChanged:)
     name: @"com.beamed.network.status-change"
     object: nil];

    // Init BMDViewController
    (void)[[BMDViewController alloc] init];
    rc = (BMDViewController*)[[(BMDAppDelegate *)[[UIApplication sharedApplication]delegate] window] rootViewController];
    self.window.rootViewController = rc;
    window = [(BMDAppDelegate *)[[UIApplication sharedApplication]delegate] window];

    // Default setting is that a purchase is not requested
    productsRequestEnum = REQ_NIL;
    
    //
    // Request Current In-App Purchase Data from StoreKit
    //
    // Paid Puzzle Packs - completion handler calls requestHintPacksInfo
    arrayOfPuzzlePacksInfo = nil;
    [self requestPuzzlePacksInfo];

    // Paid Hint Packs
//    arrayOfPaidHintPacksInfo = nil;
//    [self requestHintPacksInfo];
    
    //
    // Initialize Vungle Ad Platform
    //
    NSError* error;
    NSString* appID = vungleAppID;
    VungleSDK* sdk = [VungleSDK sharedSDK];
    if (![sdk startWithAppId:appID error:&error]) {
        if (error) {
            DLog("Error encountered starting the VungleSDK: %@", error);
        }
    }
    
    // Attach
    vungleIsLoaded = NO;
    [[VungleSDK sharedSDK] setDelegate:(id<VungleSDKDelegate> _Nullable)self];

    
    // Determine the screen dimensions and set up the viewable area
    CGRect screenRect = [[UIScreen mainScreen] nativeBounds];
    _screenWidthInPixels = screenRect.size.width;
    _screenHeightInPixels = screenRect.size.height;
    
    // Fetch the puzzle packs dictionary array from the plist file if it exists
    packsArray = [self fetchPacksArray:kPuzzlePacksArray];
    // Else create the dictionary to hold the game puzzle dictionaries
    if (packsArray) {
        DLog("kPuzzlePacksArray found.\n");
    }
    else {
        DLog("No kPuzzlePacksArray found - creating.\n");
        packsArray = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)1];
    }
    
    // Fetch the demo puzzle dictionary from the plist file if it exists
    demoPuzzleDictionary = [self fetchPackDictionaryFromPlist:kDemoPuzzlePackDictionary];
    // Else create the dictionary to hold the demo dictionaries
    if (demoPuzzleDictionary) {
        DLog("kDemoPuzzlePackDictionary found.\n");
    }
    else {
        DLog("No kDemoPuzzlePackDictionary found - creating.\n");
        demoPuzzleDictionary = [[NSMutableDictionary alloc] initWithCapacity:(NSUInteger)1];
    }

    // Fetch the daily puzzle dictionary array from the plist file if it exists
    dailyPuzzleGamePuzzleDictionary = [self fetchPackDictionaryFromPlist:kDailyPuzzlesPackDictionary];
    // Else create the dictionary to hold the game puzzle dictionaries
    if (dailyPuzzleGamePuzzleDictionary) {
        DLog("kDailyPuzzlesPackDictionary found.\n");
    }
    else {
        DLog("No kDailyPuzzlesPackDictionary found - creating.\n");
        dailyPuzzleGamePuzzleDictionary = [[NSMutableDictionary alloc] initWithCapacity:(NSUInteger)1];
    }

    // Create top puzzle dictionary and add existing game-puzzle-dictionaries
    gameDictionaries = [[NSMutableDictionary alloc] initWithCapacity:(NSUInteger)1];
    [gameDictionaries setObject:demoPuzzleDictionary forKey:@"demoPuzzlePackDictionary.plist"];
    [gameDictionaries setObject:dailyPuzzleGamePuzzleDictionary forKey:@"dailyPuzzlesPackDictionary.plist"];
    [gameDictionaries setObject:packsArray forKey:kPuzzlePacksArray];

    // Load sound effects and music from main bundle
    [self loadSoundEffects];
    
    currentPack = [self fetchCurrentPackNumber];
    currentDailyPuzzleNumber = 0;

    rootViewControllerHasLoaded = NO;
    
    // If there is no local record of Pack purchases then query StoreKit to find out
    // what Packs have been purchased
//    if (![self existPurchasedPacks]){
//        [self restorePurchases];
//    }
    
    // Establish default values for certain keys
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *defaultsDict = @{@"permittedToUseiCloud":@"NOTHING",
                                   @"firstLaunchOfThisApp":@"NOTHING",
                                   @"demoHasBeenCompleted":@"NOTHING"
    };
    [defaults registerDefaults:defaultsDict];
    
    // Is this the first launch of the app (according to local NSDefaults)?
    if ([[defaults objectForKey:@"firstLaunchOfThisApp"] isEqualToString:@"NOTHING"]){
        [defaults setObject:@"NO" forKey:@"firstLaunchOfThisApp"];
        [defaults setObject:@"YES" forKey:@"musicEnabled"];
        [defaults setObject:@"YES" forKey:@"soundsEnabled"];
        [defaults setObject:@"YES" forKey:@"editModeEnabled"];
    }
    

    if (ENABLE_GA == YES){
        //
        // Firebase
        //
        [FIRApp configure];
        NSUbiquitousKeyValueStore *kvStore = [NSUbiquitousKeyValueStore defaultStore];
        NSDictionary *kvDictionary = [kvStore dictionaryRepresentation];
        DLog("kvStore");
        
        [FIRAnalytics logEventWithName:kFIREventSelectContent
                            parameters:@{
            kFIRParameterItemID:[NSString stringWithFormat:@"id-%@", @"AppDelegate Launch"],
            kFIRParameterItemName:@"AppDelegate Launch",
            kFIRParameterContentType:@"image"
        }];
    }
    DLog("<<< Calling didFinishLaunchingWithOptions");
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    DLog(">>> Calling applicationDidBecomeActive");
    
    
    currentiCloudToken = nil;
    //
    // iCloud initialization
    //
    
    // Uncomment to clear out NSUbiquitousKeyValueStore
//    [self clearNSUbiquitousKeyValueStore];
    
    //
    // Support using iCloud for key:value storage of settings, game progress and purchase details
    //
    NSFileManager* fileManager = [NSFileManager defaultManager];
    currentiCloudToken = fileManager.ubiquityIdentityToken;
    if (currentiCloudToken) {
        NSData *newTokenData =
        [NSKeyedArchiver archivedDataWithRootObject: currentiCloudToken requiringSecureCoding:NO error:nil];
        [[NSUserDefaults standardUserDefaults]
         setObject: newTokenData
         forKey: @"com.squaretailsoftware.beamed.UbiquityIdentityToken"];
    } else {
        [[NSUserDefaults standardUserDefaults]
         removeObjectForKey: @"com.squaretailsoftware.beamed.UbiquityIdentityToken"];
    }
    
    // Detect changes to iCloud availability
    [[NSNotificationCenter defaultCenter]
        addObserver: self
           selector: @selector (iCloudAccountAvailabilityChanged:)
               name: NSUbiquityIdentityDidChangeNotification
             object: nil];
    
    // register to observe notifications from the store
    [[NSNotificationCenter defaultCenter]
        addObserver: self
           selector: @selector (storeDidChange:)
               name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
             object: [NSUbiquitousKeyValueStore defaultStore]];
    
    // get changes that might have happened while this
    // instance of your app wasn't running
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];

    // If musicEnabled and soundsEnabled are not found then initialize to @"YES"
    if ([self getStringFromDefaults:@"musicEnabled"] == nil){
        [self setObjectInDefaults:@"YES" forKey:@"musicEnabled"];
    }
    if ([self getStringFromDefaults:@"soundsEnabled"] == nil){
        [self setObjectInDefaults:@"YES" forKey:@"soundsEnabled"];
    }
    if ([self getStringFromDefaults:@"editModeEnabled"] == nil){
        [self setObjectInDefaults:@"YES" forKey:@"editModeEnabled"];
    }
    
    [rc updateTodaysDate];
    
    // Start appropriate music loop
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id demoHasBeenCompletedObject = [defaults objectForKey:@"demoHasBeenCompleted"];
    if (demoHasBeenCompletedObject != nil){
        if ([demoHasBeenCompletedObject isEqualToString:@"YES"]){
            [self playMusicLoop:loop1Player];
        }
        else {
            [self playMusicLoop:loop3Player];
        }
    }
    else if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
        [self playMusicLoop:loop3Player];
    }
    else {
        [self playMusicLoop:loop1Player];
    }
    
    [rc refreshHomeView];
    
    DLog("<<< Calling applicationDidBecomeActive");
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    DLog("Entering background.");
    [loop1Player pause];
    [loop2Player pause];
    [loop3Player pause];
}


//
// Methods to handle Network Monitoring
//
- (void)startNetworkMonitoring {
    dispatch_queue_attr_t attrs = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, DISPATCH_QUEUE_PRIORITY_DEFAULT);
    self.monitorQueue = dispatch_queue_create("com.beamed.network.monitor", attrs);
    
    self.monitor = nw_path_monitor_create();
    nw_path_monitor_set_queue(self.monitor, self.monitorQueue);
    nw_path_monitor_set_update_handler(self.monitor, ^(nw_path_t _Nonnull path) {
        nw_path_status_t status = nw_path_get_status(path);
        BOOL isWiFi = nw_path_uses_interface_type(path, nw_interface_type_wifi);
        BOOL isCellular = nw_path_uses_interface_type(path, nw_interface_type_cellular);
        BOOL isEthernet = nw_path_uses_interface_type(path, nw_interface_type_wired);
        BOOL isExpensive = nw_path_is_expensive(path);
        BOOL hasIPv4 = nw_path_has_ipv4(path);
        BOOL hasIPv6 = nw_path_has_ipv6(path);
        BOOL hasNewDNS = nw_path_has_dns(path);
        
        NSDictionary *userInfo = @{
                                    @"isWiFi" : @(isWiFi),
                                    @"isCellular" : @(isCellular),
                                    @"isEthernet" : @(isEthernet),
                                    @"status" : @(status),
                                    @"isExpensive" : @(isExpensive),
                                    @"hasIPv4" : @(hasIPv4),
                                    @"hasIPv6" : @(hasIPv6),
                                    @"hasNewDNS" : @(hasNewDNS)
                                 };
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSNotificationCenter.defaultCenter postNotificationName:@"com.beamed.network.status-change" object:nil userInfo:userInfo];
        });
    });
    nw_path_monitor_start(self.monitor);
}

- (void)stopNetworkMonitoring
{
    nw_path_monitor_cancel(self.monitor);
}

//
// Handler Methods Go Here
//

- (void)handleNetworkConnectivityChanged:(NSNotification *) notification{
    NSLog(@"%@",notification.object);
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:notification.userInfo];
    DLog("handleNetworkConnectivityChanged");
}


//
// Methods to handle NSDefaults and NSUbiquitousKeyValueStore
//

// If iCloud Account Availability changes then revoke permittedToUseiCloud and ask user for permission at next startup
- (void)iCloudAccountAvailabilityChanged:id {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    DLog("iCloudAccountAvailabilityChanged");
    currentiCloudToken = nil;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    currentiCloudToken = fileManager.ubiquityIdentityToken;
    if (currentiCloudToken == nil){
        [defaults removeObjectForKey:@"permittedToUseiCloud"];
        [rc iCloudStorageUnreachable];
    }
    else {
        [rc chooseWhetherToUseiCloudStorage];
    }
}

// Handle changes to key-value store made by this app running on a different device
- (void)storeDidChange:id {
    DLog("storeDidChange");
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

// This method clears all keys-values out of NSUbiquitousKeyValueStore
- (void)clearNSUbiquitousKeyValueStore {
    NSUbiquitousKeyValueStore *kvStore = [NSUbiquitousKeyValueStore defaultStore];
    NSDictionary *kvd = [kvStore dictionaryRepresentation];
    NSArray *arr = [kvd allKeys];
    for (int i=0; i < arr.count; i++){
        if ([arr count] > i){
            NSString *key = [arr objectAtIndex:i];
            [kvStore removeObjectForKey:key];
        }
    }
    [kvStore synchronize];
    kvStore = [NSUbiquitousKeyValueStore defaultStore];
    kvd = [kvStore dictionaryRepresentation];
}

// This method tests for the existence of a key in NSUbiquitoutKeyValueStore
- (BOOL)existsKeyInNSUbiquitousKeyValueStore:(NSString *)key {
    NSUbiquitousKeyValueStore *cloudStore = [NSUbiquitousKeyValueStore defaultStore];
//    id myObject = [cloudStore objectForKey:key];
    if ([cloudStore objectForKey:key] == nil) {
        return NO;
    }
    else {
        return YES;
    }
}

// This method tests for the existence of a key in NSDefaults
- (BOOL)existsKeyInDefaults:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:key] == nil) {
        return NO;
    }
    else {
        return YES;
    }
}

// Set object in local defaults or iCloud defaults
- (void)setObjectInDefaults:(id)object forKey:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUbiquitousKeyValueStore *cloudStore = [NSUbiquitousKeyValueStore defaultStore];
    // Use iCloud storage if permitted
    if ([[defaults objectForKey:@"permittedToUseiCloud"] isEqualToString:@"YES"]){
        [cloudStore setObject:object forKey:key];
        [cloudStore synchronize];
    }
    // iCloud use not permitted so use local default storage
    else {
        [defaults setObject:object forKey:key];
    }
}

// Remove object in local defaults or iCloud defaults
- (void)removeObjectInDefaultsForKey:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUbiquitousKeyValueStore *cloudStore = [NSUbiquitousKeyValueStore defaultStore];
    // Use iCloud storage if permitted
    if ([[defaults objectForKey:@"permittedToUseiCloud"] isEqualToString:@"YES"]){
        [cloudStore removeObjectForKey:key];
        [cloudStore synchronize];
    }
    // iCloud use not permitted so use local default storage
    else {
        [defaults removeObjectForKey:key];
    }
}

// Set unsigned integer in local defaults or iCloud defaults
- (void)setUnsignedIntInDefaults:(unsigned int)number forKey:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUbiquitousKeyValueStore *cloudStore = [NSUbiquitousKeyValueStore defaultStore];
    // Use iCloud storage if permitted
    if ([[defaults objectForKey:@"permittedToUseiCloud"] isEqualToString:@"YES"]){
        [cloudStore setObject:[NSNumber numberWithUnsignedInt:number] forKey:key];
        [cloudStore synchronize];
    }
    // iCloud use not permitted so use local default storage
    else {
        [defaults setInteger:number forKey:key];
    }
}

// Get object from local defaults or iCloud defaults
- (id)getObjectFromDefaults:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUbiquitousKeyValueStore *cloudStore = [NSUbiquitousKeyValueStore defaultStore];
    // Use iCloud storage if permitted
    if ([[defaults objectForKey:@"permittedToUseiCloud"] isEqualToString:@"YES"]){
        if ([cloudStore objectForKey:key] != nil) {
            return [cloudStore objectForKey:key];
        }
        else {
            return nil;
        }
    }
    // iCloud use not permitted so use local default storage
    else {
        if ([defaults objectForKey:key] != nil) {
            return [defaults objectForKey:key];
        }
        else {
            return nil;
        }
    }
}

// Get object directly from iCloud defaults
- (id)getObjectFromCloudDefaults:(NSString *)key {
    NSUbiquitousKeyValueStore *cloudStore = [NSUbiquitousKeyValueStore defaultStore];
    // Use iCloud storage if permitted
    if ([cloudStore objectForKey:key] != nil) {
        return [cloudStore objectForKey:key];
    }
    else {
        return nil;
    }
}

// Read NSString from local defaults or iCloud defaults
- (NSString *)getStringFromDefaults:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUbiquitousKeyValueStore *cloudStore = [NSUbiquitousKeyValueStore defaultStore];
    // Use iCloud storage if permitted
    if ([[defaults objectForKey:@"permittedToUseiCloud"] isEqualToString:@"YES"]){
        return [cloudStore stringForKey:key];
    }
    // iCloud use not permitted so use local default storage
    else {
        return [defaults objectForKey:key];
    }
}

// Read NSDictionary from local defaults or iCloud defaults
- (NSDictionary *)getDictionaryFromDefaults:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUbiquitousKeyValueStore *cloudStore = [NSUbiquitousKeyValueStore defaultStore];
    // Use iCloud storage if permitted
    if ([[defaults objectForKey:@"permittedToUseiCloud"] isEqualToString:@"YES"]){
        return [cloudStore dictionaryForKey:key];
    }
    // iCloud use not permitted so use local default storage
    else {
        return [defaults dictionaryForKey:key];
    }
}

// Read NSMutableArray from local defaults or iCloud defaults
- (NSMutableArray *)getArrayFromDefaults:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSUbiquitousKeyValueStore *cloudStore = [NSUbiquitousKeyValueStore defaultStore];
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:1];
    // Use iCloud storage if permitted
    if ([[defaults objectForKey:@"permittedToUseiCloud"] isEqualToString:@"YES"]){
        returnArray = [NSMutableArray arrayWithArray:[cloudStore arrayForKey:key]];
        return returnArray;
    }
    // iCloud use not permitted so use local default storage
    else {
        returnArray = [NSMutableArray arrayWithArray:[defaults arrayForKey:key]];
        return returnArray;
    }
}


//
// Methods specific to editMode and autoGeneration
//
- (BOOL)editModeIsEnabled {
    if (FORCE_PUZZLE_EDITOR_AUTOGEN){
        return YES;
    }
    else if (ENABLE_PUZZLE_EDITOR &&
             [[self getStringFromDefaults:@"editModeEnabled"] isEqualToString:@"YES"]){
        return YES;
    }
    else {
        return NO;
    }
}

- (BOOL)autoGenIsEnabled {
    if (ENABLE_PUZZLE_EDITOR == NO){
        return NO;
    }
    if (FORCE_PUZZLE_EDITOR_AUTOGEN){
        return YES;
    }
    id autoGen = nil;
    autoGen = [self getStringFromDefaults:@"autoGenEnabled"];
    if (autoGen == nil){
        return NO;
    }
    else {
        if ([autoGen isEqualToString:@"YES"]){
            return YES;
        }
        else {
            return NO;
        }
    }
}


//
// Methods to handle tracking of Daily Puzzle progress
//
- (void)saveDailyPuzzleNumber:(unsigned int)puzzleNumber {
    [self setObjectInDefaults:[NSNumber numberWithUnsignedInt:puzzleNumber] forKey:@"dailyPuzzleNumber"];
}

- (int)fetchDailyPuzzleNumber {
    NSNumber *NSNumberDailyPuzzleNumber = [self getObjectFromDefaults:@"dailyPuzzleNumber"];
    if (NSNumberDailyPuzzleNumber == nil){
        return -1;
    }
    else {
        return [NSNumberDailyPuzzleNumber intValue];
    }
}

- (void)saveDailyPuzzle:(unsigned int)puzzleNumber puzzle:(NSMutableDictionary *)puzzle {
    NSMutableDictionary *existingDailyPuzzle = [self fetchDailyPuzzle:puzzleNumber];
    unsigned int storedDailyPuzzleNumber = [self fetchDailyPuzzleNumber];
    if (existingDailyPuzzle == nil || puzzleNumber == storedDailyPuzzleNumber){
        [self setObjectInDefaults:puzzle forKey:@"dailyPuzzle"];
    }
}

- (NSMutableDictionary *_Nullable)fetchDailyPuzzle:(unsigned int)puzzleNumber {
    NSMutableDictionary *dailyPuzzle = nil;
    dailyPuzzle = [self getObjectFromDefaults:@"dailyPuzzle"];
    return dailyPuzzle;
}


//
// Methods to handle tracking Free and Paid Pack puzzle progress within puzzlePacksArray
//

// Initializes NSMutableArray PuzzlePacksProgress and puzzlePacksProgressPuzzleNumbers
// Store in NSUbiquitousKeyValueStore or NSDefaults
// puzzlePacksProgressPuzzleNumbersDictionary stores the current puzzle number for each pack
// puzzlePacksProgressDictionary stores the current puzzle for each pack
- (void)initializePuzzlePacksProgress {
    // Populate NSMutableArray puzzlePacksProgress from gameDictionaries
    NSMutableArray *puzzlePacksArray = [NSMutableArray arrayWithCapacity:1];
    NSMutableDictionary *puzzlePack = [NSMutableDictionary dictionaryWithCapacity:1];
    NSMutableArray *puzzlesArray = [NSMutableArray arrayWithCapacity:1];
    
    NSMutableDictionary *puzzlePacksProgressPuzzleNumbersDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
    NSMutableDictionary *puzzlePacksProgressDictionary = [NSMutableDictionary dictionaryWithCapacity:1];

    if (gameDictionaries != nil){
        puzzlePacksArray = [gameDictionaries objectForKey:kPuzzlePacksArray];
        if (puzzlePacksArray != nil){
            NSEnumerator *arrayEnum = [puzzlePacksArray objectEnumerator];
            unsigned packNumber = 0;
            unsigned packIndex = 0;
            while (puzzlePack = [arrayEnum nextObject]){
                packNumber = packIndex;
                NSString *packIndexString = [NSString stringWithFormat:@"%06d", packNumber];
                [puzzlePacksProgressPuzzleNumbersDictionary setObject:[NSNumber numberWithInt:0]
                                                               forKey:packIndexString];
                puzzlesArray = [puzzlePack objectForKey:@"puzzles"];
                if (puzzlesArray){
                    [puzzlePacksProgressDictionary setObject:[puzzlesArray objectAtIndex:0]
                                                      forKey:packIndexString];
                }
                else {
                    DLog("initializePuzzlePacksProgress: puzzle array not found in puzzlePacksArray.plist");
                }
                packIndex++;
            }
        }
        // Save the NSMutableDictionary puzzlePacksProgress
        [self setObjectInDefaults:puzzlePacksProgressPuzzleNumbersDictionary
                           forKey:@"PacksProgressNumbersDictionary"];
        [self setObjectInDefaults:puzzlePacksProgressDictionary
                           forKey:@"PacksProgressPuzzlesDictionary"];
        [self setObjectInDefaults:[NSNumber numberWithUnsignedInt:0] forKey:@"currentPack"];
        DLog("initializePuzzlePacksProgress: success");
    }
}


//
// Methods that support Puzzle Editing using an NSMutableDictionary pack of puzzles in Defaults
//
// There is only one pack stored as an NSMutableDictionary of NSMutableDictionary puzzles
// The pack NSMutableDictionary maybe be fetched or written all at once
// Individual pack puzzles may be fetched or written by specifying their index
// Pack puzzle indices begin with index 0
// A pointer to the "current" pack puzzle index may be fetched as an int (-1 means fetch fails)
// A pointer to the "current" pack puzzle index may be written as an unsigned int
//

// Fetch the entire pack from Defaults if possible.
// If the pack is not in Defaults then retrieve a version from the main bundle.
// The pack is an NSMutableDictionary object containing the following:
//     key=@"AppStorePackCost",  value=Number of cents, e.g. 99 means $0.99
//     key=@"pack_name",   value=String with pack name text
//     key=@"pack_number",   value=number with identifying pack number
//     key=@"puzzles",  value=NSArray of puzzles of type NSDictionary
- (NSMutableDictionary *)fetchEditedPack {
    // Attempt to fetch the editedPuzzlePack from Defaults
    NSMutableDictionary *pack = nil;
    pack = [self fetchEditedPackFromDefaults];
    if (pack != nil){
        return pack;
    }
    // Otherwise fetch a skeleton version from the main bundle
    else {
        pack = [self fetchEditedPackFromMainBundle];
        if (pack != nil){
            return pack;
        }
        else {
            return nil;
        }
    }
}

// Fetch the entire editedPuzzlePack from Defaults if present
- (NSMutableDictionary *)fetchEditedPackFromDefaults {
    NSMutableDictionary *pack = nil;
    pack = [NSMutableDictionary dictionaryWithDictionary:[self getObjectFromDefaults:@"editedPuzzlePack"]];
    // Empty pack returned as nil
    if ([pack count] > 0){
        return pack;
    }
    else {
        return nil;
    }
}

// Fetch a skeleton editedPuzzlePack from the main bundle
- (NSMutableDictionary *)fetchEditedPackFromMainBundle {
    NSMutableDictionary *pack = nil;
    NSString *filePath = [self filePathMainBundle:@"editedPuzzlePack.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        pack = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
        return pack;
    }
    else {
        return nil;
    }
}

- (BOOL)saveEditedPack:(NSMutableDictionary *)packDictionary {
    BOOL success1 = [self saveEditedPackToDefaults:packDictionary];
    BOOL success2 = [self saveEditedPackToFile:packDictionary];
    if (success1 && success2){
        return YES;
    }
    else {
        return NO;
    }
}

// Save the entire pack to Defaults, overwriting the current pack in the process.
- (BOOL)saveEditedPackToDefaults:(NSMutableDictionary *)packDictionary {
    BOOL success = NO;
    if (packDictionary != nil){
        [self setObjectInDefaults:packDictionary forKey:@"editedPuzzlePack"];
        success = YES;
    }
    return success;
}

// Save an array of puzzles to puzzleArray.plist, overwriting the current array in the process.
- (BOOL)saveArrayOfPuzzlesToFile:(NSMutableArray *)puzzleArray fileName:(NSString *)fileName {
    // Write the puzzle array to @"puzzleArray.plist"
    BOOL retCode = FALSE;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    if (filePath){
        DLog("saveArrayOfPuzzlesToFile:  cp %s ~/dev/BeamedLevels\n", [filePath UTF8String]);
        retCode = [puzzleArray writeToFile:filePath atomically:YES];
    }
    return retCode;
}

// Save the entire pack to File, overwriting the current pack in the process.
- (BOOL)savePuzzlePackDictionaryToFile:(NSMutableDictionary *)pack  fileName:(NSString *)fileName {
    // Write the puzzle to @"editedPuzzlePack.plist"
    BOOL retCode = FALSE;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    if (filePath){
        DLog("savePuzzlePackDictionaryToFile:  cp %s ~/dev/BeamedLevels\n", [filePath UTF8String]);
        retCode = [pack writeToFile:filePath atomically:YES];
    }
    return retCode;
}

// Save the entire pack to File, overwriting the current pack in the process.
- (BOOL)saveEditedPackToFile:(NSMutableDictionary *)pack {
    // Write the puzzle to @"editedPuzzlePack.plist"
    BOOL retCode = FALSE;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"editedPuzzlePack.plist"];
    if (filePath){
        DLog("saveEditedPackToFile:  cp %s ~/dev/BeamedLevels\n", [filePath UTF8String]);
        retCode = [pack writeToFile:filePath atomically:YES];
    }
    return retCode;
}

// Fetch an individual puzzle as an NSMutableDictionary from the pack currently stored in Defaults.
// If the pack does not exist return nil
// If the puzzle corresponding to index does not exist then return nil
- (NSMutableDictionary *)fetchEditedPuzzleFromPackInDefaults:(unsigned int)index {
    NSMutableDictionary *pack = nil;
    NSMutableDictionary *puzzle = nil;
    pack = [self fetchEditedPack];
    if (pack == nil){
        return nil;
    }
    else if ([pack count] == 0){
        return nil;
    }
    else {
        NSMutableArray *puzzlesArray = [NSMutableArray arrayWithArray:[pack objectForKey:@"puzzles"]];
        if (puzzlesArray){
            puzzle = [puzzlesArray objectAtIndex:index];
        }
    }
    return puzzle;
}

// Replace an individual puzzle as an NSMutableDictionary in the pack currently stored in Defaults.
// If the pack does not exist return NO, else return YES
- (BOOL)replaceEditedPuzzleInPackInDefaults:(unsigned int)index puzzle:(NSMutableDictionary *)puzzle {
    NSMutableDictionary *packDictionary = nil;
    packDictionary = [self fetchEditedPack];
    if (packDictionary == nil){
        return NO;
    }
    else {
        NSMutableArray *puzzlesArray = [NSMutableArray arrayWithArray:[packDictionary objectForKey:@"puzzles"]];
        if (puzzlesArray){
            [puzzlesArray setObject:puzzle atIndexedSubscript:index];
            [packDictionary setObject:puzzlesArray forKey:@"puzzles"];
            [self saveEditedPackToDefaults:packDictionary];
            return YES;
        }
        else {
            return NO;
        }
    }
}

// Fetch an index corresponding to a puzzle number within the pack
// May be used to save state across PE sessions
- (int)fetchEditedPuzzleIndexFromDefaults {
    int index = -1;
    id object = NULL;
    object = [self getObjectFromDefaults:@"editedPuzzleIndex"];
    if (object == NULL){
        index = -1;
    }
    else {
        index = [object unsignedIntValue];
    }
    return index;
}

// Save an index corresponding to a puzzle number within the pack
// May be used to save state across PE sessions
- (void)saveEditedPuzzleIndexToDefaults:(unsigned int)index {
    [self setObjectInDefaults:[NSNumber numberWithUnsignedInt:index] forKey:@"editedPuzzleIndex"];
}


//
// Puzzle plist file I/O methods
//

- (BOOL)fetchTextureFilesFromPlist:(NSString *)key textures:(NSMutableArray *)textures{
    BOOL retVal = NO;
    // See if file exists in the document directory first
    NSMutableArray *textureFilenameArray = nil;
    NSString *filePath = [self filePathDocumentsDirectory:key];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        textureFilenameArray = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
    }
    else {
        // Retrieve the file from the main bundle
        filePath = [self filePathMainBundle:key];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            textureFilenameArray = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
        }
    }
    if (textureFilenameArray != nil){
        if ([self parseTexturesFromPlist:textureFilenameArray textures:textures]){
            retVal = YES;
        }
    }
    return retVal;
}

- (BOOL)parseTexturesFromPlist:(NSMutableArray *)textureFilenameArray textures:(NSMutableArray *)textures
{
    BOOL success = YES;
    NSEnumerator *arrayEnum = [textureFilenameArray objectEnumerator];
    id textureData = nil;
    NSMutableString *fileName = nil;
    while (fileName = [arrayEnum nextObject]){
        // Check if the filename corresponds to a Texture that has already been loaded
        BOOL foundit = NO;
        if ([loadedTextureFiles count] > 0){
            for (textureData in loadedTextureFiles) {
                if ([textureData isKindOfClass:[TextureData class]]){
                    if ([[textureData valueForKey:@"textureFilename"] isEqualToString:fileName]) {
                        foundit = YES;
                        [textures addObject:textureData];       // Add a reference to the the TextureData object that has already been loaded
                    }
                }
            }
        }
        // If we did not find the file name in loadedTextureFiles then read the png file and create a new MTLTexture
        if (!foundit) {
            NSArray *fileNameComponents = [fileName componentsSeparatedByString:@"."];
            if ([self loadMetalTextureFromFile:[fileNameComponents objectAtIndex:0] withExtension:[fileNameComponents objectAtIndex:1]]) {
                TextureData *newElement = [[TextureData alloc] init];
                newElement.textureFilename = [NSString stringWithString:[fileNameComponents objectAtIndex:0]];
                newElement.texture = _texture;
                [textures addObject:newElement];    // Add the newly loaded TextureData object to the textures array...
                [loadedTextureFiles addObject:newElement];          // ...and also to the loadedTextureFiles
            }
            else {
                DLog("Loading %s failed", [fileName UTF8String]);
                return NO;
            }
        }

        
        
    }
    
    
//    // Scan the first line to get the number of textures
//    sscanf([configStrings[0] UTF8String], "%s %d", fname, &ntextures);
//
//    // Else fetch the texture number, file name and file extension and load the texture
//    int ii = 1;
//    int jj;
//    while (ii < ntextures+1) {
//        sscanf([configStrings[ii] UTF8String], "%d %s %s", &jj, fname, fext);
//        sprintf(filename, "%s.%s", fname, fext);
//        if (strcmp(fname, "nil") != 0) {
//            BOOL foundit = NO;
//            // Check if the filename corresponds to a Texture that has already been loaded
//            if ([loadedTextureFiles count] > 0)
//                for (id TextureData in loadedTextureFiles) {
//                    if ([TextureData isKindOfClass:[TextureData class]])
//                        if ([[TextureData valueForKey:@"textureFilename"] isEqualToString:[NSString stringWithCString:filename encoding:NSASCIIStringEncoding]]) {
//                            foundit = YES;
//                            [textures addObject:TextureData];       // Add a reference to the the TextureData object that has already been loaded
//                        }
//                }
//
//            // If we did not find the file name in loadedTextureFiles then read the png file and create a new MTLTexture
//            if (!foundit) {
//                if ([self loadMetalTextureFromFile:[NSString stringWithCString:fname encoding:NSASCIIStringEncoding] withExtension:[NSString stringWithCString:fext encoding:NSASCIIStringEncoding]]) {
//                    TextureData *newElement = [[TextureData alloc] init];
//                    newElement.textureFilename = [[NSString alloc] initWithString:[NSString stringWithCString:filename encoding:NSASCIIStringEncoding]];
//                    newElement.texture = _texture;
//                    [textures addObject:newElement];    // Add the newly loaded TextureData object to the textures array...
//                    [loadedTextureFiles addObject:newElement];          // ...and also to the loadedTextureFiles
//                }
//                else {
//                    DLog("Loading %s.%s failed", fname, fext);
//                    return NO;
//                }
//            }
//
//        } else {
//            TextureData *newElement = [[TextureData alloc] init];
//            newElement.textureFilename = @"nil";
//            [textures addObject:newElement];
//        }
//        ii++;
    return success;
}

- (NSMutableDictionary *)fetchPackDictionaryFromPlist:(NSString *)key {
    // See if file exists in the document directory first
    NSMutableDictionary *packDictionary = nil;
    NSString *filePath = [self filePathDocumentsDirectory:key];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        packDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
    }
    else {
        // Retrieve the file from the main bundle
        filePath = [self filePathMainBundle:key];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            packDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
        }
    }
    return packDictionary;
}

- (int)countNumberOfPacksInArray:(NSString *)key{
    int numberOfPacks = -1;
    NSMutableArray *array = nil;
    array = [self fetchPacksArray:key];
    if (array != nil){
        numberOfPacks = (int)[array count];
    }
    return numberOfPacks;
}

- (int)countNumberOfPuzzlesWithinPack:(int)packIndex InArray:(NSString *)key{
    int packLength = -1;
    NSMutableArray *puzzlePacksArray = nil, *puzzleArray = nil;
    NSMutableDictionary *puzzlePackDict = nil;
    puzzlePacksArray = [self fetchPacksArray:key];
    if (puzzlePacksArray != nil && [puzzlePacksArray count] > packIndex){
        puzzlePackDict = [puzzlePacksArray objectAtIndex:packIndex];
        if (puzzlePackDict != nil){
            puzzleArray = [puzzlePackDict objectForKey:@"puzzles"];
            if (puzzleArray != nil){
                packLength = [puzzleArray count];
                return packLength;
            }
        }
    }
    return packLength;
}



// Fetch an NSArray of packs from the documents directory or main bundle
- (NSMutableArray *)fetchPacksArray:(NSString *)key {
    // See if file exists in the document directory first
    NSMutableArray *array = nil;
    NSString *filePath = [self filePathDocumentsDirectory:key];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        array = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
    }
    else {
        // Retrieve the file from the main bundle
        filePath = [self filePathMainBundle:key];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            array = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
        }
    }
    return array;
}

- (NSString *)filePathDocumentsDirectory:(NSString *)key {
    NSString *filePath = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    if ([key isEqualToString:kPuzzlePacksArray]){
        filePath = [documentsDirectory stringByAppendingPathComponent:kPuzzlePacksArray];
    }
    else if ([key isEqualToString:@"dailyPuzzlesPackDictionary.plist"]){
        filePath = [documentsDirectory stringByAppendingPathComponent:kDailyPuzzlesPackDictionary];
    }
    else if ([key isEqualToString:@"demoPuzzlePackDictionary.plist"]){
        filePath = [documentsDirectory stringByAppendingPathComponent:kDemoPuzzlePackDictionary];
    }
    else if ([key isEqualToString:@"paidHintPacksArray.plist"]){
        filePath = [documentsDirectory stringByAppendingPathComponent:kPaidHintsPacks];
    }
    else if ([key isEqualToString:@"alternateIcons.plist"]){
        filePath = [documentsDirectory stringByAppendingPathComponent:kAltIconsPacks];
    }
    else if ([key isEqualToString:@"backgroundTextures.plist"]){
        filePath = [documentsDirectory stringByAppendingPathComponent:kBackgroundTextures];
    }
    else if ([key isEqualToString:@"backgroundAnimationTextures.plist"]){
        filePath = [documentsDirectory stringByAppendingPathComponent:kBackgroundAnimationTextures];
    }
    else if ([key isEqualToString:@"jewelTextures.plist"]){
        filePath = [documentsDirectory stringByAppendingPathComponent:kJewelTextures];
    }
    return filePath;
}

- (NSString *)filePathMainBundle:(NSString *)key {
    NSString *path = nil;
    if ([key isEqualToString:kPuzzlePacksArray]){
        path = [[NSBundle mainBundle] pathForResource:@"puzzlePacksArray" ofType:@"plist"];
    }
    else if ([key isEqualToString:@"dailyPuzzlesPackDictionary.plist"]){
        path = [[NSBundle mainBundle] pathForResource:@"dailyPuzzlesPackDictionary" ofType:@"plist"];
    }
    else if ([key isEqualToString:@"demoPuzzlePackDictionary.plist"]){
        path = [[NSBundle mainBundle] pathForResource:@"demoPuzzlePackDictionary" ofType:@"plist"];
    }
    else if ([key isEqualToString:@"editedPuzzlePack.plist"]){
        path = [[NSBundle mainBundle] pathForResource:@"editedPuzzlePack" ofType:@"plist"];
    }
    else if ([key isEqualToString:@"paidHintPacksArray.plist"]){
        path = [[NSBundle mainBundle] pathForResource:@"paidHintPacksArray" ofType:@"plist"];
    }
    else if ([key isEqualToString:@"alternateIcons.plist"]){
        path = [[NSBundle mainBundle] pathForResource:@"alternateIcons" ofType:@"plist"];
    }
    else if ([key isEqualToString:@"backgroundTextures.plist"]){
        path = [[NSBundle mainBundle] pathForResource:@"backgroundTextures" ofType:@"plist"];
    }
    else if ([key isEqualToString:@"backgroundAnimationTextures.plist"]){
        path = [[NSBundle mainBundle] pathForResource:@"backgroundAnimationTextures" ofType:@"plist"];
    }
    else if ([key isEqualToString:@"jewelTextures.plist"]){
        path = [[NSBundle mainBundle] pathForResource:@"jewelTextures" ofType:@"plist"];
    }
    return path;
}

//
// Pack and Puzzle Handling Methods
//

- (BOOL)puzzleIsEmpty:(NSMutableDictionary *)puzzle {
    BOOL empty = NO;
    NSMutableArray *arrayOfJewelsDictionaries = [puzzle objectForKey:@"arrayOfJewelsDictionaries"];
    NSMutableArray *arrayOfLasersDictionaries = [puzzle objectForKey:@"arrayOfLasersDictionaries"];
    if (arrayOfJewelsDictionaries == nil || [arrayOfJewelsDictionaries count] == 0){
        empty = YES;
    }
    if (arrayOfLasersDictionaries == nil || [arrayOfLasersDictionaries count] == 0){
        empty = YES;
    }
    return empty;
}

-(BOOL)packHasBeenCompleted {
    if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
        unsigned int puzzlesLeft = [self queryNumberOfPuzzlesLeftInCurrentPack];
        if (puzzlesLeft < 1){
            return YES;
        }
        else {
            return NO;
        }
    }
    else if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
        NSMutableDictionary *demoPackDictionary = [self fetchPackDictionaryFromPlist:kDemoPuzzlePackDictionary];
        unsigned int currentPackLength = [self countPuzzlesWithinPack:demoPackDictionary];
        unsigned int currentPuzzleNumber = [self fetchDemoPuzzleNumber];
        // Note that puzzle numbers start at 0
        if (currentPuzzleNumber+1 >= currentPackLength){
            return YES;
        }
        else {
            return NO;
        }
    }
    else {
        return NO;
    }
}

-(unsigned int)countPuzzlesWithinPack:(NSMutableDictionary *)packDictionary {
    unsigned int numberOfPuzzles = 0;
    NSMutableArray *puzzleArray = [NSMutableArray arrayWithArray:[packDictionary objectForKey:@"puzzles"]];
    if (puzzleArray){
        numberOfPuzzles = (unsigned int)[puzzleArray count];
    }
    return numberOfPuzzles;
}

- (void)saveDemoPuzzleNumber:(unsigned int)puzzleNumber {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithUnsignedInt:puzzleNumber] forKey:@"demoPuzzleNumber"];
}

- (unsigned int)fetchDemoPuzzleNumber {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id puzzleNumberObject = nil;
    puzzleNumberObject = [defaults objectForKey:@"demoPuzzleNumber"];
    if (puzzleNumberObject == nil){
        return 0;
    }
    else {
        unsigned int puzzleNumber = [puzzleNumberObject unsignedIntValue];
        return puzzleNumber;
    }
}

- (unsigned int)fetchPackIndexForPackNumber:(unsigned int)packNumber{
    // PKH pack_number {
//    unsigned int packIndex = 0;
//    NSMutableArray *packsArray = [gameDictionaries objectForKey:kPuzzlePacksArray];
//    NSEnumerator *packsEnum = [packsArray objectEnumerator];
//    NSMutableDictionary *packDictionary;
//    while (packDictionary = [packsEnum nextObject]){
//        unsigned int pack_number = [[packDictionary objectForKey:@"pack_number"]intValue];
//        if (pack_number == packNumber){
//            return packIndex;
//        }
//        packIndex++;
//    }
//    return packIndex;
    return packNumber;
    // PKH pack_number }
}

- (unsigned int)fetchPackNumberForPackIndex:(unsigned int)packIndex{
    // PKH pack_number {
//    unsigned int packNumber = 0;
//    NSMutableArray *packsArray = [gameDictionaries objectForKey:kPuzzlePacksArray];
//    NSMutableDictionary *packDictionary;
//    packDictionary = [packsArray objectAtIndex:packIndex];
//    packNumber = [[packDictionary objectForKey:@"pack_number"]intValue];
//    return packNumber;
    return packIndex;
    // PKH pack_number }
}

- (unsigned int)fetchCurrentPackNumber {
    unsigned int currentPack = [[self getObjectFromDefaults:@"currentPack"] unsignedIntValue];
    return currentPack;
}

- (void)saveCurrentPackNumber:(unsigned int)packNumber {
    [self setObjectInDefaults:[NSNumber numberWithUnsignedInt:packNumber] forKey:@"currentPack"];
}

- (unsigned int)fetchCurrentPuzzleNumber {
    unsigned int currentPack = [[self getObjectFromDefaults:@"currentPack"] unsignedIntValue];
    unsigned int puzzleNumber = [self fetchCurrentPuzzleNumberForPack:currentPack];
    return puzzleNumber;
}

- (void)saveCurrentPuzzleNumber:(unsigned int)puzzleNumber {
    unsigned int currentPack = [[self getObjectFromDefaults:@"currentPack"] unsignedIntValue];
    [self saveCurrentPuzzleNumberForPack:currentPack puzzleNumber:puzzleNumber];
}

- (int)fetchCurrentAltIconNumber {
    // Return value of -1 means default icon
    if ([self getObjectFromDefaults:@"currentAltIconNumber"] == nil){
        return -1;
    }
    else {
        int currentAltIconNumber = [[self getObjectFromDefaults:@"currentAltIconNumber"] intValue];
        return currentAltIconNumber;
    }
}

- (void)saveCurrentAltIconNumber:(int)currentAltIconNumber {
    // Input value of -1 means default icon
    [self setObjectInDefaults:[NSNumber numberWithUnsignedInt:currentAltIconNumber] forKey:@"currentAltIconNumber"];
}

- (unsigned int)fetchCurrentPuzzleNumberForPack:(unsigned int)packNumber {
    NSMutableDictionary *puzzlePacksProgressPuzzleNumbersDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
    puzzlePacksProgressPuzzleNumbersDictionary = [self getObjectFromDefaults:@"PacksProgressNumbersDictionary"];
    unsigned int puzzleNumber = 0;
    NSString *packIndexString = [NSString stringWithFormat:@"%06d", packNumber];
    puzzleNumber = [[puzzlePacksProgressPuzzleNumbersDictionary objectForKey:packIndexString] unsignedIntValue];
    return puzzleNumber;
}

- (void)saveCurrentPuzzleNumberForPack:(unsigned int)packNumber puzzleNumber:(unsigned int)puzzleNumber {
    NSMutableDictionary *puzzlePacksProgressPuzzleNumbersDictionary = [NSMutableDictionary dictionaryWithDictionary:[self getObjectFromDefaults:@"PacksProgressNumbersDictionary"]];
    NSString *packIndexString = [NSString stringWithFormat:@"%06d", packNumber];
    NSNumber *puzzleNSNumber = [NSNumber numberWithUnsignedInt:puzzleNumber];
    [puzzlePacksProgressPuzzleNumbersDictionary setObject:puzzleNSNumber
                                                   forKey:packIndexString];
    [self setObjectInDefaults:puzzlePacksProgressPuzzleNumbersDictionary forKey:@"PacksProgressNumbersDictionary"];
}

- (void)saveCurrentPuzzleToPackGameProgress:(unsigned int)packNumber puzzle:(NSMutableDictionary *)puzzle {
    NSMutableDictionary *puzzlePacksProgressDictionary = [NSMutableDictionary dictionaryWithDictionary:[NSMutableDictionary dictionaryWithDictionary:[self getObjectFromDefaults:@"PacksProgressPuzzlesDictionary"]]];
    NSString *packNumberString = [NSString stringWithFormat:@"%06d", packNumber];
    [puzzlePacksProgressDictionary setObject:puzzle forKey:packNumberString];
    [self setObjectInDefaults:puzzlePacksProgressDictionary forKey:@"PacksProgressPuzzlesDictionary"];
}

- (unsigned int)queryNumberOfPuzzlesLeftInPack:(unsigned int)packNumber {
    unsigned int retVal = 0;
    unsigned int packIndex = [self fetchPackIndexForPackNumber:packNumber];
    unsigned int packLength = [self fetchPackLength:packIndex];
    unsigned int puzzleNumber = [self fetchCurrentPuzzleNumberForPack:packNumber];
    retVal = packLength - puzzleNumber;
    return retVal;
}

- (unsigned int)queryNumberOfPuzzlesLeftInCurrentPack {
    unsigned int currentPack = [self fetchCurrentPackNumber];
    unsigned int retVal = [self queryNumberOfPuzzlesLeftInPack:currentPack];
    return retVal;
}

- (unsigned int)fetchCurrentPackLength {
    unsigned int retVal = [self fetchPackLength:[self fetchPackIndexForPackNumber:[self fetchCurrentPackNumber]]];
    return retVal;
}

- (unsigned int)fetchPackLength:(unsigned int)packIndex {
    unsigned int packLength = 0;
    NSMutableArray *puzzlePacksArray = [NSMutableArray arrayWithCapacity:1];
    NSMutableDictionary *puzzlePackDict = [NSMutableDictionary dictionaryWithCapacity:1];
    NSMutableArray *puzzleArray = [NSMutableArray arrayWithCapacity:1];
    // Puzzle Packs top level object is NSArray
    if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
        if (gameDictionaries != nil){
            puzzlePacksArray = [gameDictionaries objectForKey:kPuzzlePacksArray];
            if (puzzlePacksArray != nil && [puzzlePacksArray count] > packIndex){
                puzzlePackDict = [puzzlePacksArray objectAtIndex:packIndex];
                if (puzzlePackDict){
                    puzzleArray = [puzzlePackDict objectForKey:@"puzzles"];
                    if (puzzleArray){
                        packLength = (unsigned int)[puzzleArray count];
                        return packLength;
                    }
                }
            }
        }
    }
    // Daily Puzzle top level object is NSDictionary
    else if (rc.appCurrentGamePackType == PACKTYPE_DAILY){
        if (gameDictionaries != nil){
            puzzlePackDict = [gameDictionaries objectForKey:kDailyPuzzlesPackDictionary];
            if (puzzlePackDict != nil){
                puzzleArray = [puzzlePackDict objectForKey:@"puzzles"];
                if (puzzleArray){
                    packLength = (unsigned int)[puzzleArray count];
                    return packLength;
                }
            }
        }
    }
    // Demo Puzzle top level object is NSDictionary
    else if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
        if (gameDictionaries != nil){
            puzzlePackDict = [gameDictionaries objectForKey:kDemoPuzzlePackDictionary];
            if (puzzlePackDict != nil){
                puzzleArray = [puzzlePackDict objectForKey:@"puzzles"];
                if (puzzleArray){
                    packLength = (unsigned int)[puzzleArray count];
                    return packLength;
                }
            }
        }
    }
    else {
        DLog("fetchPackLength: rc.appCurrentGamePackType unknown");
    }
    return 0;
}

- (NSMutableDictionary *)fetchPuzzlePack:(unsigned int)packNumber {
    NSMutableArray *puzzlePacksArray = [NSMutableArray arrayWithCapacity:1];
    NSMutableDictionary *puzzlePack = [NSMutableDictionary dictionaryWithCapacity:1];
    unsigned int packIndex = [self fetchPackIndexForPackNumber:packNumber];
    if (gameDictionaries != nil){
        puzzlePacksArray = [gameDictionaries objectForKey:kPuzzlePacksArray];
        if (puzzlePacksArray != nil && [puzzlePacksArray count] > packIndex){
            puzzlePack = [puzzlePacksArray objectAtIndex:packIndex];
        }
    }
    return puzzlePack;
}

- (NSMutableDictionary *)fetchCurrentPuzzleFromPackGameProgress:(unsigned int)packNumber {
    NSMutableDictionary *puzzlePacksProgressDictionary = nil;
    puzzlePacksProgressDictionary = [self getObjectFromDefaults:@"PacksProgressPuzzlesDictionary"];
    if (puzzlePacksProgressDictionary != nil &&
        [puzzlePacksProgressDictionary count] > 0){
        NSString *packIndexString = [NSString stringWithFormat:@"%06d", packNumber];
        NSMutableDictionary *currentPuzzle = nil;
        currentPuzzle = [puzzlePacksProgressDictionary objectForKey:packIndexString];
        if (currentPuzzle != nil &&
            [currentPuzzle count] > 0){
            return currentPuzzle;
        }
    }
    return nil;
}

- (NSMutableDictionary *)fetchCurrentPuzzleFromPackDictionary:(unsigned int)packNumber {
    NSMutableDictionary *retVal = nil;
    NSMutableDictionary *packDictionary = nil;
    unsigned int currentPuzzleNumber = [self fetchCurrentPuzzleNumber];
    unsigned int packIndex = [self fetchPackIndexForPackNumber:packNumber];
    NSMutableArray *puzzlePacksArray = [NSMutableArray arrayWithCapacity:1];
    if (gameDictionaries != nil){
        puzzlePacksArray = [gameDictionaries objectForKey:kPuzzlePacksArray];
        if (puzzlePacksArray != nil && [puzzlePacksArray count] > packIndex){
            packDictionary = [puzzlePacksArray objectAtIndex:packIndex];
            NSMutableArray *puzzleArray = [NSMutableArray arrayWithArray:[packDictionary objectForKey:@"puzzles"]];
            retVal = [puzzleArray objectAtIndex:currentPuzzleNumber];
        }
    }
    return retVal;
}


//
// Music and Sound handling
//

- (void)playSound:(AVAudioPlayer *)player {
    if ([[self getStringFromDefaults:@"soundsEnabled"] isEqualToString:@"YES"] && player != nil){
        [player play];
    }
}

- (void)playMusicLoop {
    // Play appropriate music when playing a Puzzle
    if ([[self getStringFromDefaults:@"musicEnabled"] isEqualToString:@"YES"]){
        [loop1Player play];
    }
}

- (void)playMusicLoop:(AVAudioPlayer *)player {
    if ([[self getStringFromDefaults:@"musicEnabled"] isEqualToString:@"YES"] &&
        player != nil){
        // If player is already playing then leave it well enough alone
        if (!player.isPlaying){
            if (player == loop1Player){
                [loop2Player pause];
                [loop3Player pause];
            }
            else if (player == loop2Player){
                [loop1Player pause];
                [loop3Player pause];
            }
            else if (player == loop3Player){
                [loop1Player pause];
                [loop2Player pause];
            }
            [player play];
        }
    }
}

- (void)playPuzzleCompleteSoundEffect {
    if (rc.appCurrentGamePackType != PACKTYPE_DEMO){
        [loop2Player setVolume:0.10 fadeDuration:0.0];
        switch([self fetchCurrentPuzzleNumberForPack:[self fetchCurrentPackNumber]] % 3){
            case 0:{
                [self playSound:puzzleComplete1Player];
                break;
            }
            case 1:{
                [self playSound:puzzleComplete2Player];
                break;
            }
            case 2:
            default:{
                [self playSound:puzzleComplete3Player];
                break;
            }
        }
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    DLog("audioPlayerDidFinishPlaying");
    if (player == puzzleComplete1Player ||
        player == puzzleComplete2Player ||
        player == puzzleComplete3Player){
        if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
            [loop1Player setVolume:1.0 fadeDuration:0.0];
        }
        else {
            [loop2Player setVolume:1.0 fadeDuration:0.0];
        }
    }
}

- (void)playLaserSound {
    AVAudioPlayer *player;
    if (laserSoundFlip){
        player = laser1Player;
    }
    else {
        player = laser2Player;
    }
    laserSoundFlip = !laserSoundFlip;
    if ([[self getStringFromDefaults:@"soundsEnabled"] isEqualToString:@"YES"] && player != nil){
        [player play];
    }
}


//
// ***** Texture and Animation File Processing happens here *****
//
// Find lines within a text string which:
//    1. are newline-terminated
//    2. do not begin with the comment characters '//'
// If such a line is found return a pointer to its first character as well as a count of characters (including the newline character)
// Lines which begin with '//' cause a return value of zero
int getTextureAndAnimationLine(char *instring, char *outstring, int sp, int max, BOOL *commentLine)
{
    int ii = 0;
    while (ii != max) {
        if (instring[sp+ii] == '\n')
            break;
        ii++;
    }
    outstring = instring+sp;        // outstring points to the start of the newline-terminated string
    
    if (instring[sp]=='/' && instring[sp+1]=='/') {
        *commentLine = YES;                // comment string so *commentLine = YES
    }
    else {
        *commentLine = NO;                // not comment string so *commentLine = NO
    }
    return ii+1;                    // return the number of characters in the string
}

- (BOOL)initAllTextures:(nonnull MTKView *)mtkView metalRenderer:(BMDRenderer *)metalRenderer {
    BOOL success = YES;
    // Read Tile animations configuration file and set up data structure of animation names
    _device = mtkView.device;
    view = mtkView;
    
    loadedTextureFiles = [NSMutableArray arrayWithCapacity:1];
    backgroundTextures = [NSMutableArray arrayWithCapacity:1];
    backgroundAnimationContainers = [NSMutableArray arrayWithCapacity:1];
    jewelTextures = [NSMutableArray arrayWithCapacity:1];
    tileAnimationContainers = [NSMutableArray arrayWithCapacity:1];
    beamAnimationContainers = [NSMutableArray arrayWithCapacity:1];
    ringAnimationContainers = [NSMutableArray arrayWithCapacity:1];
    logoAnimationContainers = [NSMutableArray arrayWithCapacity:1];

    if ((tileAnimationContainers = [self fetchAnimationDataFromPlist:@"tileAnimations" fext:@"plist" animationContainers:tileAnimationContainers]) != nil)
        DLog("Tile animation initialization complete.\n");
    else {
        DLog("Tile animation initialization failed.\n");
        success = NO;
    }

    if ((beamAnimationContainers = [self fetchAnimationDataFromPlist:@"beamAnimations" fext:@"plist" animationContainers:beamAnimationContainers]) != nil)
        DLog("Beam animation initialization complete.\n");
    else {
        DLog("Beam animation initialization failed.\n");
        success = NO;
    }

    if ((ringAnimationContainers = [self fetchAnimationDataFromPlist:@"ringAnimations" fext:@"plist" animationContainers:ringAnimationContainers]) != nil)
        DLog("Ring animation initialization complete.\n");
    else {
        DLog("Ring animation initialization failed.\n");
        success = NO;
    }
    
    if ((logoAnimationContainers = [self fetchAnimationDataFromPlist:@"logoAnimations" fext:@"plist" animationContainers:logoAnimationContainers]) != nil)
        DLog("Logo animation initialization complete.\n");
    else {
        DLog("Logo animation initialization failed.\n");
        success = NO;
    }
    
    // Read Background textures from plist
    if ([self fetchTextureFilesFromPlist:@"backgroundTextures.plist" textures:backgroundTextures])
        DLog("Background textures loaded from plist.\n");
    else {
        DLog("Error: Unable to load Background textures from plist.\n");
        success = NO;
    }
    
    // Read Jewel textures from plist
    if ([self fetchTextureFilesFromPlist:@"jewelTextures.plist" textures:jewelTextures])
        DLog("Jewel textures loaded from plist.\n");
    else {
        DLog("Error: Unable to load Jewel textures from plist.\n");
        success = NO;
    }
    
    return success;
}

// Find lines within a text NSString which:
//    1. are newline-terminated
//    2. do not begin with the comment characters '//'
void getTextureAndAnimationLineWithinNSString(NSMutableString *inString, NSMutableString *currentLine, NSMutableString *remainingString, BOOL *commentLine) {
    int ii = 0;
    while (ii < [inString length]) {
        if ([inString characterAtIndex:ii] == '\n')
            break;
        ii++;
    }
    [currentLine setString:[inString substringToIndex:ii+1]];              // currentLine includes the newline character
    [remainingString setString:[inString substringFromIndex:ii+1]];        // remainingString is what is left after the currentLine is removed
    
    if ([currentLine characterAtIndex:0]=='/' && [currentLine characterAtIndex:1]=='/') {
        *commentLine = YES;                // comment string so *commentLine = YES
    }
    else {
        *commentLine = NO;                // not comment string so *commentLine = NO
    }
}

- (BOOL)loadMetalTextureFromFile:(NSString *)name withExtension:(NSString *)ext {
    NSURL *imageFileLocation = [[NSBundle mainBundle] URLForResource:name withExtension:ext];
    MTKTextureLoader *loader = [[MTKTextureLoader alloc] initWithDevice: _device];
    if ([ext isEqualToString:@"png"]) {
        _texture = [loader newTextureWithContentsOfURL:imageFileLocation options:nil error:nil];
        if (!_texture)
            return FALSE;
        else
            return TRUE;
    }
    else {
//        DLog("Invalid file extensiom %s", ext.UTF8String);
        return FALSE;
    }
}

- (NSMutableArray *)fetchAnimationDataFromPlist:(NSString *)fname fext:(NSString *)fext animationContainers:(NSMutableArray *)animationContainers
{
    // See if file exists in the document directory first
    NSMutableArray *textureFilenameArray = nil;
    // Get the path to the configuration file.
    NSString *filePath = [[NSBundle bundleForClass:[self class] ] pathForResource:fname ofType:fext ];
    textureFilenameArray = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
    if (textureFilenameArray != nil){
        if ((animationContainers = [self parseAnimationsFromPlist:textureFilenameArray animationContainers:animationContainers]) != nil){
            return animationContainers;
        }
    }
    return nil;
}

- (NSMutableArray *)parseAnimationsFromPlist:(NSMutableArray *)textureFilenameArray animationContainers:(NSMutableArray *)animationContainers{
    int containerIndex, angleIndex, animationIndex, frameIndex;
    //
    // Process the Animation Containers
    //
    NSString *trimmedConfigString;

    NSEnumerator *containerEnum = nil, *angleEnum = nil, *animationEnum = nil, *frameEnum = nil;
    NSMutableArray *containerArray = [NSMutableArray array];
    NSMutableArray *angleArray = [NSMutableArray array];
    NSMutableArray *animationArray = [NSMutableArray array];
    NSMutableArray *frameArray = [NSMutableArray array];
    NSString *textureFilename = [NSString string];
    
    for (containerIndex = 0; containerIndex < [textureFilenameArray count]; containerIndex++){
        if ((angleArray = [textureFilenameArray objectAtIndex:containerIndex]) != nil){
            for (angleIndex = 0; angleIndex < [angleArray count]; angleIndex++){
                if ((animationArray = [angleArray objectAtIndex:angleIndex]) != nil){
                    for (animationIndex = 0; animationIndex < [animationArray count]; animationIndex++){
                        if ((frameArray = [animationArray objectAtIndex:animationIndex]) != nil){
                            for (frameIndex = 0; frameIndex < [frameArray count]; frameIndex++){
                                if ((textureFilename = [frameArray objectAtIndex:frameIndex]) != nil){
//                                    DLog("textureFilename = %s", [textureFilename UTF8String]);
                                    if (![textureFilename isEqualToString:@"NULL"]){
                                        BOOL foundit = NO;
                                        // Check if the filename corresponds to a Texture that has already been loaded
                                        if ([loadedTextureFiles count] > 0){
                                            for (id TextureData in loadedTextureFiles){
                                                if ([TextureData isKindOfClass:[TextureData class]]){
                                                    if ([[TextureData valueForKey:@"textureFilename"] isEqualToString:textureFilename]) {
                                                        foundit = YES;
                                                        [frameArray replaceObjectAtIndex:frameIndex withObject:TextureData];
                                                        [animationArray replaceObjectAtIndex:animationIndex withObject:frameArray];
                                                        [angleArray replaceObjectAtIndex:angleIndex withObject:animationArray];
                                                        [textureFilenameArray replaceObjectAtIndex:containerIndex withObject:angleArray];
                                                    }
                                                }
                                            }
                                        }
                                        // If we did not find the file name in loadedTextureFiles then read the png file and create a new MTLTexture
                                        if (!foundit) {
                                            NSArray *fileNameComponents = [textureFilename componentsSeparatedByString:@"."];
                                            if ([self loadMetalTextureFromFile:[fileNameComponents objectAtIndex:0] withExtension:[fileNameComponents objectAtIndex:1]]) {
                                                TextureData *newElement = [[TextureData alloc] init];
                                                newElement.textureFilename = [[NSString alloc] initWithString:textureFilename];
                                                newElement.texture = _texture;
                                                [loadedTextureFiles addObject:newElement];
                                                [frameArray replaceObjectAtIndex:frameIndex withObject:newElement];
                                                [animationArray replaceObjectAtIndex:animationIndex withObject:frameArray];
                                                [angleArray replaceObjectAtIndex:angleIndex withObject:animationArray];
                                                [textureFilenameArray replaceObjectAtIndex:containerIndex withObject:angleArray];
                                            }
                                            else {
                                                DLog("Loading %s failed", [textureFilename UTF8String]);
                                            }
                                        }
                                    }
                                    else {
                                        // Remove NSString @"NULL"
                                        [frameArray removeObjectAtIndex:frameIndex];
                                        [animationArray replaceObjectAtIndex:animationIndex withObject:frameArray];
                                        [angleArray replaceObjectAtIndex:angleIndex withObject:animationArray];
                                        [textureFilenameArray replaceObjectAtIndex:containerIndex withObject:angleArray];
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    animationContainers = textureFilenameArray;
    return animationContainers;
}

- (BOOL)fetchAnimationData:(NSString *)fname fext:(NSString *)fext animationContainers:(NSMutableArray *)containers
{
    BOOL success = NO;
    NSMutableString *configFileText = [NSMutableString string];
    NSMutableString *remainingFileText = [NSMutableString string];
    NSMutableString *currentLine = [NSMutableString string];
    NSMutableArray *configStrings = [NSMutableArray array];

    // Get the path to the configuration file.
    NSString *filePath = [[ NSBundle bundleForClass:[self class] ] pathForResource:fname ofType:fext ];
    // Read the entire configuration file into a single string
    if (filePath)
        configFileText = [NSMutableString stringWithContentsOfFile:filePath encoding:NSASCIIStringEncoding error:NULL];
    else {
        DLog("Invalid file path - could not fetch animation data.");
        return FALSE;
    }
    if (configFileText) {
        // Split the configuration text into individual lines and store them, eliminating all comments
        BOOL commentLine = FALSE;
        while ([configFileText length] > 0) {
            getTextureAndAnimationLineWithinNSString(configFileText, currentLine, remainingFileText, &commentLine);
            if (!commentLine)
                [configStrings addObject:[[NSString alloc] initWithString:currentLine]];
            configFileText = remainingFileText;
        }
        success = YES;
        // Parse all of the animations and load the textures
        if (![self parseAnimations:configStrings animationContainers:containers])
            success = NO;
    }
    return success;
}

- (BOOL)parseAnimations:(NSMutableArray *)configStrings animationContainers:(NSMutableArray *)containers
{
    BOOL success = YES;
    int containerIndex, angleIndex, animationIndex, frameIndex;
    //
    // Process the Animation Containers
    //
    NSString *trimmedConfigString;
    
    // NSMutableArray *containers contains all of the animation containers
    NSMutableArray *angles;         // Working array containing angles for the current container
    NSMutableArray *animations;     // Working array containing animations for the current container-angle
    NSMutableArray *frames;         // Working array containing frames for the current container-angle-animation
    if ([configStrings count] > 0)
        for (id thisString in configStrings) {
            if ([thisString isKindOfClass:[NSString class]]) {
                trimmedConfigString = [thisString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                // Get the AnimationContainer number
                if ([trimmedConfigString hasPrefix:@"AnimationContainer"]) {
                    containerIndex = [[[trimmedConfigString componentsSeparatedByString:@" "] objectAtIndex:1] intValue];
                    DLog("AnimationContainer %d", containerIndex);
                }
                // Get the Angle number
                else if ([trimmedConfigString hasPrefix:@"Angle"]) {
                    angleIndex = [[[trimmedConfigString componentsSeparatedByString:@" "] objectAtIndex:1] intValue];
                    DLog("Angle %d", angleIndex);
                    if (angleIndex == 0) {
                        angles = [NSMutableArray arrayWithCapacity:1];
                        [containers addObject:angles];
                    }
                }
                // Get the Animation number
                else if ([trimmedConfigString hasPrefix:@"Animation"]) {
                    animationIndex = [[[trimmedConfigString componentsSeparatedByString:@" "] objectAtIndex:1] intValue];
                    DLog("Animation %d", animationIndex);
                    if (animationIndex == 0) {
                        animations = [NSMutableArray arrayWithCapacity:1];
                        [angles addObject:animations];
                    }
                }
                // Get the Frame number
                else if ([trimmedConfigString hasPrefix:@"Frame"]) {
                    frameIndex = [[[trimmedConfigString componentsSeparatedByString:@" "] objectAtIndex:1] intValue];
                    NSArray *frameString = [trimmedConfigString componentsSeparatedByString:@" "];
                    if (frameIndex == 0){
                        frames = [NSMutableArray arrayWithCapacity:1];
                        [animations addObject:frames];
                    }
                    if (![[[frameString objectAtIndex:2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@"NULL"]) {
                        NSString *filenameWithExt = [[[frameString objectAtIndex:2] stringByAppendingString:@"."] stringByAppendingString:[[frameString objectAtIndex:3] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                        BOOL foundit = NO;
                        // Check if the filename corresponds to a Texture that has already been loaded
                        if ([loadedTextureFiles count] > 0)
                            for (id TextureData in loadedTextureFiles) {
                                if ([TextureData isKindOfClass:[TextureData class]])
                                    if ([[TextureData valueForKey:@"textureFilename"] isEqualToString:filenameWithExt]) {
                                        foundit = YES;
                                        [frames addObject:TextureData];
                                    }
                            }
                        // If we did not find the file name in loadedTextureFiles then read the png file and create a new MTLTexture
                        if (!foundit) {
                            if ([self loadMetalTextureFromFile:[frameString objectAtIndex:2] withExtension:[[frameString objectAtIndex:3] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]) {
                                TextureData *newElement = [[TextureData alloc] init];
                                newElement.textureFilename = [[NSString alloc] initWithString:[NSString stringWithString:filenameWithExt]];
                                newElement.texture = _texture;
                                [loadedTextureFiles addObject:newElement];
                                [frames addObject:newElement];
                            }
                            else {
                                DLog("Loading %s.%s failed", [[frameString objectAtIndex:2] UTF8String], [[frameString objectAtIndex:3] UTF8String]);
                            }
                        }
                    }
                }
                else {
                    DLog("Unexpected line %s", [trimmedConfigString UTF8String]);
                }
            }
        }
    return success;
}
//// ***** End Texture and Animation File Processing *****


// ***** Create Haptics Patterns Here *****
- (void)createHapticsPatterns {
    
}


// ***** Load Sound Effects Here *****
- (void)loadSoundEffects {
    // Initialize all objects to zero
    tapSoundFileObject = 0;
    tapSoundFileObject = 0;
    plopSoundFileObject = 0;
    clinkSoundFileObject = 0;
    twinkleSoundFileObject = 0;
    tileCorrectlyPlacedSoundFileObject = 0;
    laser1SoundFileObject = 0;
    laser2SoundFileObject = 0;
    jewelEnergizedSoundFileObject = 0;
    
    puzzleBegin1_SoundFileObject = 0;
    
    puzzleComplete1_SoundFileObject = 0;
    puzzleComplete2_SoundFileObject = 0;
    puzzleComplete3_SoundFileObject = 0;
    puzzleComplete4_SoundFileObject = 0;
    loopMusic1_SoundFileObject = 0;

    laserSoundCurrentlyPlaying = NO;
    laserSoundFlip = NO;

    //    AVAudioPlayer for Laser 1 sound effect
    NSString *path = [[NSBundle mainBundle] pathForResource:kLaserSound1 ofType:@"wav"];
    NSURL *laser1Effect = [NSURL URLWithString:path];
    laser1Player = [[AVAudioPlayer alloc] initWithContentsOfURL:laser1Effect error:nil];
    if(!laser1Player)
       DLog("error in initializing laser player 1");
    laser1Player.delegate = self;
    laser1Player.numberOfLoops = 0;

    //    AVAudioPlayer for Laser 2 sound effect
    path = [[NSBundle mainBundle] pathForResource:kLaserSound2 ofType:@"wav"];
    NSURL *laser2Effect = [NSURL URLWithString:path];
    laser2Player = [[AVAudioPlayer alloc] initWithContentsOfURL:laser2Effect error:nil];
    if(!laser2Player)
       DLog("error in initializing laser player 2");
    laser2Player.delegate = self;
    laser2Player.numberOfLoops = 0;

    //    AVAudioPlayer for tap sound effect
    path = [[NSBundle mainBundle] pathForResource:kButtonClickSoundEffect ofType:@"wav"];
    NSURL *tapEffect = [NSURL URLWithString:path];
    tapPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:tapEffect error:nil];
    if(!tapPlayer)
       DLog("error in initializing tap player");
    tapPlayer.delegate = self;
    tapPlayer.numberOfLoops = 0;

    //    AVAudioPlayer for clink sound effect
    path = [[NSBundle mainBundle] pathForResource:kButtonClinkSoundEffect ofType:@"wav"];
    NSURL *clinkEffect = [NSURL URLWithString:path];
    clinkPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:clinkEffect error:nil];
    if(!clinkPlayer)
       DLog("error in initializing clinkPlayer");
    clinkPlayer.delegate = self;
    clinkPlayer.numberOfLoops = 0;

    //    AVAudioPlayer for tileCorrectlyPlacedPlayer effect
    path = [[NSBundle mainBundle] pathForResource:kTilePlacedCorrectly ofType:@"wav"];
    NSURL *tileCorrectlyPlacedEffect = [NSURL URLWithString:path];
    tileCorrectlyPlacedPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:tileCorrectlyPlacedEffect error:nil];
    if(!tileCorrectlyPlacedPlayer)
       DLog("error in initializing tileCorrectlyPlacedPlayer");
    tileCorrectlyPlacedPlayer.delegate = self;
    tileCorrectlyPlacedPlayer.numberOfLoops = 0;

    //    AVAudioPlayer for puzzleComplete1Player sound effect
    path = [[NSBundle mainBundle] pathForResource:kPuzzleComplete1 ofType:@"wav"];
    NSURL *puzzleComplete1Effect = [NSURL URLWithString:path];
    puzzleComplete1Player = [[AVAudioPlayer alloc] initWithContentsOfURL:puzzleComplete1Effect error:nil];
    if(!puzzleComplete1Player)
       DLog("error in initializing puzzleComplete1Player");
    puzzleComplete1Player.delegate = self;
    puzzleComplete1Player.numberOfLoops = 0;

    //    AVAudioPlayer for puzzleComplete2Player sound effect
    path = [[NSBundle mainBundle] pathForResource:kPuzzleComplete2 ofType:@"wav"];
    NSURL *puzzleComplete2Effect = [NSURL URLWithString:path];
    puzzleComplete2Player = [[AVAudioPlayer alloc] initWithContentsOfURL:puzzleComplete2Effect error:nil];
    if(!puzzleComplete2Player)
       DLog("error in initializing puzzleComplete2Player");
    puzzleComplete2Player.delegate = self;
    puzzleComplete2Player.numberOfLoops = 0;

    //    AVAudioPlayer for puzzleComplete3Player sound effect
    path = [[NSBundle mainBundle] pathForResource:kPuzzleComplete3 ofType:@"wav"];
    NSURL *puzzleComplete3Effect = [NSURL URLWithString:path];
    puzzleComplete3Player = [[AVAudioPlayer alloc] initWithContentsOfURL:puzzleComplete3Effect error:nil];
    if(!puzzleComplete3Player)
       DLog("error in initializing puzzleComplete3Player");
    puzzleComplete3Player.delegate = self;
    puzzleComplete3Player.numberOfLoops = 0;

//    //    Get Jewel Energized sound effect
//    path = [[NSBundle mainBundle] pathForResource:kJewelEnergized ofType:@"wav"];
//    NSURL *jewelEnergizedSound = [NSURL URLWithString:path];
//    // Store the URL as a CFURLRef instance
//    jewelEnergizedSoundFileURLRef = (__bridge CFURLRef) jewelEnergizedSound;
//    AudioServicesCreateSystemSoundID (jewelEnergizedSoundFileURLRef, &jewelEnergizedSoundFileObject);
//
//    //    Get Puzzle Begin 1 sound effect
//    path = [[NSBundle mainBundle] pathForResource:kPuzzleBegin1 ofType:@"wav"];
//    NSURL *puzzleBeginSound1 = [NSURL URLWithString:path];
//    // Store the URL as a CFURLRef instance
//    puzzleBegin1_SoundFileURLRef = (__bridge CFURLRef) puzzleBeginSound1;
//    AudioServicesCreateSystemSoundID (puzzleBegin1_SoundFileURLRef, &puzzleBegin1_SoundFileObject);
//
//    //    Get Puzzle Complete 1 sound effect
//    path = [[NSBundle mainBundle] pathForResource:kPuzzleComplete1 ofType:@"wav"];
//    NSURL *puzzleCompleteSound1 = [NSURL URLWithString:path];
//    // Store the URL as a CFURLRef instance
//    puzzleComplete1_SoundFileURLRef = (__bridge CFURLRef) puzzleCompleteSound1;
//    AudioServicesCreateSystemSoundID (puzzleComplete1_SoundFileURLRef, &puzzleComplete1_SoundFileObject);
//
//    //    Get Puzzle Complete 2 sound effect
//    path = [[NSBundle mainBundle] pathForResource:kPuzzleComplete2 ofType:@"wav"];
//    NSURL *puzzleCompleteSound2 = [NSURL URLWithString:path];
//    // Store the URL as a CFURLRef instance
//    puzzleComplete2_SoundFileURLRef = (__bridge CFURLRef) puzzleCompleteSound2;
//    AudioServicesCreateSystemSoundID (puzzleComplete2_SoundFileURLRef, &puzzleComplete2_SoundFileObject);
//
//    //    Get Puzzle Complete 3 sound effect
//    path = [[NSBundle mainBundle] pathForResource:kPuzzleComplete3 ofType:@"wav"];
//    NSURL *puzzleCompleteSound3 = [NSURL URLWithString:path];
//    // Store the URL as a CFURLRef instance
//    puzzleComplete3_SoundFileURLRef = (__bridge CFURLRef) puzzleCompleteSound3;
//    AudioServicesCreateSystemSoundID (puzzleComplete3_SoundFileURLRef, &puzzleComplete3_SoundFileObject);
//
//    //    Get Puzzle Complete 4 sound effect
//    path = [[NSBundle mainBundle] pathForResource:kPuzzleComplete4 ofType:@"wav"];
//    NSURL *puzzleCompleteSound4 = [NSURL URLWithString:path];
//    // Store the URL as a CFURLRef instance
//    puzzleComplete4_SoundFileURLRef = (__bridge CFURLRef) puzzleCompleteSound4;
//    AudioServicesCreateSystemSoundID (puzzleComplete4_SoundFileURLRef, &puzzleComplete4_SoundFileObject);
    
    //    Get Loop Music 1
    path = [[NSBundle mainBundle] pathForResource:kLoopMusic1 ofType:@"wav"];
    NSURL *loopMusic1 = [NSURL URLWithString:path];
    loop1Player = [[AVAudioPlayer alloc] initWithContentsOfURL:loopMusic1 error:nil];
    if(!loop1Player)
       DLog("error in playing music loop 1");
    loop1Player.delegate = self;
    loop1Player.numberOfLoops = -1;

    //    Get Loop Music 2
    path = [[NSBundle mainBundle] pathForResource:kLoopMusic2 ofType:@"wav"];
    NSURL *loopMusic2 = [NSURL URLWithString:path];
    loop2Player = [[AVAudioPlayer alloc] initWithContentsOfURL:loopMusic2 error:nil];
    if(!loop2Player)
       DLog("error in playing music loop 2");
    loop2Player.delegate = self;
    loop2Player.numberOfLoops = -1;

    //    Get Loop Music 3
    path = [[NSBundle mainBundle] pathForResource:kLoopMusic3 ofType:@"wav"];
    NSURL *loopMusic3 = [NSURL URLWithString:path];
    loop3Player = [[AVAudioPlayer alloc] initWithContentsOfURL:loopMusic3 error:nil];
    if(!loop3Player)
       DLog("error in playing music loop 3");
    loop3Player.delegate = self;
    loop3Player.numberOfLoops = -1;

//    if (loop2Player.playing)
//        DLog("loop2Player is playing");
//    else
//        DLog("loop2Player NOT playing");
//
//    if (loop3Player.playing)
//        DLog("loop3Player is playing");
//    else
//        DLog("loop3Player NOT playing");


}
// ***** End Load Sound Effects *****


//
// Methods to handle Touches
//
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    if ([[event allTouches] count] > 0) {
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:view];
        vector_int2 p;
        p.x = view.contentScaleFactor*point.x;
        p.y = view.contentScaleFactor*point.y;
        [optics saveTouchEvent:p];
        [optics touchesBegan];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    if ([[event allTouches] count] > 0) {
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:view];
        vector_int2 p;
        p.x = view.contentScaleFactor*point.x;
        p.y = view.contentScaleFactor*point.y;
        [optics saveTouchEvent:p];
        [optics touchesMoved];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    if ([[event allTouches] count] > 0) {
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:view];
        vector_int2 p;
        p.x = view.contentScaleFactor*point.x;
        p.y = view.contentScaleFactor*point.y;
        [optics saveTouchEvent:p];
        [optics touchesEnded];
    }
}


//
// Utilities
//
- (uint)getLocalDaysSinceReferenceDate {
    NSDate *date = [NSDate date];
    NSTimeInterval secondsSinceReferenceDate = [date timeIntervalSinceReferenceDate];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = formatter.timeZone;
    NSInteger secondsFromGMT = [timeZone secondsFromGMT];
    NSTimeInterval localDaysSinceReferenceDate = (secondsSinceReferenceDate + secondsFromGMT)/(3600.0*24.0);
    return (uint)localDaysSinceReferenceDate;
}


//
// Utility methods to handle Endless Hints purchase and use
//
- (BOOL)checkForEndlessHintsPurchased{
    BOOL endlessHints = [[self getObjectFromDefaults:@"endlessHintsHasBeenPurchased"] boolValue];
    return endlessHints;
}

- (void)setEndlessHintsPurchased {
    [self setObjectInDefaults:[NSNumber numberWithBool:YES] forKey:@"endlessHintsHasBeenPurchased"];
}


//
// Edit Mode Button Handlers
//
- (NSMutableString *)queryHintPackName:(NSMutableString *)name pack:(unsigned int)hintPack {
    NSMutableArray *arrayOfPaidHintPacks = [self fetchPacksArray:@"paidHintPacksArray.plist"];
    if ([arrayOfPaidHintPacks count] > hintPack){
        NSMutableDictionary *packDictionary = [arrayOfPaidHintPacks objectAtIndex:hintPack];
        name = [packDictionary objectForKey:@"pack_name"];
        return name;
    }
    else {
        return nil;
    }
}

- (NSMutableString *)queryPuzzlePackName:(NSMutableString *)name pack:(unsigned int)packIndex {
    NSMutableArray *packsArray = [gameDictionaries objectForKey:kPuzzlePacksArray];
    if ([packsArray count] > packIndex){
        NSMutableDictionary *packDictionary = [packsArray objectAtIndex:packIndex];
        name = [packDictionary objectForKey:@"pack_name"];
        return name;
    }
    else {
        return nil;
    }
}


//
// Methods to keep score including updating and querying the puzzleScoresArray from defaults
// Game Center
//
- (BOOL)isGameCenterAvailable {
    // Check for presence of GKLocalPlayer API.
    Class gcClass = (NSClassFromString(@"GKLocalPlayer"));
    
    // The device must be running running iOS 4.1 or later.
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
    
    return (gcClass && osVersionSupported);
}

- (void)authenticatePlayer {
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    [localPlayer setAuthenticateHandler:
     ^(UIViewController *viewController, NSError *error) {
        if (viewController != nil) {
            [self.rc presentViewController:viewController
            animated:YES completion:nil];
        } else if ([GKLocalPlayer localPlayer].authenticated) {
            DLog("Player successfully authenticated");
            [self loadLeaderboards];
        } else if (error) {
            DLog("Game Center authentication error: %@", error);
        }
    }];
}

- (void)loadLeaderboards {
    [GKLeaderboard loadLeaderboardsWithIDs:@[@"BEAMED2_TOTAL_PUZZLES_LEADERBOARD",
        @"BEAMED2_TOTAL_JEWELS_LEADERBOARD"]
                         completionHandler:
     ^(NSArray<GKLeaderboard *> *leaderboards, NSError *error) {
        if (leaderboards != nil){
            self.totalPuzzlesLeaderboard = [leaderboards objectAtIndex:0];
            self.totalJewelsLeaderboard = [leaderboards objectAtIndex:1];
            DLog("loadTotalPuzzlesLeaderboard: successfully loaded BEAMED2_TOTAL_PUZZLES_LEADERBOARD");
        } else {
            self.totalPuzzlesLeaderboard = nil;
            DLog("loadTotalJewelsLeaderboard: failed to load BEAMED2_TOTAL_PUZZLES_LEADERBOARD");
        }
    }];
}

- (void)loadTotalPuzzlesLeaderboard {
    [GKLeaderboard loadLeaderboardsWithIDs:@[@"BEAMED2_TOTAL_PUZZLES_LEADERBOARD"]
                         completionHandler:
     ^(NSArray<GKLeaderboard *> *leaderboards, NSError *error) {
        if (leaderboards != nil){
            self.totalPuzzlesLeaderboard = [leaderboards firstObject];
            DLog("loadTotalPuzzlesLeaderboard: successfully loaded BEAMED2_TOTAL_PUZZLES_LEADERBOARD");
        } else {
            self.totalPuzzlesLeaderboard = nil;
            DLog("loadTotalJewelsLeaderboard: failed to load BEAMED2_TOTAL_PUZZLES_LEADERBOARD");
        }
    }];
}

- (void)loadTotalJewelsLeaderboard {
    [GKLeaderboard loadLeaderboardsWithIDs:@[@"BEAMED2_TOTAL_JEWELS_LEADERBOARD"]
                         completionHandler:
     ^(NSArray<GKLeaderboard *> *leaderboards, NSError *error) {
        if (leaderboards != nil){
            self.totalJewelsLeaderboard = [leaderboards firstObject];
            DLog("loadTotalJewelsLeaderboard: successfully loaded BEAMED2_TOTAL_JEWELS_LEADERBOARD");
        } else {
            self.totalJewelsLeaderboard = nil;
            DLog("loadTotalJewelsLeaderboard: failed to load BEAMED2_TOTAL_JEWELS_LEADERBOARD");
        }
    }];
}

- (NSString *)queryCurrentGameDictionaryName {
    NSString *dictionaryName = [[NSString alloc] init];
    switch (rc.appCurrentGamePackType) {
        case PACKTYPE_MAIN:{
            dictionaryName = kPuzzlePacksArray;
            break;
        }
        case PACKTYPE_DAILY:{
            dictionaryName = @"dailyPuzzlesPackDictionary.plist";
            break;
        }
        case PACKTYPE_DEMO:
        default:{
            dictionaryName = @"demoPuzzlePackDictionary.plist";
            break;
        }
    }
    return dictionaryName;
}

- (NSMutableDictionary *)fetchGamePuzzle:(int)packNumber puzzleIndex:(int)puzzleIndex {
    NSMutableArray *puzzlePacksArray = [NSMutableArray arrayWithCapacity:1];
    NSMutableDictionary *puzzlePackDict = [NSMutableDictionary dictionaryWithCapacity:1];
    NSMutableArray *puzzleArray = [NSMutableArray arrayWithCapacity:1];
    NSMutableDictionary *puzzle = [NSMutableDictionary dictionaryWithCapacity:1];
    unsigned packIndex = [self fetchPackIndexForPackNumber:packNumber];
    // Puzzle Packs top level object is NSArray
    if (rc.appCurrentGamePackType == PACKTYPE_MAIN){
        if (gameDictionaries != nil){
            puzzlePacksArray = [gameDictionaries objectForKey:kPuzzlePacksArray];
            if (puzzlePacksArray != nil && [puzzlePacksArray count] > packIndex){
                puzzlePackDict = [puzzlePacksArray objectAtIndex:packIndex];
                if (puzzlePackDict){
                    puzzleArray = [puzzlePackDict objectForKey:@"puzzles"];
                    if (puzzleArray != nil && [puzzleArray count] > puzzleIndex){
                        puzzle = [puzzleArray objectAtIndex:puzzleIndex];
                        return puzzle;
                    }
                }
            }
        }
    }
    // Daily Puzzle top level object is NSDictionary
    else if (rc.appCurrentGamePackType == PACKTYPE_DAILY){
        if (gameDictionaries != nil){
            puzzlePackDict = [gameDictionaries objectForKey:kDailyPuzzlesPackDictionary];
            if (puzzlePackDict != nil){
                puzzleArray = [puzzlePackDict objectForKey:@"puzzles"];
                if (puzzleArray != nil && [puzzleArray count] > puzzleIndex){
                    puzzle = [puzzleArray objectAtIndex:puzzleIndex];
                    return puzzle;
                }
            }
        }
    }
    else if (rc.appCurrentGamePackType == PACKTYPE_DEMO){
        if (gameDictionaries != nil){
            puzzlePackDict = [gameDictionaries objectForKey:kDemoPuzzlePackDictionary];
            if (puzzlePackDict != nil){
                puzzleArray = [puzzlePackDict objectForKey:@"puzzles"];
                if (puzzleArray != nil && [puzzleArray count] > puzzleIndex){
                    puzzle = [puzzleArray objectAtIndex:puzzleIndex];
                    return puzzle;
                }
            }
        }
    }
    else {
        DLog("fetchGamePuzzle: rc.appCurrentGamePackType does not match");
    }
    return nil;
}

- (NSMutableDictionary *)fetchGameDictionaryForKey:(NSString *)key {
    NSMutableDictionary *dictionary = [gameDictionaries objectForKey:key];
    return dictionary;
}

- (NSMutableDictionary *)queryPuzzleJewelCountByColor:(int)puzzleNumber {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:1];
    int redCount=0, greenCount=0, blueCount=0, yellowCount=0, magentaCount=0, cyanCount=0, whiteCount=0;
    NSDictionary *puzzleDictionary = [self fetchGamePuzzle:currentPack puzzleIndex:puzzleNumber];
    NSArray *jewelDictionaryArray = [puzzleDictionary objectForKey:@"arrayOfJewelsDictionaries"];
    if (jewelDictionaryArray != nil){
        NSEnumerator *jewelArrayEnum = [jewelDictionaryArray objectEnumerator];
        NSMutableDictionary *jewelDictionary;
        while (jewelDictionary = [jewelArrayEnum nextObject]){
            int colorNumber = [[jewelDictionary objectForKey:@"Color"] intValue];
            switch(colorNumber){
                case 0:{
                    redCount++;
                    break;
                }
                case 1:{
                    greenCount++;
                    break;
                }
                case 2:{
                    blueCount++;
                    break;
                }
                case 3:{
                    yellowCount++;
                    break;
                }
                case 4:{
                    magentaCount++;
                    break;
                }
                case 5:{
                    cyanCount++;
                    break;
                }
                case 6:{
                    whiteCount++;
                    break;
                }
            }
        }
    }
    [dictionary setObject:[NSNumber numberWithInt:redCount] forKey:@"redCount"];
    [dictionary setObject:[NSNumber numberWithInt:greenCount] forKey:@"greenCount"];
    [dictionary setObject:[NSNumber numberWithInt:blueCount] forKey:@"blueCount"];
    [dictionary setObject:[NSNumber numberWithInt:yellowCount] forKey:@"yellowCount"];
    [dictionary setObject:[NSNumber numberWithInt:magentaCount] forKey:@"magentaCount"];
    [dictionary setObject:[NSNumber numberWithInt:cyanCount] forKey:@"cyanCount"];
    [dictionary setObject:[NSNumber numberWithInt:whiteCount] forKey:@"whiteCount"];
    return dictionary;
}

- (NSMutableDictionary *)buildEmptyJewelCountDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:1];
    int redCount=0, greenCount=0, blueCount=0, yellowCount=0, magentaCount=0, cyanCount=0, whiteCount=0;
    [dictionary setObject:[NSNumber numberWithInt:redCount] forKey:@"redCount"];
    [dictionary setObject:[NSNumber numberWithInt:greenCount] forKey:@"greenCount"];
    [dictionary setObject:[NSNumber numberWithInt:blueCount] forKey:@"blueCount"];
    [dictionary setObject:[NSNumber numberWithInt:yellowCount] forKey:@"yellowCount"];
    [dictionary setObject:[NSNumber numberWithInt:magentaCount] forKey:@"magentaCount"];
    [dictionary setObject:[NSNumber numberWithInt:cyanCount] forKey:@"cyanCount"];
    [dictionary setObject:[NSNumber numberWithInt:whiteCount] forKey:@"whiteCount"];
    return dictionary;
}

- (int)queryPuzzleJewelCount:(int)puzzleNumber {
    int intJewelCount;
    NSMutableDictionary *puzzleDictionary = [self fetchGamePuzzle:currentPack puzzleIndex:puzzleNumber];
    NSArray *jewelDictionaryArray = [puzzleDictionary objectForKey:@"arrayOfJewelsDictionaries"];
    if (jewelDictionaryArray == nil){
        intJewelCount = 0;
    }
    else {
        intJewelCount = (int)[jewelDictionaryArray count];
    }
    return intJewelCount;
}

- (int)queryPuzzleJewelCountFromDictionary:(NSMutableDictionary *)dictionary {
    int intJewelCount;
    NSArray *jewelDictionaryArray = [dictionary objectForKey:@"arrayOfJewelsDictionaries"];
    if (jewelDictionaryArray == nil){
        intJewelCount = 0;
    }
    else {
        intJewelCount = (int)[jewelDictionaryArray count];
    }
    return intJewelCount;
}

- (int)countTotalJewelsCollectedByColorKey:(NSString *)colorKey {
    int numberOfJewels = 0;
    // Enumerate over puzzleScoresArray
    NSMutableArray *puzzleScoresArray = [self getArrayFromDefaults:@"puzzleScoresArray"];
    if (puzzleScoresArray != nil && [puzzleScoresArray count] > 0){
        NSEnumerator *scoresEnum = [puzzleScoresArray objectEnumerator];
        NSMutableDictionary *scoreDictionary;
        while (scoreDictionary = [scoresEnum nextObject]) {
            NSDictionary *numberOfJewelsDictionary = [scoreDictionary objectForKey:@"numberOfJewelsDictionary"];
            if (numberOfJewelsDictionary != nil){
                NSNumber *jewelsNum = [numberOfJewelsDictionary objectForKey:colorKey];
                int jewels = [jewelsNum intValue];
                if (jewels > 0){
                    numberOfJewels = numberOfJewels + jewels;
                }
            }
        }
    }
    return numberOfJewels;
}

- (int)countTotalJewelsCollected {
    int numberOfJewels = 0;
    // Enumerate over puzzleScoresArray
    NSMutableArray *puzzleScoresArray = [self getArrayFromDefaults:@"puzzleScoresArray"];
    if (puzzleScoresArray != nil && [puzzleScoresArray count] > 0){
        NSEnumerator *scoresEnum = [puzzleScoresArray objectEnumerator];
        NSMutableDictionary *scoreDictionary;
        while (scoreDictionary = [scoresEnum nextObject]) {
            NSDictionary *numberOfJewelsDictionary = [scoreDictionary objectForKey:@"numberOfJewelsDictionary"];
            if (numberOfJewelsDictionary != nil){
                NSNumber *jewelsNum = [numberOfJewelsDictionary objectForKey:@"redCount"];
                int jewels = [jewelsNum intValue];
                if (jewels > 0){
                    numberOfJewels = numberOfJewels + jewels;
                }
                jewelsNum = [numberOfJewelsDictionary objectForKey:@"greenCount"];
                jewels = [jewelsNum intValue];
                if (jewels > 0){
                    numberOfJewels = numberOfJewels + jewels;
                }
                jewelsNum = [numberOfJewelsDictionary objectForKey:@"blueCount"];
                jewels = [jewelsNum intValue];
                if (jewels > 0){
                    numberOfJewels = numberOfJewels + jewels;
                }
                jewelsNum = [numberOfJewelsDictionary objectForKey:@"yellowCount"];
                jewels = [jewelsNum intValue];
                if (jewels > 0){
                    numberOfJewels = numberOfJewels + jewels;
                }
                jewelsNum = [numberOfJewelsDictionary objectForKey:@"cyanCount"];
                jewels = [jewelsNum intValue];
                if (jewels > 0){
                    numberOfJewels = numberOfJewels + jewels;
                }
                jewelsNum = [numberOfJewelsDictionary objectForKey:@"magentaCount"];
                jewels = [jewelsNum intValue];
                if (jewels > 0){
                    numberOfJewels = numberOfJewels + jewels;
                }
                jewelsNum = [numberOfJewelsDictionary objectForKey:@"whiteCount"];
                jewels = [jewelsNum intValue];
                if (jewels > 0){
                    numberOfJewels = numberOfJewels + jewels;
                }
            }
        }
    }
    return numberOfJewels;
}

- (int)countPuzzlesSolved {
    int numberOfPuzzlesSolved = 0;
    // Enumerate over puzzleScoresArray
    NSMutableArray *puzzleScoresArray = [self getArrayFromDefaults:@"puzzleScoresArray"];
    if (puzzleScoresArray != nil && [puzzleScoresArray count] > 0){
        NSEnumerator *scoresEnum = [puzzleScoresArray objectEnumerator];
        NSMutableDictionary *scoreDictionary;
        while (scoreDictionary = [scoresEnum nextObject]) {
            BOOL puzzleSolved = [[scoreDictionary objectForKey:@"solved"]boolValue];
            if (puzzleSolved){
                numberOfPuzzlesSolved++;
            }
        }
    }
    return numberOfPuzzlesSolved;
}

- (long)fetchTotalSolutionTimeForAllPacks {
    long totalSolutionTime = 0;
    long solutionTime = 0;
    // Enumerate over puzzleScoresArray
    NSMutableArray *puzzleScoresArray = [self getArrayFromDefaults:@"puzzleScoresArray"];
    if (puzzleScoresArray != nil && [puzzleScoresArray count] > 0){
        NSEnumerator *scoresEnum = [puzzleScoresArray objectEnumerator];
        NSMutableDictionary *scoreDictionary;
        while (scoreDictionary = [scoresEnum nextObject]) {
            BOOL puzzleSolved = [[scoreDictionary objectForKey:@"solved"]boolValue];
            if (puzzleSolved){
                NSNumber *solutionTimeNumber = nil;
                solutionTimeNumber = [scoreDictionary objectForKey:@"solutionTime"];
                if (solutionTimeNumber){
                    solutionTime = [solutionTimeNumber longValue];
                    totalSolutionTime = totalSolutionTime + solutionTime;
                }
            }
        }
    }
    return totalSolutionTime;
}

- (long)calculateSolutionTime:(int)packNumber
             puzzleNumber:(int)puzzleNumber {
    long solutionTime = 0;
    // Read puzzleScoresArray from defaults
    NSMutableArray *puzzleScoresArray = [NSMutableArray arrayWithArray:[self getArrayFromDefaults:@"puzzleScoresArray"]];
    NSMutableDictionary *scoreDictionary = nil;
    if (puzzleScoresArray != nil){
        if ([puzzleScoresArray count] > 0){
            int scoreDictionaryIndex = -1;
            NSDictionary *dict = nil;
            for (int ii=0; ii<[puzzleScoresArray count]; ii++){
                dict = [puzzleScoresArray objectAtIndex:ii];
                NSNumber *storedPackNumber = [dict objectForKey:@"packNumber"];
                NSNumber *storedPuzzleNumber = [dict objectForKey:@"puzzleNumber"];
                if ([storedPackNumber intValue] == packNumber &&
                    [storedPuzzleNumber intValue] == puzzleNumber){
                    scoreDictionaryIndex = ii;
                    break;
                }
            }
            // IF there is a matching scoreDictionary AND the puzzle is solved THEN retrieve timeSegmentArray
            if (dict != nil && scoreDictionaryIndex >= 0){
                scoreDictionary = [NSMutableDictionary dictionaryWithDictionary:dict];
                BOOL puzzleSolved = [[scoreDictionary objectForKey:@"solved"]boolValue];
                // Solved so continue
                if (puzzleSolved){
                    NSMutableArray *timeSegmentArray = [NSMutableArray arrayWithArray:[scoreDictionary objectForKey:@"timeSegmentArray"]];
                    if (timeSegmentArray != nil){
                        if ([timeSegmentArray count] > 0){
                            NSEnumerator *arrayEnum = [timeSegmentArray objectEnumerator];
                            NSMutableDictionary *timeSegmentDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
                            solutionTime = 0;
                            long startTime = 0, endTime = 0, segmentTime = 0;
                            while (timeSegmentDictionary = [arrayEnum nextObject]){
                                startTime = [[timeSegmentDictionary objectForKey:@"startTime"] intValue];
                                endTime = [[timeSegmentDictionary objectForKey:@"endTime"] intValue];
                                segmentTime = endTime - startTime;
                                if (segmentTime < 0){
                                    DLog("fetchSolutionTime error: startTime > endTime");
                                    return -1;
                                }
                                else {
                                    solutionTime = solutionTime + segmentTime;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return solutionTime;
}

// +1   Puzzle is solved
//  0   Puzzle is unsolved
// -1   Puzzle is in progress
- (int)puzzleSolutionStatus:(int)packNumber
            puzzleNumber:(int)puzzleNumber {
    NSMutableArray *puzzleScoresArray = [NSMutableArray arrayWithArray:[self getArrayFromDefaults:@"puzzleScoresArray"]];
    NSMutableDictionary *scoreDictionary = nil;
    if (puzzleScoresArray == nil){
        // Unsolved
        return 0;
    }
    else {
        if ([puzzleScoresArray count] > 0){
            int scoreDictionaryIndex = -1;
            NSDictionary *dict = nil;
            for (int ii=0; ii<[puzzleScoresArray count]; ii++){
                dict = [puzzleScoresArray objectAtIndex:ii];
                NSNumber *storedPackNumber = [dict objectForKey:@"packNumber"];
                NSNumber *storedPuzzleNumber = [dict objectForKey:@"puzzleNumber"];
                if ([storedPackNumber intValue] == packNumber &&
                    [storedPuzzleNumber intValue] == puzzleNumber){
                    scoreDictionaryIndex = ii;
                    break;
                }
            }
            if (dict == nil || scoreDictionaryIndex == -1){
                // Unsolved - no matching score dictionary
                return 0;
            }
            else {
                scoreDictionary = [NSMutableDictionary dictionaryWithDictionary:dict];
                BOOL puzzleSolved = [[scoreDictionary objectForKey:@"solved"]boolValue];
                // Solved - @"solved" set to YES
                if (puzzleSolved){
                    return +1;
                }
                // Unolved - @"solved" set to NO
                else {
                    return -1;
                }
            }
        }
        else {
            // Unsolved
            return 0;
        }
    }
}


// IF a scoreDictionary corresponding to (packNumber,puzzleNumber) exists in puzzleScoresArray
// AND the scoreDictionary @"solved" value is NO
// THEN increment the @"numberOfMoves" value
// ELSE do nothing
- (void)incrementNumberOfMovesInPuzzleScoresArray:(int)packNumber
                                     puzzleNumber:(int)puzzleNumber
{
    DLog("incrementNumberOfMovesInPuzzleScoresArray: %d, %d",
          packNumber,
          puzzleNumber);
    // Read puzzleScoresArray from defaults
    NSMutableArray *puzzleScoresArray = [NSMutableArray arrayWithArray:[self getArrayFromDefaults:@"puzzleScoresArray"]];
    NSMutableDictionary *scoreDictionary = nil;
    if (puzzleScoresArray != nil){
        if ([puzzleScoresArray count] > 0){
            // If there is a matching scoreDictionary stored for this (pack, puzzle) then retrieve it
            int scoreDictionaryIndex = -1;
            NSDictionary *dict = nil;
            for (int ii=0; ii<[puzzleScoresArray count]; ii++){
                dict = [puzzleScoresArray objectAtIndex:ii];
                NSNumber *storedPackNumber = [dict objectForKey:@"packNumber"];
                NSNumber *storedPuzzleNumber = [dict objectForKey:@"puzzleNumber"];
                if ([storedPackNumber intValue] == packNumber &&
                    [storedPuzzleNumber intValue] == puzzleNumber){
                    scoreDictionaryIndex = ii;
                    break;
                }
            }
            // If there is a matching scoreDictionary then increment numberOfMoves
            if (dict != nil && scoreDictionaryIndex >= 0){
                scoreDictionary = [NSMutableDictionary dictionaryWithDictionary:dict];
                BOOL puzzleSolved = [[scoreDictionary objectForKey:@"solved"]boolValue];
                // Not yet solved so increment numberOfMoves
                if (!puzzleSolved){
                    int numberOfMoves = [[scoreDictionary objectForKey:@"numberOfMoves"]intValue];
                    numberOfMoves++;
                    [scoreDictionary setObject:[NSNumber numberWithInt:numberOfMoves] forKey:[NSString stringWithFormat:@"numberOfMoves"]];
                    DLog("numberOfMoves = %d", numberOfMoves);
                    [puzzleScoresArray replaceObjectAtIndex:scoreDictionaryIndex withObject:scoreDictionary];
                    // Save puzzleScoresArray to defaults
                    [self setObjectInDefaults:puzzleScoresArray forKey:@"puzzleScoresArray"];
                }
            }
        }
    }
}


- (void)updatePuzzleScoresArray:(int)packNumber
                   puzzleNumber:(int)puzzleNumber
                 numberOfJewels:(NSDictionary *)numberOfJewelsDictionary
                      startTime:(long)startTime
                        endTime:(long)endTime
                         solved:(BOOL)solved
{
    DLog("updatePuzzleScoresArray: %d, %d, %ld, %ld, %d",
          packNumber,
          puzzleNumber,
          startTime,
          endTime,
          solved);
    // Read puzzleScoresArray from defaults
    NSMutableArray *puzzleScoresArray = [NSMutableArray arrayWithArray:[self getArrayFromDefaults:@"puzzleScoresArray"]];
    NSMutableDictionary *scoreDictionary = nil;
    if (puzzleScoresArray != nil){
        if ([puzzleScoresArray count] > 0){
            // If there is a matching scoreDictionary stored for this (pack, puzzle) then retrieve it
            int scoreDictionaryIndex = -1;
            NSDictionary *dict = nil;
            for (int ii=0; ii<[puzzleScoresArray count]; ii++){
                dict = [puzzleScoresArray objectAtIndex:ii];
                NSNumber *storedPackNumber = [dict objectForKey:@"packNumber"];
                NSNumber *storedPuzzleNumber = [dict objectForKey:@"puzzleNumber"];
                if ([storedPackNumber intValue] == packNumber &&
                    [storedPuzzleNumber intValue] == puzzleNumber){
                    scoreDictionaryIndex = ii;
                    break;
                }
            }
            // If there is a matching scoreDictionary stored then replace it if already solved, else update it
            if (dict != nil && scoreDictionaryIndex >= 0){
                scoreDictionary = [NSMutableDictionary dictionaryWithDictionary:dict];
                BOOL puzzleSolved = [[scoreDictionary objectForKey:@"solved"] boolValue];
                // Solved so replace
                if (puzzleSolved){
                    // Remove the solved scoreDictionary
                    [puzzleScoresArray removeObjectAtIndex:scoreDictionaryIndex];
                    // Build new scoreDictionary
                    scoreDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
                    [scoreDictionary setObject:[NSNumber numberWithInt:packNumber] forKey:[NSString stringWithFormat:@"packNumber"]];
                    [scoreDictionary setObject:[NSNumber numberWithInt:puzzleNumber] forKey:[NSString stringWithFormat:@"puzzleNumber"]];
                    [scoreDictionary setObject:numberOfJewelsDictionary forKey:[NSString stringWithFormat:@"numberOfJewelsDictionary"]];
                    [scoreDictionary setObject:[NSNumber numberWithInt:0] forKey:[NSString stringWithFormat:@"numberOfMoves"]];
                    [scoreDictionary setObject:[NSNumber numberWithBool:NO] forKey:@"solved"];
                    // Build timeSegmentArray and timeSegmentDictionary
                    NSMutableArray *timeSegmentArray = [NSMutableArray arrayWithCapacity:1];
                    NSMutableDictionary *timeSegmentDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
                    [timeSegmentDictionary setObject:[NSNumber numberWithLong:startTime] forKey:[NSString stringWithFormat:@"startTime"]];
                    [timeSegmentDictionary setObject:[NSNumber numberWithLong:endTime] forKey:[NSString stringWithFormat:@"endTime"]];
                    [timeSegmentArray addObject:timeSegmentDictionary];
                    // Add timeSegmentArray to scoreDictionary
                    [scoreDictionary setObject:timeSegmentArray forKey:@"timeSegmentArray"];
                    // Add scoreDictionary to puzzleScoresArray
                    [puzzleScoresArray addObject:scoreDictionary];
                }
                // The corresponding stored scoreDictionary is not yet solved so update timeSegment array and puzzleSolved status
                else {
                    // If we just solved it then add numberOfJewelsDictionary
                    if (solved){
                        // numberOfJewelsDictionary, numberOfTiles, numberOfMoves parameters set with parameters
                        [scoreDictionary setObject:[NSNumber numberWithBool:YES] forKey:@"solved"];
                        [scoreDictionary setObject:numberOfJewelsDictionary forKey:[NSString stringWithFormat:@"numberOfJewelsDictionary"]];
                    }
                    else {
                        // numberOfJewelsDictionary omitted, numberOfTiles, numberOfMoves parameters disregarded and fields set to -1
                        [scoreDictionary setObject:[NSNumber numberWithBool:NO] forKey:@"solved"];
//                        [scoreDictionary setObject:nil forKey:[NSString stringWithFormat:@"numberOfJewelsDictionary"]];
                    }
                    // Retrieve timeSegmentArray for updating
                    NSArray *tsArray = [scoreDictionary objectForKey:@"timeSegmentArray"];
                    NSMutableArray *timeSegmentArray = [NSMutableArray arrayWithArray:tsArray];
                    NSMutableDictionary *timeSegmentDictionary = [NSMutableDictionary dictionaryWithDictionary:[timeSegmentArray lastObject]];
                    if (startTime > 0){
                        // Handle situation where the previous startTime was not paired with a positive value endTime
                        if ([[timeSegmentDictionary objectForKey:@"endTime"]longValue] < 0){
                            [timeSegmentArray removeLastObject];
                        }
                        [timeSegmentDictionary setObject:[NSNumber numberWithLong:startTime] forKey:[NSString stringWithFormat:@"startTime"]];
                        [timeSegmentDictionary setObject:[NSNumber numberWithLong:-1] forKey:[NSString stringWithFormat:@"endTime"]];
                    }
                    else if (endTime > 0){
                        [timeSegmentDictionary setObject:[NSNumber numberWithLong:endTime] forKey:[NSString stringWithFormat:@"endTime"]];
                        [timeSegmentArray removeLastObject];
                    }
                    [timeSegmentArray addObject:timeSegmentDictionary];
                    // Add timeSegmentArray to scoreDictionary
                    [scoreDictionary setObject:timeSegmentArray forKey:@"timeSegmentArray"];
                    // Add scoreDictionary to puzzleScoresArray
                    [puzzleScoresArray replaceObjectAtIndex:scoreDictionaryIndex withObject:scoreDictionary];
                    // Save puzzleScoresArray to defaults so that we can calcuate solutionTime
                    [self setObjectInDefaults:puzzleScoresArray forKey:@"puzzleScoresArray"];
                    if (solved){
                        // If solved then calculate total solutionTime and add it to scoreDictionary
                        long solutionTime = [self calculateSolutionTime:packNumber puzzleNumber:puzzleNumber];
                        [scoreDictionary setObject:[NSNumber numberWithLong:solutionTime] forKey:@"solutionTime"];
                    }
                    // Add scoreDictionary to puzzleScoresArray
                    [puzzleScoresArray replaceObjectAtIndex:scoreDictionaryIndex withObject:scoreDictionary];
                }
            }
            else {
                // Build new scoreDictionary
                scoreDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
                if (solved){
                    [scoreDictionary setObject:[NSNumber numberWithBool:YES] forKey:@"solved"];
                }
                else {
                    [scoreDictionary setObject:[NSNumber numberWithBool:NO] forKey:@"solved"];
                }
                [scoreDictionary setObject:[NSNumber numberWithInt:packNumber] forKey:[NSString stringWithFormat:@"packNumber"]];
                [scoreDictionary setObject:[NSNumber numberWithInt:puzzleNumber] forKey:[NSString stringWithFormat:@"puzzleNumber"]];
                [scoreDictionary setObject:numberOfJewelsDictionary forKey:[NSString stringWithFormat:@"numberOfJewelsDictionary"]];
                [scoreDictionary setObject:[NSNumber numberWithInt:0] forKey:[NSString stringWithFormat:@"numberOfMoves"]];
                // Build timeSegmentArray and timeSegmentDictionary
                NSMutableArray *timeSegmentArray = [NSMutableArray arrayWithCapacity:1];
                NSMutableDictionary *timeSegmentDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
                [timeSegmentDictionary setObject:[NSNumber numberWithLong:startTime] forKey:[NSString stringWithFormat:@"startTime"]];
                [timeSegmentDictionary setObject:[NSNumber numberWithLong:endTime] forKey:[NSString stringWithFormat:@"endTime"]];
                [timeSegmentArray addObject:timeSegmentDictionary];
                // Add timeSegmentArray to scoreDictionary
                [scoreDictionary setObject:timeSegmentArray forKey:@"timeSegmentArray"];
                // Add scoreDictionary to puzzleScoresArray
                [puzzleScoresArray addObject:scoreDictionary];
            }
            // Save puzzleScoresArray to defaults
            [self setObjectInDefaults:puzzleScoresArray forKey:@"puzzleScoresArray"];
        }
        else {
            // Create puzzleScoresArray
            puzzleScoresArray = [NSMutableArray arrayWithCapacity:1];
            // Build new scoreDictionary
            scoreDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
            if (solved){
                [scoreDictionary setObject:[NSNumber numberWithBool:YES] forKey:@"solved"];
            }
            else {
                [scoreDictionary setObject:[NSNumber numberWithBool:NO] forKey:@"solved"];
            }
            [scoreDictionary setObject:[NSNumber numberWithInt:packNumber] forKey:[NSString stringWithFormat:@"packNumber"]];
            [scoreDictionary setObject:[NSNumber numberWithInt:puzzleNumber] forKey:[NSString stringWithFormat:@"puzzleNumber"]];
            [scoreDictionary setObject:numberOfJewelsDictionary forKey:[NSString stringWithFormat:@"numberOfJewelsDictionary"]];
            [scoreDictionary setObject:[NSNumber numberWithInt:0] forKey:[NSString stringWithFormat:@"numberOfMoves"]];
            // Build timeSegmentArray and timeSegmentDictionary
            NSMutableArray *timeSegmentArray = [NSMutableArray arrayWithCapacity:1];
            NSMutableDictionary *timeSegmentDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
            [timeSegmentDictionary setObject:[NSNumber numberWithLong:startTime] forKey:[NSString stringWithFormat:@"startTime"]];
            [timeSegmentDictionary setObject:[NSNumber numberWithLong:endTime] forKey:[NSString stringWithFormat:@"endTime"]];
            [timeSegmentArray addObject:timeSegmentDictionary];
            // Add timeSegmentArray to scoreDictionary
            [scoreDictionary setObject:timeSegmentArray forKey:@"timeSegmentArray"];
            // Add scoreDictionary to puzzleScoresArray
            [puzzleScoresArray addObject:scoreDictionary];
            // Save puzzleScoresArray to defaults
            [self setObjectInDefaults:puzzleScoresArray forKey:@"puzzleScoresArray"];
        }
    }
}

- (void)resetPuzzleProgressAndScores {
    [self initializePuzzlePacksProgress];
    [self removeObjectInDefaultsForKey:@"puzzleScoresArray"];
    [self removeObjectInDefaultsForKey:@"dailyPuzzle"];
    [self removeObjectInDefaultsForKey:@"dailyPuzzleNumber"];
    [self removeObjectInDefaultsForKey:@"dailyPuzzleCompletionDay"];
    [self removeObjectInDefaultsForKey:@"demoHasBeenCompleted"];
    [self removeObjectInDefaultsForKey:@"demoPuzzleNumber"];
}


//
// StoreKit interface and supporting methods for purchasing puzzle and hint packs and handling reviews
//
- (void)completeAdFreePurchase {
    DLog("Purchased Ad Free Puzzles");
    [self setObjectInDefaults:@"YES" forKey:@"AD_FREE_PUZZLES"];
    [rc refreshHomeView];
    [self vungleCloseBannerAd];
}

- (void)completeAdFreeRestore {
    DLog("Restored Purchase of Ad Free Puzzles");
    [self setObjectInDefaults:@"YES" forKey:@"AD_FREE_PUZZLES"];
    [self vungleCloseBannerAd];
}

- (void)completePuzzlePackPurchase:(int)packNumber {
    if (packNumber > 0){
        [self savePurchasedPuzzlePack:packNumber];
        NSMutableString *packName = [[NSMutableString alloc] init];
        unsigned int packIndex = [self fetchPackIndexForPackNumber:packNumber];
        packName = [self queryPuzzlePackName:packName pack:packIndex];
        
        UIButton *lockImage = nil;
        UIButton *packButton = [rc.packsViewController.puzzlePacksButtonsArray objectAtIndex:packIndex];
        UIImage *btnImageFree = [UIImage imageNamed:@"cyanRectangle.png"];
        UIImage *btnSelectedImageFree = [UIImage imageNamed:@"cyanRectangleSelected.png"];
        [rc.packsViewController updateOnePackButtonTitle:packIndex
                                              packNumber:packNumber
                                                  button:packButton];
        if ([rc.packsViewController.puzzlePacksButtonsArray count] > packIndex){
            lockImage = [rc.packsViewController.puzzlePacksLockIconsArray objectAtIndex:packIndex];
            lockImage.hidden = YES;
            packButton = [rc.packsViewController.puzzlePacksButtonsArray objectAtIndex:packIndex];
            packButton.enabled = YES;
            packButton.backgroundColor = [UIColor blackColor];
            [rc.packsViewController unHighlightAllPacks];
            [packButton setBackgroundImage:btnImageFree forState:UIControlStateNormal];
            [packButton setBackgroundImage:btnSelectedImageFree forState:UIControlStateHighlighted];
//            currentPack = (unsigned int)pack;
            [self saveCurrentPackNumber:(unsigned int)packNumber];
            [rc.packsViewController highlightCurrentlySelectedPack];
        }
    }
}

- (void)completeHintPackPurchase:(int)pack {
    DLog("Purchased Hint Pack %d", pack);
    NSMutableArray *arrayOfPaidHintPacks = [self fetchPacksArray:@"paidHintPacksArray.plist"];
    
    if ([arrayOfPaidHintPacks count] > pack){
        NSMutableDictionary *hintPackDictionary = [arrayOfPaidHintPacks objectAtIndex:pack];
        // Update the number of hints in the defaults and in the screen hint button
        [self updateHintsRemainingDisplayAndStorage:[[hintPackDictionary valueForKey:@"number_of_hints"] intValue]];
    }
}

- (void)completeAltIconPurchase:(unsigned int)idx {
    // Fetch the name of the selection App Icon
    NSMutableArray *alternateIconsArray = [NSMutableArray arrayWithCapacity:1];
    alternateIconsArray = [self fetchAlternateIconsArray:alternateIconsArray];
    NSMutableDictionary *iconDict = [NSMutableDictionary dictionaryWithDictionary:[alternateIconsArray objectAtIndex:idx]];
    NSString *iconName = [iconDict objectForKey:@"appIcon"];
    BOOL supportsAlternateIcons = [UIApplication.sharedApplication supportsAlternateIcons];
    if (supportsAlternateIcons){
        [UIApplication.sharedApplication setAlternateIconName:iconName completionHandler:^(NSError *error){
            if (error == nil){
                [self saveCurrentAltIconNumber:idx];
                [self savePurchasedAltIcon:idx];
                NSMutableDictionary *notificationDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
                [notificationDictionary setObject:[NSNumber numberWithInt:idx] forKey:@"idx"];
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"altIconPurchased"
                 object:nil
                 userInfo:@{@"Status": notificationDictionary}];
                DLog("Success: icon changed");
            }
            else {
                DLog("Failure with error");
            }
        }];
    }
}

- (void)updateHintsRemainingDisplayAndStorage:(int)newHints {
    if (![self checkForEndlessHintsPurchased]){
        if (newHints == -1000){
            // Indicates Endless Hints purchased
            [self setEndlessHintsPurchased];
            [rc updateMoreHintPacksButton];
            if (rc.puzzleViewController != nil){
                [rc.puzzleViewController setHintButtonLabel:newHints];
            }
            if (rc.hintsViewController != nil){
                [rc.hintsViewController updateHintsViewLabel];
                [rc.hintsViewController backButtonPressed];
            }
            if (rc.puzzleViewController.hintsViewController != nil){
                [rc.puzzleViewController.hintsViewController updateHintsViewLabel];
                [rc.puzzleViewController.hintsViewController backButtonPressed];
            }
        }
        else {
            numberOfHintsRemaining = [[self getObjectFromDefaults:@"numberOfHintsRemaining"] intValue];
            numberOfHintsRemaining = numberOfHintsRemaining + newHints;
            [self setObjectInDefaults:[NSNumber numberWithInt:numberOfHintsRemaining] forKey:@"numberOfHintsRemaining"];
            if (rc.puzzleViewController != nil){
                [rc.puzzleViewController setHintButtonLabel:numberOfHintsRemaining];
            }
            if (rc.hintsViewController != nil){
                [rc.hintsViewController updateHintsViewLabel];
            }
            if (rc.puzzleViewController.hintsViewController != nil){
                [rc.puzzleViewController.hintsViewController updateHintsViewLabel];
            }
            [rc updateMoreHintPacksButton];
        }
    }
}

- (BOOL)existPurchasedPacks {
    NSDictionary *dictionary = [self getDictionaryFromDefaults:kPaidPuzzlePacksKey];
    if (dictionary){
        return YES;
    }
    return NO;
}
  
- (BOOL)queryPurchasedPuzzlePack:(unsigned int)packNumber {
    // Access the dictionary for purchased packs if it exists
    NSDictionary *dictionary = [self getDictionaryFromDefaults:kPaidPuzzlePacksKey];
    if (dictionary) {
        NSEnumerator *enumerator = [dictionary keyEnumerator];
        id key;
        NSInteger packKeyNumber;
        while((key = [enumerator nextObject])){
            packKeyNumber = [key integerValue];
            if (packKeyNumber == packNumber){
                return YES;
            }
        }
    }
    return NO;
}

- (void)savePurchasedPuzzlePack:(int)pack {
    // Access the dictionary for purchased packs if it exists
    NSDictionary *dictionary = [self getDictionaryFromDefaults:kPaidPuzzlePacksKey];
    NSMutableDictionary *paidPuzzlePacksDictionary = [[NSMutableDictionary alloc] init];
    if (dictionary) {
        // Initialize paidPuzzlePacksDictionary if it exists
        [paidPuzzlePacksDictionary setDictionary:dictionary];
    }
    [paidPuzzlePacksDictionary setObject:[NSNumber numberWithBool:YES] forKey:[NSString stringWithFormat:@"%06d", pack]];
    [self setObjectInDefaults:paidPuzzlePacksDictionary forKey:kPaidPuzzlePacksKey];
}

- (BOOL)existPurchasedAltIcons {
    NSDictionary *dictionary = [self getDictionaryFromDefaults:kPaidAltIconsKey];
    if (dictionary){
        return YES;
    }
    return NO;
}
  
- (BOOL)queryPurchasedAltIcon:(unsigned int)iconNumber {
    // Access the dictionary for purchased packs if it exists
    NSDictionary *dictionary = [self getDictionaryFromDefaults:kPaidAltIconsKey];
    if (dictionary) {
        NSEnumerator *enumerator = [dictionary keyEnumerator];
        id key;
        NSInteger iconKeyNumber;
        while((key = [enumerator nextObject])){
            iconKeyNumber = [key integerValue];
            if (iconKeyNumber == iconNumber){
                return YES;
            }
        }
    }
    return NO;
}

- (void)savePurchasedAltIcon:(unsigned int)iconNumber {
    // Access the dictionary for purchased packs if it exists
    NSDictionary *dictionary = [self getDictionaryFromDefaults:kPaidAltIconsKey];
    NSMutableDictionary *paidAltIconsDictionary = [[NSMutableDictionary alloc] init];
    if (dictionary) {
        // Initialize paidAltIconsDictionary if it exists
        [paidAltIconsDictionary setDictionary:dictionary];
    }
    [paidAltIconsDictionary setObject:[NSNumber numberWithBool:YES] forKey:[NSString stringWithFormat:@"%06d", iconNumber]];
    [self setObjectInDefaults:paidAltIconsDictionary forKey:kPaidAltIconsKey];
}

- (void)purchasePuzzlePack:(NSString *)productionId {
    DLog("Purchase puzzle pack with id %s", [productionId UTF8String]);
    if([SKPaymentQueue canMakePayments]){
        DLog("User can make payments");
        productsRequestEnum = REQ_PURCHASE;
        SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:productionId]];
        productsRequest.delegate = self;
        [productsRequest start];
    }
    else{
        DLog("User cannot make payments, most likely due to parental controls");
    }
}

- (void)purchaseHintPack:(NSString *)productionId {
    DLog("Purchase hint pack with id %s", [productionId UTF8String]);
    if([SKPaymentQueue canMakePayments]){
        DLog("User can make payments");
        productsRequestEnum = REQ_PURCHASE;
        SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:productionId]];
        productsRequest.delegate = self;
        [productsRequest start];
    }
    else{
        DLog("User cannot make payments, most likely due to parental controls");
    }
}

- (void)purchaseAltIcon:(NSString *)productionId {
    DLog("Purchase alt icon with id %s", [productionId UTF8String]);
    if([SKPaymentQueue canMakePayments]){
        DLog("User can make payments");
        productsRequestEnum = REQ_PURCHASE;
        SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:productionId]];
        productsRequest.delegate = self;
        [productsRequest start];
    }
    else{
        DLog("User cannot make payments, most likely due to parental controls");
    }
}

+ (NSString *)removeAdsPermanentlyProductionIdentifier
{
    static NSString *removeAdsPermanentlyPI;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        removeAdsPermanentlyPI = @"BMD2_REMOVE_ADS_PERM_AD0001";
    });
    return removeAdsPermanentlyPI;
}

- (void)purchaseAdFreePuzzles {
    NSString *adFree = [self getObjectFromDefaults:@"AD_FREE_PUZZLES"];
    if (![adFree isEqualToString:@"YES"]){
        DLog("User requests to purchase ad free puzzles");
        if([SKPaymentQueue canMakePayments]){
            DLog("User can make payments");
            productsRequestEnum = REQ_PURCHASE;
            NSString *removeAdsPermanentlyPI = nil;
            removeAdsPermanentlyPI = [[self class] removeAdsPermanentlyProductionIdentifier];
            if (removeAdsPermanentlyPI != nil){
                SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:removeAdsPermanentlyPI]];
                productsRequest.delegate = self;
                [productsRequest start];
            }
        }
        else{
            DLog("User cannot make payments, most likely due to parental controls");
        }
    }
    else {
        DLog("User has already bought Ad Free Puzzles");
    }
}


//
// Methods to request information about StoreKit In-App Purchases go here
//
- (void)requestAdFreePuzzlesInfo {
    productsRequestEnum = REQ_INFO_AD_FREE;
    NSString *removeAdsPermanentlyPI = nil;
    removeAdsPermanentlyPI = [[self class] removeAdsPermanentlyProductionIdentifier];
    if (removeAdsPermanentlyPI != nil){
        SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:removeAdsPermanentlyPI]];
        productsRequest.delegate = self;
        [productsRequest start];
    }
}

- (void)requestHintPacksInfo {
    productsRequestEnum = REQ_INFO_HINT_PACK;
    // Initialize array that will receive results from StoreKit
    arrayOfPaidHintPacksInfo = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *hintPacksProductionID = [self fetchPacksArray:@"paidHintPacksArray.plist"];
    NSEnumerator *hintPacksEnum = [hintPacksProductionID objectEnumerator];
    id dict;
    NSSet *hintPacksSet = [NSSet set];
    while (dict = [hintPacksEnum nextObject]){
        hintPacksSet = [hintPacksSet setByAddingObject:[dict objectForKey:@"production_id"]];
    }

    if ([hintPacksSet count] > 0){
        SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:hintPacksSet];
        productsRequest.delegate = self;
        [productsRequest start];
    }
}

- (void)requestPuzzlePacksInfo {
    productsRequestEnum = REQ_INFO_PUZZLE_PACK;
    // Initialize array that will receive results from StoreKit
    arrayOfPuzzlePacksInfo = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *puzzlePacksArray = [self fetchPacksArray:@"puzzlePacksArray.plist"];
    NSEnumerator *puzzlePacksEnum = [puzzlePacksArray objectEnumerator];
    NSSet *puzzlePacksSet = [NSSet set];
    NSMutableDictionary *dict;
    while (dict = [puzzlePacksEnum nextObject]){
        if ([dict objectForKey:@"production_id"]){
            puzzlePacksSet = [puzzlePacksSet setByAddingObject:[dict objectForKey:@"production_id"]];
        }
    }
    if ([puzzlePacksSet count] > 0){
        SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:puzzlePacksSet];
        productsRequest.delegate = self;
        [productsRequest start];
    }
}

- (void)requestAltIconsInfo {
    productsRequestEnum = REQ_INFO_ICON;
    // Initialize array that will receive results from StoreKit
    arrayOfAltIconsInfo = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *altIconsArray = [self fetchPacksArray:@"alternateIcons.plist"];
    NSEnumerator *altIconsEnum = [altIconsArray objectEnumerator];
    NSSet *altIconsSet = [NSSet set];
    NSMutableDictionary *dict;
    while (dict = [altIconsEnum nextObject]){
        if ([dict objectForKey:@"production_id"]){
            altIconsSet = [altIconsSet setByAddingObject:[dict objectForKey:@"production_id"]];
        }
    }
    if ([altIconsSet count] > 0){
        SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:altIconsSet];
        productsRequest.delegate = self;
        [productsRequest start];
    }
}

// Handler for response from product information request to StoreKit
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    SKProduct *validProduct = nil;
    int count = (int)[response.products count];
    if(count > 0){
        validProduct = [response.products objectAtIndex:0];
        switch(productsRequestEnum){
            case REQ_INFO_PUZZLE_PACK:{
                // Traverse the puzzlePacksArray in order to create an output array with:
                // 1) elements representing free puzzle packs which will be populated with stored data
                // 2) elements with paid puzzle packs populated with StoreKit data
                NSMutableArray *puzzlePacksArray = [self fetchPacksArray:@"puzzlePacksArray.plist"];
                NSEnumerator *puzzlePacksEnum = [puzzlePacksArray objectEnumerator];
                NSMutableDictionary *inputPuzzlePackDict;
                NSMutableDictionary *outputPuzzlePackDict;
                unsigned int idx = 0;
                while (inputPuzzlePackDict = [puzzlePacksEnum nextObject]){
                    outputPuzzlePackDict = [NSMutableDictionary dictionaryWithCapacity:1];
                    [outputPuzzlePackDict setObject:[NSNumber numberWithUnsignedInt:idx] forKey:@"pack_number"];
                    [outputPuzzlePackDict setObject:[inputPuzzlePackDict objectForKey:@"pack_name"] forKey:@"pack_name"];
                    NSString *production_id = [inputPuzzlePackDict objectForKey:@"production_id"];
                    if (production_id){
                        [outputPuzzlePackDict setObject:production_id forKey:@"production_id"];
                        // Find production_id in the array of SKProduct returned by StoreKit
                        NSEnumerator *productsEnum = [response.products objectEnumerator];
                        SKProduct *currentProduct;
                        while (currentProduct = [productsEnum nextObject]){
                            NSString *productIdentifier = currentProduct.productIdentifier;
                            if ([productIdentifier isEqualToString:production_id]){
//                                [outputPuzzlePackDict setObject:currentProduct.localizedTitle forKey:@"pack_name"];
                                [outputPuzzlePackDict setObject:currentProduct.localizedDescription forKey:@"pack_description"];
                                [outputPuzzlePackDict setObject:currentProduct.price forKey:@"storekit_price"];
                                unsigned int integerPrice = round([currentProduct.price floatValue]*100);
                                [outputPuzzlePackDict setObject:[NSNumber numberWithInt:integerPrice] forKey:@"AppStorePackCost"];
                                [outputPuzzlePackDict setObject:currentProduct.priceLocale forKey:@"price_locale"];
                                // Create and store price formatted string!
                                NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                                [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
                                [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
                                [numberFormatter setLocale:currentProduct.priceLocale];
                                NSString *formattedPriceString = [numberFormatter stringFromNumber:currentProduct.price];
                                if (formattedPriceString){
                                    [outputPuzzlePackDict setObject:formattedPriceString forKey:@"formatted_price_string"];
                                }
                            }
                        }
                    }
                    else {
                        [outputPuzzlePackDict setObject:[inputPuzzlePackDict objectForKey:@"pack_name"] forKey:@"pack_name"];
                        [outputPuzzlePackDict setObject:[inputPuzzlePackDict objectForKey:@"AppStorePackCost"] forKey:@"AppStorePackCost"];
                    }
                    [arrayOfPuzzlePacksInfo addObject:outputPuzzlePackDict];
                    idx++;
                }
                productsRequestEnum = REQ_NIL;
                arrayOfPaidHintPacksInfo = nil;
                [self requestHintPacksInfo];
                break;
            }
            case REQ_INFO_HINT_PACK:{
                NSEnumerator *productsEnum = [response.products objectEnumerator];
                SKProduct *currentProduct;
                NSMutableDictionary *currentProductInfoDict;
                unsigned int idx = 0;
                while (currentProduct = [productsEnum nextObject]){
                    currentProductInfoDict = [NSMutableDictionary dictionaryWithCapacity:1];
                    [currentProductInfoDict setObject:[NSNumber numberWithUnsignedInt:idx] forKey:@"pack_number"];
                    [currentProductInfoDict setObject:currentProduct.localizedTitle forKey:@"pack_name"];
                    [currentProductInfoDict setObject:currentProduct.localizedDescription forKey:@"pack_description"];
                    [currentProductInfoDict setObject:currentProduct.productIdentifier forKey:@"production_id"];
                    [currentProductInfoDict setObject:currentProduct.price forKey:@"storekit_price"];
                    unsigned int integerPrice = round([currentProduct.price floatValue]*100);
                    [currentProductInfoDict setObject:[NSNumber numberWithInt:integerPrice] forKey:@"AppStorePackCost"];
                    [currentProductInfoDict setObject:currentProduct.priceLocale forKey:@"price_locale"];
                    // Create and store price formatted string!
                    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
                    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
                    [numberFormatter setLocale:currentProduct.priceLocale];
                    NSString *formattedPriceString = [numberFormatter stringFromNumber:currentProduct.price];
                    if (formattedPriceString){
                        [currentProductInfoDict setObject:formattedPriceString forKey:@"formatted_price_string"];
                    }
                    [arrayOfPaidHintPacksInfo addObject:currentProductInfoDict];
                    idx++;
                }
                productsRequestEnum = REQ_NIL;
                arrayOfAltIconsInfo = nil;
                [self requestAltIconsInfo];
                break;
            }
            case REQ_INFO_ICON:{
                NSEnumerator *productsEnum = [response.products objectEnumerator];
                SKProduct *currentProduct;
                NSMutableDictionary *currentProductInfoDict;
                NSMutableDictionary *bundleArrayCurrentItem;
                NSMutableArray *altIconsBundleArray = [self fetchPacksArray:@"alternateIcons.plist"];
                unsigned int idx = 0;
                while (currentProduct = [productsEnum nextObject]){
                    currentProductInfoDict = [NSMutableDictionary dictionaryWithCapacity:1];
                    bundleArrayCurrentItem = [altIconsBundleArray objectAtIndex:idx];
                    [currentProductInfoDict setObject:[bundleArrayCurrentItem objectForKey:@"appIcon"] forKey:@"appIcon"];
                    [currentProductInfoDict setObject:[bundleArrayCurrentItem objectForKey:@"iconImage"] forKey:@"iconImage"];
                    [currentProductInfoDict setObject:[NSNumber numberWithUnsignedInt:idx] forKey:@"icon_number"];
                    [currentProductInfoDict setObject:currentProduct.localizedTitle forKey:@"icon_name"];
                    [currentProductInfoDict setObject:currentProduct.localizedDescription forKey:@"icon_description"];
                    [currentProductInfoDict setObject:currentProduct.productIdentifier forKey:@"production_id"];
                    [currentProductInfoDict setObject:currentProduct.price forKey:@"storekit_price"];
                    unsigned int integerPrice = round([currentProduct.price floatValue]*100);
                    [currentProductInfoDict setObject:[NSNumber numberWithInt:integerPrice] forKey:@"AppStorePackCost"];
                    [currentProductInfoDict setObject:currentProduct.priceLocale forKey:@"price_locale"];
                    // Create and store price formatted string!
                    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
                    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
                    [numberFormatter setLocale:currentProduct.priceLocale];
                    NSString *formattedPriceString = [numberFormatter stringFromNumber:currentProduct.price];
                    if (formattedPriceString){
                        [currentProductInfoDict setObject:formattedPriceString forKey:@"formatted_price_string"];
                    }
                    [arrayOfAltIconsInfo addObject:currentProductInfoDict];
                    idx++;
                }
                // Add default icon entry as last item if arrayOfAltIconsInfo is not empty
                if (arrayOfAltIconsInfo != nil && [arrayOfAltIconsInfo count] > 0){
                    currentProductInfoDict = [NSMutableDictionary dictionaryWithCapacity:1];
                    NSMutableDictionary *dict = [altIconsBundleArray lastObject];
                    [currentProductInfoDict setObject:[NSNumber numberWithUnsignedInt:idx] forKey:@"icon_number"];
//                    bundleArrayCurrentItem = [altIconsBundleArray objectAtIndex:idx];
                    [currentProductInfoDict setObject:[dict objectForKey:@"appIcon"] forKey:@"appIcon"];
                    [currentProductInfoDict setObject:[dict objectForKey:@"iconImage"] forKey:@"iconImage"];
                    [arrayOfAltIconsInfo addObject:currentProductInfoDict];
                }
                productsRequestEnum = REQ_NIL;
                break;
            }
            case REQ_INFO_AD_FREE:{
//                NSString *productIdentifier = [NSString stringWithString:validProduct.productIdentifier];
//                NSDecimalNumber *price = validProduct.price;
//                NSString *localizedTitle = [NSString stringWithString:validProduct.localizedTitle];
                productsRequestEnum = REQ_NIL;
                break;
            }
            case REQ_PURCHASE:{
                productsRequestEnum = REQ_NIL;
                [self purchase:validProduct];
                break;
            }
            case REQ_NIL:
            default:{
                productsRequestEnum = REQ_NIL;
                break;
            }
        }
    }
    else if(!validProduct){
        DLog("No products available");
        //this is called if your product id is not valid, this shouldn't be called unless that happens.
    }
}

- (void)purchase:(SKProduct *)product{
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)restorePurchases{
    //this is called when the user restores purchases, you should hook this up to a button
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    DLog("received restored transactions: %lu", (unsigned long)queue.transactions.count);
    for(SKPaymentTransaction *transaction in queue.transactions){
        if(transaction.transactionState == SKPaymentTransactionStateRestored){
            //called when the user successfully restores a purchase
            DLog("Transaction state -> Restored");
            //if you have more than one in-app purchase product,
            //you restore the correct product for the identifier.
            //For example, you could use
            //if(productID == kRemoveAdsProductIdentifier)
            //to get the product identifier for the
            //restored purchases, you can use
            //
            int index;
            NSString *productID = transaction.payment.productIdentifier;
            NSString *removeAdsPermanentlyPI = [[self class] removeAdsPermanentlyProductionIdentifier];
            if ((index = [self fetchIndexOfPuzzleProductID:productID]) >= 0){
                [self completePuzzlePackPurchase:index];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            }
            else if ((index = [self fetchIndexOfHintPackProductID:productID]) >= 0){
                [self completeHintPackPurchase:index];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            }
            else if ((index = [self fetchIndexOfAltIconProductID:productID]) >= 0){
                [self completeAltIconPurchase:index];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            }
            else if ([removeAdsPermanentlyPI isEqualToString:productID]){
                [self completeAdFreeRestore];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            }
            break;
        }
    }
}

- (int)fetchIndexOfHintPackProductID:(NSString *)productId{
    NSMutableArray *array = [self fetchPacksArray:@"paidHintPacksArray.plist"];
    NSDictionary *dict = nil;
    for (int arrayIndex=0; arrayIndex<[array count]; arrayIndex++){
        dict = [array objectAtIndex:arrayIndex];
        if ([[dict objectForKey:@"production_id"]isEqualToString:productId]){
            return arrayIndex;
        }
    }
    return -1;
}

- (int)fetchIndexOfPuzzleProductID:(NSString *)productId{
    NSMutableArray *array = [gameDictionaries objectForKey:kPuzzlePacksArray];
    NSDictionary *dict = nil;
    for (int arrayIndex=0; arrayIndex<[array count]; arrayIndex++){
        dict = [array objectAtIndex:arrayIndex];
        if ([[dict objectForKey:@"production_id"]isEqualToString:productId]){
            return arrayIndex;
        }
    }
    return -1;
}

- (int)fetchIndexOfAltIconProductID:(NSString *)productId{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:1];
    array = [self fetchAlternateIconsArray:array];
    NSDictionary *dict = nil;
    for (int arrayIndex=0; arrayIndex<[array count]; arrayIndex++){
        dict = [array objectAtIndex:arrayIndex];
        if ([[dict objectForKey:@"production_id"]isEqualToString:productId]){
            return arrayIndex;
        }
    }
    return -1;
}

- (NSMutableArray *)fetchAlternateIconsArray:(NSMutableArray *)alternateIconsArray {
    NSString *filePath = [[NSBundle bundleForClass:[self class]]
                          pathForResource:@"alternateIcons"
                          ofType:@"plist"];
    alternateIconsArray = [NSMutableArray arrayWithCapacity:1];
    alternateIconsArray = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
    return alternateIconsArray;
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions{
    for(SKPaymentTransaction *transaction in transactions){
        //if you have multiple in app purchases in your app,
        //you can get the product identifier of this transaction
        //by using transaction.payment.productIdentifier
        //
        //then, check the identifier against the product IDs
        //that you have defined to check which product the user
        //just purchased

        NSString *productID;
        NSString *removeAdsPermanentlyPI = [[self class] removeAdsPermanentlyProductionIdentifier];
        int index;
        switch(transaction.transactionState){
            case SKPaymentTransactionStatePurchasing:
                DLog("Transaction state -> Purchasing");
                //called when the user is in the process of purchasing, do not add any of your own code here.
                break;
            case SKPaymentTransactionStatePurchased:
                //this is called when the user has successfully purchased the package (Ka-Ching!)
                productID = transaction.payment.productIdentifier;
                if ((index = [self fetchIndexOfPuzzleProductID:productID]) >= 0){
                    [self completePuzzlePackPurchase:index];
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                }
                else if ((index = [self fetchIndexOfHintPackProductID:productID]) >= 0){
                    [self completeHintPackPurchase:index];
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                }
                else if ((index = [self fetchIndexOfAltIconProductID:productID]) >= 0){
                    [self completeAltIconPurchase:index];
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                }
                else if ([removeAdsPermanentlyPI isEqualToString:productID]){
                    [self completeAdFreePurchase];
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                }
                DLog("Transaction state -> Purchased");
                break;
            case SKPaymentTransactionStateRestored:
                productID = transaction.payment.productIdentifier;
                if ((index = [self fetchIndexOfPuzzleProductID:productID]) >= 0){
                    [self completePuzzlePackPurchase:index];
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                }
                else if ((index = [self fetchIndexOfHintPackProductID:productID]) >= 0){
                    [self completeHintPackPurchase:index];
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                }
                else if ((index = [self fetchIndexOfAltIconProductID:productID]) >= 0){
                    [self completeAltIconPurchase:index];
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                }
                else if ([removeAdsPermanentlyPI isEqualToString:productID]){
                    [self completeAdFreeRestore];
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                }
                DLog("Transaction state -> Restored");
                break;
            case SKPaymentTransactionStateFailed:
                //called when the transaction does not finish
                if(transaction.error.code == SKErrorPaymentCancelled){
                    DLog("Transaction state -> Cancelled");
                    //the user cancelled the payment ;(
                }
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateDeferred:
                DLog("Transaction state -> Deferred");
                break;
        }
    }
}

- (BOOL)reviewRequestIsAppropriate {
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString* versionString = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSString* storedLatestVersionReviewedString = [self getObjectFromDefaults:kCFBundleShortVersionStringHasBeenReviewed];
    if (storedLatestVersionReviewedString == nil){
        return YES;
    }
    else if ([storedLatestVersionReviewedString isEqualToString:versionString] == NO)
        return YES;
    else
        return NO;
}

- (BOOL)automatedReviewRequestIsAppropriate {
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString* versionString = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSString* storedLatestVersionReviewedString = [self getObjectFromDefaults:kCFBundleShortVersionStringHasBeenReviewed];
    int totalPuzzlesSolved = [self countPuzzlesSolved];
    if (storedLatestVersionReviewedString == nil &&
        totalPuzzlesSolved > 0 &&
        totalPuzzlesSolved % 5 == 0){
        return YES;
    }
    else if ([storedLatestVersionReviewedString isEqualToString:versionString] == NO &&
        totalPuzzlesSolved > 0 &&
        totalPuzzlesSolved % 5 == 0)
        return YES;
    else
        return NO;
}


//
// Vungle Ad Network Methods
//
- (void)vungleSDKDidInitialize{
    DLog("Vungle Ad Network Initialized");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    vungleIsLoaded = YES;
    // Cache Vungle Rewarded Ad
    [self vungleLoadRewardedAd];
    // Load Vungle Banner Ad
    if (vungleIsLoaded &&
        ([[defaults objectForKey:@"demoHasBeenCompleted"] isEqualToString:@"YES"] ||
         TARGET_OS_SIMULATOR) &&
        rc.appCurrentPageNumber == PAGE_HOME){
        switch (rc.displayAspectRatio) {
            case ASPECT_4_3:
                // iPad (9th generation)
            case ASPECT_10_7:
                // iPad Air (5th generation)
            case ASPECT_3_2: {
                // iPad Mini (6th generation)
                [self vungleLoadBannerLeaderboardAd];
                break;
            }
            case ASPECT_16_9:
            case ASPECT_13_6:
            default: {
                // iPhones
                [self vungleLoadBannerAd];
                break;
            }
        }
    }
}

- (void)vungleLoadBannerAd{
    DLog("vungleLoadBannerAd");
    NSString *adFree = [self getObjectFromDefaults:@"AD_FREE_PUZZLES"];
    if ([adFree isEqualToString:@"YES"]){
        DLog("User purchased Ad Free Puzzles");
    }
    else {
        NSError *error;
        if (rc.bannerAdView != nil){
            [rc.bannerAdView removeFromSuperview];
            rc.bannerAdView = nil;
        }
        VungleSDK* sdk = [VungleSDK sharedSDK];
        if (![sdk loadPlacementWithID:vunglePlacementBanner withSize:VungleAdSizeBanner error:&error]) {
            if (error) {
                DLog("Error occurred in loadPlacementWithID: %@", error);
            }
        }
        else {
            DLog("vungleLoadBannerAd: success");
        }
    }
}

- (void)vungleLoadBannerLeaderboardAd{
    NSString *adFree = [self getObjectFromDefaults:@"AD_FREE_PUZZLES"];
    if ([adFree isEqualToString:@"YES"]){
        DLog("User purchased Ad Free Puzzles");
    }
    else {
        DLog("vungleLoadBannerLeaderboardAd");
        NSError *error;
        if (rc.bannerAdView != nil){
            [rc.bannerAdView removeFromSuperview];
            rc.bannerAdView = nil;
        }
        VungleSDK* sdk = [VungleSDK sharedSDK];
        if (![sdk loadPlacementWithID:vunglePlacementBannerLeaderboard withSize:VungleAdSizeBannerLeaderboard error:&error]) {
            if (error) {
                DLog("Error occurred in loadPlacementWithID: %@", error);
            }
        }
        else {
            DLog("vungleLoadBannerLeaderboardAd: success");
        }
    }
}

- (void)vungleLoadRewardedAd{
    NSError *error;
    VungleSDK* sdk = [VungleSDK sharedSDK];
    if (![sdk loadPlacementWithID:vunglePlacementRewardedHint error:&error]) {
        DLog("vungleLoadRewardedAd: not a success");
        if (error) {
            DLog("Error occurred in loadPlacementWithID: %@", error);
        }
    }
    else {
        DLog("vungleLoadRewardedAd: success");
    }
}

- (void)vungleCloseBannerAd {
    DLog("vungleCloseBannerAd");
    VungleSDK* sdk = [VungleSDK sharedSDK];
    [sdk finishDisplayingAd:vunglePlacementBanner];
    [sdk finishDisplayingAd:vunglePlacementBannerLeaderboard];
    if (rc.bannerAdView != nil){
        [rc.bannerAdView removeFromSuperview];
        rc.bannerAdView = nil;
    }
}


//
// Vungle Ad Network Callbacks
//
- (void)vungleWillShowAdForPlacementID:(nullable NSString *)placementID{
    DLog("vungleWillShowAdForPlacementID %s", [placementID UTF8String]);
    if ([placementID isEqualToString:vunglePlacementRewardedHint]){
        // Nothing right now
    }
}

- (void)vungleDidCloseAdForPlacementID:(nonnull NSString *)placementID{
    if ([placementID isEqualToString:vunglePlacementRewardedHint]){
        // Cache Vungle Rewarded Ad
        DLog("vungleDidCloseAdForPlacementID %s", [placementID UTF8String]);
        [self vungleLoadRewardedAd];
    }
}

- (void)vungleTrackClickForPlacementID:(nullable NSString *)placementID{
    DLog("vungleTrackClickForPlacementID %s", [placementID UTF8String]);
}

- (void)vungleRewardUserForPlacementID:(nullable NSString *)placementID{
    DLog("vungleRewardUserForPlacementID %s", [placementID UTF8String]);
    [self updateHintsRemainingDisplayAndStorage:1];
}

- (void)vungleAdPlayabilityUpdate:(BOOL)isAdPlayable placementID:(NSString *)placementID error:(nullable NSError *)error {
    DLog("vungleAdPlayabilityUpdate: %s", [placementID UTF8String]);
    VungleSDK* sdk = [VungleSDK sharedSDK];
    
    // Banner Ads
    if ([placementID isEqualToString:vunglePlacementBanner] ||
        [placementID isEqualToString:vunglePlacementBannerLeaderboard]){
        if (rc.bannerAdView == nil &&
            [sdk isAdCachedForPlacementID:placementID] &&
            rc.renderPuzzleON == NO){
            DLog("addAdViewToView: %s", [placementID UTF8String]);
            NSError *adError;
            [rc buildVungleAdView];
            if (![sdk addAdViewToView:rc.bannerAdView withOptions:nil placementID:placementID error:&adError]) {
                if (adError) {
                    DLog("Error encountered in addAdViewToView: %@", adError);
                }
            }
        }
    }
    // Interstitial Rewarded Ad
    else if ([placementID isEqualToString:vunglePlacementRewardedHint]){
//        if ([sdk isAdCachedForPlacementID:placementID]){
//            [self vunglePlayRewardedAd];
//        }
    }
    else {
        DLog("placementID %s does not match any active ads", [placementID UTF8String]);
    }
    
}


@end
