/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation of renderer class which performs Metal setup and per frame rendering
*/

@import simd;
@import MetalKit;

#import "BMDRenderer.h"
#import "BMDViewController.h"
#import "BMDAppDelegate.h"

//
//
// Metal and MetalKit storage
//

MTKView *_view;
NSMutableArray *renderArray;
NSMutableDictionary *renderDictionary;
NSMutableArray *tileRenderArray;

// Main class performing the rendering
API_AVAILABLE(ios(13.0))
@implementation BMDRenderer
{
    // The device (aka GPU) used to render
    id<MTLDevice> _device;
    MTKView *_view;
    
    id<MTLRenderPipelineState> _pipelineState0;
    id<MTLRenderPipelineState> _pipelineState1;
    id<MTLRenderPipelineState> _pipelineState2;
    id<MTLRenderPipelineState> _pipelineState3;
    id<MTLRenderPipelineState> _pipelineState4;
    id<MTLRenderPipelineState> _pipelineState5;
    id<MTLRenderPipelineState> _pipelineState6;
    id<MTLRenderPipelineState> _pipelineState7;
    id<MTLRenderPipelineState> _pipelineState8;
    id<MTLRenderPipelineState> _pipelineState9;

    // The command Queue used to submit commands.
    id<MTLCommandQueue> _commandQueue;
    
    id<MTLRenderCommandEncoder> _renderEncoder;

    // The Metal texture objects
    id<MTLTexture>      __strong _texture;
    
    // The Metal buffer that holds the vertex data.
    id<MTLBuffer> _vertices;

    // The number of vertices in the vertex buffer.
    NSUInteger _numVertices;

    // The current size of the view.
    vector_uint2 _viewportSize;
    
    // Display frame counter
    u_long frameCounter;
    
    // Device screen dimensions
    CGFloat _screenWidthInPixels;
    CGFloat _screenHeightInPixels;

    // Matrix transformation
    matrix_float2x2 _rotationMatrix;
    matrix_float2x2 _identityMatrix;

    // Rotation Transformation Uniform
    id<MTLBuffer> _transformationRotation;
    id<MTLBuffer> _transformationIdentity;
}


- (MTLFunctionConstantValues *)functionConstantsForColors:(BOOL)hasRedColor hasGreenColor:(BOOL)hasGreenColor hasBlueColor:(BOOL)hasBlueColor
{
    MTLFunctionConstantValues* constantValues = [MTLFunctionConstantValues new];
    [constantValues setConstantValue:&hasRedColor type:MTLDataTypeBool atIndex:AAPLColorConstantRed];
    [constantValues setConstantValue:&hasGreenColor type:MTLDataTypeBool atIndex:AAPLColorConstantGreen];
    [constantValues setConstantValue:&hasBlueColor type:MTLDataTypeBool atIndex:AAPLColorConstantBlue];
    return constantValues;
}


- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView
{
    self = [super init];
    if(self)
    {
        _device = mtkView.device;
        _view = mtkView;
    }
    //
    // Create the render pipelines.
    //
    // Load the shaders from the default library
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
    id<MTLFunction> redFragmentFunction = [defaultLibrary newFunctionWithName:@"redShader"];
    id<MTLFunction> greenFragmentFunction = [defaultLibrary newFunctionWithName:@"greenShader"];
    id<MTLFunction> blueFragmentFunction = [defaultLibrary newFunctionWithName:@"blueShader"];
    id<MTLFunction> yellowFragmentFunction = [defaultLibrary newFunctionWithName:@"yellowShader"];
    id<MTLFunction> magentaFragmentFunction = [defaultLibrary newFunctionWithName:@"magentaShader"];
    id<MTLFunction> cyanFragmentFunction = [defaultLibrary newFunctionWithName:@"cyanShader"];
    id<MTLFunction> whiteFragmentFunction = [defaultLibrary newFunctionWithName:@"whiteShader"];
    id<MTLFunction> originalColorFragmentFunction = [defaultLibrary newFunctionWithName:@"originalColorShader"];
    id<MTLFunction> grayFragmentFunction = [defaultLibrary newFunctionWithName:@"grayColorShader"];
    id<MTLFunction> deepPurpleFragmentFunction = [defaultLibrary newFunctionWithName:@"deepPurpleShader"];

    // Set up a descriptor for creating a pipeline state object
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    
    // Create render pipeline red
    pipelineStateDescriptor.label = @"Texturing Pipeline Red";
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = redFragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
    pipelineStateDescriptor.colorAttachments[0].blendingEnabled = YES;
    pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    NSError *error = nil;
    _pipelineState0 = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    NSAssert(_pipelineState0, @"Failed to created red pipeline state, error %@", error);

    // Create render pipeline green
    pipelineStateDescriptor.label = @"Texturing Pipeline Green";
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = greenFragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
    pipelineStateDescriptor.colorAttachments[0].blendingEnabled = YES;
    pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    _pipelineState1 = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    NSAssert(_pipelineState1, @"Failed to created green pipeline state, error %@", error);

    // Create render pipeline blue
    pipelineStateDescriptor.label = @"Texturing Pipeline Blue";
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = blueFragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
    pipelineStateDescriptor.colorAttachments[0].blendingEnabled = YES;
    pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    _pipelineState2 = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    NSAssert(_pipelineState2, @"Failed to created blue pipeline state, error %@", error);

    // Create render pipeline yellow
    pipelineStateDescriptor.label = @"Texturing Pipeline Yellow";
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = yellowFragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
    pipelineStateDescriptor.colorAttachments[0].blendingEnabled = YES;
    pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    _pipelineState3 = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    NSAssert(_pipelineState3, @"Failed to created blue pipeline state, error %@", error);

    // Create render pipeline magenta
    pipelineStateDescriptor.label = @"Texturing Pipeline magenta";
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = magentaFragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
    pipelineStateDescriptor.colorAttachments[0].blendingEnabled = YES;
    pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    _pipelineState4 = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    NSAssert(_pipelineState4, @"Failed to created magenta pipeline state, error %@", error);

    // Create render pipeline cyan
    pipelineStateDescriptor.label = @"Texturing Pipeline cyan";
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = cyanFragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
    pipelineStateDescriptor.colorAttachments[0].blendingEnabled = YES;
    pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    _pipelineState5 = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    NSAssert(_pipelineState5, @"Failed to created cyan pipeline state, error %@", error);

    // Create render pipeline white
    pipelineStateDescriptor.label = @"Texturing Pipeline white";
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = whiteFragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
    pipelineStateDescriptor.colorAttachments[0].blendingEnabled = YES;
    pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    _pipelineState6 = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    NSAssert(_pipelineState6, @"Failed to created white pipeline state, error %@", error);

    // Create render pipeline originalColor
    pipelineStateDescriptor.label = @"Texturing Pipeline originalColor";
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = originalColorFragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
    pipelineStateDescriptor.colorAttachments[0].blendingEnabled = YES;
    pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    _pipelineState7 = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    NSAssert(_pipelineState7, @"Failed to created original color pipeline state, error %@", error);
    
    // Create render pipeline gray
    pipelineStateDescriptor.label = @"Texturing Pipeline gray";
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = grayFragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
    pipelineStateDescriptor.colorAttachments[0].blendingEnabled = YES;
    pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    _pipelineState8 = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    NSAssert(_pipelineState8, @"Failed to created gray pipeline state, error %@", error);

    // Create render pipeline deep purple
    pipelineStateDescriptor.label = @"Texturing Pipeline deep purple";
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = deepPurpleFragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
    pipelineStateDescriptor.colorAttachments[0].blendingEnabled = YES;
    pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    _pipelineState9 = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    NSAssert(_pipelineState9, @"Failed to created deep purple pipeline state, error %@", error);

    //
    // Create the command queue
    //
    _commandQueue = [_device newCommandQueue];
    NSAssert(_commandQueue, @"Failed to created command queue, error %@", error);

    //
    // Instruct BMDAppDelegate to load and store textures
    //
//    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
//    if (![appDelegate initAllTextures:mtkView metalRenderer:self])
//        DLog("Texture initialization failed.");
    
    return self;
}

