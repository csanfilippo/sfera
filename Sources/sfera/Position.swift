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

/// Why a ``Position`` could not be created.
public enum PositionError: Error {
    /// The latitude is outside -90…90 degrees, or is NaN.
    case latitudeOutOfRange
    /// The longitude is outside -180…180 degrees, or is NaN.
    case longitudeOutOfRange
    /// The altitude is infinite or NaN.
    case altitudeNotFinite
}

/// A location on the Earth in WGS 84 coordinates (RFC 7946 §3.1.1).
///
/// A `Position` is always valid: its initializer rejects coordinates outside their ranges, and so does decoding.
/// It is encoded longitude first, as `[longitude, latitude]` or `[longitude, latitude, altitude]`.
public struct Position: Sendable {
    /// Degrees north of the equator, in -90…90.
    public let latitude: Double
    /// Degrees east of the prime meridian, in -180…180.
    public let longitude: Double
    /// Height in meters above or below the WGS 84 ellipsoid, if known.
    public let altitude: Double?
    
    /// Creates a position, validating each coordinate.
    ///
    /// - Throws: ``PositionError`` when a coordinate is out of range or not finite.
    public init(latitude: Double, longitude: Double, altitude: Double? = nil) throws(PositionError) {
        
        guard (-90...90).contains(latitude) else {
            throw .latitudeOutOfRange
        }
        
        guard (-180...180).contains(longitude) else {
            throw .longitudeOutOfRange
        }
        
        if let altitude, !altitude.isFinite {
            throw .altitudeNotFinite
        }
        
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
    }
}

extension Position: Encodable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(longitude)
        try container.encode(latitude)
        
        if let altitude {
            try container.encode(altitude)
        }
    }
}

extension Position: Hashable {}

extension Position: Decodable {
    // Elements after the altitude are ignored: RFC 7946 leaves their meaning unspecified.
    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let longitude = try container.decode(Double.self)
        let latitude = try container.decode(Double.self)
        let altitude = try container.decodeIfPresent(Double.self)
        do {
            try self.init(latitude: latitude, longitude: longitude, altitude: altitude)
        } catch {
            throw DecodingError.invalid("Invalid position [\(longitude), \(latitude)]", in: decoder, underlyingError: error)
        }
    }
}
