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

/// Why a ``JSONNumber`` could not be created.
public enum JSONNumberError: Error {
    /// The value is NaN or an infinity, which JSON cannot represent.
    case notFinite
}

/// A JSON number (RFC 8259 §6), as used in a Feature's `properties` and `id`.
///
/// JSON has a single number type, so `2` and `2.0` are the same `JSONNumber`. Whole numbers from `Int64.min` to
/// `Int64.max` are kept exactly on every platform, so 64-bit identifiers survive a round trip; a `Double` equals
/// an integer only when it converts to it exactly. Integers are encoded without a fractional part.
///
/// A `JSONNumber` is always finite, because JSON has no NaN or infinity, so it always encodes. A float literal that
/// overflows to infinity (which the compiler only warns about) is a programmer error and traps.
public struct JSONNumber: Sendable, Hashable {

    // Whole numbers in the Int64 range are always stored as `.int64`, so each value has one representation
    // and the synthesized equality and hashing are numeric.
    private enum Storage: Sendable, Hashable {
        case int64(Int64)
        case double(Double)
    }
    
    private let storage: Storage
    
    /// The number as a `Double`, rounded to the nearest one for integers beyond 2^53.
    public var doubleValue: Double {
        switch storage {
        case .int64(let int64):
            return Double(int64)
        case .double(let double):
            return double
        }
    }
    
    /// The number as an exact `Int64`, or `nil` if it has a fractional part or is outside the `Int64` range.
    public var int64Value: Int64? {
        switch storage {
        case .int64(let int64):
            return int64
        case .double:
            return nil
        }
    }
    
    /// Creates a number from a `Double`. A whole value in the `Int64` range is equal to that integer.
    ///
    /// - Throws: ``JSONNumberError/notFinite`` when `value` is NaN or an infinity.
    public init(_ value: Double) throws(JSONNumberError) {
        guard value.isFinite else {
            throw JSONNumberError.notFinite
        }
        self.storage = Int64(exactly: value).map(Storage.int64) ?? .double(value)
    }
    
    public init(_ value: Int64) {
        self.storage = .int64(value)
    }
}

extension JSONNumber: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int64) {
        self.init(value)
    }
}

extension JSONNumber: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        try! self.init(value)
    }
}

extension JSONNumber: Encodable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch storage {
        case .int64(let int64):
            try container.encode(int64)
        case .double(let double):
            try container.encode(double)
        }
    }
}

extension JSONNumber: Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let integer = try? container.decode(Int64.self) {
            self.init(integer)
        } else {
            let double = try container.decode(Double.self)
            do {
                try self.init(double)
            } catch {
                throw DecodingError.invalid("A JSON number must be finite, found \(double)", in: decoder, underlyingError: error)
            }
        }
    }
}
