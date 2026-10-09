/*
 MIT License

 Copyright (c) 2026 Calogero Sanfilippo

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

/// A spatially bounded thing (RFC 7946 §3.2): a geometry, its properties, and an optional identifier.
///
/// `geometry` and `properties` are always encoded, as `null` when absent; `id` is left out when absent.
public struct Feature: Sendable, Hashable {
    /// A feature identifier: a string or a number.
    public enum Identifier: Sendable, Hashable {
        case string(String)
        /// A numeric identifier; integer literals produce this case. `"7"` and `7` are different identifiers.
        case number(JSONNumber)
    }

    /// The feature's identifier, if it has one.
    public let id: Identifier?
    /// Where the feature is, or `nil` for an unlocated feature.
    public let geometry: Geometry?
    /// Arbitrary data about the feature, or `nil` if it has none.
    public let properties: [String: JSONValue]?

    /// Creates a feature. Pass `nil` as the geometry for a feature without a location.
    public init(id: Identifier? = nil, geometry: Geometry?, properties: [String: JSONValue]? = nil) {
        self.id = id
        self.geometry = geometry
        self.properties = properties
    }
}

extension Feature {
    enum CodingKeys: String, CodingKey {
        case type
        case id
        case geometry
        case properties
    }
}

extension Feature: Encodable {
    // `geometry` and `properties` are required members and are written as null when absent; `id` is optional and omitted.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(GeoJSONType.feature, forKey: .type)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(geometry, forKey: .geometry)
        try container.encode(properties, forKey: .properties)
    }
}

extension Feature.Identifier: Encodable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let string):
            try container.encode(string)
        case .number(let number):
            try container.encode(number)
        }
    }
}

extension Feature.Identifier: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension Feature.Identifier: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int64) {
        self = .number(JSONNumber(value))
    }
}

extension Feature: Decodable {
    // Missing `geometry` and `properties` are accepted as null, although RFC 7946 requires the members.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(GeoJSONType.self, forKey: .type)
        guard type == .feature else {
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Expected a Feature, found \"\(type.rawValue)\"")
        }
        self.init(
            id: try container.decodeIfPresent(Identifier.self, forKey: .id),
            geometry: try container.decodeIfPresent(Geometry.self, forKey: .geometry),
            properties: try container.decodeIfPresent([String: JSONValue].self, forKey: .properties)
        )
    }
}

extension Feature.Identifier: Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else {
            self = .number(try container.decode(JSONNumber.self))
        }
    }
}
