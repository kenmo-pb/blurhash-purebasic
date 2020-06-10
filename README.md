# blurhash-purebasic
BlurHash encoder and decoder library for [PureBasic](http://purebasic.com), by [kenmo-pb](https://github.com/kenmo-pb)

## What is BlurHash?
[BlurHash](https://blurha.sh) is a small algorithm by [Dag Ågren](https://github.com/DagAgren) / [Wolt](https://github.com/woltapp) for encoding an image to a short string (typically 20-30 characters), which can be decoded to a colorful, blurred placeholder image.

![Encode/decode example](https://github.com/woltapp/blurhash/raw/master/Media/HowItWorks2.jpg)

## Uses

Uses for BlurHash include:
- display colorful placeholders (client-side) before full-res images are downloaded (like Instagram)
- blur images marked as 'sensitive' until the user chooses to display them (like Mastodon)
- artistic effect and design
- guide the user's focus elsewhere

![Placeholder example](https://github.com/woltapp/blurhash/raw/master/Media/WhyBlurHash.png)

## PureBasic Implementation

Using this library is as simple as 'Including' one file, and calling the declared procedures:

    IncludeFile "BlurHash.pbi"
    
    
    ; Encode an image (already loaded) and return its BlurHash string
    Declare.s BlurHashEncodeFromImage(Image.i, xComponents.i = #PB_Default, yComponents.i = #PB_Default, PreShrink.i = #False)
    
    ; Encode an image (from file path) and return its BlurHash string
    Declare.s BlurHashEncodeFromFile(File.s, xComponents.i = #PB_Default, yComponents.i = #PB_Default, PreShrink.i = #False)
    
    ; Decode a BlurHash string to an image in memory
    Declare.i BlurHashDecodeToImage(Hash.s, DestImage.i = #PB_Any, width.i = #PB_Default, height.i = #PB_Default, PreShrink.i = #False)
    
    ; Decode a BlurHash string to an image file
    Declare.i BlurHashDecodeToFile(Hash.s, DestFile.s, width.i = #PB_Default, height.i = #PB_Default, PreShrink.i = #False)
    
    ; Directly BlurHash an input image (already loaded) to an output image
    Declare.i BlurHashImageToImage(SourceImage.i, DestImage.i = #PB_Any, xComponents.i = #PB_Default, yComponents.i = #PB_Default, width.i = #PB_Default, height.i = #PB_Default, PreShrink.i = #False)
    
    ; Directly BlurHash an input image (from file path) to an output file
    Declare.i BlurHashFileToFile(SourceFile.s, DestFile.s, xComponents.i = #PB_Default, yComponents.i = #PB_Default, width.i = #PB_Default, height.i = #PB_Default, PreShrink.i = #False)

The `xComponents` and `yComponents` refer to the number of color components encoded in the string. The default is 4x3.

The `PreShrink` parameter can be set to `#True` to speed up encoding/decoding at a negligible cost in accuracy. (The output image is vague and blurred anyway.)

## Commandline Program

This project also contains a simple PureBasic commandline program to demonstrate encoding and decoding. The usage is:

    blurhash encode <inFile> [xComps] [yComps] [outFile]
    blurhash decode <hashString> <outFile> [width] [height]

A pre-compiled Windows executable is included.

## References
- https://blurha.sh
- https://github.com/woltapp/blurhash (including example images)
- https://github.com/woltapp/blurhash/pull/42
- https://github.com/halcy/blurhash-python
