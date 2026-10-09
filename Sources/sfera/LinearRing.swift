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

/// A closed boundary through three or more vertices (RFC 7946 §3.1.6).
///
/// A ring stores each vertex once and closes itself when encoded, by repeating the first vertex at the end,
/// so an open ring cannot be produced. Decoding requires a closed ring of at least four positions
/// and drops the repeated closing position.
public struct LinearRing: Sendable, Hashable {
    /// The vertices in boundary order, without the closing position. They are not required to differ from each other.
    public let vertices: AtLeast<3, Position>
    
    init(_ vertices: AtLeast<3, Position>) {
        self.vertices = vertices
    }

    /// Creates a ring from its vertices in boundary order, without repeating the first one at the end.
    ///
    /// - Parameters:
    ///   - vertices: The first three vertices.
    ///   - rest: Any further vertices.
    public init(_ vertices: InlineArray<3, Position>, _ rest: [Position] = []) {
        self.init(AtLeast(vertices, rest))
    }

    /// Creates a ring from vertices known only at runtime, in boundary order, without repeating the first one at the end.
    ///
    /// Prefer ``init(_:_:)`` when the vertices are written in code: it checks the minimum at compile time.
    ///
    /// - Throws: ``AtLeastError/minimumNotMet`` when there are fewer than three vertices.
    public init(validating vertices: [Position]) throws(AtLeastError) {
        self.init(try AtLeast(validating: vertices))
    }
}

enum Orientation {
    case counterClockwise
    case clockwise
}

extension LinearRing {
    func oriented(_ orientation: Orientation) -> LinearRing {
        guard let current = self.orientation, current != orientation else {
            return self
        }
        return reversed()
    }

    // A ring with zero area (collinear vertices) has no orientation.
    private var orientation: Orientation? {
        let area = twiceSignedArea
        if area > 0 { return .counterClockwise }
        if area < 0 { return .clockwise }
        return nil
    }

    // Shoelace formula on the plane, longitude as x and latitude as y: positive when counter-clockwise.
    private var twiceSignedArea: Double {
        let next = Array(vertices.dropFirst()) + [vertices[0]]
        return zip(vertices, next).reduce(0) { area, edge in
            area + edge.0.longitude * edge.1.latitude - edge.1.longitude * edge.0.latitude
        }
    }

    // Walks the same edges in the opposite direction, starting from the same first vertex.
    private func reversed() -> LinearRing {
        let last = vertices.count - 1
        return LinearRing(
            [vertices[0], vertices[last], vertices[last - 1]],
            Array(vertices[1..<(last - 1)].reversed())
        )
    }
}

extension LinearRing: Encodable {
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(contentsOf: vertices)
        try container.encode(vertices[0])
    }
}

extension LinearRing: Decodable {
    // The encoded ring repeats its first position at the end; the model drops that closing position.
    public init(from decoder: any Decoder) throws {
        let positions = try [Position](from: decoder)
        guard positions.count >= 4 else {
            throw DecodingError.invalid("A linear ring needs at least four positions, found \(positions.count)", in: decoder)
        }
        guard positions.first == positions.last else {
            throw DecodingError.invalid("A linear ring must end with its first position", in: decoder)
        }
        self.init(try! AtLeast(validating: Array(positions.dropLast())))
    }
}
