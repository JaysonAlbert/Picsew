import Testing

@testable import PicsewMedia

@Test("frame extraction request stores import metadata")
func frameExtractionRequestStoresMetadata() {
    let asset = PicsewVideoAssetDescriptor(
        identifier: "demo4",
        source: .photos,
        fileExtension: "mp4"
    )
    let request = PicsewFrameExtractionRequest(
        preferredLongEdge: 1536,
        targetFrameCount: 155
    )

    #expect(asset.source == .photos)
    #expect(asset.fileExtension == "mp4")
    #expect(request.preferredLongEdge == 1536)
    #expect(request.targetFrameCount == 155)
}
