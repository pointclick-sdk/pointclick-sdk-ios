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
    .package(url: "https://github.com/pointclick-sdk/pointclick-sdk-ios.git", from: "0.0.6")
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
        )
    }
}
```

| 구분 | 파라미터 | 설명 |
|------|---------|------|
| 필수 | `appId` | 앱 고유 식별자 |
| 필수 | `userId` | 사용자 고유 식별자 |
| 선택 | `gender` | `.male` 또는 `.female` |
| 선택 | `birthYear` | 출생 연도 (YYYY) |

> ATT 권한이 거부되어도 SDK 는 정상 동작합니다. IDFA 없이 동작하며 맞춤형 광고 성능이 저하될 수 있습니다.

### 3. UI 표시

**SwiftUI:**
```swift
PointClickView()
```

**UIKit:**
```swift
let pointClickUI = PointClickUI()
pointClickUI.show(on: viewController)
```

---

## 전체 연동 예시

### SwiftUI

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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                ATTrackingManager.requestTrackingAuthorization { _ in
                    DispatchQueue.main.async {
                        PointClick.shared.initialize(
                            appId: "YOUR_APP_ID",
                            userId: "user123"
                        )
                        isSDKReady = true
                    }
                }
            }
        }
    }
}
```

### UIKit

```swift
import AppTrackingTransparency
import PointClickSdk

class ViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        ATTrackingManager.requestTrackingAuthorization { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else { return }
                PointClick.shared.initialize(
                    appId: "YOUR_APP_ID",
                    userId: "user123"
                )
                PointClickUI().show(on: self)
            }
        }
    }
}
```

### Objective-C

```objc
@import AppTrackingTransparency;
@import PointClickSdk;

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[PCPointClick shared] initializeWithAppId:@"YOUR_APP_ID" userId:@"user123"];

            PCPointClickUI *ui = [[PCPointClickUI alloc] init];
            [ui showOn:self];
        });
    }];
}
```

---

## Shortcut 브릿지 (매체 WebView 연동)

앱이 소유한 WKWebView 에서 PointClick Web SDK(`pointclick-web-sdk.js`)의 Shortcut 광고를 표시하려면, 해당 WebView 에 브릿지를 등록합니다.

> SDK 초기화(`initialize`)가 먼저 완료된 상태여야 합니다.

### Swift (UIKit)

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

### Objective-C

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
> `unregisterWebView` 는 ViewController 의 `deinit`(또는 `dealloc`)에서 호출하여 메모리 누수를 방지합니다.

---

## AI Agent Support

AI 코딩 도구(Claude Code, Codex, Gemini CLI, Cursor 등)를 사용하여 SDK 를 연동하는 경우 [AGENTS.md](AGENTS.md) 를 참고하세요.

## License

Proprietary. 자세한 내용은 [LICENSE](LICENSE) 파일을 참고하세요.

Copyright © PointClick. All rights reserved.
