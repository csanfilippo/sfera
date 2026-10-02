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

@Suite struct GeometryMultiPolygonTests {
    @Test func `polygons are encoded in order`() throws {
        let field = Polygon(
            exterior: LinearRing([try at(0, 0), try at(10, 0), try at(10, 10)], [try at(0, 10)]),
            holes: [LinearRing([try at(2, 2), try at(2, 4), try at(4, 4)], [try at(4, 2)])]
        )
        let triangle = Polygon(exterior: LinearRing([try at(20, 0), try at(30, 0), try at(20, 10)]))
        
        let multiPolygon: Geometry = .multiPolygon([field, triangle])
        
        #expect(try geoJSON(multiPolygon) == #"{"coordinates":[[[[0,0],[10,0],[10,10],[0,10],[0,0]],[[2,2],[2,4],[4,4],[4,2],[2,2]]],[[[20,0],[30,0],[20,10],[20,0]]]],"type":"MultiPolygon"}"#)
    }
    
    @Test func `empty multi polygon is encoded with empty coordinates`() throws {
        let emptyMultiPolygon: Geometry = .multiPolygon([])
        
        #expect(try geoJSON(emptyMultiPolygon) == #"{"coordinates":[],"type":"MultiPolygon"}"#)
    }

    @Test func `multi polygon is decoded from its polygons`() throws {
        let json = #"{"coordinates":[[[[0,0],[10,0],[10,10],[0,10],[0,0]],[[2,2],[2,4],[4,4],[4,2],[2,2]]],[[[20,0],[30,0],[20,10],[20,0]]]],"type":"MultiPolygon"}"#

        #expect(try geoJSON(decoded(Geometry.self, from: json)) == json)
    }
}
