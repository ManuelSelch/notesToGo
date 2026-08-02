import Foundation
import Flux

nonisolated struct SettingsFeature: Feature {
    struct State: Equatable, Sendable {
        
    }
    
    enum Action: Equatable, Sendable {
        
    }
    
    enum Route: Codable {
        case settings
        case console
    }
    
    func reduce(_ state: inout State, _ action: Action) {
        
    }
}
