import Testing

@testable import PicsewAlgorithm

@Test("reference baseline keeps the expected pipeline stages")
func referenceBaselineStages() {
    let baseline = PicsewAlgorithmBaseline()

    #expect(baseline.reference.stages == [
        .metadata,
        .lowResolutionFrames,
        .scrollingWindow,
        .keyframes,
        .offsets,
        .stitch,
    ])
    #expect(baseline.rules.contains(.preserveReferenceBehavior))
    #expect(baseline.rules.contains(.validateWithFixtures))
}
