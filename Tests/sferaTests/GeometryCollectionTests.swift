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

@Suite struct GeometryCollectionTests {
    @Test func `empty geometry collection is encoded with empty geometries`() throws {
        let emptyGeometryCollection: Geometry = .geometryCollection([])
                
        let jsonString = try geoJSON(emptyGeometryCollection)
        #expect(jsonString == #"{"geometries":[],"type":"GeometryCollection"}"#)
    }
    
    @Test func `geometries are encoded in order`() throws {
        let geometryCollection: Geometry = .geometryCollection([
            .point(try .init(latitude: 89, longitude: 1)),
            .lineString(LineString(
                [
                    try .init(latitude: 10, longitude: 0),
                    try .init(latitude: 11, longitude: 1)
                ]
            ))
        ])
                
        let jsonString = try geoJSON(geometryCollection)
        #expect(jsonString == #"{"geometries":[{"coordinates":[1,89],"type":"Point"},{"coordinates":[[0,10],[1,11]],"type":"LineString"}],"type":"GeometryCollection"}"#)
    }
    
    @Test func `nested geometry collections are encoded`() throws {
        let geometryCollection: Geometry = .geometryCollection([
            .point(try .init(latitude: 89, longitude: 1)),
            .geometryCollection([
                .point(try .init(latitude: 89, longitude: 1)),
                .lineString(LineString(
                    [
                        try .init(latitude: 10, longitude: 0),
                        try .init(latitude: 11, longitude: 1)
                    ]
                ))
            ])
        ])
                
        let jsonString = try geoJSON(geometryCollection)
        #expect(jsonString == #"{"geometries":[{"coordinates":[1,89],"type":"Point"},{"geometries":[{"coordinates":[1,89],"type":"Point"},{"coordinates":[[0,10],[1,11]],"type":"LineString"}],"type":"GeometryCollection"}],"type":"GeometryCollection"}"#)
    }

    @Test func `geometry collection is decoded from its geometries`() throws {
        let json = #"{"geometries":[{"coordinates":[1,89],"type":"Point"},{"geometries":[],"type":"GeometryCollection"}],"type":"GeometryCollection"}"#

        #expect(try geoJSON(decoded(Geometry.self, from: json)) == json)
    }
}
