#  ImageDemo

## Overview
This code demonstrates how to apply live filters to a camera feed on iOS. The user can enable a filter that inverts the colours.

## How to run
Requirements: Xcode 12, iOS 14
Open the  ImageDemo.xcodeproj and run the ImageDemo scheme.

## Implementation rationale

The standard advice in the community how to implement this would be through GPUImage:

https://stackoverflow.com/questions/5156872/how-to-apply-filters-to-avcapturevideopreviewlayer/5158856#5158856 
https://github.com/BradLarson/GPUImage

GPUImage is a third party dependency and is using OpenGL ES. It has been around since iOS 4.

Since then, Apple has introduced Metal as a replacement for OpenGL ES on its platforms.

Apple has released sample code for applying live image filters using Metal: 

https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/avcamfilter_applying_filters_to_a_capture_stream
