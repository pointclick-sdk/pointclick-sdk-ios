// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PointClickSdk",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "PointClickSdk",
            targets: ["PointClickSdk"]
        )
    ],
    targets: [
        // 바이너리 타깃 이름은 아티팩트(PointClickSdk.xcframework) 이름과 일치해야 한다.
        //
        // 이 SDK 는 광고 SDK 를 번들하지 않는다. 리워드 비디오 미디에이션에 필요한
        // AdWhale / AdMob 어댑터는 매체 앱이 직접 SPM 으로 추가한다 (README 참고).
        // SDK 소스는 광고 SDK 를 import 하지 않고 Objective-C 런타임으로 호출하므로
        // 여기서 광고 SDK 를 전이시킬 필요가 없다.
        //
        // 기기 정보(FSNDeviceInfo)와 WebView 호스팅(FSNWebView)은 이 바이너리에
        // 정적으로 포함되어 있어 매체 앱이 별도로 추가하지 않는다.
        .binaryTarget(
            name: "PointClickSdk",
            path: "PointClickSdk.xcframework"
        )
    ]
)
