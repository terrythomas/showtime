public enum CalendarAuthorization: Equatable, Sendable {
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

/// EventKit stores created before access was granted can keep returning no events.
public func needsFreshEventStore(previous: CalendarAuthorization, current: CalendarAuthorization) -> Bool {
    current == .fullAccess && previous != .fullAccess
}
