import SwiftUI

// CameraView をカスタマイズして UI表示するための SwiftUIView
struct CustomCameraView: View {

    let cameraService = CameraService()
    // 撮影された画像を保持するためのバインディング変数
    @Binding var capturedImage: UIImage?
    // プレゼンテーションモードを使用して、ビューが表示されているかどうかを追跡
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            // CustomCameraView が表示されると、CameraService インスタンスが作成される
            // カメラプレビューと撮影ボタンの表示
            CameraView(cameraService: cameraService) { result in
                switch result {
                case .success(let photo):
                    // 撮影した写真からデータを取得し、UIImageに変換
                    if let data = photo.fileDataRepresentation() {
                        capturedImage = UIImage(data: data)
                        // 画像がキャプチャされた後にビューを閉じます。
                        presentationMode.wrappedValue.dismiss()
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
                    // 撮影ボタンが押されたときに写真をキャプチャします。
                    cameraService.capturePhoto()
                }, label: {
                    Image(systemName: "circle")
                        .font(.system(size: 72))
                        .foregroundColor(.white)
                })
                .padding(.bottom)
            }
        }
    }
}