// Called whenever view changes orientation or is resized
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    // Save the size of the drawable to pass to the vertex shader.
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

// Called whenever the view needs to render a frame
- (void)drawInMTKView:(nonnull MTKView *)view
{
    // Calling drawInMTKView
    _view = view;
    _view.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);
    
    // Create a new command buffer for each render pass to the current drawable
    id<MTLCommandBuffer> commandBuffer1 = [_commandQueue commandBuffer];
    commandBuffer1.label = @"MyCommand1";

    // Obtain a renderPassDescriptor generated from the view's drawable textures
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    
    // Experiment with clearColor
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);

    // Experiment with texture rotation
    _identityMatrix = identity_matrix();

    if(renderPassDescriptor != nil)
    {
        // Create a new Render Encoder
        _renderEncoder = [commandBuffer1 renderCommandEncoderWithDescriptor:renderPassDescriptor];
        _renderEncoder.label = @"MyRenderEncoder";
        // Set the region of the drawable to draw into.
        [_renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }];
        
        // - App displays are a mixture of UIViews directly controlled by BMDViewController and Metal textures
        //   which are rendered here.
        // - Use the App Page number to determine what textures should be rendered
        BMDViewController *rootController = (BMDViewController*)[[(BMDAppDelegate *)[[UIApplication sharedApplication]delegate] window] rootViewController];
        BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];

        if (rootController.renderBackgroundON){
            // Load and draw textures for various screen backgrounds other than Puzzles
            renderDictionary = [rootController renderBackground];
            
            // Draw a background image behind other screen elements
            TextureRenderData *backgroundImage = [renderDictionary objectForKey:@"backgroundImage"];
            if (backgroundImage != nil){
                [self drawMetalTexture:backgroundImage withView:_view texturePositionInPixels:backgroundImage->texturePositionInPixels textureSizeInPixels:backgroundImage->textureDimensionsInPixels withPipelineState:backgroundImage->tileColor withRotationTransformation:NO];
            }
            
            // Render array of ring textures
            [self renderRingTextures:[renderDictionary objectForKey:@"ringRenderArray"] withPipelineState:7];
        }
        
        if (rootController.renderPuzzleON){
            // Load and draw textures
            //
            // Update Optics
            // - receive array of Tile RenderData
            // - receive background RenderData
            Optics *optics = appDelegate->optics;
            renderDictionary = [optics renderPuzzle];
            
            // Draw a background image behind the Gameplay area
            TextureRenderData *backgroundImage = [renderDictionary objectForKey:@"backgroundImage"];
            if (backgroundImage != nil){
                [self drawMetalTexture:backgroundImage withView:_view texturePositionInPixels:backgroundImage->texturePositionInPixels textureSizeInPixels:backgroundImage->textureDimensionsInPixels withPipelineState:backgroundImage->tileColor withRotationTransformation:NO];
            }

            // Draw an outer background behind the Gameplay area where the Lasers and Jewels appear
            TextureRenderData *backgroundOuter = [renderDictionary objectForKey:@"backgroundRenderDataOuter"];
            if (backgroundOuter != nil){
                [self drawMetalTexture:backgroundOuter withView:_view texturePositionInPixels:backgroundOuter->texturePositionInPixels textureSizeInPixels:backgroundOuter->textureDimensionsInPixels withPipelineState:backgroundOuter->tileColor withRotationTransformation:NO];
            }

            // Draw an inner background behind the Gameplay area where the other Tiles appear
            TextureRenderData *backgroundInner = [renderDictionary objectForKey:@"backgroundRenderDataInner"];
            if (backgroundInner != nil){
                [self drawMetalTexture:backgroundInner withView:_view texturePositionInPixels:backgroundInner->texturePositionInPixels textureSizeInPixels:backgroundInner->textureDimensionsInPixels withPipelineState:backgroundInner->tileColor withRotationTransformation:NO];
            }

            // Draw a background behind the unused Tiles area
            TextureRenderData *unusedTileBackground = [renderDictionary objectForKey:@"unusedTileBackgroundRenderData"];
            if (unusedTileBackground != nil){
                [self drawMetalTexture:unusedTileBackground withView:_view texturePositionInPixels:unusedTileBackground->texturePositionInPixels textureSizeInPixels:unusedTileBackground->textureDimensionsInPixels withPipelineState:unusedTileBackground->tileColor withRotationTransformation:NO];
            }

            // Draw a border around the game screen
            TextureRenderData *border = [renderDictionary objectForKey:@"borderRenderData"];
            if (border != nil){
                [self drawMetalTexture:border withView:_view texturePositionInPixels:border->texturePositionInPixels textureSizeInPixels:border->textureDimensionsInPixels withPipelineState:border->tileColor withRotationTransformation:NO];
            }
            
            // Render an array of Tile-sized background textures
            [self renderTextureArray:[renderDictionary objectForKey:@"backgroundRenderArray"] withPipelineState:7];
            
            // Render BeamTextureRenderData
            [self renderBeamTextureArray:[renderDictionary objectForKey:@"beamsRenderArray"]];
            
            // Render Tutorial arrow if present
            if ([renderDictionary objectForKey:@"arrowRenderData"]){
                [self drawArrowTextureRenderData:[renderDictionary objectForKey:@"arrowRenderData"] withView:_view withPipelineState:3];
            }
            
            // Render array of tile textures
            [self renderTileTextures:[renderDictionary objectForKey:@"tileRenderArray"] withPipelineState:1];
            
            // Render array of ring textures
            [self renderRingTextures:[renderDictionary objectForKey:@"ringRenderArray"] withPipelineState:7];
            
            // Render game control array of tile textures
            if ([renderDictionary objectForKey:@"gameControlTiles"]){
                [self renderTileTextures:[renderDictionary objectForKey:@"gameControlTiles"] withPipelineState:1];
            }
            
            // Render a foreground completion texture
            if ([renderDictionary objectForKey:@"puzzleCompleteRenderArray"] != nil){
                [self renderTextureArray:[renderDictionary objectForKey:@"puzzleCompleteRenderArray"] withPipelineState:7];
            }
        }
        
        // That is all the encoder commands for this frame
        [_renderEncoder endEncoding];
        
        // Schedule and present once the framebuffer is complete using the current drawable
                    [commandBuffer1 presentDrawable:view.currentDrawable];
        
        // Finalize rendering here & push the command buffer to the GPU
        [commandBuffer1 commit];
        
    }
    
}


