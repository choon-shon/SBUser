import Foundation

struct ServerResponseError: LocalizedError, CustomDebugStringConvertible {
    let data: Data
    
    init(_ data: Data) {
        self.data = data
    }
    
    var errorDescription: String? {
        String(data: self.data, encoding: .utf8) ?? "Unknown Error"
    }
    
    var debugDescription: String {
        String(data: self.data, encoding: .utf8) ?? "Unknown Error"
    }
}

/// Local Errors within Package
enum PackageError: LocalizedError {
    case invalidPackageSetupAttempt
    
    var errorDescription: String? {
        switch self {
        case .invalidPackageSetupAttempt:
            return "Package setup attempted with invalid appId or apiToken"
        }
    }

    var failureReason: String? {
        switch self {
        case .invalidPackageSetupAttempt:
            return "initApplication(_:) called with an empty appId or apiToken."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidPackageSetupAttempt:
            return "Please check whether appId and apiToken are empty before invoking `initApplication(_:)`."
        }
    }
}

/// Errors Related to Server API calls
enum DataTaskError: LocalizedError, Equatable {
    case exceededUserCreationLimit
    case emptyStringRequest
    case whiteSpaceOrNewlineStringRequest
    
    var errorDescription: String? {
        switch self {
        case .exceededUserCreationLimit:
            return "Cannot create more than \(GlobalPreference.userCreationCountLimit) users at a time."
        case .emptyStringRequest:
            return "Empty user ids / nicknames are not allowed."
        case .whiteSpaceOrNewlineStringRequest:
            return "User ids / nicknames with white spaces or newlines is not allowed."
        }
    }

    var failureReason: String? {
        switch self {
        case .exceededUserCreationLimit:
            return "Attempted to create more than \(GlobalPreference.userCreationCountLimit) users at a time."
        case .emptyStringRequest:
            return "Attempted to create / update user with an empty user id or nickname."
        case .whiteSpaceOrNewlineStringRequest:
            return "Attempted to create / update user using user info containing whitespaces or newlines."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .exceededUserCreationLimit:
            return "Please try reducing the number of user creations to \(GlobalPreference.userCreationCountLimit) "
        case .emptyStringRequest:
            return "Please check if the user id / nickname is empty."
        case .whiteSpaceOrNewlineStringRequest:
            return "Please check if the user id / nickname has any white spaces for newlines."
        }
    }
}
