// iOS 18 移植垫片（SDK 27 shims）
//
// 上游按 iOS 27 SDK 编写；GitHub 的 macos-26 runner 只有 iOS 26 SDK，
// 一批 iOS 27 独占符号在编译期不存在，光靠源码里的 #available 运行时守卫救不了。
// 本文件在同一模块内补上这些符号的空实现，语义统一为「普通 iPhone」：
//   - iPhone 不是折叠屏：没有铰链、没有 division / occlusion 保留区；
//   - iPhone 没有竖排工具栏：toolbarVerticalEdge 恒为 nil；
//   - 工具栏的竖排 / 压缩 / 最小化行为一律透传走系统默认。
// 所有调用点本来就被 #available(iOS 27.x) 守卫或在无铰链时走同一条回退路径，
// 所以在 iPhone 上与原版行为等价，不是砍功能。
//
// ⚠️ 若将来改用 iOS 27 SDK 编译，本文件会与系统符号重名，届时应整文件删除。
import SwiftUI

// MARK: - GeometryProxy.reservedRegions（折痕 / 遮挡保留区）

/// 保留区类别垫片（对应 iOS 27 的 reserved-region kind）。
enum DYReservedRegionKind {
    case division
    case occlusion
}

/// 保留区布局方向行为垫片。
enum DYReservedRegionLayoutDirectionBehavior {
    case fixed
    case mirrored
}

/// 保留区元素垫片：只补上游实际读取的 frame / isActive 两个字段。
struct DYReservedRegion {
    var frame: CGRect = .zero
    var isActive: Bool = false
}

extension GeometryProxy {
    /// iPhone 无折痕、无系统保留区：恒返回空数组。
    /// 上游拿到空数组后的处理（不分屏、不平移、遮挡内边距为 0）正是普通手机应有的结果。
    func reservedRegions(kind: DYReservedRegionKind,
                         layoutDirectionBehavior: DYReservedRegionLayoutDirectionBehavior = .fixed) -> [DYReservedRegion] {
        []
    }
}

// MARK: - DeviceHinge / View.onHingeChange（铰链状态）

/// 铰链垫片（对应 iOS 27 的 DeviceHinge）。iPhone 没有铰链，
/// 本类型永远不会产生实例：onHingeChange 垫片不回调、context.hinge 恒为 nil，
/// 调用方一律走「不支持折叠」路径。
struct DeviceHinge {
    enum Status {
        case closed
        case partiallyOpen
        case fullyOpen
    }
    var status: Status
}

/// onHingeChange 回调上下文垫片：只补调用方实际读取的 hinge 字段。
struct DYHingeChangeContext {
    var hinge: DeviceHinge? = nil
}

extension View {
    /// 无铰链设备上永不触发：直接透传，不挂任何监听。
    func onHingeChange(perform action: @escaping (DeviceHinge?, DYHingeChangeContext) -> Void) -> Self {
        self
    }
}

// MARK: - EnvironmentValues.toolbarVerticalEdge（竖排工具栏所在边）

extension EnvironmentValues {
    /// iPhone 没有系统竖排工具栏：恒为 nil。
    /// 上游对 nil 的处理就是「没有竖栏、控件走普通横排」，即普通手机的原样行为。
    @Entry var toolbarVerticalEdge: HorizontalEdge? = nil
}

// MARK: - ToolbarPlacement.statusBar

extension ToolbarPlacement {
    /// iOS 27 的状态栏工具栏位置在 iOS 26 SDK 里不存在：回退 .automatic。
    /// 唯一调用点在 #available(iOS 27.0) 守卫内（评论栏状态栏显隐），
    /// iOS 18 设备上不会执行到；仅在 iOS 27 设备上跑这个包时，
    /// 状态栏显隐会作用到 automatic 位置，与原意略有出入。
    static var statusBar: ToolbarPlacement { .automatic }
}

// MARK: - 工具栏竖排 / 压缩 / 最小化行为（一律透传走默认）

/// 对应 iOS 27 的 toolbarVerticalBehavior 参数。
enum DYToolbarVerticalBehavior {
    case automatic
    case disabled
}

/// 对应 iOS 27 的 toolbarVerticalCompressionBehavior 参数。
enum DYToolbarVerticalCompressionBehavior {
    case prefersToolbarItems
}

/// 对应 iOS 27 的 toolbarMinimizationBehavior 参数。
enum DYToolbarMinimizationBehavior {
    case automatic
    case never
}

extension View {
    /// iPhone 没有竖排工具栏，竖排行为无从谈起：透传。
    func toolbarVerticalBehavior(_ behavior: DYToolbarVerticalBehavior) -> Self { self }

    /// 竖排压缩只影响系统竖栏的排布，iPhone 上不存在：透传。
    func toolbarVerticalCompressionBehavior(_ behavior: DYToolbarVerticalCompressionBehavior) -> Self { self }

    /// 工具栏最小化是 iOS 27 的新行为，低版本本来就不最小化：透传即默认。
    func toolbarMinimizationBehavior(_ behavior: DYToolbarMinimizationBehavior,
                                     for placement: ToolbarPlacement) -> Self { self }
}

// MARK: - ToolbarContent.axisBehavior / visibilityPriority（竖栏内的项排布）

/// 对应 iOS 27 的 axisBehavior 参数。
enum DYToolbarAxisBehavior {
    case verticalPreferred
}

/// 对应 iOS 27 的 visibilityPriority 参数。
enum DYToolbarVisibilityPriority {
    case high
}

extension ToolbarContent {
    /// 对应 iOS 27 的 ToolbarContent.hidden：iOS 26 SDK 里同名方法被标为 unavailable。
    /// 调用方 DYNativeVideoActions 整体是 iOS 27.1 限定类型，iOS 18 上不会实例化，
    /// 这里只需编译期透传（iOS 27 设备上跑此包时该项不会被隐藏，与原意略有出入）。
    func dyHidden(_ hidden: Bool = true) -> Self { self }

    /// 只影响系统竖栏存在时工具项的排布方向，iPhone 无竖栏：透传。
    func axisBehavior(_ behavior: DYToolbarAxisBehavior) -> Self { self }

    /// 只影响系统竖栏存在时工具项的取舍优先级，iPhone 无竖栏：透传。
    func visibilityPriority(_ priority: DYToolbarVisibilityPriority) -> Self { self }
}
