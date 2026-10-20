import Foundation

/// Loads and saves one Codable value as a JSON file. A missing or unreadable
/// file yields the default value rather than an error.
public final class JSONFileStore<Value: Codable> {
    public let url: URL
    private let defaultValue: Value

    public init(url: URL, default defaultValue: Value) {
        self.url = url
        self.defaultValue = defaultValue
    }

    public func load() -> Value {
        guard let data = try? Data(contentsOf: url),
              let value = try? JSONDecoder().decode(Value.self, from: data) else { return defaultValue }
        return value
    }

    public func save(_ value: Value) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(value).write(to: url, options: .atomic)
    }
}