- (void)prepareVertexBuffer:(nonnull MTKView *)mtkView texturePositionInPixelsX:(int)positionX texturePositionInPixelsY:(int)positionY textureSizeInPixels:(vector_int2)size isMetal:(BOOL)metal rotationAngle:(float)angle
{
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    BMDViewController *rc = (BMDViewController*)[[(BMDAppDelegate *)[[UIApplication sharedApplication]delegate] window] rootViewController];
    
    vector_int2 position;
    position.x = positionX; position.y = positionY;

    // Set up a simple MTLBuffer with vertices which include texture coordinates
    AAPLVertex quadVertices[6];
    
    vector_float2 textureTopLeft;        // (0, 0) in Metal texture space
    vector_float2 textureTopRight;       // (1, 0) in Metal texture space
    vector_float2 textureLowerLeft;      // (0, 1) in Metal texture space
    vector_float2 textureLowerRight;     // (1, 1) in Metal texture space
    
    textureTopLeft[0] =     (float)position.x   -   ((float)rc.screenWidthInPixels/2.f);
    textureTopLeft[1] =     -(float)position.y   +   ((float)rc.screenHeightInPixels/2.f);
    textureTopRight[0] =    (float)position.x   -   ((float)rc.screenWidthInPixels/2.f)   + (float)size.x;
    textureTopRight[1] =    -(float)position.y   +   ((float)rc.screenHeightInPixels/2.f);
    textureLowerLeft[0] =   (float)position.x   -   ((float)rc.screenWidthInPixels/2.f);
    textureLowerLeft[1] =   -(float)position.y   +   ((float)rc.screenHeightInPixels/2.f)  - (float)size.y;
    textureLowerRight[0] =  (float)position.x   -   ((float)rc.screenWidthInPixels/2.f)   + (float)size.x;
    textureLowerRight[1] =  -(float)position.y   +   ((float)rc.screenHeightInPixels/2.f)  - (float)size.y;

    if (metal) {
        // Use Metal convention to set up the texture to screen mapping based on the characteristics of the device screen
        quadVertices[0].position = textureLowerRight;
        quadVertices[0].textureCoordinate[0] = 1.f;
        quadVertices[0].textureCoordinate[1] = 1.f;
        quadVertices[1].position = textureLowerLeft;
        quadVertices[1].textureCoordinate[0] = 0.f;
        quadVertices[1].textureCoordinate[1] = 1.f;
        quadVertices[2].position = textureTopLeft;
        quadVertices[2].textureCoordinate[0] = 0.f;
        quadVertices[2].textureCoordinate[1] = 0.f;
        quadVertices[3].position = textureLowerRight;
        quadVertices[3].textureCoordinate[0] = 1.f;
        quadVertices[3].textureCoordinate[1] = 1.f;
        quadVertices[4].position = textureTopLeft;
        quadVertices[4].textureCoordinate[0] = 0.f;
        quadVertices[4].textureCoordinate[1] = 0.f;
        quadVertices[5].position = textureTopRight;
        quadVertices[5].textureCoordinate[0] = 1.f;
        quadVertices[5].textureCoordinate[1] = 0.f;
    } else {
        // Use OpenGL convention to set up the texture to screen mapping based on the characteristics of the device screen
        quadVertices[0].position = textureLowerRight;
        quadVertices[0].textureCoordinate[0] = 1.f;
        quadVertices[0].textureCoordinate[1] = 0.f;
        quadVertices[1].position = textureLowerLeft;
        quadVertices[1].textureCoordinate[0] = 0.f;
        quadVertices[1].textureCoordinate[1] = 0.f;
        quadVertices[2].position = textureTopLeft;
        quadVertices[2].textureCoordinate[0] = 0.f;
        quadVertices[2].textureCoordinate[1] = 1.f;
        quadVertices[3].position = textureLowerRight;
        quadVertices[3].textureCoordinate[0] = 1.f;
        quadVertices[3].textureCoordinate[1] = 0.f;
        quadVertices[4].position = textureTopLeft;
        quadVertices[4].textureCoordinate[0] = 0.f;
        quadVertices[4].textureCoordinate[1] = 1.f;
        quadVertices[5].position = textureTopRight;
        quadVertices[5].textureCoordinate[0] = 1.f;
        quadVertices[5].textureCoordinate[1] = 1.f;
    }

    // Create a vertex buffer, and initialize it with the quadVertices array
    _vertices = [_device newBufferWithBytes:quadVertices length:sizeof(quadVertices) options:MTLResourceStorageModeShared];

    //Calculate a Rotation Transformation
    _rotationMatrix = matrix_from_rotation(angle);
    _transformationRotation = [_device newBufferWithBytes:(void*)&_rotationMatrix length:sizeof(_rotationMatrix) options:MTLResourceStorageModeShared];
    
    //Calculate an Identity Transformation
    _transformationIdentity = [_device newBufferWithBytes:(void*)&_identityMatrix length:sizeof(_identityMatrix) options:MTLResourceStorageModeShared];

    // Calculate the number of vertices by dividing the byte length by the size of each vertex
    _numVertices = sizeof(quadVertices) / sizeof(AAPLVertex);
}


