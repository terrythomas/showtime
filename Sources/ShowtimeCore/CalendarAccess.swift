public enum CalendarAuthorization: Sendable {
    case notDetermined, denied, restricted, fullAccess, writeOnly
}

/// What the menu should show about calendar permission.
public enum AccessBanner: Equatable, Sendable {
    case none, requestAccess, openSystemSettings, restricted
}

public func accessBanner(for authorization: CalendarAuthorization) -> AccessBanner {
    switch authorization {
    case .notDetermined: .requestAccess
    case .denied, .writeOnly: .openSystemSettings
    case .restricted: .restricted
    case .fullAccess: .none
    }
}
