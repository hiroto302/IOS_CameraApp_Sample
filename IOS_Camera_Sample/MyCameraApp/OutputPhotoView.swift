import SwiftUI

struct OutputPhotoView: View {
    // 撮影された画像を保持する変数
    @Binding var capturedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            // capturedImage nil でない値が設定されている場合、撮影された画像を全画面で表示
            if capturedImage != nil {
                Image(uiImage: capturedImage!)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            // capturedImage が nil の場合
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
}

// プレビュー用
#Preview {
    ContentView()
}
