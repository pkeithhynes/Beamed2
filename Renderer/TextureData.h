//
//  TextureData.h
//  BasicTexturing
//
//  This class associates a Texture with a source file and is used for storage of loaded Textures.
//
//  Created by Patrick Keith-Hynes on 11/20/20.
//  Copyright © 2020 Apple. All rights reserved.
//
@import MetalKit;

#import <Foundation/Foundation.h>
#import "Definitions.h"

NS_ASSUME_NONNULL_BEGIN

@interface TextureData : NSObject
    @property NSString *textureFilename;
    @property id<MTLTexture>  texture;
@end

NS_ASSUME_NONNULL_END
