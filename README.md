# PointClick iOS SDK

PointClick 서비스를 앱에 통합하는 iOS SDK 입니다.
SwiftUI, UIKit, Objective-C 를 모두 지원합니다.

> **Requirements:** iOS 15.0+, Swift 5.9+, Xcode 16.0+
>
> **Privacy manifest:** 이 SDK 는 `PrivacyInfo.xcprivacy` 를 포함합니다.
> Xcode 가 앱을 아카이브할 때 앱의 개인정보 보고서에 자동으로 합쳐집니다. 별도 설정은 필요 없습니다.

---

## Installation

Swift Package Manager 로 설치합니다.

이 SDK 는 **광고 SDK 를 번들하지 않습니다.** 리워드 비디오 미디에이션에 필요한
AdWhale / AdMob 어댑터와 (선택) AdFit SDK 는 **매체 앱이 직접 SPM 으로 추가**합니다 (아래 목록 참고).
매체가 이미 사용 중인 광고 SDK 버전을 매체가 직접 관리할 수 있도록 하기 위함입니다.

> 기기 정보 / WebView 호스팅 라이브러리(FSNDeviceInfo, FSNWebView)는 이 SDK 바이너리에
> **정적으로 포함**되어 있어 매체 앱이 별도로 추가하지 않습니다.

### 1. PointClick SDK 추가

Xcode → File → Add Package Dependencies 에서 아래 URL 을 추가합니다.

```
https://github.com/pointclick-sdk/pointclick-sdk-ios
```

또는 `Package.swift` 에 직접 추가합니다.

```swift
dependencies: [
    .package(url: "https://github.com/pointclick-sdk/pointclick-sdk-ios.git", from: "1.0.6")
]
```

### 2. 광고 SDK / 미디에이션 어댑터 추가 (매체가 직접)

리워드 비디오 광고를 제공하려면 아래 패키지를 앱 타깃에 함께 추가합니다.

**AdWhale SDK** — `https://github.com/adwhale-sdk/adwhale-sdk-ios`

| Product | 필수 여부 |
|---------|----------|
| `AdWhaleSDK` | 필수 |
| `AdWhaleAdMobAdapter` | 필수 (AdMob 미디에이션) |
| `AdWhaleCaulyAdapter` | Cauly 네트워크를 쓸 때만 |

**AdMob 미디에이션 네트워크 어댑터** — 아래 8종을 각각 추가합니다.

| Package URL | Product |
|-------------|---------|
| `https://github.com/googleads/googleads-mobile-ios-mediation-applovin.git` | `AppLovinAdapterTarget` |
| `https://github.com/googleads/googleads-mobile-ios-mediation-dtexchange.git` | `DTExchangeAdapterTarget` |
| `https://github.com/googleads/googleads-mobile-ios-mediation-inmobi.git` | `InMobiAdapterTarget` |
| `https://github.com/googleads/googleads-mobile-ios-mediation-liftoffmonetize.git` | `LiftoffMonetizeAdapterTarget` |
| `https://github.com/googleads/googleads-mobile-ios-mediation-mintegral.git` | `MintegralAdapterTarget` |
| `https://github.com/googleads/googleads-mobile-ios-mediation-moloco.git` | `MolocoAdapterTarget` |
| `https://github.com/googleads/googleads-mobile-ios-mediation-pangle.git` | `PangleAdapterTarget` |
| `https://github.com/googleads/googleads-mobile-ios-mediation-unity.git` | `UnityAdapterTarget` |

**AdFit SDK (선택)** — 오퍼월/미디어 WebView 내 AdFit 배너를 네이티브로 렌더링할 때만 추가합니다.

| Package URL | Product |
|-------------|---------|
| `https://github.com/adfit/adfit-spm.git` | `AdFitSDK` |

> AdFit 광고를 사용하지 않으면 추가하지 않아도 됩니다. SDK 는 AdFit SDK 를 직접 import 하지 않고 런타임으로만 호출하므로, AdFit 이 없으면 해당 배너 렌더링을 건너뛸 뿐 빌드/동작에는 영향이 없습니다.

### 3. `-ObjC` 링커 플래그 추가 (필수)

AdWhale(AdMob) SDK 가 정적 라이브러리로 제공되어, 앱 타깃에 아래 설정이 필요합니다.

1. Xcode → 앱 타깃 → Build Settings → **Other Linker Flags**
2. `-ObjC` 추가

이 설정이 없으면 AdMob 미디에이션 어댑터가 등록되지 않아 리워드 비디오 광고가 동작하지 않습니다.

### 4. `Info.plist` 에 `GADApplicationIdentifier` 추가 (필수)

AdWhale 은 내부적으로 Google Mobile Ads(AdMob) SDK 를 사용합니다. `Info.plist` 에
`GADApplicationIdentifier` 키가 없으면 앱이 실행 직후 크래시됩니다
("The Google Mobile Ads SDK was initialized incorrectly").

