import SwiftUI
import CoreImage.CIFilterBuiltins
//import PortraitEffectsMatter

struct OutputPhotoView: View {
    // 撮影された画像を保持する変数
    @Binding var capturedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    // モノクロームに加工した画像を保持する変数
    @State private var monochromeImage: UIImage?

    var body: some View {
        ZStack {
            // 撮影された画像を全画面で表示
            if let image = capturedImage {
//            if let image = translateColorMonochrome(from: capturedImage!) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .onAppear {
                        monochromeImage = image
                        /*
                         info.plist に Privacy - Photo Library Usage Description を追加して許可を求める
                         TODO: 許可されなかった時のエラー対応が必要
                         */
                        // カメラロールへの保存処理
                        UIImageWriteToSavedPhotosAlbum(monochromeImage!, nil, nil, nil)
                    }
            // image が nil の場合
            } else {
                Color(UIColor.systemBackground)
            }

            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        // 前の画面に戻る
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Image(systemName: "camera.fill")
                            .font(.largeTitle)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    })
                    VStack{
                        // モノクロ画像の保存
                        Button(action: {
                            saveImageToDocumentsDirectory(monochromeImage!)
                        }, label: {
                            Image(systemName: "square.and.arrow.down")
                                .font(.largeTitle)
                                .padding()
                                .background(Color.black)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        })
                        // ロード
                        Button(action: {
                            capturedImage = loadImageFromDocumentsDirectory()
                        }, label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.largeTitle)
                                .padding()
                                .background(Color.black)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        })

                    }


                }
                .padding(.bottom)
            }
        }
    }

    // 下記の処理は縦横の比率を保持する処理を追加する必要がある
    private func  applyMonochromeFilter() {
        guard let image = capturedImage else {
            return
        }

        let context = CIContext()
        let ciImage = CIImage(image: image)

        // モノクロ加工フィルターを適用
        let filter = CIFilter.colorMonochrome()
        filter.inputImage = ciImage

        if let outputImage = filter.outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            monochromeImage = UIImage(cgImage: cgImage)
        }
    }

    // モノクローム加工処理した CIImange を出力
    func colorMonochrome(inputImage: CIImage) -> CIImage {
        let colorMonochromeFilter = CIFilter.colorMonochrome()
        colorMonochromeFilter.inputImage = inputImage
        colorMonochromeFilter.color = CIColor(red: 0.5, green: 0.5, blue: 0.5)
        colorMonochromeFilter.intensity = 1
        return colorMonochromeFilter.outputImage!
    }

    // モノクローム加工したUI UIImage を出力
    func translateColorMonochrome(from image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        let ciContext = CIContext(options: nil)

        // CIImageを使用した画像編集処理
        let filteredCIImage = colorMonochrome(inputImage: ciImage)

        guard let cgImage = ciContext.createCGImage(filteredCIImage, from: filteredCIImage.extent) else { return nil }
        let result = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)

        return result
    }

    // 撮影した画像を保存する処理
    func saveImageToDocumentsDirectory(_ image: UIImage) {
        // ドキュメントディレクトリのFileURLを取得
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        // UIImageをData型に変換
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            return
        }

        // 保存するファイル名の決定
//        let fileName = "\(UUID().uuidString).jpg"
        // TODO: テスト用のファイル名
        let fileName = "1.jpg"
        let fileURL = documentsURL.appendingPathComponent(fileName)

        // 4. Data型のデータをドキュメントディレクトリに書き込む
        do {
            try imageData.write(to: fileURL)
            print("Image saved to \(fileURL.path)")
        } catch {
            print("Error saving image: \(error)")
        }
    }

    // TODO: テスト用のロード処理
    func loadImageFromDocumentsDirectory() -> UIImage? {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent("1.jpg")

        do {
            let imageData = try Data(contentsOf: fileURL)
            if let image = UIImage(data: imageData) {
                return image
            } else {
                print("Failed to convert data to UIImage")
                return nil
            }
        } catch {
            print("Error loading image: \(error)")
            return nil
        }
    }

//    // カメラの映像から人物を「Portrait Matte(ポートレートマット)」でマスクし、背景に画像を合成させ表示する
//    func blendPersonWithBackground(personImage: UIImage, backgroundImage: UIImage) -> UIImage? {
//        // PortraitEffectMattingクラスを初期化
//        let portraitEffectsMatter = PortraitEffectsMatter()
//
//        // 人物画像から人物のシルエットマスクを生成
//        guard let personMask = try? portraitEffectsMatter.generatePersonSegmentationMask(from: personImage) else {
//            return nil
//        }
//
//        // 背景画像とシルエットマスクから合成画像を生成
//        guard let blendedImage = portraitEffectsMatter.blendPersonOnBackground(backgroundImage, personImage, personMask) else {
//            return nil
//        }
//
//        return blendedImage
//    }
}