- (void)renderRingTextures:(NSMutableArray *)tileTextures withPipelineState:(int)pipelineState {
    // Render array of tile textures
    TextureRenderData *textureRenderData;
    NSEnumerator *TextureRenderDataEnumerator = [tileTextures objectEnumerator];
    uint color;
    while (textureRenderData = [TextureRenderDataEnumerator nextObject]) {
        // Draw the ring
        color = textureRenderData->tileColor;
        [self drawRingTexture:textureRenderData withView:_view withPipelineState:color];
        [self drawRingTexture:textureRenderData withView:_view withPipelineState:color];
        [self drawRingTexture:textureRenderData withView:_view withPipelineState:color];
   }
}

- (void)drawRingTexture:(TextureRenderData *)textureRenderData withView:(nonnull MTKView *)view withPipelineState:(int)pipelineState {
    [self prepareVertexBuffer:view texturePositionInPixelsX:textureRenderData->texturePositionInPixels.x texturePositionInPixelsY:textureRenderData->texturePositionInPixels.y textureSizeInPixels:textureRenderData->textureDimensionsInPixels isMetal:YES rotationAngle:0.0];
    switch(pipelineState){
        case 0:
            [_renderEncoder setRenderPipelineState:_pipelineState0];
            break;
        case 1:
            [_renderEncoder setRenderPipelineState:_pipelineState1];
            break;
        case 2:
            [_renderEncoder setRenderPipelineState:_pipelineState2];
            break;
        case 3:
            [_renderEncoder setRenderPipelineState:_pipelineState3];
            break;
        case 4:
            [_renderEncoder setRenderPipelineState:_pipelineState4];
            break;
        case 5:
            [_renderEncoder setRenderPipelineState:_pipelineState5];
            break;
        case 6:
            [_renderEncoder setRenderPipelineState:_pipelineState6];
            break;
        case 7:
            [_renderEncoder setRenderPipelineState:_pipelineState7];
            break;
        case 8:
            [_renderEncoder setRenderPipelineState:_pipelineState8];
            break;
        case 9:
            [_renderEncoder setRenderPipelineState:_pipelineState9];
            break;
        default:
            [_renderEncoder setRenderPipelineState:_pipelineState6];
    }
    [_renderEncoder setVertexBuffer:_vertices offset:0 atIndex:AAPLVertexInputIndexVertices];
    [_renderEncoder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:AAPLVertexInputIndexViewportSize];
    [_renderEncoder setVertexBuffer:_transformationIdentity offset:0 atIndex:2];
    [_renderEncoder setFragmentTexture:textureRenderData.renderTexture atIndex:AAPLTextureIndexBaseColor];
    // Draw the triangles.
    [_renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_numVertices];
}

