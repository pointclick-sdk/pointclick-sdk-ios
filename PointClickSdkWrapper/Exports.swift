// PointClickSdk 바이너리와 서드파티 광고 SDK(AdFit, LevelPlay)를 함께 링크하기 위한 래퍼 타깃.
// 매체 앱에서는 기존과 동일하게 `import PointClickSdk` 로 사용한다.
//
// LevelPlay(IronSource) SDK 와 미디에이션 어댑터는 import 없이도
// Package.swift 의 product 의존성 그래프에 의해 앱에 링크/임베드된다.
// (SDK 내부는 NSClassFromString 런타임 조회로 호출하므로 직접 import 가 필요 없음)
@_exported import PointClickSdk
import AdFitSDK
