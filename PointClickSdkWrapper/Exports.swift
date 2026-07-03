// PointClickSdk 바이너리와 서드파티 광고 SDK(AdFit, LevelPlay)를 함께 링크하기 위한 래퍼 타깃.
// 매체 앱에서는 기존과 동일하게 `import PointClickSdk` 로 사용한다.
//
// 주의: 이 파일에서 `import PointClickSdk` 를 하면 안 된다.
// 래퍼와 바이너리 타깃이 같은 패키지(pointclick-sdk-ios)에 속하는데, Swift 는 같은 패키지의
// 모듈을 (private) swiftinterface 로 import 하는 것을 금지하므로 매체 앱 빌드가 실패한다.
// ("Module 'PointClickSdk' is in package ... but was built from a non-package interface")
// 매체 앱(다른 패키지)에서의 `import PointClickSdk` 는 이 규칙에 해당하지 않아 정상 동작한다.
//
// LevelPlay(IronSource) SDK 와 미디에이션 어댑터, PointClickSdk 바이너리는 import 없이도
// Package.swift 의 product 의존성 그래프에 의해 앱에 링크/임베드된다.
import AdFitSDK
