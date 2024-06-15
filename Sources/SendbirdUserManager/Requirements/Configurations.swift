import Foundation

public struct APIConfiguration {
    let applicationId: String
    let apiToken: String
}

enum GlobalPreference {
    static let userCreationCountLimit: Int = 10
    
    static let dataTaskRateInSeconds: Int = 1
}

