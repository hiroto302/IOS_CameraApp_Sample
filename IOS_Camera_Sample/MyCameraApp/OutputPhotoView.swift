import SwiftUI
import CoreImage.CIFilterBuiltins

struct OutputPhotoView: View {
    // 撮影された画像を保持する変数
    @Binding var capturedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    // モノクロームに加工した画像を保持する変数
    @State private var monochromeImage: UIImage?

    var body: some View {
        ZStack {
            // 撮影された画像を全画面で表示
//            if let image = monochromeImage ?? capturedImage {
            if let image = translateColorMonochrome(from: capturedImage!) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            // image が nil の場合
            } else {
                Color(UIColor.systemBackground)
            }

            VStack {
                Spacer()
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

}

