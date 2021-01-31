#  ImageDemo

## Overview
This code demonstrates how to apply live filters to a camera feed on iOS. The user can enable a filter that inverts the colours.

## Requirements
* Xcode 12 (tested only with 12.4)
* iOS 13 (tested only with 14.4)
* physical iOS device

## How to run
Open the ` ImageDemo.xcodeproj` and run the *ImageDemo* scheme.

## Implementation rationale

The standard community advice would be to use  [GPUImage](https://github.com/BradLarson/GPUImage) ([Stackoverflow post](https://stackoverflow.com/questions/5156872/how-to-apply-filters-to-avcapturevideopreviewlayer/5158856#5158856)).

However this appears to be outdated information (the answer is from 2011). GPUImage relies on OpenGL ES, which has been deprecated by Apple in favor for Metal (which promises better performace). It also has not been updated in 5 years.

On the same stackoverflow page, [another user has linked](https://stackoverflow.com/a/60650215/2378197) some official Apple  [sample code](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/avcamfilter_applying_filters_to_a_capture_stream) that demonstrates a live color filter using Metal and CoreImage.

The sample code adds a rose-red filter to the camera feed. I figured it should be easy enough to modify it for my purposes.

I have fully reused some components from the sample such as the shaders, the Metal backed UIView subclass  `PreviewMetalView` and `RosyCIRenderer` (renamed to `ColorInvertCIRenderer`), which applies a CIImageFilter to a pixel buffer. The rest of the code I have written myself.

The colour inversion is achieved using the `CIColorInvert`  filter.