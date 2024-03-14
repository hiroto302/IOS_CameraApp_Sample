import Foundation
import AVFoundation

// カメラ機能を提供するクラス
// カメラ使用権限を .plist に追加 App < info < KEY = Privacy - Camera Usage Description, Value = TakePhotos
// 上記により、ユーザーにアプリ使用時のカメラ使用許可を求められる

/* カメラ機能が動作する流れ
AVCaptureDevice(ここでは IPhone)クラスで入力したデータを AVCaptureDevice を介して AVCaptureSession に渡す。
AVCaptureSession クラスから出力されるデータを AVCaptureOutputで決定し、Image を出力する
*/
class CameraService {

    // AVCaptureSession : カメラのインプットとアウトプットを管理するクラス
    var session: AVCaptureSession?
    // 撮影された写真を処理するデリゲート
    var delegate: AVCapturePhotoCaptureDelegate?
    // 撮影した写真を出力するオブジェクト(出力データを受け取るオブジェクト)
    let output = AVCapturePhotoOutput()
    // カメラのプレビューを表示するレイヤー
    let previewLayer = AVCaptureVideoPreviewLayer()

    // カメラ機能を初期化する
    func start(delegate: AVCapturePhotoCaptureDelegate, completion: @escaping (Error?) -> ()) {
        self.delegate = delegate // デリゲートを設定
    }

    // 0. カメラの使用許可確認
    private func checkPermissions(completion: @escaping (Error?) -> ()) {
        // カメラの使用状況を確認
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined: // 許可されていない場合
            // ユーザーに使用許可を求める
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else { return } // 許可されなかった場合は終了
                DispatchQueue.main.async { // メインスレッドで実行
                    self?.setupCamera(completion: completion) // カメラを設定
                }
            }
        case .restricted: // 制限されている場合
            break // 何もしない
        case .denied: // 拒否された場合
            break // 何もしない
        case .authorized: // 許可されている場合
            setupCamera(completion: completion) // カメラを設定
        @unknown default: // 未知の状態の場合
            break // 何もしない
        }
    }

    // 1. カメラ設定
    private func setupCamera(completion: @escaping (Error?) -> ()) {
        // 1.1 AVCaptureSessionを作成 : デバイスからの入力と出力を管理するクラス
        let session = AVCaptureSession()
        // 1.2 デフォルトのカメラデバイスを取得・設定
        if let device = AVCaptureDevice.default(for: .video) {
            // 1.3 入出力データの設定
            do {

                // 1.3.1 指定したデバイスからインプットを作成するための初期化
                let input = try AVCaptureDeviceInput(device: device)
                // 1.3.2 セッションにインプットを追加
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                // 1.3.3 セッションにアウトプットを追加 (output = AVCapturePhotoOutput())
                if session.canAddOutput(output) {
                    // ここで出力するフォーマットを指定してもいいかも
                    session.addOutput(output)
                }

                // 1.4 プレビューレイヤーの設定
                // LayerはViewに描画する内容を管理するオブジェクト (UIKit なので UIViewController Representable を作成する必要がある)
                // このレイヤーを CameraView (Viewは実際の描画や画面のイベント処理を行うオブジェクト) で表示する
                // videoGravity : プレビューレイヤが、カメラからの映像をどのように表示するかを設定
                // resizeAspectFill : 縦横比を維持したまま表示するための設定
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = session

                // startRunnnigメソッド : 起動することで、セッションの入力から出力へのデータの流れが開始され、画面にカメラのキャプチャーを表示することができる
                session.startRunning() // セッションを開始
                self.session = session // セッションを保持
            } catch {
                completion(error) // エラーが発生した場合は完了ハンドラにエラーを渡す
            }
        }
    }

    // カメラ撮影
    func capturePhoto(with settings: AVCapturePhotoSettings = AVCapturePhotoSettings()) {
        // 設定されたデリゲートに撮影要求を送る
        output.capturePhoto(with: settings, delegate: delegate!)
    }
}
