import SwiftUI

// CameraView をカスタマイズして UI表示するための SwiftUIView
struct MyCustomCameraView: View {

    let cameraService = MyCameraService()
    // 撮影された画像を保持するための変数
    @State var capturedImage: UIImage?
    // 出力画面に移動するか
    @State private var isOutputPhotoViewPresented = false

    var body: some View {
        ZStack {
            // CustomCameraView が表示されると、CameraService インスタンスが作成される
            // カメラプレビューと撮影ボタンの表示
            MyCameraView(cameraService: cameraService) { result in
                switch result {
                case .success(let photo):
                    // 撮影した写真からデータを取得し、UIImageに変換
                    if let data = photo.fileDataRepresentation() {
                        capturedImage = UIImage(data: data)
                        // ここで OutputPhotoView を呼び出したい
                        isOutputPhotoViewPresented.toggle()
                    } else {
                        // 画像データが見つからない場合はエラーメッセージを表示します。
                        print("Error: no image data found")
                    }
                case .failure(let err):
                    print(err.localizedDescription)
                }
            }
            // 撮影ボタンを中央下部に配置します。
            VStack {
                Spacer()
                Button(action: {
                    // 撮影ボタンが押されたときに写真をキャプチャ
                    cameraService.capturePhoto()
                }, label: {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 72))
                        .foregroundColor(.white)
                })
                .padding(.bottom)
            }
        }.sheet(isPresented: $isOutputPhotoViewPresented, content: {
            OutputPhotoView(capturedImage: $capturedImage)
        })
    }
}
