//
//  IOS_Camera_SampleApp.swift
//  IOS_Camera_Sample
//
//  Created by hiroto taniguchi on 2024/03/13.
//

import SwiftUI

// @main : この属性は、アプリケーションの開始点を示す
// アプリケーションの実行時に、この属性が付与された構造体が自動的に呼び出される
@main
// Appプロトコルに準拠する構造体を定義し。
// この構造体は、アプリケーションの設定とルートビューを提供する役割
struct IOS_Camera_SampleApp: App {
    var body: some Scene {
        // WindowGroup : アプリケーションのウィンドウを管理するための構造体
        // 下記は、ContentViewをルートビューとして設定(アプリケーションが起動すると ContentViewが最初に表示さる)
        WindowGroup {
//            ContentView()
            MyCustomCameraView()
        }
    }
}