> `PUBLISHER_UID` 등 AdWhale 게시자 식별자는 오퍼월 로드 시 웹 런타임에서 주입되므로
> 앱 측 별도 설정은 필요 없습니다.

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
수집이 끝나면 결과를 `completion` 에 전달합니다. 성공 시 `.success`, 실패 시 `.failure(error)` 로
메인 스레드에서 호출됩니다. (디바이스 정보 수집에 실패하면 오퍼월 광고를 제공할 수 없어 초기화 실패로 처리됩니다.)

> **주의**: `initialize` 는 비동기 동작입니다. `completion` 이 호출되기 전에
> `setUser`, `registerWebView`, `show` 등을 호출하면 디바이스 정보(IDFA 등)가 수집되지 않은 상태이므로
> 400 Bad Request 에러 및 광고 노출 차단이 발생할 수 있습니다.
> 반드시 `completion` 의 `.success` 분기 안에서 다음 단계를 진행해야 합니다.

> **이번 버전에서 변경된 내용**: `completion` 이 결과(`Result`)를 전달하도록 변경되었습니다.
> 인자 없이 `initialize(...) { ... }` 로 호출하던 코드는 `initialize(...) { result in switch result { ... } }` 형태로 수정해야 합니다.
> (Objective-C 는 `completion:^{ ... }` → `completion:^(NSError * _Nullable error) { ... }`)

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
        ) { result in
            switch result {
            case .success:
                // 초기화 완료 - 이제 SDK 사용 가능
                break
            case .failure(let error):
                // 초기화 실패 - IDFA 등 수집 실패로 오퍼월 표시 불가
                print("PointClick init failed: \(error)")
            }
        }
    }
}
```

**Swift:**
```swift
import PointClickSdk

// Case 1: 로그인 필수 앱 - userId 를 함께 전달
PointClick.shared.initialize(appId: "YOUR_APP_ID", userId: "USER_ID") { result in
    switch result {
    case .success:
        // 초기화 완료 - 이제 registerWebView / show 등 사용 가능
        break
    case .failure(let error):
        // 초기화 실패 - IDFA 등 수집 실패로 오퍼월 표시 불가
        print("PointClick init failed: \(error)")
    }
}

// Case 2: 비로그인 앱 - userId 없이 초기화, 로그인 후 setUser 호출
PointClick.shared.initialize(appId: "YOUR_APP_ID") { result in
    switch result {
    case .success:
        // 초기화 완료 - userId 가 설정되지 않았으므로 광고 표시 불가
        // 로그인 완료 후 setUser() 호출 필요
        break
    case .failure(let error):
        // 초기화 실패 - IDFA 등 수집 실패로 오퍼월 표시 불가
        print("PointClick init failed: \(error)")
    }
}

// 선택 파라미터 포함 (completion 생략 가능)
PointClick.shared.initialize(
    appId: "YOUR_APP_ID",
    userId: "USER_ID",
    gender: .male,
    birthYear: 1990
) { result in
    switch result {
    case .success:
        // 초기화 완료 - 이제 SDK 사용 가능
        break
    case .failure(let error):
        // 초기화 실패 - IDFA 등 수집 실패로 오퍼월 표시 불가
        print("PointClick init failed: \(error)")
    }
}
```

**Objective-C:**
```objc
@import PointClickSdk;

// Case 1: 로그인 필수 앱
[[PCPointClick shared] initializeWithAppId:@"YOUR_APP_ID"
                                    userId:@"USER_ID"
                                completion:^(NSError * _Nullable error) {
    if (error == nil) {
        // 초기화 완료
    } else {
        // 초기화 실패 - 오퍼월 표시 불가
    }
}];

// Case 2: 비로그인 앱
[[PCPointClick shared] initializeWithAppId:@"YOUR_APP_ID"
                                completion:^(NSError * _Nullable error) {
    if (error == nil) {
        // 초기화 완료 - 로그인 후 setUser 호출 필요
    } else {
        // 초기화 실패 - 오퍼월 표시 불가
    }
}];