- (void)renderTileTextures:(NSMutableArray *)tileTextures withPipelineState:(int)pipelineState {
    // Render array of tile textures
    TextureRenderData *textureRenderData;
    NSEnumerator *TextureRenderDataEnumerator = [tileTextures objectEnumerator];
    uint color;
    while (textureRenderData = [TextureRenderDataEnumerator nextObject]) {
        
        switch (textureRenderData->tileShape) {
            case LASER:
                color = 7;          // Draw in the original colors
                [self drawMetalTileTexture:textureRenderData withView:_view  withPipelineState:color withRotationTransformation:YES];
                break;
            case JEWEL:
                if (textureRenderData->tileAnimation == TILE_A_ENERGIZED && textureRenderData->isJewelBackground == YES){
                    color = textureRenderData->tileColor;
                    color = 7;
                    [self drawMetalTileTexture:textureRenderData withView:_view  withPipelineState:color withRotationTransformation:YES];
                    break;
                }
                if (textureRenderData->tileAnimation == TILE_A_ENERGIZED && textureRenderData->isJewelBackground == NO){
                    color = COLOR_WHITE;
                    color = 7;
                    [self drawMetalTileTexture:textureRenderData withView:_view  withPipelineState:color withRotationTransformation:YES];
                    break;
                }
                if (textureRenderData->tileAnimation == TILE_A_LIGHTSWEEP){
                    color = textureRenderData->tileColor;
                    color = 7;
                    [self drawMetalTileTexture:textureRenderData withView:_view  withPipelineState:color withRotationTransformation:YES];
                    break;
                }
                if (textureRenderData->tileAnimation == TILE_A_WAITING || textureRenderData->tileAnimation == TILE_A_STATIC) {
                    color = textureRenderData->tileColor;
                    color = 7;
                    [self drawMetalTileTexture:textureRenderData withView:_view  withPipelineState:color withRotationTransformation:YES];
                    break;
                }
                else {
                    color = textureRenderData->tileColor;
                    color = 7;
                    [self drawMetalTileTexture:textureRenderData withView:_view  withPipelineState:color withRotationTransformation:YES];
                }
                break;
            case MIRROR:
                color = 7;              // Use original color
                [self drawMetalTileTexture:textureRenderData withView:_view  withPipelineState:color withRotationTransformation:YES];
                break;
            case BEAMSPLITTER:
                color = 7;              // Use original color
                [self drawMetalTileTexture:textureRenderData withView:_view  withPipelineState:color withRotationTransformation:YES];
                break;
            case PRISM:
                color = 7;
                [self drawMetalTileTexture:textureRenderData withView:_view  withPipelineState:color withRotationTransformation:YES];
               break;
            case RECTANGLE:
                if (textureRenderData->tileAnimationContainer == TILE_AC_GLOWWHITE_RECTANGLE &&
                    (textureRenderData->tileAnimation == TILE_A_WAITING ||
                     textureRenderData->tileAnimation == TILE_A_ENERGIZED)) {
                    color = textureRenderData->tileColor;
                    [self drawMetalTileTexture:textureRenderData withView:_view  withPipelineState:color withRotationTransformation:YES];
                    [self drawMetalTileTexture:textureRenderData withView:_view  withPipelineState:color withRotationTransformation:YES];
                    [self drawMetalTileTexture:textureRenderData withView:_view  withPipelineState:color withRotationTransformation:YES];
                    [self drawMetalTileTexture:textureRenderData withView:_view  withPipelineState:color withRotationTransformation:YES];
                    [self drawMetalTileTexture:textureRenderData withView:_view  withPipelineState:color withRotationTransformation:YES];
                }
                else {
                    color = textureRenderData->tileColor;
                    [self drawMetalTileTexture:textureRenderData withView:_view  withPipelineState:color withRotationTransformation:YES];
                }
                break;
            default:
//                color = 7;  // TEST - use original color
//                [self drawMetalTileTexture:textureRenderData withView:_view  withPipelineState:color withRotationTransformation:YES];
                break;
        }
   }
}

- (void)renderTextureArray:(NSMutableArray *)backgroundTextureArray withPipelineState:(int)pipelineState {
    // Render array of tile textures
    TextureRenderData *textureRenderData;
    NSEnumerator *TextureRenderDataEnumerator = [backgroundTextureArray objectEnumerator];
    uint color;
    while (textureRenderData = [TextureRenderDataEnumerator nextObject]) {
        // Draw one background texture without rotation
        color = textureRenderData->tileColor;
        [self drawMetalTileTexture:textureRenderData withView:_view  withPipelineState:pipelineState withRotationTransformation:NO];
//        [self drawMetalTileTexture:textureRenderData withView:_view  withPipelineState:color withRotationTransformation:NO];
    }
}

- (vector_int2)preRotationTilePosition:(TextureRenderData *)textureRenderData rotationAngle:(CGFloat)rotationAngle {
    // If the tile has an angle other than ANGLE0 and if transformation==YES then
    // pre-compensate for the rotation about the center of the display by giving the tile a different
    // display location.
    vector_int2 precompensatedPosition;
    vector_float2 origin;
    origin.x = _viewportSize.x/2.0;
    origin.y = _viewportSize.y/2.0;
    CGFloat deltaX = textureRenderData->texturePositionInPixels.x - origin.x + textureRenderData->textureDimensionsInPixels.x/2.0;
    CGFloat deltaY = textureRenderData->texturePositionInPixels.y - origin.y + textureRenderData->textureDimensionsInPixels.y/2.0;
    CGFloat radius = sqrt(pow(deltaX,2) + pow(deltaY,2));
    CGFloat objectAngle;
    if (deltaX > 0)
        objectAngle = asin(deltaY/radius);
    else
        objectAngle = PI - asin(deltaY/radius);
    precompensatedPosition.x = (int)(radius*cos(objectAngle+rotationAngle) + origin.x - textureRenderData->textureDimensionsInPixels.x/2.0);
    precompensatedPosition.y = (int)(radius*sin(objectAngle+rotationAngle) + origin.y - textureRenderData->textureDimensionsInPixels.y/2.0);
    return precompensatedPosition;
}

