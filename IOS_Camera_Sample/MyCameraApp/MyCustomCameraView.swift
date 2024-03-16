import SwiftUI

// CameraView をカスタマイズして UI表示するための SwiftUIView
struct MyCustomCameraView: View {

    let cameraService = MyCameraService()
    // 撮影された画像を保持するための変数
    @State var capturedImage: UIImage?
    // 出力画面に移動するか
    @State private var isOutputPhotoViewPresented = false

    // カウントダウンタイマー関連変数群
    @State private var isCountDown = false
    @State private var countDownTime = 3

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
                        // 撮影成功後 OutputPhotoView へ遷移
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
                if isCountDown {
                    ZStack{
                        Circle()
                            .foregroundStyle(.white)
                            .frame(width: 72, height: 72)
                        Text("\(countDownTime)")
                            .foregroundStyle(.blue)
                            .font(.largeTitle)
                    }.padding(.bottom)
                } else {
                    // 撮影ボタンが押されたときに写真をキャプチャ
                    Button(action: {
                        // TODO: 現在の実装では countDownTimer の中で　cameraService.capturePhoto()実行されている。 Countdownが成功・失敗時の処理を分けるか、一度押されたら再度押せないようにする必要がある
                        // TODO: カウントダウンによるタイマー処理の実装
                        countDownTimer()
                    }, label: {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 72))
                            .foregroundColor(.white)
                            .padding(.bottom)
                    })
                }
        }
        // OutputPhotoView へ遷移
        }.sheet(isPresented: $isOutputPhotoViewPresented, content: {
            OutputPhotoView(capturedImage: $capturedImage)
        })
    }

    // HACK: 再起処理によるカウントダウンタイマー実装になっている
    func countDownTimer() {
        isCountDown = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if countDownTime > 1 {
                countDownTime -= 1
                countDownTimer()
            } else {
                countDownTime = 3
                isCountDown = false
                cameraService.capturePhoto()
            }
        }
    }
}

#Preview {
    MyCustomCameraView()
}
