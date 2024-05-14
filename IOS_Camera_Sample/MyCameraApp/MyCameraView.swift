import SwiftUI
import AVFoundation

// SwiftUIでカメラプレビューを表示するためのビューコンポーネント
struct MyCameraView: UIViewControllerRepresentable {

    // 利用したい ViewController を typealiasで指定
    // TODO: 必要に応じて UINavigationController になどに変更を検討
    typealias UIViewControllerType = UIViewController
    // CameraServiceインスタンス
    let cameraService: MyCameraService
    // 非同期で完了する写真撮影処理の結果を受け取り、成功時と失敗時でそれぞれ異なる処理を行うこと可能とする Result
    let didFinishProcessingPhoto: (Result<AVCapturePhoto, Error>) -> ()

    // makeUIViewController : CameraViewが作られた時に呼ばれる関数
    // TODO: 作成成したいViewControllerを返すメソッドを実装
    // HACK: ここでスタート関数を呼び出していいのか疑問
    func makeUIViewController(context: Context) -> UIViewController {
        // CameraServiceを開始
        cameraService.start(delegate: context.coordinator) { err in
            if let err = err {
                didFinishProcessingPhoto(.failure(err))
                return
            }
        }

        // UIViewControllerを作成
        let viewController = UIViewController()
        // 背景色
        viewController.view.backgroundColor = .black
        // プレビューレイヤーをUIViewControllerのサブレイヤーとして追加
        viewController.view.layer.addSublayer(cameraService.previewLayer)
        // カメラのプレビューレイヤーのフレームをviewControllerの境界に設定
        cameraService.previewLayer.frame = viewController.view.bounds

        return viewController
    }


    // Coordinatorのファクトリーメソッドを実装
    // デリゲートを ViewController と Link し 写真の処理が完了する方法 を Coordinator から作成??
    func makeCoordinator() -> Coordinator {
        return Coordinator(self, didFinishProcessingPhoto: didFinishProcessingPhoto)
    }

    /*
     SwiftUI からの新しい情報で指定したビューコントローラの状態を更新する
     コンテキストパラメータで提供される新しい状態情報と一致するように、ビューコントローラの設定を更新するためにこのメソッドを使用する
     */
    // updateUIViewController : Viewが更新されたときに呼ばれる関数(SwiftUIから更新が必要になった時)
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }


    // TODO: UINavigationController を利用した実装に変更できるか検討する
    // UINavigationControllerDelegate(プロトコル) : ナビゲーションコントローラーに関連した処理を行うためのプロトコルです。
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {

        let parent: MyCameraView
        private var didFinishProcessingPhoto: (Result<AVCapturePhoto, Error>) -> ()

        init(_ parent: MyCameraView,
             didFinishProcessingPhoto: @escaping (Result<AVCapturePhoto, Error>) -> ()) {
            self.parent = parent
            self.didFinishProcessingPhoto = didFinishProcessingPhoto
        }

        // AVCapturePhotoが処理されるときに呼び出される
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if let error = error {
                // エラーがある場合、エラーをコールバック
                parent.didFinishProcessingPhoto(.failure(error))
                return
            }

            guard let imageData = photo.fileDataRepresentation(),
                  let previewImage = UIImage(data: imageData)
            else {
                return
            }

            print(photo.depthData ?? "depthData なし")
            if photo.portraitEffectsMatte == nil {
                print("画像にポートレイトエフェクトが含まれていません")
            } else {
                print("画像にポートレイトエフェクトが含まれています!")
//                let croppedImage = cropImageWithPortraitEffectsMatte(previewImage, portraitEffectsMatte)
                let resolvedSettings = photo.resolvedSettings
                let matteDimensions = resolvedSettings.portraitEffectsMatteDimensions
                let matteImage = cropImageWithPortraitEffectsMatte(previewImage, photo.portraitEffectsMatte!)
            }
            // 処理が成功した場合、AVCapturePhotoをコールバック
            parent.didFinishProcessingPhoto(.success(photo))
        }

        func cropImageWithPortraitEffectsMatte(_ image: UIImage, _ portraitEffectsMatte: AVPortraitEffectsMatte) -> UIImage? {
            guard let cgImage = image.cgImage else {
                return nil
            }

            let renderer = UIGraphicsImageRenderer(size: image.size)
            let croppedImage = renderer.image { context in
                // CGRect が取得したい
                let rect = portraitEffectsMatte.accessibilityFrame
                let imageRect = CGRect(origin: .zero, size: image.size)

                // 元の画像を描画
                context.cgContext.draw(cgImage, in: imageRect)

                // マットの領域以外を透明にする
                context.cgContext.setBlendMode(.clear)
                context.cgContext.setFillColor(UIColor.clear.cgColor)
    //            context.cgContext.fill(imageRect.di)
            }

            return croppedImage
        }

        
    }


}
