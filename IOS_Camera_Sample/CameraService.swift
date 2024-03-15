import Foundation
import AVFoundation

// カメラ機能を提供するクラス
// カメラ使用権限を .plist に追加 App < info < KEY = Privacy - Camera Usage Description, Value = TakePhotos
// 上記により、ユーザーにアプリ使用時のカメラ使用許可を求められる

/* 写真(Image)をカメラ機能でキャプチャするまでのワークフロー
AVCaptureDevice(ここでは IPhone)クラスで入力したデータを AVCaptureDeviceInput(カメラ類) を介して AVCaptureSession に渡す。
AVCaptureSession クラスから出力されるデータを AVCaptureOutputで決定し、Image としてを出力する
*/
class CameraService {

    // AVCaptureSession : カメラのインプットとアウトプットを管理するクラス
    var session: AVCaptureSession?
    // 撮影した写真を出力するオブジェクト(出力データを受け取るオブジェクト) : 今回出力するものは毎回写真なのでここで定義する
    let output = AVCapturePhotoOutput()
    // カメラのプレビューを表示するレイヤー
    let previewLayer = AVCaptureVideoPreviewLayer()
    // 撮影された写真を処理するデリゲート
    var delegate: AVCapturePhotoCaptureDelegate?

    // カメラ機能を初期化する
    func start(delegate: AVCapturePhotoCaptureDelegate, completion: @escaping (Error?) -> ()) {
        // デリゲートを設定
        self.delegate = delegate
        // カメラ使用許可確認
        checkPermissions(completion: completion)
    }

    // 0. カメラの使用許可確認 : capture session をセットアップする前に必ず AVCaptureDevice.authorizationStatus を実行することに注意
    private func checkPermissions(completion: @escaping (Error?) -> ()) {
        // カメラの使用状況を確認
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        // 許可されていない場合
        case .notDetermined:
            // ユーザーに使用許可を求める
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else { return } // 許可されなかった場合は終了
                DispatchQueue.main.async { // メインスレッドで実行
                    // 使用許可を得たらカメラを設定
                    self?.setupCamera(completion: completion)
                }
            }
        case .restricted: // 制限されている場合
            break
        case .denied: // 拒否された場合
            break
        case .authorized: // 許可されている場合 (一度アプリを起動して既に許可されている場合)
            // カメラを設定
            setupCamera(completion: completion)
        @unknown default: // 未知の状態の場合
            break
        }
    }

    // 1. カメラ設定
    private func setupCamera(completion: @escaping (Error?) -> ()) {
        // 1.1 AVCaptureSessionを作成 : デバイスからの入力と出力を管理するクラス
        let session = AVCaptureSession()
        // 1.2 device : デフォルトのカメラデバイスを取得・設定
        // TODO: ここで Choosing a Capture Device(front- and back-facing cameras)　を検討
        // default の場合、利用可能なベストな背面カメラが使用される
        // Call beginConfiguration() before changing a session’s inputs or outputs, and call commitConfiguration() after making changes. とあるが、使用カメラを変更する場合には呼び出す必要があるということ？
        if let device = AVCaptureDevice.default(for: .video) {
            // 1.3 入出力データの設定
            do {
                // 1.3.1 input : 指定したデバイスからインプットを作成するための初期化
                let input = try AVCaptureDeviceInput(device: device)
                // 1.3.2 セッションにインプットを追加(コネクト)
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                // 1.3.3 output : セッションにアウトプットを追加 (output = AVCapturePhotoOutput())
                if session.canAddOutput(output) {
                    // TODO : ここで出力するフォーマットを指定してもいいかも
                    session.addOutput(output)
                }

                // 1.4 プレビューレイヤーの設定
                // AVCaptureVideoPreviewLayer をキャプチャセッションに接続することで、プレビューを提供することができる
                // LayerはViewに描画する内容を管理するオブジェクト (UIKit なので UIViewController Representable を作成する必要がある)
                // このレイヤーを CameraView (Viewは実際の描画や画面のイベント処理を行うオブジェクト) で表示する
                // videoGravity : プレビューレイヤが、カメラからの映像をどのように表示するかを設定
                // resizeAspectFill : 縦横比を維持したまま表示するための設定
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = session

                // startRunnnigメソッド : 起動することで、セッションの入力から出力へのデータの流れが開始され、画面にカメラのキャプチャーを表示することができる
                session.startRunning()
                // キャプチャセッションでプレビューレイヤーを使用するには、レイヤーのセッションプロパティを設定
                // 設定(input・output・previewLayer) した セッションを 保持
                self.session = session
            } catch {
                completion(error)
            }
        }
    }

    // カメラ撮影
    // with は、メソッドの引数 settings がこのメソッドに与えられる写真の撮影設定を表す
    // 現在の実装では、settings がデフォルトの設定は AVCapturePhotoSettings() であり、撮影時のデフォルトの設定を使用することを意味している
    //写真を撮るには、AVCapturePhotoSettingsオブジェクトを作成・設定し、AVCapturePhotoOutputのcapturePhoto(with:delegate:)メソッドに渡す 必要がある。
    // TODO: FlashMode 時には AVCapturePhotoSettings() を変える必要がある！？
    // ex) let customSettings = AVCapturePhotoSettings()
    // customSettings.flashMode = .on
    // capturePhoto(with: customSettings)
    func capturePhoto(with settings: AVCapturePhotoSettings = AVCapturePhotoSettings()) {
        // 設定されたデリゲートに撮影要求を送る
        // AVCapturePhotoOutput().capturePhoto(with: delegate:): 指定された設定を用いて写真のキャプチャを開始
        output.capturePhoto(with: settings, delegate: delegate!)
    }
}
