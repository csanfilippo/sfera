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

@Suite struct GeometryMultiLineStringTests {
    
    @Test func `line strings are encoded in order`() throws {
        let expectedString = #"{"coordinates":[[[0,89],[1,90]],[[10,88],[11,17]]],"type":"MultiLineString"}"#

        let multiLineString: Geometry = .multiLineString(
            [
                LineString(
                    [
                        try .init(latitude: 89, longitude: 0),
                        try .init(latitude: 90, longitude: 1)
                    ]
                ),
                LineString(
                    [
                        try .init(latitude: 88, longitude: 10),
                        try .init(latitude: 17, longitude: 11)
                    ]
                )
            ]
        )
        

        let jsonString = try geoJSON(multiLineString)
        
        #expect(jsonString == expectedString)
    }
    
    @Test func `empty multi line string are encoded as an empty array`() throws {
        let expectedString = #"{"coordinates":[],"type":"MultiLineString"}"#

        let emptyMultiLineString: Geometry = .multiLineString([])
        

        let jsonString = try geoJSON(emptyMultiLineString)
        
        #expect(jsonString == expectedString)
    }
}
