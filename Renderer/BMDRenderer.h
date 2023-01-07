/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header for renderer class which performs Metal setup and per frame rendering
*/

@import MetalKit;

#import "Definitions.h"
#import "TextureData.h"
#import "TextureRenderData.h"
#import "BeamTextureRenderData.h"
#import "Optics.h"


// Header shared between C code here, which executes Metal API commands, and .metal files, which
//   uses these types as inputs to the shaders
#import "BMDShaderTypes.h"




// The platform independent renderer class
@interface BMDRenderer : NSObject<MTKViewDelegate> {
    @public
}

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView;

@end
