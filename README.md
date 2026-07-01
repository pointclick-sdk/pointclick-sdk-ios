# PointClick iOS SDK

PointClick 서비스를 앱에 통합하는 iOS SDK 입니다.
SwiftUI, UIKit, Objective-C 를 모두 지원합니다.

> **Requirements:** iOS 15.0+ · Swift 5.9+ · Xcode 16.0+

---

## Installation

### Swift Package Manager

Xcode → File → Add Package Dependencies 에서 아래 URL 을 추가합니다.

```
https://github.com/pointclick-sdk/pointclick-sdk-ios
```

또는 `Package.swift` 에 직접 추가합니다.

```swift
dependencies: [
    .package(url: "https://github.com/pointclick-sdk/pointclick-sdk-ios.git", from: "1.0.2")
]
```

---

## Quick Start

### 1. ATT 권한 요청 (필수)

SDK 는 내부적으로 IDFA 를 수집합니다. ATT 권한 요청 후 SDK 를 초기화해야 IDFA 가 정상적으로 수집됩니다.

`Info.plist` 에 아래 키를 추가합니다.

```xml
<key>NSUserTrackingUsageDescription</key>
<string>맞춤형 광고 및 리워드 제공을 위해 광고 식별자를 사용합니다.</string>
```

### 2. 초기화

ATT 권한 요청이 완료된 후 SDK 를 초기화합니다. 다른 SDK 기능을 사용하기 전에 반드시 호출해야 합니다.

`initialize` 는 내부적으로 디바이스 정보(IDFA, IP 등)를 비동기로 수집하며,
수집이 완료되면 `completion` 이 메인 스레드에서 호출됩니다.

> **주의**: `initialize` 는 비동기 동작입니다. `completion` 콜백이 호출되기 전에
> `setUser`, `registerWebView`, `show` 등을 호출하면 디바이스 정보(IDFA 등)가 수집되지 않은 상태이므로
> 400 Bad Request 에러 및 광고 노출 차단이 발생할 수 있습니다.
> 반드시 `completion` 콜백 내에서 다음 단계를 진행해야 합니다.

```swift
import AppTrackingTransparency
import PointClickSdk

ATTrackingManager.requestTrackingAuthorization { _ in
    DispatchQueue.main.async {
        PointClick.shared.initialize(
            appId: "YOUR_APP_ID",
            userId: "USER_ID",
            gender: .male,       // 선택
            birthYear: 1990      // 선택
        ) {
            // 초기화 완료 — 이제 SDK 사용 가능
        }
    }
}
```

**Swift:**
```swift
import PointClickSdk

// Case 1: 로그인 필수 앱 — userId 를 함께 전달
PointClick.shared.initialize(appId: "YOUR_APP_ID", userId: "USER_ID") {
    // 초기화 완료 — 이제 registerWebView / show 등 사용 가능
}

// Case 2: 비로그인 앱 — userId 없이 초기화, 로그인 후 setUser 호출
PointClick.shared.initialize(appId: "YOUR_APP_ID") {
    // 초기화 완료 — userId 가 설정되지 않았으므로 광고 표시 불가
    // 로그인 완료 후 setUser() 호출 필요
}

// 선택 파라미터 포함 (completion 생략 가능)
PointClick.shared.initialize(
    appId: "YOUR_APP_ID",
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
[[PCPointClick shared] initializeWithAppId:@"YOUR_APP_ID"
                                    userId:@"USER_ID"
                                completion:^{
    // 초기화 완료
}];

// Case 2: 비로그인 앱
[[PCPointClick shared] initializeWithAppId:@"YOUR_APP_ID"
                                completion:^{
    // 초기화 완료 — 로그인 후 setUser 호출 필요
}];

// 선택 파라미터 포함
[[PCPointClick shared] initializeWithAppId:@"YOUR_APP_ID"
                                    userId:@"USER_ID"
                                    gender:PCUserGenderMale
                                 birthYear:1990
                                completion:^{
    // 초기화 완료 — 이제 SDK 사용 가능
}];
```

| 구분 | 파라미터 | 설명 |
|------|---------|------|
| 필수 | `appId` | 앱 고유 식별자 |
| 선택 | `userId` | 사용자 고유 식별자. 비로그인 앱은 생략 후 `setUser` 로 나중에 설정 |
| 선택 | `gender` | `.male` 또는 `.female` |
| 선택 | `birthYear` | 출생 연도 (YYYY) |
| 선택 | `completion` | 초기화 완료 시 메인 스레드에서 호출되는 콜백 |

> ATT 권한이 거부되어도 SDK 는 정상 동작합니다. IDFA 없이 동작하며 맞춤형 광고 성능이 저하될 수 있습니다.

### 3. 사용자 설정 (setUser)

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

### 4. UI 표시

**SwiftUI:**
```swift
PointClickView()
```

**UIKit:**
```swift
let pointClickUI = PointClickUI()
pointClickUI.show(on: viewController)
```

**Objective-C:**
```objc
PCPointClickUI *ui = [[PCPointClickUI alloc] init];
[ui showOn:self];
```

---

## 전체 연동 예시

### Case 1: 로그인 필수 앱

