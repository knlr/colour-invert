//
//  PreviewMetalView.swift
//  ImageDemo
//
//  Created by Knut Lorenzen on 31/01/2021.
//

import Metal
import MetalKit


class PreviewMetalView: MTKView {

    private var internalPixelBuffer: CVPixelBuffer?
    private let syncQueue = DispatchQueue(label: "Preview View Sync Queue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    private var textureCache: CVMetalTextureCache!
    private var textureWidth: Int = 0
    private var textureHeight: Int = 0
    private var textureMirroring = false
    private var sampler: MTLSamplerState!
    private var renderPipelineState: MTLRenderPipelineState!
    private var commandQueue: MTLCommandQueue?
    private var vertexCoordBuffer: MTLBuffer!
    private var textCoordBuffer: MTLBuffer!
    private var internalBounds: CGRect!
    private var textureTranform: CGAffineTransform?


    required init(coder: NSCoder) {

        super.init(coder: coder)
        device = MTLCreateSystemDefaultDevice()
        configureMetal()
        createTextureCache()
        colorPixelFormat = .bgra8Unorm
    }


    private func createTextureCache() {
        var newTextureCache: CVMetalTextureCache?
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device!, nil, &newTextureCache) == kCVReturnSuccess {
            textureCache = newTextureCache
        } else {
            assertionFailure("Unable to allocate texture cache")
        }
    }


    func configureMetal() {
        let defaultLibrary = device!.makeDefaultLibrary()!
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "vertexPassThrough")
        pipelineDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "fragmentPassThrough")

        // To determine how textures are sampled, create a sampler descriptor to query for a sampler state from the device.
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        sampler = device!.makeSamplerState(descriptor: samplerDescriptor)

        do {
            renderPipelineState = try device!.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Unable to create preview Metal view pipeline state. (\(error))")
        }

        commandQueue = device!.makeCommandQueue()
    }


    override func draw(_ rect: CGRect) {
        var pixelBuffer: CVPixelBuffer?
//        var mirroring = false
//        var rotation: Rotation = .rotate0Degrees

        syncQueue.sync {
            pixelBuffer = internalPixelBuffer
//            mirroring = internalMirroring
//            rotation = internalRotation
        }

        guard let drawable = currentDrawable,
            let currentRenderPassDescriptor = currentRenderPassDescriptor,
            let previewPixelBuffer = pixelBuffer else {
                return
        }

        // Create a Metal texture from the image buffer.
        let width = CVPixelBufferGetWidth(previewPixelBuffer)
        let height = CVPixelBufferGetHeight(previewPixelBuffer)

        if textureCache == nil {
            createTextureCache()
        }
        var cvTextureOut: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                  textureCache!,
                                                  previewPixelBuffer,
                                                  nil,
                                                  .bgra8Unorm,
                                                  width,
                                                  height,
                                                  0,
                                                  &cvTextureOut)
        guard let cvTexture = cvTextureOut, let texture = CVMetalTextureGetTexture(cvTexture) else {
            print("Failed to create preview texture")

            CVMetalTextureCacheFlush(textureCache!, 0)
            return
        }

//        if texture.width != textureWidth ||
//            texture.height != textureHeight ||
//            self.bounds != internalBounds ||
//            mirroring != textureMirroring ||
//            rotation != textureRotation {
//            setupTransform(width: texture.width, height: texture.height, mirroring: mirroring, rotation: rotation)
//        }

        // Set up command buffer and encoder
        guard let commandQueue = commandQueue else {
            print("Failed to create Metal command queue")
            CVMetalTextureCacheFlush(textureCache!, 0)
            return
        }

        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            print("Failed to create Metal command buffer")
            CVMetalTextureCacheFlush(textureCache!, 0)
            return
        }

        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: currentRenderPassDescriptor) else {
            print("Failed to create Metal command encoder")
            CVMetalTextureCacheFlush(textureCache!, 0)
            return
        }

        commandEncoder.label = "Preview display"
        commandEncoder.setRenderPipelineState(renderPipelineState!)
        commandEncoder.setVertexBuffer(vertexCoordBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(textCoordBuffer, offset: 0, index: 1)
        commandEncoder.setFragmentTexture(texture, index: 0)
        commandEncoder.setFragmentSamplerState(sampler, index: 0)
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        commandEncoder.endEncoding()

        // Draw to the screen.
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
