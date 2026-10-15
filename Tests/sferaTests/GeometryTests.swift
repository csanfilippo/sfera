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

import sfera
import Testing

@Suite struct GeometryTests {
    @Test func `geometry is described as GeoJSON, type first`() throws {
        let rome: Geometry = .point(try at(12.4964, 41.9028))

        #expect(String(describing: rome) == #"{"type": "Point", "coordinates": [12.4964, 41.9028]}"#)
    }

    @Test func `multi geometry is described with the coordinates of each member`() throws {
        let island = Polygon(exterior: LinearRing([try at(0.5, 0.5), try at(1.5, 0.5), try at(0.5, 1.5)]))

        let archipelago: Geometry = .multiPolygon([island])

        #expect(String(describing: archipelago) == #"{"type": "MultiPolygon", "coordinates": [[[[0.5, 0.5], [1.5, 0.5], [0.5, 1.5], [0.5, 0.5]]]]}"#)
    }

    @Test func `geometry collection is described with its member geometries`() throws {
        let trip: Geometry = .geometryCollection([
            .point(try at(0.5, 1.5)),
            .lineString(LineString([try at(0.5, 1.5), try at(2.5, 3.5)])),
        ])

        #expect(String(describing: trip) == #"{"type": "GeometryCollection", "geometries": [{"type": "Point", "coordinates": [0.5, 1.5]}, {"type": "LineString", "coordinates": [[0.5, 1.5], [2.5, 3.5]]}]}"#)
    }

    @Test func `unknown geometry type is rejected when decoding`() {
        #expect(throws: DecodingError.self) {
            try decoded(Geometry.self, from: #"{"coordinates":[0,0],"type":"Circle"}"#)
        }
    }

    @Test func `decoded geometry equals the geometry it was encoded from`() throws {
        let lineString: Geometry = .lineString(LineString([try at(0, 89), try at(1, 90)], [try at(2, 88)]))

        #expect(try decoded(Geometry.self, from: geoJSON(lineString)) == lineString)
    }

    @Test func `geometries of different kinds are not equal`() throws {
        let position = try at(0, 89)

        #expect(Geometry.point(position) != Geometry.multiPoint([position]))
    }
}
