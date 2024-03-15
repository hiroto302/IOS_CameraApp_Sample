//
//  ContentView.swift
//  IOS_Camera_Sample
//
//  Created by hiroto taniguchi on 2024/03/13.
//

import SwiftUI

struct ContentView: View {
    // 撮影された画像を保持する変数
    @State private var capturedImage: UIImage? = nil
    // CustomCameraView を表示するかどうか
    @State private var isCustomCameraViewPresented = false

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
                    // カメラボタンがタップされた時の処理
                    // isCustomCameraViewPresentedの値を反転させる
                    isCustomCameraViewPresented.toggle()
                }, label: {
                    Image(systemName: "camera.fill")
                        .font(.largeTitle)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                })
                .padding(.bottom)
                // isCustomCameraViewPresentedがtrueの場合、CustomCameraViewをシートとして表示
                .sheet(isPresented: $isCustomCameraViewPresented, content: {
                    CustomCameraView(capturedImage: $capturedImage)
                })
            }
        }
    }
}

// プレビュー用
#Preview {
    ContentView()
}
