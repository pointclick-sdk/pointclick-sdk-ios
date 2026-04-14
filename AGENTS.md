# PointClick iOS SDK

PointClick 서비스를 앱에 통합하는 iOS SDK 입니다.
바이너리(XCFramework)로 배포되며, Swift 및 Objective-C 프로젝트 모두에서 사용할 수 있습니다.

## Requirements

- iOS 15.0+
- Swift 5.9+
- Xcode 16.0+

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/pointclick-sdk/pointclick-sdk-ios.git", from: "0.0.2")
]
```

## API Overview

| 클래스 | 역할 |
|--------|------|
| `PointClick` | 싱글톤. SDK 초기화 (`initialize`) |
| `PointClickView` | SwiftUI View (`UIViewControllerRepresentable`) |
| `PointClickUI` | UIKit UI 진입점 (`show`, `createViewController`) |
| `PointClickUserGender` | 성별 enum (`.male`, `.female`) |
| `PointClickError` | 에러 타입 (`.notInitialized`, `.networkError`, `.invalidConfig`) |

## ATT (App Tracking Transparency)

SDK 는 내부적으로 IDFA 를 수집합니다. ATT 권한 요청 완료 후 SDK 를 초기화해야 합니다.

### 필수 설정

1. `Info.plist` 에 `NSUserTrackingUsageDescription` 추가
2. `ATTrackingManager.requestTrackingAuthorization` 호출 후 SDK 초기화

**Swift:**
```swift
import AppTrackingTransparency
import PointClickSdk

ATTrackingManager.requestTrackingAuthorization { status in
    DispatchQueue.main.async {
        PointClick.shared.initialize(appId: "APP_ID", userId: "USER_ID")
    }
}
```

**Objective-C:**
```objc
@import AppTrackingTransparency;
@import PointClickSdk;

[ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[PCPointClick shared] initializeWithAppId:@"APP_ID" userId:@"USER_ID"];
    });
}];
```

> ATT 거부 시에도 SDK 는 정상 동작하나 IDFA 가 수집되지 않습니다.

## Usage

### 1. 초기화

`PointClick.shared.initialize()` 를 앱 시작 시 호출합니다. 다른 SDK 기능을 사용하기 전에 반드시 호출해야 합니다.

**Swift:**
```swift
import PointClickSdk

// 필수 파라미터만
PointClick.shared.initialize(appId: "APP_ID", userId: "USER_ID")

// 선택 파라미터 포함
PointClick.shared.initialize(
    appId: "APP_ID",
    userId: "USER_ID",
    gender: .male,
    birthYear: 1990
)
```

**Objective-C:**
```objc
@import PointClickSdk;

[[PCPointClick shared] initializeWithAppId:@"APP_ID" userId:@"USER_ID"];

[[PCPointClick shared] initializeWithAppId:@"APP_ID"
                                    userId:@"USER_ID"
                                    gender:PCUserGenderMale
                                 birthYear:1990];
```

#### 파라미터

| 구분 | 파라미터 | 타입 | 설명 |
|------|---------|------|------|
| 필수 | `appId` | `String` | 앱 고유 식별자 |
| 필수 | `userId` | `String` | 사용자 고유 식별자 |
| 선택 | `gender` | `PointClickUserGender` | `.male` 또는 `.female` |
| 선택 | `birthYear` | `Int` | 출생 연도 (YYYY) |

### 2. UI 표시

**SwiftUI:**
```swift
import SwiftUI
import PointClickSdk

struct ContentView: View {
    var body: some View {
        PointClickView()
    }
}
```

**UIKit (Swift):**
```swift
let pointClickUI = PointClickUI()

// 전체 화면으로 표시
pointClickUI.show(on: viewController)

// 또는 ViewController 를 생성하여 직접 임베드
if let vc = pointClickUI.createViewController() {
    addChild(vc)
    view.addSubview(vc.view)
    vc.view.frame = view.bounds
    vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    vc.didMove(toParent: self)
}
```

**Objective-C:**
```objc
PCPointClickUI *ui = [[PCPointClickUI alloc] init];
[ui showOn:viewController];
```

## Important

- `initialize()` 를 호출하지 않고 UI 를 표시하면 `PointClickError.notInitialized` 에러가 발생합니다.
- `PointClick.shared.isInitialized` 로 초기화 여부를 확인할 수 있습니다.
- 이 SDK 는 바이너리로만 배포됩니다. 소스 코드는 제공되지 않습니다.
