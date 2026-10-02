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

@Suite struct GeometryLineStringTests {
    
    @Test func `line string positions are encoded in order`() throws {
        let expectedString = #"{"coordinates":[[0,89],[1,90]],"type":"LineString"}"#

        let lineString: Geometry = .lineString(
            LineString(
                [
                    try .init(latitude: 89, longitude: 0),
                    try .init(latitude: 90, longitude: 1)
                ]
            )
        )

        let jsonString = try geoJSON(lineString)
        
        #expect(jsonString == expectedString)
    }

    @Test func `line string is decoded from its positions`() throws {
        let json = #"{"coordinates":[[0,89],[1,90],[2,88]],"type":"LineString"}"#

        #expect(try geoJSON(decoded(Geometry.self, from: json)) == json)
    }

    @Test func `line string with a single position is rejected when decoding`() {
        #expect(throws: DecodingError.self) {
            try decoded(Geometry.self, from: #"{"coordinates":[[0,89]],"type":"LineString"}"#)
        }
    }
}
