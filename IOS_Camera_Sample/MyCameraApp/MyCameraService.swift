import Foundation
import AVFoundation

// カメラ機能を提供するクラス
class MyCameraService {
    private var session: AVCaptureSession?
    private let output = AVCapturePhotoOutput()
    let previewLayer = AVCaptureVideoPreviewLayer()
    var delegate: AVCapturePhotoCaptureDelegate?

    // TODO: CustomCameraView で決定される変更を反映させる
    // TODO: カメラのデバイス設定変数
    private var device: AVCaptureDevice?
    // TODO: フォトの設定変数
    // フラッシュモード引数
    var flashMode: AVCaptureDevice.TorchMode = .on


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
                    // TODO: setUpCamera_2 で問題なく動作するかテスト
                    self?.setUpCamera_2(completion: completion)
                }
            }
        case .restricted: // 制限されている場合
            break
        case .denied: // 拒否された場合
            break
        case .authorized: // 許可されている場合 (一度アプリを起動して既に許可されている場合)
            self.setUpCamera_2(completion: completion)
        @unknown default: // 未知の状態の場合
            break
        }
    }

    func setUpCamera_2(settingDevice: AVCaptureDevice? = AVCaptureDevice.default(for: .video), completion: @escaping (Error?) -> ()) {
        // 既にセッションがある場合、停止 と Input・Output の削除
        // TODO: device の設定が変わっていない場合、実行する必要ないことを考慮すること
        self.session?.stopRunning()
        self.session?.inputs.forEach { self.session?.removeInput($0) }
        self.session?.outputs.forEach { self.session?.removeOutput($0) }
        // session の削除
        self.session = nil

        let newSession = AVCaptureSession()
        // Set a sessionPreset to a format that supports depth, such as .photo.

//        do {
            // 新しいセッションを作成し、入力と出力を設定
//            if let device = settingDevice {
//                let newSession = try createSession(with: device)
//                previewLayer.session = newSession
//                previewLayer.videoGravity = .resizeAspectFill
//
//                self.session = newSession
//                self.device = device
//                // セッションの開始
//                self.session?.startRunning()
//                }
//            } catch {
//                completion(error)
//            }
//        let ssettingDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back)
        let ssettingDevice = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front)

        // 新しいデバイスでセッションを再設定
        if let device = ssettingDevice {
            do {
//                self.session?.beginConfiguration()
                newSession.sessionPreset = .photo

                let input = try AVCaptureDeviceInput(device: device)
                if newSession.canAddInput(input) == true {
                    newSession.addInput(input)
                }

                // ポートレートエフェクトマットをサポートするように設定
//                output.setPillCrop(true, completionHandler: nil)
//                output.setPortraitEffectsMatteDeliveryEnabled(true, completionHandler: nil)


                if newSession.canAddOutput(output) == true {
                    newSession.addOutput(output)

                }
//                self.session?.commitConfiguration()
                
                // Add the cameraPhotoOutput to session before setting .isDepthDataDeliveryEnabled = true.
                if output.isDepthDataDeliverySupported {
                    print("DepthDataDelivery サポートしているよ")
                    // 下記を true にする必要がある
                    output.isDepthDataDeliveryEnabled = true
//                    output.isPortraitEffectsMatteDeliveryEnabled = output.isPortraitEffectsMatteDeliverySupported
                    output.isPortraitEffectsMatteDeliveryEnabled = true
                    output.enabledSemanticSegmentationMatteTypes = output.availableSemanticSegmentationMatteTypes
                    print("availableSemanticSegmentationMatteTypes :  \(output.availableSemanticSegmentationMatteTypes)")
                }


                previewLayer.session = newSession
                previewLayer.videoGravity = .resizeAspectFill

                // TODO: この実行順序は正しいのか？　self.session を Start させても良い
                // セッション開始
                newSession.startRunning()

                // 各変数を保持
                self.session = newSession
//                self.device = device
                self.device = ssettingDevice

//                print("activeDepthDataFormat : \(device.activeDepthDataFormat!)")

            } catch {
                completion(error)
            }
        }
    }

    
    // 前後のカメラ切り替え
    func switchCameraPosition(completion: @escaping (Error?) -> ()) {
        // カメラの位置切り替え
        guard let currentDevice = device else { return }
        let newPosition: AVCaptureDevice.Position = currentDevice.position == .back ? .front : .back
//        device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition)
        device = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back)
