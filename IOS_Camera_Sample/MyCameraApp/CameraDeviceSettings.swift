import AVFoundation

// カメラデバイス 設定
struct CameraDeviceSettings {
    var cameraPosition: AVCaptureDevice.Position

    init(cameraPosition: AVCaptureDevice.Position) {
        self.cameraPosition = cameraPosition
    }

    static func getDefaultCameraDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }
}
