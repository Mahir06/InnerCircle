import Foundation
import Combine

// Home cards redirect into their feature tabs through this.
@MainActor
final class TabRouter: ObservableObject {
    @Published var selection: String

    init() {
        selection = ProcessInfo.processInfo.environment["IC_START_TAB"] ?? "home"
    }
}
