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

/// An area bounded by an exterior ring, with optional holes (RFC 7946 §3.1.6).
///
/// Rings follow the right-hand rule: walking any ring, the polygon's area is on the left, so the exterior
/// runs counter-clockwise and holes run clockwise. ``init(exterior:holes:)`` reverses a ring given in the other
/// direction, keeping its first vertex; a ring whose vertices are collinear has no direction and is kept as given.
public struct Polygon: Sendable, Hashable {
    /// The outer boundary, counter-clockwise.
    public let exterior: LinearRing
    /// Areas cut out of the polygon, each clockwise.
    public let holes: [LinearRing]
    
    /// Creates a polygon, reversing any ring that does not follow the right-hand rule.
    public init(exterior: LinearRing, holes: [LinearRing] = []) {
        self.exterior = exterior.oriented(.counterClockwise)
        self.holes = holes.map { $0.oriented(.clockwise) }
    }
}

extension Polygon: Encodable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(exterior)
        try container.encode(contentsOf: holes)
    }
}

extension Polygon: Decodable {
    // Rings of either winding are accepted (RFC 7946 §3.1.6) and normalized by `init(exterior:holes:)`.
    public init(from decoder: any Decoder) throws {
        let rings = try [LinearRing](from: decoder)
        guard let exterior = rings.first else {
            throw DecodingError.invalid("A polygon needs an exterior ring", in: decoder)
        }
        self.init(exterior: exterior, holes: Array(rings.dropFirst()))
    }
}