//        device = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: newPosition)
//        device = self.videoDeviceDiscoverySession.devices
        // カメラの切り替え後、再度セットアップ実行
        setUpCamera_2(settingDevice: device, completion: completion)
    }

    // カメラの切り替え時の処理
    func myswitchCameraPosition(completion: @escaping (Error?) -> ()) {
        guard let currentDevice = device else { return }
        let newPosition: AVCaptureDevice.Position = currentDevice.position == .back ? .front : .back
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else { return }

        // 古いセッションを停止し、新しいセッションを作成
        session?.stopRunning()
        do {
            self.session?.inputs.forEach { self.session?.removeInput($0) }
            self.session?.outputs.forEach { self.session?.removeOutput($0) }
            let newSession = try createSession(with: newDevice)
            session = newSession
            device = newDevice
            previewLayer.session = newSession
            newSession.startRunning()
        } catch {
            completion(error)
        }
    }

    // セッションの作成と入出力の設定を別メソッドに分ける
    private func createSession(with device: AVCaptureDevice) throws -> AVCaptureSession {
        let session = AVCaptureSession()
        let input = try AVCaptureDeviceInput(device: device)
        if session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        return session
    }


    // カメラのフォーカス切り替え
    func switchCameraFocusMode(completion: @escaping (Error?) -> ()) {
        do{
            try device!.lockForConfiguration()
            device!.focusMode = device?.focusMode == .continuousAutoFocus ? .locked : .continuousAutoFocus
            device!.unlockForConfiguration()
            setUpCamera_2(settingDevice: device, completion: completion)
        } catch {
            print(completion)
        }
    }

    // カメラの映像の反転on/off機能
    func switchMirrorView() {
        session?.beginConfiguration()
//        if let connection = output.connection(with: .video) {
//            connection.automaticallyAdjustsVideoMirroring.toggle()
//            connection.isVideoMirrored.toggle()
//            previewLayer.videoGravity = .resizeAspect 
//        }

        if let connection = output.connection(with: .video) {
            if connection.isVideoMirroringSupported {
                print("automaticallyAdjustsVideoMirroring : \(connection.automaticallyAdjustsVideoMirroring)")
                print("isVideoMirrored : \(connection.isVideoMirrored)")
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = true
                print("support Mirror")
            } else {
                connection.isVideoMirrored = !connection.isVideoMirrored
                print("No support Mirror")
            }
        }
        session?.commitConfiguration()
    }

    // TODO: フラッシュモード切り替え 実装方法を再検討
    func switchFlashMode(flashMode: AVCaptureDevice.FlashMode) -> AVCaptureDevice.FlashMode {
        let newFlashMode: AVCaptureDevice.FlashMode = flashMode == .off ? .on : .off
        return newFlashMode
    }

    // カメラ撮影
    // TODO: settings をデフォルト以外にも対応 (フラッシュとか)
    // TODO: デバイス設定
    func capturePhoto(with settings: AVCapturePhotoSettings = AVCapturePhotoSettings(), flashMode: AVCaptureDevice.FlashMode) {

        // フロントカメラの場合はフラッシュモードをoffに設定
        if output.supportedFlashModes.contains(.on) {
            settings.flashMode = flashMode
        } else {
            settings.flashMode = .off
        }
        
//        output.isPortraitEffectsMatteDeliveryEnabled = true
//        output.enabledSemanticSegmentationMatteTypes = output.availableSemanticSegmentationMatteTypes

        if self.output.isDepthDataDeliverySupported {
            settings.isPortraitEffectsMatteDeliveryEnabled = true
            settings.isDepthDataDeliveryEnabled = true

            settings.embedsDepthDataInPhoto = true
            settings.embedsPortraitEffectsMatteInPhoto = true
        }


        output.capturePhoto(with: settings, delegate: delegate!)
    }
}
