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
            targets: ["PointClickSdkWrapper"]
        )
    ],
    dependencies: [
        // 카카오 AdFit SDK — 매체 앱이 이 패키지만 추가하면 자동으로 링크/임베드된다.
        .package(url: "https://github.com/adfit/adfit-spm.git", from: "3.21.24"),
        // LevelPlay(IronSource) SDK — 리워드 비디오 미디에이션
        .package(url: "https://github.com/ironsource-mobile/LevelPlay-Swift-Package.git", from: "9.5.0"),
        // LevelPlay 미디에이션 어댑터 (각 어댑터가 해당 네트워크 SDK 를 전이 의존성으로 포함)
        // ⚠️ InMobi · Moloco · Smaato · Verve 어댑터는 SPM 미제공 (CocoaPods 전용)
        // ⚠️ Pangle 어댑터는 SPM 매니페스트 결함(Pangle SDK 를 존재하지 않는 4자리 버전 exact "8.1.1.1" 로
        //    요구하여 resolve 불가)으로 제외 (CocoaPods 전용). IronSource 측 수정 시 추가 가능.
        .package(url: "https://github.com/ironsource-mobile/LevelPlay-AppLovin-Adapter-Swift-Package.git", from: "5.7.1"),
        .package(url: "https://github.com/ironsource-mobile/LevelPlay-BidMachine-Adapter-Swift-Package.git", from: "5.7.1"),
        .package(url: "https://github.com/ironsource-mobile/LevelPlay-Facebook-Adapter-Swift-Package.git", from: "5.3.1"),
        .package(url: "https://github.com/ironsource-mobile/LevelPlay-Fyber-Adapter-Swift-Package.git", from: "5.9.0"),
        .package(url: "https://github.com/ironsource-mobile/LevelPlay-Mintegral-Adapter-Swift-Package.git", from: "5.18.1"),
        .package(url: "https://github.com/ironsource-mobile/LevelPlay-UnityAds-Adapter-Swift-Package.git", from: "5.9.0"),
        .package(url: "https://github.com/ironsource-mobile/LevelPlay-Vungle-Adapter-Swift-Package.git", from: "5.10.1")
    ],
    targets: [
        // 바이너리 타깃 이름은 아티팩트(PointClickSdk.xcframework) 이름과 일치해야 한다.
        .binaryTarget(
            name: "PointClickSdk",
            path: "PointClickSdk.xcframework"
        ),
        // 바이너리(PointClickSdk.xcframework)와 서드파티 광고 SDK 를 함께 묶는 래퍼 타깃.
        // 바이너리 타깃은 의존성을 가질 수 없으므로, 소스 타깃을 통해 전이 의존성으로 노출한다.
        .target(
            name: "PointClickSdkWrapper",
            dependencies: [
                .target(name: "PointClickSdk"),
                .product(name: "AdFitSDK", package: "adfit-spm"),
                .product(name: "UnityMediationSDK", package: "LevelPlay-Swift-Package"),
                .product(name: "AppLovinAdapter", package: "LevelPlay-AppLovin-Adapter-Swift-Package"),
                .product(name: "BidMachineAdapter", package: "LevelPlay-BidMachine-Adapter-Swift-Package"),
                .product(name: "FacebookAdapter", package: "LevelPlay-Facebook-Adapter-Swift-Package"),
                .product(name: "FyberAdapter", package: "LevelPlay-Fyber-Adapter-Swift-Package"),
                .product(name: "MintegralAdapter", package: "LevelPlay-Mintegral-Adapter-Swift-Package"),
                .product(name: "UnityAdsAdapter", package: "LevelPlay-UnityAds-Adapter-Swift-Package"),
                .product(name: "VungleAdapter", package: "LevelPlay-Vungle-Adapter-Swift-Package")
            ],
            path: "PointClickSdkWrapper"
        )
    ]
)
