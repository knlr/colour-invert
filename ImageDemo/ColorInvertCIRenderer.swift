/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The rosy-colored filter renderer, implemented with Core Image.
*/

import CoreMedia
import CoreVideo
import CoreImage

class ColorInvertCIRenderer {
    
    var isPrepared = false
    private var ciContext: CIContext?
    private var ciFilter: CIFilter?
    private var outputColorSpace: CGColorSpace?
    private var outputPixelBufferPool: CVPixelBufferPool?
    private(set) var outputFormatDescription: CMFormatDescription?
    private(set) var inputFormatDescription: CMFormatDescription?


    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        guard let rosyFilter = ciFilter,
              let ciContext = ciContext,
              isPrepared else {
            assertionFailure("Invalid state: Not prepared")
            return nil
        }

        let sourceImage = CIImage(cvImageBuffer: pixelBuffer)
        rosyFilter.setValue(sourceImage, forKey: kCIInputImageKey)

        guard let filteredImage = rosyFilter.value(forKey: kCIOutputImageKey) as? CIImage else {
            print("CIFilter failed to render image")
            return nil
        }

        var pbuf: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, outputPixelBufferPool!, &pbuf)
        guard let outputPixelBuffer = pbuf else {
            print("Allocation failure")
            return nil
        }

        // Render the filtered image out to a pixel buffer (no locking needed, as CIContext's render method will do that)
        ciContext.render(filteredImage, to: outputPixelBuffer, bounds: filteredImage.extent, colorSpace: outputColorSpace)
        return outputPixelBuffer
    }

    /// - Tag: FilterCoreImageRosy
    func prepare(with formatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int) {
        reset()
        
        (outputPixelBufferPool,
         outputColorSpace,
         outputFormatDescription) = allocateOutputBufferPool(
            with: formatDescription,
            outputRetainedBufferCountHint: outputRetainedBufferCountHint)
        if outputPixelBufferPool == nil {
            return
        }
        inputFormatDescription = formatDescription
        ciContext = CIContext()
        ciFilter = CIFilter(name: "CIColorInvert")
        isPrepared = true
    }
}

private extension ColorInvertCIRenderer {
    func reset() {
        ciContext = nil
        ciFilter = nil
        outputColorSpace = nil
        outputPixelBufferPool = nil
        outputFormatDescription = nil
        inputFormatDescription = nil
        isPrepared = false
    }


    func allocateOutputBufferPool(with inputFormatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int) ->(
        outputBufferPool: CVPixelBufferPool?,
        outputColorSpace: CGColorSpace?,
        outputFormatDescription: CMFormatDescription?) {

        let inputMediaSubType = CMFormatDescriptionGetMediaSubType(inputFormatDescription)
        if inputMediaSubType != kCVPixelFormatType_32BGRA {
            assertionFailure("Invalid input pixel buffer type \(inputMediaSubType)")
            return (nil, nil, nil)
        }

        let inputDimensions = CMVideoFormatDescriptionGetDimensions(inputFormatDescription)
        var pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: UInt(inputMediaSubType),
            kCVPixelBufferWidthKey as String: Int(inputDimensions.width),
            kCVPixelBufferHeightKey as String: Int(inputDimensions.height),
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]

        // Get pixel buffer attributes and color space from the input format description.
        var cgColorSpace = CGColorSpaceCreateDeviceRGB()
        if let inputFormatDescriptionExtension = CMFormatDescriptionGetExtensions(inputFormatDescription) as Dictionary? {
            let colorPrimaries = inputFormatDescriptionExtension[kCVImageBufferColorPrimariesKey]

            if let colorPrimaries = colorPrimaries {
                var colorSpaceProperties: [String: AnyObject] = [kCVImageBufferColorPrimariesKey as String: colorPrimaries]

                if let yCbCrMatrix = inputFormatDescriptionExtension[kCVImageBufferYCbCrMatrixKey] {
                    colorSpaceProperties[kCVImageBufferYCbCrMatrixKey as String] = yCbCrMatrix
                }

                if let transferFunction = inputFormatDescriptionExtension[kCVImageBufferTransferFunctionKey] {
                    colorSpaceProperties[kCVImageBufferTransferFunctionKey as String] = transferFunction
                }

                pixelBufferAttributes[kCVBufferPropagatedAttachmentsKey as String] = colorSpaceProperties
            }

            if let cvColorspace = inputFormatDescriptionExtension[kCVImageBufferCGColorSpaceKey] {
                cgColorSpace = cvColorspace as! CGColorSpace
            } else if (colorPrimaries as? String) == (kCVImageBufferColorPrimaries_P3_D65 as String) {
                cgColorSpace = CGColorSpace(name: CGColorSpace.displayP3)!
            }
        }

        // Create a pixel buffer pool with the same pixel attributes as the input format description.
        let poolAttributes = [kCVPixelBufferPoolMinimumBufferCountKey as String: outputRetainedBufferCountHint]
        var cvPixelBufferPool: CVPixelBufferPool?
        CVPixelBufferPoolCreate(kCFAllocatorDefault, poolAttributes as NSDictionary?, pixelBufferAttributes as NSDictionary?, &cvPixelBufferPool)
        guard let pixelBufferPool = cvPixelBufferPool else {
            assertionFailure("Allocation failure: Could not allocate pixel buffer pool.")
            return (nil, nil, nil)
        }

        preallocateBuffers(pool: pixelBufferPool, allocationThreshold: outputRetainedBufferCountHint)

        // Get the output format description.
        var pixelBuffer: CVPixelBuffer?
        var outputFormatDescription: CMFormatDescription?
        let auxAttributes = [kCVPixelBufferPoolAllocationThresholdKey as String: outputRetainedBufferCountHint] as NSDictionary
        CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, pixelBufferPool, auxAttributes, &pixelBuffer)
        if let pixelBuffer = pixelBuffer {
            CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                         imageBuffer: pixelBuffer,
                                                         formatDescriptionOut: &outputFormatDescription)
        }
        pixelBuffer = nil

        return (pixelBufferPool, cgColorSpace, outputFormatDescription)
    }

    /// - Tag: AllocateRenderBuffers
    func preallocateBuffers(pool: CVPixelBufferPool, allocationThreshold: Int) {
        var pixelBuffers = [CVPixelBuffer]()
        var error: CVReturn = kCVReturnSuccess
        let auxAttributes = [kCVPixelBufferPoolAllocationThresholdKey as String: allocationThreshold] as NSDictionary
        var pixelBuffer: CVPixelBuffer?
        while error == kCVReturnSuccess {
            error = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, pool, auxAttributes, &pixelBuffer)
            if let pixelBuffer = pixelBuffer {
                pixelBuffers.append(pixelBuffer)
            }
            pixelBuffer = nil
        }
        pixelBuffers.removeAll()
    }
}