- (void)drawMetalTileTexture:(TextureRenderData *)textureRenderData withView:(nonnull MTKView *)view withPipelineState:(int)pipelineState withRotationTransformation:(BOOL)transformation {
    // If the tile has an angle other than ANGLE0 and if transformation==YES then
    // pre-compensate for the rotation about the center of the display by giving the tile a different
    // display location.
    CGFloat rotationAngle = -(float)textureRenderData->angle*PI/4.0;
    vector_int2 precompensatedPosition = [self preRotationTilePosition:textureRenderData rotationAngle:rotationAngle];
    if (textureRenderData->angle!=ANGLE0 && transformation==YES) {
        [self prepareVertexBuffer:view texturePositionInPixelsX:precompensatedPosition.x texturePositionInPixelsY:precompensatedPosition.y textureSizeInPixels:textureRenderData->textureDimensionsInPixels isMetal:NO rotationAngle:rotationAngle];
    } else {
        [self prepareVertexBuffer:view texturePositionInPixelsX:textureRenderData->texturePositionInPixels.x texturePositionInPixelsY:textureRenderData->texturePositionInPixels.y textureSizeInPixels:textureRenderData->textureDimensionsInPixels isMetal:NO rotationAngle:0.0];
    }
    switch(pipelineState){
        case 0:
            [_renderEncoder setRenderPipelineState:_pipelineState0];
            break;
        case 1:
            [_renderEncoder setRenderPipelineState:_pipelineState1];
            break;
        case 2:
            [_renderEncoder setRenderPipelineState:_pipelineState2];
            break;
        case 3:
            [_renderEncoder setRenderPipelineState:_pipelineState3];
            break;
        case 4:
            [_renderEncoder setRenderPipelineState:_pipelineState4];
            break;
        case 5:
            [_renderEncoder setRenderPipelineState:_pipelineState5];
            break;
        case 6:
            [_renderEncoder setRenderPipelineState:_pipelineState6];
            break;
        case 7:
            [_renderEncoder setRenderPipelineState:_pipelineState7];
            break;
        case 8:
            [_renderEncoder setRenderPipelineState:_pipelineState8];
            break;
        case 9:
            [_renderEncoder setRenderPipelineState:_pipelineState9];
            break;
        default:
            [_renderEncoder setRenderPipelineState:_pipelineState6];
    }
    [_renderEncoder setVertexBuffer:_vertices offset:0 atIndex:AAPLVertexInputIndexVertices];
    [_renderEncoder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:AAPLVertexInputIndexViewportSize];
    if (transformation)
        [_renderEncoder setVertexBuffer:_transformationRotation offset:0 atIndex:2];
    else
        [_renderEncoder setVertexBuffer:_transformationIdentity offset:0 atIndex:2];
    [_renderEncoder setFragmentTexture:textureRenderData.renderTexture atIndex:AAPLTextureIndexBaseColor];
    // Draw the triangles.
    [_renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_numVertices];
}

- (void)drawPrismSpectrumTexture:(TextureRenderData *)textureRenderData withView:(nonnull MTKView *)view withPipelineState:(int)pipelineState withRotationTransformation:(BOOL)transformation {
    // If the tile has an angle other than ANGLE0 and if transformation==YES then
    // pre-compensate for the rotation about the center of the display by giving the tile a different
    // display location.
    CGFloat rotationAngle = -(float)textureRenderData->spectrumAngle*PI/4.0;
    vector_int2 precompensatedPosition = [self preRotationTilePosition:textureRenderData rotationAngle:rotationAngle];
    if (textureRenderData->angle!=ANGLE0 && transformation==YES) {
        [self prepareVertexBuffer:view texturePositionInPixelsX:precompensatedPosition.x texturePositionInPixelsY:precompensatedPosition.y textureSizeInPixels:textureRenderData->textureDimensionsInPixels isMetal:NO rotationAngle:rotationAngle];
    } else {
        [self prepareVertexBuffer:view texturePositionInPixelsX:textureRenderData->texturePositionInPixels.x texturePositionInPixelsY:textureRenderData->texturePositionInPixels.y textureSizeInPixels:textureRenderData->textureDimensionsInPixels isMetal:NO rotationAngle:0.0];
    }
    switch(pipelineState){
        case 0:
            [_renderEncoder setRenderPipelineState:_pipelineState0];
            break;
        case 1:
            [_renderEncoder setRenderPipelineState:_pipelineState1];
            break;
        case 2:
            [_renderEncoder setRenderPipelineState:_pipelineState2];
            break;
        case 3:
            [_renderEncoder setRenderPipelineState:_pipelineState3];
            break;
        case 4:
            [_renderEncoder setRenderPipelineState:_pipelineState4];
            break;
        case 5:
            [_renderEncoder setRenderPipelineState:_pipelineState5];
            break;
        case 6:
            [_renderEncoder setRenderPipelineState:_pipelineState6];
            break;
        case 7:
            [_renderEncoder setRenderPipelineState:_pipelineState7];
            break;
        case 8:
            [_renderEncoder setRenderPipelineState:_pipelineState8];
            break;
        case 9:
            [_renderEncoder setRenderPipelineState:_pipelineState9];
            break;
        default:
            [_renderEncoder setRenderPipelineState:_pipelineState6];
    }
    [_renderEncoder setVertexBuffer:_vertices offset:0 atIndex:AAPLVertexInputIndexVertices];
    [_renderEncoder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:AAPLVertexInputIndexViewportSize];
    if (transformation)
        [_renderEncoder setVertexBuffer:_transformationRotation offset:0 atIndex:2];
    else
        [_renderEncoder setVertexBuffer:_transformationIdentity offset:0 atIndex:2];
    [_renderEncoder setFragmentTexture:textureRenderData.spectrumTexture atIndex:AAPLTextureIndexBaseColor];
    // Draw the triangles.
    [_renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_numVertices];
}


