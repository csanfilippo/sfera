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

/// Any GeoJSON object (RFC 7946 §3): a geometry, a feature, or a feature collection.
///
/// Decoding reads the `type` member and produces the matching case, so use this type when the kind of input
/// is not known in advance. Encoding writes the wrapped object exactly as it would be written on its own.
public enum GeoJSON: Sendable, Hashable {
    case geometry(Geometry)
    case feature(Feature)
    case featureCollection(FeatureCollection)
}

extension GeoJSON: Encodable {
    // Encodes as the wrapped object itself; its own "type" member already identifies the kind.
    public func encode(to encoder: any Encoder) throws {
        switch self {
        case .geometry(let geometry):
            try geometry.encode(to: encoder)
        case .feature(let feature):
            try feature.encode(to: encoder)
        case .featureCollection(let featureCollection):
            try featureCollection.encode(to: encoder)
        }
    }
}

extension GeoJSON: Decodable {
    private enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: any Decoder) throws {
        let type = try decoder.container(keyedBy: CodingKeys.self).decode(GeoJSONType.self, forKey: .type)
        switch type {
        case .feature:
            self = .feature(try Feature(from: decoder))
        case .featureCollection:
            self = .featureCollection(try FeatureCollection(from: decoder))
        case .point, .lineString, .polygon, .multiPoint, .multiLineString, .multiPolygon, .geometryCollection:
            self = .geometry(try Geometry(from: decoder))
        }
    }
}
