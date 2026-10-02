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
import Foundation

@Suite struct GeometryPolygonTests {
    @Test func `polygon without holes is encoded as a single ring`() throws {
        let exterior = LinearRing([try at(0, 0), try at(10, 0), try at(10, 10)], [try at(0, 10)])

        let polygon: Geometry = .polygon(Polygon(exterior: exterior))
        
        let jsonString = try geoJSON(polygon)
        
        #expect(jsonString == #"{"coordinates":[[[0,0],[10,0],[10,10],[0,10],[0,0]]],"type":"Polygon"}"#)
    }
    
    @Test func `holes follow the exterior ring`() throws {
       
        let exterior      = LinearRing([try at(0, 0), try at(10, 0), try at(10, 10)], [try at(0, 10)])
        let southWestHole = LinearRing([try at(2, 2), try at(2, 4), try at(4, 4)],    [try at(4, 2)])
        let northEastHole = LinearRing([try at(6, 6), try at(6, 8), try at(8, 8)],    [try at(8, 6)])
        
        let polygon: Geometry = .polygon(Polygon(exterior: exterior, holes: [southWestHole, northEastHole]))
        
        let jsonString = try geoJSON(polygon)
        
        #expect(jsonString == #"{"coordinates":[[[0,0],[10,0],[10,10],[0,10],[0,0]],[[2,2],[2,4],[4,4],[4,2],[2,2]],[[6,6],[6,8],[8,8],[8,6],[6,6]]],"type":"Polygon"}"#)
    }
    
    private func at(_ longitude: Double, _ latitude: Double) throws -> Position {
        try Position(latitude: latitude, longitude: longitude)
    }
}