- (void)renderBeamTextureArray:(NSMutableArray *)beamTextureArray {
    // Render array of beam textures from a 2d array of BeamTextureRenderData instances
    NSEnumerator *bgaEnum = [beamTextureArray objectEnumerator];
    BeamTextureRenderData *brd;
    unsigned int color;
    while (brd = [bgaEnum nextObject]) {
        color = [self mapBeamColorVector:brd->beamCountsByColor];
        [self drawMetalBeamTextureRenderData:brd withView:_view  withPipelineState:color withRotationTransformation:YES];
    }
}

- (vector_int2)preRotationBeamPosition:(BeamTextureRenderData *)beamTextureRenderData rotationAngle:(CGFloat)rotationAngle {
    // If the tile has an angle other than ANGLE0 and if transformation==YES then
    // pre-compensate for the rotation about the center of the display by giving the tile a different
    // display location.
    vector_int2 precompensatedPosition;
    vector_float2 origin;
    origin.x = _viewportSize.x/2.0;
    origin.y = _viewportSize.y/2.0;
    CGFloat deltaX = beamTextureRenderData->texturePositionInPixels.x - origin.x + beamTextureRenderData->textureDimensionsInPixels.x/2.0;
    CGFloat deltaY = beamTextureRenderData->texturePositionInPixels.y - origin.y + beamTextureRenderData->textureDimensionsInPixels.y/2.0;
    CGFloat radius = sqrt(pow(deltaX,2) + pow(deltaY,2));
    CGFloat objectAngle;
    if (deltaX > 0)
        objectAngle = asin(deltaY/radius);
    else
        objectAngle = PI - asin(deltaY/radius);
    precompensatedPosition.x = (int)(radius*cos(objectAngle+rotationAngle) + origin.x - beamTextureRenderData->textureDimensionsInPixels.x/2.0);
    precompensatedPosition.y = (int)(radius*sin(objectAngle+rotationAngle) + origin.y - beamTextureRenderData->textureDimensionsInPixels.y/2.0);
    return precompensatedPosition;
}



- (unsigned int)mapBeamColorVector:(vector_uint3)colorVector {
    unsigned int color = COLOR_WHITE;
    if (colorVector[0] > 0 && colorVector[1] ==0 && colorVector[2] == 0)
        color = COLOR_RED;
    else if (colorVector[0] == 0 && colorVector[1] > 0 && colorVector[2] == 0)
        color = COLOR_GREEN;
    else if (colorVector[0] == 0 && colorVector[1] == 0 && colorVector[2] > 0)
        color = COLOR_BLUE;
    else if (colorVector[0] > 0 && colorVector[1] > 0 && colorVector[2] == 0)
        color = COLOR_YELLOW;
    else if (colorVector[0] == 0 && colorVector[1] > 0 && colorVector[2] > 0)
        color = COLOR_CYAN;
    else if (colorVector[0] > 0 && colorVector[1] == 0 && colorVector[2] > 0)
        color = COLOR_MAGENTA;
    else if (colorVector[0] > 0 && colorVector[1] > 0 && colorVector[2] > 0)
        color = COLOR_WHITE;
    return color;
}

- (void)drawArrowTextureRenderData:(TextureRenderData *)textureRenderData withView:(nonnull MTKView *)view withPipelineState:(int)pipelineState{
    CGFloat rotationAngle = (float)textureRenderData->arrowAngle;
    vector_int2 precompensatedPosition = [self preRotationTilePosition:textureRenderData rotationAngle:rotationAngle];
        [self prepareVertexBuffer:view texturePositionInPixelsX:precompensatedPosition.x texturePositionInPixelsY:precompensatedPosition.y textureSizeInPixels:textureRenderData->textureDimensionsInPixels isMetal:YES rotationAngle:rotationAngle];
    switch(pipelineState){
        case 0:
            [_renderEncoder setRenderPipelineState:_pipelineState0];
            break;
        case 1:
            [_renderEncoder setRenderPipelineState:_pipelineState1];
            break;
        case 2:
            [_renderEncoder setRenderPipelineState:_pipelineState2];
            break;
        case 3:
            [_renderEncoder setRenderPipelineState:_pipelineState3];
            break;
        case 4:
            [_renderEncoder setRenderPipelineState:_pipelineState4];
            break;
        case 5:
            [_renderEncoder setRenderPipelineState:_pipelineState5];
            break;
        case 6:
            [_renderEncoder setRenderPipelineState:_pipelineState6];
            break;
        case 7:
            [_renderEncoder setRenderPipelineState:_pipelineState7];
            break;
        case 8:
            [_renderEncoder setRenderPipelineState:_pipelineState8];
            break;
        case 9:
            [_renderEncoder setRenderPipelineState:_pipelineState9];
            break;
        default:
            [_renderEncoder setRenderPipelineState:_pipelineState6];
    }
    [_renderEncoder setVertexBuffer:_vertices offset:0 atIndex:AAPLVertexInputIndexVertices];
    [_renderEncoder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:AAPLVertexInputIndexViewportSize];
    [_renderEncoder setVertexBuffer:_transformationRotation offset:0 atIndex:2];
    [_renderEncoder setFragmentTexture:textureRenderData.renderTexture atIndex:AAPLTextureIndexBaseColor];
    // Draw the triangles.
    [_renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_numVertices];
}




