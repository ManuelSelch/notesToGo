import Foundation
import Flux

nonisolated struct SettingsFeature: Feature {
    struct State: Equatable, Sendable {
        var penSize: CGFloat = 1
    }
    
    enum Action: Equatable, Sendable {
        case penSizeLoaded(CGFloat)
        case penSizeChanged(CGFloat)
    }
    
    enum Route: Codable {
        case settings
        case console
    }
    
    func reduce(_ state: inout State, _ action: Action) {
        switch(action) {
        case let .penSizeLoaded(size):
            state.penSize = size
        case let .penSizeChanged(size):
            state.penSize = size
        }
    }
}
