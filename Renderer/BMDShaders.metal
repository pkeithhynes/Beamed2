/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal shaders used for this sample
*/

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// Include header shared between this Metal shader code and C code executing Metal API commands
#import "BMDShaderTypes.h"

constant bool hasRedColor [[function_constant(AAPLColorConstantRed)]];
constant bool hasGreenColor [[function_constant(AAPLColorConstantGreen)]];
constant bool hasBlueColor [[function_constant(AAPLColorConstantBlue)]];

typedef struct
{
    // The [[position]] attribute qualifier of this member indicates this value is
    // the clip space position of the vertex when this structure is returned from
    // the vertex shader
    float4 position [[position]];

    // Since this member does not have a special attribute qualifier, the rasterizer
    // will interpolate its value with values of other vertices making up the triangle
    // and pass that interpolated value to the fragment shader for each fragment in
    // that triangle.
    float2 textureCoordinate;
} RasterizerData;

// Vertex Function
vertex RasterizerData
vertexShader(uint vertexID [[ vertex_id ]],
             constant AAPLVertex *vertexArray [[ buffer(AAPLVertexInputIndexVertices) ]],
             constant vector_uint2 *viewportSizePointer  [[ buffer(AAPLVertexInputIndexViewportSize) ]], constant float2x2 &transformation [[buffer(2)]])

{

    RasterizerData out;

    // Index into the array of positions to get the current vertex.
    //   Positions are specified in pixel dimensions (i.e. a value of 100 is 100 pixels from
    //   the origin)
    float2 pixelSpacePosition = transformation*vertexArray[vertexID].position.xy;

    // Get the viewport size and cast to float.
    float2 viewportSize = float2(*viewportSizePointer);

    // To convert from positions in pixel space to positions in clip-space,
    //  divide the pixel coordinates by half the size of the viewport.
    // Z is set to 0.0 and w to 1.0 because this is 2D sample.
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = pixelSpacePosition / (viewportSize / 2.0);
//    out.position.xy = transformation*out.position.xy;

    // Pass the input textureCoordinate straight to the output RasterizerData. This value will be
    //   interpolated with the other textureCoordinate values in the vertices that make up the
    //   triangle.
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    return out;
}

// Fragment function
//fragment float4 fragmentShader(RasterizerData in [[stage_in]])
//{
//    // Return the interpolated color.
//    return in.color;
//}

fragment float4
redShader(RasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[ texture(AAPLTextureIndexBaseColor) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    // Sample the texture to obtain a color
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    
    float4 color = float4(1.0, 0.3, 0.3, 1.0);
    
    if (colorSample.a > 0.0) {
        return colorSample.a*color;
    }

    // return the color of the texture
    return float4(colorSample);
}

fragment float4
greenShader(RasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[ texture(AAPLTextureIndexBaseColor) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    // Sample the texture to obtain a color
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    
    float4 color = float4(0.3, 1.0, 0.3, 1.0);
    
    if (colorSample.a > 0.0) {
        return colorSample.a*color;
    }

    // return the color of the texture
    return float4(colorSample);
}

fragment float4
blueShader(RasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[ texture(AAPLTextureIndexBaseColor) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    // Sample the texture to obtain a color
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    
    float4 color = float4(0.3, 0.5, 1.0, 1.0);
    
    if (colorSample.a > 0.0) {
        return colorSample.a*color;
    }

    // return the color of the texture
    return float4(colorSample);
}


fragment float4
yellowShader(RasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[ texture(AAPLTextureIndexBaseColor) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    // Sample the texture to obtain a color
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    
//    float4 color = float4(1.0, 1.0, 0.0, 1.0);
    float4 color = float4(251.0/255.0, 212.0/255.0, 12.0/255.0, 1.0);

    if (colorSample.a > 0.0) {
        return colorSample.a*color;
    }

    // return the color of the texture
    return float4(colorSample);
}


fragment float4
magentaShader(RasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[ texture(AAPLTextureIndexBaseColor) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    // Sample the texture to obtain a color
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    
    float4 color = float4(1.0, 0.0, 1.0, 1.0);
    
    if (colorSample.a > 0.0) {
        return colorSample.a*color;
    }

    // return the color of the texture
    return float4(colorSample);
}


fragment float4
cyanShader(RasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[ texture(AAPLTextureIndexBaseColor) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    // Sample the texture to obtain a color
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    
    float4 color = float4(0.0, 1.0, 1.0, 1.0);
    
    if (colorSample.a > 0.0) {
        return colorSample.a*color;
    }

    // return the color of the texture
    return float4(colorSample);
}


fragment float4
whiteShader(RasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[ texture(AAPLTextureIndexBaseColor) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    // Sample the texture to obtain a color
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    
    float4 color = float4(1.0, 1.0, 1.0, 1.0);
    
    if (colorSample.a > 0.0) {
        return colorSample.a*color;
    }

    // return the color of the texture
    return float4(colorSample);
}


fragment float4
originalColorShader(RasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[ texture(AAPLTextureIndexBaseColor) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    // Sample the texture to obtain a color
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    
//    colorSample.a = 1.0;
    
//    float4 color = float4(1.0, 1.0, 1.0, 1.0);
    
//    if (colorSample.a > 0.0) {
//        return colorSample.a*color;
//    }

    // return the color of the texture
    return float4(colorSample);
}

fragment float4
grayColorShader(RasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[ texture(AAPLTextureIndexBaseColor) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    // Sample the texture to obtain a color
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    
    float4 color = float4(1.0, 1.0, 1.0, 0.6);
    
    if (colorSample.a > 0.0) {
        return colorSample.a*color;
    }

    // return the color of the texture
    return float4(colorSample);
}


fragment float4
deepPurpleShader(RasterizerData in [[stage_in]],
               texture2d<half> colorTexture [[ texture(AAPLTextureIndexBaseColor) ]])
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);

    // Sample the texture to obtain a color
    const half4 colorSample = colorTexture.sample(textureSampler, in.textureCoordinate);
    
    float4 color = float4(0.2275, 0.1412, 0.2314, 1.0);
    
    if (colorSample.a > 0.0) {
        return colorSample.a*color;
    }

    // return the color of the texture
    return float4(colorSample);
}