ATT 권한 요청 → SDK 초기화(userId 포함) → `completion` 에서 UI 표시하는 전체 흐름입니다.

**SwiftUI:**
```swift
import SwiftUI
import AppTrackingTransparency
import PointClickSdk

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var isSDKReady = false

    var body: some View {
        Group {
            if isSDKReady {
                PointClickView()
            } else {
                ProgressView()
            }
        }
        .onAppear {
            // 1. ATT 권한 요청 (화면 표시 후 0.5초 딜레이 — Apple 권장)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                ATTrackingManager.requestTrackingAuthorization { _ in
                    DispatchQueue.main.async {
                        // 2. SDK 초기화 — completion 에서 UI 전환
                        PointClick.shared.initialize(
                            appId: "YOUR_APP_ID",
                            userId: "user123"
                        ) {
                            // 3. 초기화 완료 — 이 시점부터 SDK 사용 가능
                            isSDKReady = true
                        }
                    }
                }
            }
        }
    }
}
```

**UIKit:**
```swift
import AppTrackingTransparency
import PointClickSdk

class ViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // 1. ATT 권한 요청
        ATTrackingManager.requestTrackingAuthorization { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else { return }
                // 2. SDK 초기화
                PointClick.shared.initialize(
                    appId: "YOUR_APP_ID",
                    userId: "user123"
                ) {
                    // 3. 초기화 완료 — completion 안에서 UI 표시
                    PointClickUI().show(on: self)
                }
            }
        }
    }
}
```

**Objective-C:**
```objc
@import AppTrackingTransparency;
@import PointClickSdk;

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // 1. ATT 권한 요청
    [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 2. SDK 초기화
            [[PCPointClick shared] initializeWithAppId:@"YOUR_APP_ID"
                                                userId:@"user123"
                                            completion:^{
                // 3. 초기화 완료 — completion 안에서 UI 표시
                PCPointClickUI *ui = [[PCPointClickUI alloc] init];
                [ui showOn:self];
            }];
        });
    }];
}
```

### Case 2: 비로그인 앱 (로그인 선택)

userId 없이 SDK 를 먼저 초기화하고, 로그인 완료 후 `setUser` 로 사용자를 설정하는 흐름입니다.

**Swift:**
```swift
import PointClickSdk

// 1. 앱 시작 시 초기화 (userId 없이)
// ⚠️ completion 이 호출되기 전에는 setUser / registerWebView / show 사용 불가
PointClick.shared.initialize(appId: "YOUR_APP_ID") {
    // 초기화 완료 — 아직 userId 없으므로 광고 표시 불가
    // 이 시점부터 setUser 호출 가능
}

// 2. 로그인 완료 후
guard PointClick.shared.isInitialized else {
    // 아직 초기화 중이면 대기 필요
    return
}
PointClick.shared.setUser(userId: "user123")

// 3. 이제 광고 표시 가능
let pointClickUI = PointClickUI()
pointClickUI.show(on: self)
```

**Objective-C:**
```objc
@import PointClickSdk;

// 1. 앱 시작 시 초기화 (userId 없이)
[[PCPointClick shared] initializeWithAppId:@"YOUR_APP_ID"
                                completion:^{
    // 초기화 완료 — 아직 userId 없으므로 광고 표시 불가
    // 이 시점부터 setUser 호출 가능
}];

// 2. 로그인 완료 후
if (![PCPointClick shared].isInitialized) {
    // 아직 초기화 중이면 대기 필요
    return;
}
[[PCPointClick shared] setUserWithUserId:@"user123"];

// 3. 이제 광고 표시 가능
PCPointClickUI *ui = [[PCPointClickUI alloc] init];
[ui showOn:self];
```

---

## Shortcut 브릿지 (매체 WebView 연동)

매체 앱이 소유한 WKWebView에서 PointClick Web SDK(pointclick-web-sdk.js)의 Shortcut 광고를 표시하려면, 해당 WebView에 브릿지를 등록해야 합니다.

> `registerWebView` 호출 전에 다음 조건이 충족되어야 합니다:
> 1. `initialize`의 `completion` 콜백이 호출된 상태 (초기화 완료)
> 2. `userId`가 설정된 상태 (`initialize` 시 전달 또는 `setUser` 호출)

**Swift:**
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
        //    userId 가 설정되어 있어야 합니다 (initialize 시 전달 또는 setUser 호출)
        PointClick.shared.registerWebView(webView)

        // 2. Web SDK가 포함된 매체 웹페이지 로드
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

> `registerWebView`는 반드시 `initialize` 완료 후, URL 로드 전에 호출해야 합니다.
> userId 가 설정되어 있지 않으면 에러 로그와 함께 등록이 무시됩니다.
> `unregisterWebView`는 ViewController의 `deinit`(또는 `dealloc`)에서 호출하여 메모리 누수를 방지합니다.

---

## AI Agent Support

AI 코딩 도구(Claude Code, Codex, Gemini CLI, Cursor 등)를 사용하여 SDK 를 연동하는 경우 [AGENTS.md](AGENTS.md) 를 참고하세요.

## License

Proprietary. 자세한 내용은 [LICENSE](LICENSE) 파일을 참고하세요.

Copyright © PointClick. All rights reserved.
