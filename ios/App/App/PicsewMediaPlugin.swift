import Foundation
import Capacitor
import Photos
import UIKit

@objc(PicsewMediaPlugin)
class PicsewMediaPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "PicsewMediaPlugin"
    public let jsName = "PicsewMedia"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "saveImageToPhotos", returnType: CAPPluginReturnPromise)
    ]

    @objc func saveImageToPhotos(_ call: CAPPluginCall) {
        guard let dataUrl = call.getString("dataUrl"),
              let imageData = Self.decodeDataUrl(dataUrl),
              let image = UIImage(data: imageData) else {
            call.reject("Invalid image payload.")
            return
        }

        let saveImage = {
            PHPhotoLibrary.shared().performChanges({
                PHAssetCreationRequest.creationRequestForAsset(from: image)
            }) { success, error in
                DispatchQueue.main.async {
                    if let error {
                        call.reject("Failed to save image to Photos.", nil, error)
                    } else {
                        call.resolve(["saved": success])
                    }
                }
            }
        }

        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            saveImage()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                if status == .authorized || status == .limited {
                    saveImage()
                } else {
                    call.reject("Photo library permission was denied.")
                }
            }
        default:
            call.reject("Photo library permission was denied.")
        }
    }

    private static func decodeDataUrl(_ value: String) -> Data? {
        let payload = value.contains(",") ? String(value.split(separator: ",", maxSplits: 1)[1]) : value
        return Data(base64Encoded: payload, options: .ignoreUnknownCharacters)
    }
}