// 선택 파라미터 포함
[[PCPointClick shared] initializeWithAppId:@"YOUR_APP_ID"
                                    userId:@"USER_ID"
                                    gender:PCUserGenderMale
                                 birthYear:1990
                                completion:^(NSError * _Nullable error) {
    if (error == nil) {
        // 초기화 완료 - 이제 SDK 사용 가능
    } else {
        // 초기화 실패 - 오퍼월 표시 불가
    }
}];
```

| 구분 | 파라미터 | 설명 |
|------|---------|------|
| 필수 | `appId` | 앱 고유 식별자 |
| 선택* | `userId` | 사용자 고유 식별자. `initialize` 시에는 생략 가능하나, **오퍼월과 Shortcut 사용 전에는 반드시 설정되어 있어야 합니다.** 비로그인 앱은 생략 후 로그인 시 `setUser` 로 설정 |
| 선택 | `gender` | `.male` 또는 `.female` |
| 선택 | `birthYear` | 출생 연도 (YYYY) |
| 선택 | `completion` | 초기화 결과 콜백. 성공 시 .success, 실패 시 .failure(error). 항상 메인 스레드에서 호출 |

`*` `userId` 는 초기화 시 생략할 수 있으나, 오퍼월과 Shortcut 을 사용하려면 `initialize` 또는 `setUser` 로 반드시 설정되어 있어야 합니다. 미설정 시 오퍼월/Shortcut 은 에러 로그와 함께 동작하지 않습니다.

> ATT 권한이 거부되면 오퍼월 광고가 표시되지 않습니다. 리워드 광고 제공을 위해 광고 추적 허용이 필요합니다.

### 3. 사용자 설정 (setUser)

비로그인 상태에서 SDK 를 초기화한 앱은, 로그인 완료 후 `setUser` 를 호출하여 사용자를 설정합니다.

> `setUser` 는 `initialize` 의 `completion` 콜백이 호출된 후 (`isInitialized == true`) 에만 호출할 수 있습니다.
> 초기화가 완료되지 않은 상태에서 호출하면 무시됩니다.
> 이미 `registerWebView` 로 브릿지가 등록된 경우, 사용자 변경을 WebView 에 반영하려면
> WebView 를 reload 해야 합니다 (Web SDK 가 `window.PointClickSdkInfo` 를 초기 로드 시 캐싱하기 때문).

**Swift:**
```swift
// 로그인 완료 시 - 반드시 isInitialized 확인 후 호출
guard PointClick.shared.isInitialized else { return }
PointClick.shared.setUser(userId: "USER_ID")

// 프로필 정보도 함께 설정
PointClick.shared.setUser(userId: "USER_ID", gender: .female, birthYear: 1995)
```

**Objective-C:**
```objc
// 로그인 완료 시 - 반드시 isInitialized 확인 후 호출
if ([PCPointClick shared].isInitialized) {
    [[PCPointClick shared] setUserWithUserId:@"USER_ID"];
}

// 프로필 정보도 함께 설정
[[PCPointClick shared] setUserWithUserId:@"USER_ID" gender:PCUserGenderFemale birthYear:1995];
```

**로그아웃 (clearUser)**

로그아웃 시 `clearUser` 를 호출하여 사용자 정보를 초기화합니다. 이후 `userId` 가 없어 오퍼월과 Shortcut 은 차단됩니다.

```swift
// Swift
PointClick.shared.clearUser()
```

```objc
// Objective-C
[[PCPointClick shared] clearUser];
```

> 이미 `registerWebView` 로 브릿지를 등록한 매체 WebView 는, 로그아웃 상태를 반영하려면 매체 앱에서 WebView 를 **reload** 해야 합니다. (SDK 는 매체 소유 WebView 를 자동으로 reload 하지 않습니다. 오퍼월은 로그아웃 전 이미 닫혀 있으므로 해당 없음.)

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
            // 1. ATT 권한 요청 (화면 표시 후 0.5초 딜레이 - Apple 권장)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                ATTrackingManager.requestTrackingAuthorization { _ in
                    DispatchQueue.main.async {
                        // 2. SDK 초기화 - completion 에서 UI 전환
                        PointClick.shared.initialize(
                            appId: "YOUR_APP_ID",
                            userId: "user123"
                        ) { result in
                            switch result {
                            case .success:
                                // 3. 초기화 완료 - 이 시점부터 SDK 사용 가능
                                isSDKReady = true
                            case .failure(let error):
                                // 초기화 실패 처리 (재시도/에러 UI 등)
                                print("PointClick init failed: \(error)")
                            }
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
                ) { result in
                    switch result {
                    case .success:
                        // 3. 초기화 완료 - completion 안에서 UI 표시
                        PointClickUI().show(on: self)
                    case .failure(let error):
                        // 초기화 실패 - IDFA 등 수집 실패로 오퍼월 표시 불가
                        print("PointClick init failed: \(error)")
                    }
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
                                            completion:^(NSError * _Nullable error) {
                if (error == nil) {
                    // 3. 초기화 완료 - completion 안에서 UI 표시
                    PCPointClickUI *ui = [[PCPointClickUI alloc] init];
                    [ui showOn:self];
                } else {
                    // 초기화 실패 - 오퍼월 표시 불가
                }
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
PointClick.shared.initialize(appId: "YOUR_APP_ID") { result in
    switch result {
    case .success:
        // 초기화 완료 - 아직 userId 없으므로 광고 표시 불가
        // 이 시점부터 setUser 호출 가능
        break
    case .failure(let error):
        // 초기화 실패 - IDFA 등 수집 실패로 오퍼월 표시 불가
        print("PointClick init failed: \(error)")
    }
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
                                completion:^(NSError * _Nullable error) {
    if (error == nil) {
        // 초기화 완료 - 아직 userId 없으므로 광고 표시 불가
        // 이 시점부터 setUser 호출 가능
    } else {
        // 초기화 실패 - 오퍼월 표시 불가
    }
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
