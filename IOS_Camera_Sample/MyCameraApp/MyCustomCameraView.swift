import SwiftUI
import AVFoundation

// CameraView をカスタマイズして UI表示するための SwiftUIView
struct MyCustomCameraView: View {

    // カメラサービス クラスインスタンス作成
    let cameraService = MyCameraService()
    // カメラのフラッシュモード設定
    @State var flashMode: AVCaptureDevice.FlashMode = .off
    // カメラのフォーカスモード設定
    @State var focusMode: AVCaptureDevice.FocusMode = .continuousAutoFocus

    // 撮影された画像を保持するための変数
    @State var capturedImage: UIImage?
    // 出力画面に移動するか
    @State private var isOutputPhotoViewPresented = false

    // カウントダウンタイマー関連変数群
    @State private var isCountDown = false
    @State private var countDownTime = 3

    let myCountDownTimer = CountDownTimer(time: 3.0)

    // フラッシュモードの切り替え
//    @State private var flashMode: AVCaptureDevice.TorchMode = .off

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

                        if (photo.portraitEffectsMatte != nil) {
                            let resolvedSettings = photo.resolvedSettings
//                            let matteImage = cropImageWithPortraitEffectsMatte(capturedImage!, photo.portraitEffectsMatte!)
                            print("matt処理したよ")
                            capturedImage = composeImageWithPortraitEffectsMatte(capturedImage!, portraitEffectsMatte: photo.portraitEffectsMatte!, resolvedSettings: resolvedSettings)
                            
                        }

                        if (photo.depthData != nil) {
                            print("depthData あるよ")
                        }

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
            VStack {
                HStack{
                    // 撮影フラッシュ切り替え
                    Button(action: {
                        flashMode = cameraService.switchFlashMode(flashMode: flashMode)
                    }, label: {
                        Image(systemName: flashMode == .on ? "flashlight.on.fill" : "flashlight.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .padding(.bottom)
                    })
                    Spacer()
                    // 前後カメラの切り替え
                    Button(action: {
                        cameraService.switchCameraPosition { error in
                            if let error = error {
                                print(error)
                            }
                        }
                    }, label: {
                        Image(systemName: "camera.rotate.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .padding(.bottom)
                    }) 
                    Spacer()
                    // フォーカス切り替え
                    Button(action: {
                        cameraService.switchCameraFocusMode { error in
                            if let error = error {
                                print(error)
                            }
                        }

                    }, label: {
                        Image(systemName: "camera.metering.partial")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .padding(.bottom)
                    })
                    Spacer()
                    // カメラの表示映像の反転切り替え
                    Button(action: {
                        cameraService.switchMirrorView()
                    }, label: {
                        ZStack{
                            Image(systemName: "video")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                                .padding(.bottom)
                            Image(systemName: "arrow.triangle.2.circlepath.doc.on.clipboard")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding(.bottom)
                        }
                    })
                }
                .padding()
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
//                        myCountDownTimer.startTimer()
                    }, label: {
                        Image(systemName: "circle")
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
                cameraService.capturePhoto(flashMode: flashMode)
            }
        }
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

    func composeImageWithPortraitEffectsMatte(_ originalImage: UIImage, portraitEffectsMatte: AVPortraitEffectsMatte, resolvedSettings: AVCaptureResolvedPhotoSettings) -> UIImage? {
        let matteDimensions = resolvedSettings.portraitEffectsMatteDimensions
//        let matteData = portraitEffectsMatte.portraitEffectsMatteData
        let mattingRect = portraitEffectsMatte.accessibilityFrame


        // 1. ポートレートエフェクトマットから人物領域を取得
        let personRect = mattingRect.applying(CGAffineTransform(scaleX: originalImage.size.width / CGFloat(matteDimensions.width), y: originalImage.size.height / CGFloat(matteDimensions.height)))

        // 2. 人物領域を使って元画像から人物を切り抜く
        let renderer = UIGraphicsImageRenderer(size: originalImage.size)
        let croppedPersonImage = renderer.image { _ in
            originalImage.draw(at: .zero)
            UIColor.clear.set()
            UIRectFill(personRect)
        }

        // 3. 任意の背景画像を用意する
        let backgroundImage = UIImage(named: "background")

        // 4. 切り抜いた人物画像と背景画像を合成する
        UIGraphicsBeginImageContextWithOptions(originalImage.size, true, 0.0)
        backgroundImage?.draw(in: CGRect(origin: .zero, size: originalImage.size))
        croppedPersonImage.draw(in: CGRect(origin: .zero, size: originalImage.size))
        let compositeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return compositeImage
    }
}

#Preview {
    MyCustomCameraView()
}
