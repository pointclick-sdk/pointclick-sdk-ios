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
    .package(url: "https://github.com/pointclick-sdk/pointclick-sdk-ios.git", from: "1.0.1")
]
```

## API Overview

| 클래스 | 역할 |
|--------|------|
| `PointClick` | 싱글톤. SDK 초기화 (`initialize`), 사용자 설정 (`setUser`), Shortcut 브릿지 등록 (`registerWebView` / `unregisterWebView`) |
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

`initialize` 는 내부적으로 디바이스 정보(IDFA, IP 등)를 비동기로 수집하며,
수집이 완료되면 `completion` 이 메인 스레드에서 호출됩니다.

> **주의**: `initialize` 는 비동기 동작입니다. `completion` 콜백이 호출되기 전에
> `setUser`, `registerWebView`, `show` 등을 호출하면 디바이스 정보(IDFA 등)가 수집되지 않은 상태이므로
> 400 Bad Request 에러 및 광고 노출 차단이 발생할 수 있습니다.
> 반드시 `completion` 콜백 내에서 다음 단계를 진행해야 합니다.

**Swift:**
```swift
import PointClickSdk

// Case 1: 로그인 필수 앱 — userId 를 함께 전달
PointClick.shared.initialize(appId: "APP_ID", userId: "USER_ID") {
    // 초기화 완료 — 이제 registerWebView / show 등 사용 가능
}

// Case 2: 비로그인 앱 — userId 없이 초기화, 로그인 후 setUser 호출
PointClick.shared.initialize(appId: "APP_ID") {
    // 초기화 완료 — userId 가 설정되지 않았으므로 광고 표시 불가
    // 로그인 완료 후 setUser() 호출 필요
}

// 선택 파라미터 포함 (completion 생략 가능)
PointClick.shared.initialize(
    appId: "APP_ID",
    userId: "USER_ID",
    gender: .male,
    birthYear: 1990
) {
    // 초기화 완료 — 이제 SDK 사용 가능
}
```

**Objective-C:**
```objc
@import PointClickSdk;

// Case 1: 로그인 필수 앱
[[PCPointClick shared] initializeWithAppId:@"APP_ID"
                                    userId:@"USER_ID"
                                completion:^{
    // 초기화 완료
}];

// Case 2: 비로그인 앱
[[PCPointClick shared] initializeWithAppId:@"APP_ID"
                                completion:^{
    // 초기화 완료 — 로그인 후 setUser 호출 필요
}];

// 선택 파라미터 포함
[[PCPointClick shared] initializeWithAppId:@"APP_ID"
                                    userId:@"USER_ID"
                                    gender:PCUserGenderMale
                                 birthYear:1990
                                completion:^{
    // 초기화 완료 — 이제 SDK 사용 가능
}];
```

#### 파라미터

| 구분 | 파라미터 | 타입 | 설명 |
|------|---------|------|------|
| 필수 | `appId` | `String` | 앱 고유 식별자 |
| 선택 | `userId` | `String` | 사용자 고유 식별자. 비로그인 앱은 생략 후 `setUser` 로 나중에 설정 |
| 선택 | `gender` | `PointClickUserGender` | `.male` 또는 `.female` |
| 선택 | `birthYear` | `Int` | 출생 연도 (YYYY) |
| 선택 | `completion` | `(() -> Void)?` | 초기화 완료 시 메인 스레드에서 호출되는 콜백 |

### 2. 사용자 설정 (setUser)

비로그인 상태에서 SDK 를 초기화한 앱은, 로그인 완료 후 `setUser` 를 호출하여 사용자를 설정합니다.

> `setUser` 는 `initialize` 의 `completion` 콜백이 호출된 후 (`isInitialized == true`) 에만 호출할 수 있습니다.
> 초기화가 완료되지 않은 상태에서 호출하면 무시됩니다.
> 이미 `registerWebView` 로 브릿지가 등록된 경우, 사용자 변경을 WebView 에 반영하려면
> WebView 를 reload 해야 합니다 (Web SDK 가 `window.PointClickSdkInfo` 를 초기 로드 시 캐싱하기 때문).

**Swift:**
```swift
// 로그인 완료 시 — 반드시 isInitialized 확인 후 호출
guard PointClick.shared.isInitialized else { return }
PointClick.shared.setUser(userId: "USER_ID")

// 프로필 정보도 함께 설정
PointClick.shared.setUser(userId: "USER_ID", gender: .female, birthYear: 1995)
```

**Objective-C:**
```objc
// 로그인 완료 시 — 반드시 isInitialized 확인 후 호출
if ([PCPointClick shared].isInitialized) {
    [[PCPointClick shared] setUserWithUserId:@"USER_ID"];
}

// 프로필 정보도 함께 설정
[[PCPointClick shared] setUserWithUserId:@"USER_ID" gender:PCUserGenderFemale birthYear:1995];
```

### 3. UI 표시

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

### 4. Shortcut 브릿지 (매체 WebView 연동)

앱이 소유한 WKWebView 에서 PointClick Web SDK(`pointclick-web-sdk.js`)의 Shortcut 광고를 표시할 수 있습니다.

> `registerWebView` 호출 전에 다음 조건이 충족되어야 합니다:
> 1. `initialize`의 `completion` 콜백이 호출된 상태 (초기화 완료)
> 2. `userId`가 설정된 상태 (`initialize` 시 전달 또는 `setUser` 호출)

**Swift (UIKit):**
```swift
import PointClickSdk
import WebKit

class MyViewController: UIViewController {
    var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        webView = WKWebView(frame: view.bounds)
        view.addSubview(webView)

        // 1. 브릿지 등록 (URL 로드 전에 호출)
        PointClick.shared.registerWebView(webView)

        // 2. Web SDK 가 포함된 매체 웹페이지 로드
        let url = URL(string: "https://www.example.com/mypage")!
        webView.load(URLRequest(url: url))
    }

    deinit {
        // 3. 해제 (메모리 누수 방지)
        PointClick.shared.unregisterWebView(webView)
    }
}
```

**Objective-C:**
```objc
@import PointClickSdk;
@import WebKit;

@interface MyViewController ()
@property (nonatomic, strong) WKWebView *webView;
@end

@implementation MyViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.webView];

    // 1. 브릿지 등록
    [[PCPointClick shared] registerWebView:self.webView];

    // 2. 매체 웹페이지 로드
    NSURL *url = [NSURL URLWithString:@"https://www.example.com/mypage"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)dealloc {
    // 3. 해제
    [[PCPointClick shared] unregisterWebView:self.webView];
}

@end
```

> `registerWebView` 는 반드시 `initialize` 호출 후, URL 로드 전에 호출해야 합니다.
> `unregisterWebView` 는 ViewController 의 `deinit`(또는 `dealloc`)에서 호출합니다.

## Important

- `initialize()` 를 호출하지 않고 UI 를 표시하면 `PointClickError.notInitialized` 에러가 발생합니다.
- `PointClick.shared.isInitialized` 로 초기화 여부를 확인할 수 있습니다.
- 이 SDK 는 바이너리로만 배포됩니다. 소스 코드는 제공되지 않습니다.
