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

import Foundation

public typealias LineString = AtLeast<2, Position>
public typealias MultiPoint = [Position]
public typealias MultiLineString = [LineString]
public typealias MultiPolygon = [Polygon]

public enum Geometry: Sendable {
    case point(Position)
    case lineString(LineString)
    case multiPoint(MultiPoint)
    case multiLineString(MultiLineString)
    case geometryCollection([Geometry])
    case polygon(Polygon)
    case multiPolygon(MultiPolygon)
}

extension Geometry {
    enum CodingKeys: String, CodingKey {
        case type
        case coordinates
        case geometries
    }
}

extension Geometry: Encodable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .point(let position):
            try container.encode(GeoJSONType.point, forKey: .type)
            try container.encode(position, forKey: .coordinates)
        case .lineString(let lineString):
            try container.encode(GeoJSONType.lineString, forKey: .type)
            try container.encode(lineString, forKey: .coordinates)
        case .multiPoint(let points):
            try container.encode(GeoJSONType.multiPoint, forKey: .type)
            try container.encode(points, forKey: .coordinates)
        case .multiLineString(let lineStrings):
            try container.encode(GeoJSONType.multiLineString, forKey: .type)
            try container.encode(lineStrings, forKey: .coordinates)
        case .geometryCollection(let geometries):
            try container.encode(GeoJSONType.geometryCollection, forKey: .type)
            try container.encode(geometries, forKey: .geometries)
        case .polygon(let polygon):
            try container.encode(GeoJSONType.polygon, forKey: .type)
            try container.encode(polygon, forKey: .coordinates)
        case .multiPolygon(let multiPolygon):
            try container.encode(GeoJSONType.multiPolygon, forKey: .type)
            try container.encode(multiPolygon, forKey: .coordinates)
        }
    }
}

extension Geometry: Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(GeoJSONType.self, forKey: .type)
        switch type {
        case .point:
            self = .point(try container.decode(Position.self, forKey: .coordinates))
        case .lineString:
            self = .lineString(try container.decode(LineString.self, forKey: .coordinates))
        case .multiPoint:
            self = .multiPoint(try container.decode(MultiPoint.self, forKey: .coordinates))
        case .multiLineString:
            self = .multiLineString(try container.decode(MultiLineString.self, forKey: .coordinates))
        case .polygon:
            self = .polygon(try container.decode(Polygon.self, forKey: .coordinates))
        case .multiPolygon:
            self = .multiPolygon(try container.decode(MultiPolygon.self, forKey: .coordinates))
        case .geometryCollection:
            self = .geometryCollection(try container.decode([Geometry].self, forKey: .geometries))
        case .feature, .featureCollection:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Expected a geometry, found \"\(type.rawValue)\"")
        }
    }
}
