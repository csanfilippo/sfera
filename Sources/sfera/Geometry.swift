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
            try container.encode("Point", forKey: .type)
            try container.encode(position, forKey: .coordinates)
        case .lineString(let lineString):
            try container.encode("LineString", forKey: .type)
            try container.encode(lineString, forKey: .coordinates)
        case .multiPoint(let points):
            try container.encode("MultiPoint", forKey: .type)
            try container.encode(points, forKey: .coordinates)
        case .multiLineString(let lineStrings):
            try container.encode("MultiLineString", forKey: .type)
            try container.encode(lineStrings, forKey: .coordinates)
        case .geometryCollection(let geometries):
            try container.encode("GeometryCollection", forKey: .type)
            try container.encode(geometries, forKey: .geometries)
        case .polygon(let polygon):
            try container.encode("Polygon", forKey: .type)
            try container.encode(polygon, forKey: .coordinates)
        case .multiPolygon(let multiPolygon):
            try container.encode("MultiPolygon", forKey: .type)
            try container.encode(multiPolygon, forKey: .coordinates)
        }
    }
}

extension Geometry: Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "Point":
            self = .point(try container.decode(Position.self, forKey: .coordinates))
        case "LineString":
            self = .lineString(try container.decode(LineString.self, forKey: .coordinates))
        case "MultiPoint":
            self = .multiPoint(try container.decode(MultiPoint.self, forKey: .coordinates))
        case "MultiLineString":
            self = .multiLineString(try container.decode(MultiLineString.self, forKey: .coordinates))
        case "Polygon":
            self = .polygon(try container.decode(Polygon.self, forKey: .coordinates))
        case "MultiPolygon":
            self = .multiPolygon(try container.decode(MultiPolygon.self, forKey: .coordinates))
        case "GeometryCollection":
            self = .geometryCollection(try container.decode([Geometry].self, forKey: .geometries))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown geometry type \"\(type)\"")
        }
    }
}
