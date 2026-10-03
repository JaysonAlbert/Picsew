import CoreGraphics
import SwiftUI

#if os(iOS)
    import UIKit

    public struct PicsewZoomableImage: UIViewRepresentable {
        public let image: CGImage

        public init(image: CGImage) { self.image = image }

        public func makeUIView(context: Context) -> PicsewImageScrollView {
            PicsewImageScrollView(image: image)
        }

        public func updateUIView(_ view: PicsewImageScrollView, context: Context) {
            view.setImageIfChanged(image)
        }
    }

    public final class PicsewImageScrollView: UIScrollView, UIScrollViewDelegate {
        private let imageView = UIImageView()
        private var source: CGImage
        private var fittedWidth: CGFloat = 0

        init(image: CGImage) {
            source = image
            super.init(frame: .zero)
            delegate = self
            minimumZoomScale = 1
            maximumZoomScale = 3
            contentInsetAdjustmentBehavior = .never
            backgroundColor = PicsewPalette.surfaceUIColor
            imageView.image = UIImage(cgImage: image)
            imageView.contentMode = .scaleAspectFit
            addSubview(imageView)
            isAccessibilityElement = true
            accessibilityLabel = "Stitched preview"
            accessibilityTraits = .image
            updateZoomAccessibility()
            let doubleTap = UITapGestureRecognizer(target: self, action: #selector(toggleZoom(_:)))
            doubleTap.numberOfTapsRequired = 2
            addGestureRecognizer(doubleTap)
            accessibilityCustomActions = [
                UIAccessibilityCustomAction(name: "Zoom in") { [weak self] _ in
                    guard let self else { return false }
                    self.setZoomScale(min(3, self.zoomScale + 1), animated: false)
                    return true
                },
                UIAccessibilityCustomAction(name: "Reset zoom") { [weak self] _ in
                    self?.setZoomScale(1, animated: false)
                    return self != nil
                },
            ]
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

        func setImageIfChanged(_ image: CGImage) {
            guard source !== image else { return }
            source = image
            imageView.image = UIImage(cgImage: image)
            fittedWidth = 0
            setZoomScale(1, animated: false)
            setNeedsLayout()
        }

        public override func layoutSubviews() {
            super.layoutSubviews()
            guard bounds.width > 0, bounds.width != fittedWidth else { return }
            let previousScale = zoomScale
            let previousFraction = max(0, contentOffset.y) / max(1, contentSize.height)
            fittedWidth = bounds.width
            setZoomScale(1, animated: false)
            imageView.frame = CGRect(
                x: 0, y: 0, width: bounds.width,
                height: bounds.width * CGFloat(source.height) / CGFloat(source.width))
            contentSize = imageView.bounds.size
            setZoomScale(previousScale, animated: false)
            let top = min(previousFraction * contentSize.height, max(0, contentSize.height - bounds.height))
            contentOffset = CGPoint(x: 0, y: top)
            centerShortImage()
        }

        public func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

        public func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerShortImage()
            updateZoomAccessibility()
        }

        private func centerShortImage() {
            let inset = max(0, (bounds.height - imageView.frame.height) / 2)
            contentInset = UIEdgeInsets(top: inset, left: 0, bottom: inset, right: 0)
        }

        private func updateZoomAccessibility() {
            accessibilityValue = "\(Int((zoomScale * 100).rounded())) percent zoom"
        }

        @objc private func toggleZoom(_ recognizer: UITapGestureRecognizer) {
            let animated = !UIAccessibility.isReduceMotionEnabled
            if zoomScale > 1.01 {
                setZoomScale(1, animated: animated)
            } else {
                let point = recognizer.location(in: imageView)
                let size = CGSize(width: bounds.width / 2, height: bounds.height / 2)
                zoom(
                    to: CGRect(
                        x: point.x - size.width / 2, y: point.y - size.height / 2,
                        width: size.width, height: size.height), animated: animated)
            }
        }
    }
#else
    public struct PicsewZoomableImage: View {
        public let image: CGImage

        public init(image: CGImage) { self.image = image }

        public var body: some View {
            GeometryReader { geometry in
                ScrollView {
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width)
                }
            }
        }
    }
#endif
