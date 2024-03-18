import Foundation
import AVFoundation

// カメラ機能を提供するクラス
class MyCameraService {
    private var session: AVCaptureSession?
    private let output = AVCapturePhotoOutput()
    let previewLayer = AVCaptureVideoPreviewLayer()
    var delegate: AVCapturePhotoCaptureDelegate?

    // フラッシュモード引数
    var flashMode: AVCaptureDevice.TorchMode = .on

    // TODO: CustomCameraView で決定される変更を反映させる
    // TODO: カメラのデバイス設定変数
    // TODO: フォトの設定変数


    // カメラ起動時の初期化
    func start(delegate: AVCapturePhotoCaptureDelegate, completion: @escaping (Error?) -> ()) {
        self.delegate = delegate
        checkPermissions(completion: completion)
    }

    // アプリ内でのカメラ使用許可確認
    // @escaping : このクロージャが非同期に実行される可能性があることを示すアノテーション
    private func checkPermissions(completion: @escaping (Error?) -> ()) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        // 許可されていない場合
        case .notDetermined:
            // ユーザーに使用許可を求める
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else { return }
                DispatchQueue.main.async {
                    // 使用許可を得たらカメラを設定
                    self?.setupCamera(completion: completion)
                }
            }
        case .restricted: // 制限されている場合
            break
        case .denied: // 拒否された場合
            break
        case .authorized: // 許可されている場合 (一度アプリを起動して既に許可されている場合)
            setupCamera(completion: completion)
        @unknown default: // 未知の状態の場合
            break
        }
    }

        private func setupCamera(completion: @escaping (Error?) -> ()) {
            let session = AVCaptureSession()
            if let device = AVCaptureDevice.default(for: .video) {
                do {

                    let input = try AVCaptureDeviceInput(device: device)
                                if session.canAddInput(input) {
                                    session.addInput(input)
                                }

                    // 使用デバイスの決定
                    // TODO: 前後のカメラを使用できるように検討
    //                let input = try AVCaptureDeviceInput(device: device)

                    // Input・Output を Session に追加
                    if session.canAddInput(input) {
                        session.addInput(input)
                    }
                    if session.canAddOutput(output) {
                        session.addOutput(output)
                    }

                    try device.lockForConfiguration()
                    if device.isFocusModeSupported(.autoFocus) {
                        // デフォルト .continuousAutoFocus モード
                        // TODO: .continuousAutoFocus と .autoFocus と
                        device.focusMode = .continuousAutoFocus
                        device.isSmoothAutoFocusEnabled = true
                        print("Device Focus設定 on")
                        device.unlockForConfiguration()
                    }

                    print(device.focusMode)

                    // PreviewLayer を Session に追加
                    previewLayer.videoGravity = .resizeAspectFill
                    previewLayer.session = session

                    session.startRunning()
                    self.session = session
                } catch {
                    completion(error)
                }
            }
        }

    // カメラ撮影
    // TODO: settings をデフォルト以外にも対応 (フラッシュとか)
    // TODO: デバイス設定
    func capturePhoto(with settings: AVCapturePhotoSettings = AVCapturePhotoSettings()) {
        if let device = AVCaptureDevice.default(for: .video), device.isTorchModeSupported(flashMode) {
//            settings.flashMode = .on
//            device.focusMode = AVCaptureDevice.FocusMode.autoFocus
            do {
                    try device.lockForConfiguration()

                    if device.isTorchModeSupported(flashMode) {
                        // TODO: フラッシュモードの設定は AVCaptureDevice.FlashMode　でも設定できるが、AVCapturePhotoSettings で設定することが推奨されている
                        settings.flashMode = .on
                    }

                        device.unlockForConfiguration()
                    } catch {
                        print("Failed to lock configuration: \(error)")
                    }
        }

        


        output.capturePhoto(with: settings, delegate: delegate!)
    }
}
