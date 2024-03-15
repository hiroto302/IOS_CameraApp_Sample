import SwiftUI
import AVFoundation

// CameraViewクラスは、SwiftUIでカメラプレビューを表示するためのビューコンポーネント
// UIViewControllerRepresentable (プロトコル) : SwiftUIでUIKitのUIViewControllerをラップして利用できるようにするためのプロトコル
// makeUIViewController・updateUIViewController・Coordinatorの関数を実装して成り立つ

struct CameraView: UIViewControllerRepresentable {

    // 利用したい ViewController を typealiasで指定
    // TODO: UINavigationController になどに変更可能
    typealias UIViewControllerType = UIViewController

    // CameraServiceインスタンスと写真処理が完了したときのコールバッククロージャを受け取る
    let cameraService: CameraService
    /* Result : 写真撮影処理が完了したときに実行されるクロージャ(無名関数)
    引数としてResult<AVCapturePhoto, Error>型を受け取り、戻り値は存在しない クロージャであることを示しています。
    この Result型は、成功時にAVCapturePhotoインスタンス、失敗時にErrorインスタンスを保持できる列挙型
     下記のように、CameraViewインスタンスを初期化する際、クロージャを渡す.

     CameraView(cameraService: cameraService) { result in
         // 撮影結果に応じた処理...
     }

     こうすることで、非同期で完了する写真撮影処理の結果を受け取り、成功時と失敗時でそれぞれ異なる処理を行うこと可能

    */
    let didFinishProcessingPhoto: (Result<AVCapturePhoto, Error>) -> ()

    // makeUIViewController : CameraViewが作られた時に呼ばれる関数
    // (ViewControllerを最初に作成する1回きり呼び出されます。たいてい表示される初回のみのはず. それ以降は updateUIViewController が呼ばれる)
    // TODO: 作成成したいViewControllerを返すメソッドを実装
    // カメラサービスを開始  と UIViewController を返す
    // HACK : ここでスタート関数を呼び出していいのか疑問
    // 戻り値に使用したいUIKitViewControllerを指定
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
        // 背景色を黒に設定します。
        viewController.view.backgroundColor = .black
        // カメラのプレビューレイヤーをviewControllerのサブレイヤーとして追加
        viewController.view.layer.addSublayer(cameraService.previewLayer)
        // カメラのプレビューレイヤーのフレームをviewControllerの境界に設定
        cameraService.previewLayer.frame = viewController.view.bounds

        return viewController
    }

    /*
     ビューコントローラの変更を SwiftUI インターフェイスの他の部分に伝えるために使うカスタムインスタンスを作成
     */
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

    /*
     システムはビューコントローラー内で起こる変更をSwiftUIインターフェイスの他の部分に自動的に伝達できない。
     協調させたい場合、それらの相互作用を促進するためにコーディネーターのインスタンスを提供する必要がある
     ViewController から SwiftUIビュー にdelegateメッセージを転送するためにコーディネーターを使用する。
     */
    // Coordinator : AVCapturePhotoのキャプチャを処理を担当
    // (Coordinatorは利用するViewControllerがイベントを処理するために、そのイベントハンドリングを行う型を定義することができる)
    // Coordinatorクラスでは、AVCapturePhotoのキャプチャ処理が完了したときに、親ビューに結果を返す
    // Coordinatorを作成。UIImagePickerControllerを使用する場合、以下のクラスを継承とプロトコルに適応した実装が必要です。
    // NSObject : 多くのクラスの元となるクラスです。
    // UIImagePickerControllerDelegate(プロトコル) : カメラを撮った時、ImagePickerController関数が呼ばれます。
    // TODO: UINavigationController を利用した実装に変更できるか検討する
    // UINavigationControllerDelegate(プロトコル) : ナビゲーションコントローラーに関連した処理を行うためのプロトコルです。
        class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {

        let parent: CameraView
        private var didFinishProcessingPhoto: (Result<AVCapturePhoto, Error>) -> ()

        init(_ parent: CameraView,
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
            // 処理が成功した場合、AVCapturePhotoをコールバック
            parent.didFinishProcessingPhoto(.success(photo))
        }
    }
}