- (void)drawMetalBeamTextureRenderData:(BeamTextureRenderData *)beamTextureRenderData withView:(nonnull MTKView *)view withPipelineState:(int)pipelineState withRotationTransformation:(BOOL)transformation{
    // If the beam has an angle other than ANGLE0 and if transformation==YES then
    // pre-compensate for the rotation about the center of the display by giving the tile a different
    // display location.
    CGFloat rotationAngle = (float)beamTextureRenderData->angle*PI/4.0;
    if (beamTextureRenderData->angle % 2 != 0 && beamTextureRenderData->angle % 4 != 0) {
        rotationAngle = - rotationAngle;
    }
    vector_int2 precompensatedPosition = [self preRotationBeamPosition:beamTextureRenderData rotationAngle:rotationAngle];
    if (beamTextureRenderData->angle!=ANGLE0 && transformation==YES) {
        [self prepareVertexBuffer:view texturePositionInPixelsX:precompensatedPosition.x texturePositionInPixelsY:precompensatedPosition.y textureSizeInPixels:beamTextureRenderData->textureDimensionsInPixels isMetal:YES rotationAngle:rotationAngle];
    }
    else {
        [self prepareVertexBuffer:view texturePositionInPixelsX:beamTextureRenderData->texturePositionInPixels.x texturePositionInPixelsY:beamTextureRenderData->texturePositionInPixels.y textureSizeInPixels:beamTextureRenderData->textureDimensionsInPixels isMetal:YES rotationAngle:0.0];
    }
    switch(pipelineState){
        case 0:
            [_renderEncoder setRenderPipelineState:_pipelineState0];
            break;
        case 1:
            [_renderEncoder setRenderPipelineState:_pipelineState1];
            break;
        case 2:
            [_renderEncoder setRenderPipelineState:_pipelineState2];
            break;
        case 3:
            [_renderEncoder setRenderPipelineState:_pipelineState3];
            break;
        case 4:
            [_renderEncoder setRenderPipelineState:_pipelineState4];
            break;
        case 5:
            [_renderEncoder setRenderPipelineState:_pipelineState5];
            break;
        case 6:
            [_renderEncoder setRenderPipelineState:_pipelineState6];
            break;
        case 7:
            [_renderEncoder setRenderPipelineState:_pipelineState7];
            break;
        case 8:
            [_renderEncoder setRenderPipelineState:_pipelineState8];
            break;
        case 9:
            [_renderEncoder setRenderPipelineState:_pipelineState9];
            break;
        default:
            [_renderEncoder setRenderPipelineState:_pipelineState6];
    }
    [_renderEncoder setVertexBuffer:_vertices offset:0 atIndex:AAPLVertexInputIndexVertices];
    [_renderEncoder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:AAPLVertexInputIndexViewportSize];
    if (transformation)
        [_renderEncoder setVertexBuffer:_transformationRotation offset:0 atIndex:2];
    else
        [_renderEncoder setVertexBuffer:_transformationIdentity offset:0 atIndex:2];
    [_renderEncoder setFragmentTexture:beamTextureRenderData.beamRenderTexture atIndex:AAPLTextureIndexBaseColor];
    // Draw the triangles.
    [_renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_numVertices];
}


- (void)drawMetalTexture:(TextureRenderData *)textureRenderData withView:(nonnull MTKView *)view texturePositionInPixels:(vector_int2)position textureSizeInPixels:(vector_int2)size withPipelineState:(int)pipelineState withRotationTransformation:(BOOL)transformation {
    // Draw the tile
    _texture = textureRenderData.renderTexture;
    [self prepareVertexBuffer:view texturePositionInPixelsX:position.x texturePositionInPixelsY:position.y textureSizeInPixels:size isMetal:YES rotationAngle:0.0];
    switch(pipelineState){
        case 0:
            [_renderEncoder setRenderPipelineState:_pipelineState0];
            break;
        case 1:
            [_renderEncoder setRenderPipelineState:_pipelineState1];
            break;
        case 2:
            [_renderEncoder setRenderPipelineState:_pipelineState2];
            break;
        case 3:
            [_renderEncoder setRenderPipelineState:_pipelineState3];
            break;
        case 4:
            [_renderEncoder setRenderPipelineState:_pipelineState4];
            break;
        case 5:
            [_renderEncoder setRenderPipelineState:_pipelineState5];
            break;
        case 6:
            [_renderEncoder setRenderPipelineState:_pipelineState6];
            break;
        case 7:
            [_renderEncoder setRenderPipelineState:_pipelineState7];
            break;
        case 8:
            [_renderEncoder setRenderPipelineState:_pipelineState8];
            break;
        case 9:
            [_renderEncoder setRenderPipelineState:_pipelineState9];
            break;
        default:
            [_renderEncoder setRenderPipelineState:_pipelineState6];
    }
    [_renderEncoder setVertexBuffer:_vertices offset:0 atIndex:AAPLVertexInputIndexVertices];
    [_renderEncoder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:AAPLVertexInputIndexViewportSize];
    if (transformation)
        [_renderEncoder setVertexBuffer:_transformationRotation offset:0 atIndex:2];
    else
        [_renderEncoder setVertexBuffer:_transformationIdentity offset:0 atIndex:2];
    [_renderEncoder setFragmentTexture:_texture atIndex:AAPLTextureIndexBaseColor];
    // Draw the triangles.
    [_renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_numVertices];
}

static matrix_float2x2 matrix_from_rotation(float radians)
{
    float cos = cosf(radians);
    float sin = sinf(radians);
    
    matrix_float2x2 m = {
        .columns[0] = {
            cos,
            sin,
        },
        .columns[1] = {
            -sin,
            cos,
        },
    };
    return m;
}

static matrix_float2x2 identity_matrix()
{
    
    matrix_float2x2 m = {
        .columns[0] = {
            1.0,
            0.0,
        },
        .columns[1] = {
            0.0,
            1.0,
        },
    };
    return m;
}

@end
