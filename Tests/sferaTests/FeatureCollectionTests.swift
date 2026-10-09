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

@Suite struct FeatureCollectionTests {
    @Test func `features are encoded in order`() throws {
        let collection = FeatureCollection([
            Feature(id: "rome", geometry: .point(try at(12.5, 41.9))),
            Feature(id: "nowhere", geometry: nil, properties: ["unlocated": true]),
        ])

        #expect(try geoJSON(collection) == #"{"features":[{"geometry":{"coordinates":[12.5,41.9],"type":"Point"},"id":"rome","properties":null,"type":"Feature"},{"geometry":null,"id":"nowhere","properties":{"unlocated":true},"type":"Feature"}],"type":"FeatureCollection"}"#)
    }

    @Test func `empty feature collection is encoded with empty features`() throws {
        let collection = FeatureCollection([])

        #expect(try geoJSON(collection) == #"{"features":[],"type":"FeatureCollection"}"#)
    }

    @Test func `feature collection is decoded from its features`() throws {
        let json = #"{"features":[{"geometry":{"coordinates":[12.5,41.9],"type":"Point"},"id":"rome","properties":null,"type":"Feature"}],"type":"FeatureCollection"}"#

        #expect(try geoJSON(decoded(FeatureCollection.self, from: json)) == json)
    }

    @Test func `object of another type is rejected when decoding a feature collection`() {
        #expect(throws: DecodingError.self) {
            try decoded(FeatureCollection.self, from: #"{"geometry":null,"properties":null,"type":"Feature"}"#)
        }
    }

    @Test func `decoded numbers equal the same numbers written as literals`() throws {
        let json = #"{"features":[{"geometry":null,"id":7,"properties":{"area":4.5,"floors":7,"rooms":7.0,"population":1234567890123456789},"type":"Feature"},{"geometry":null,"id":7.0,"properties":null,"type":"Feature"}],"type":"FeatureCollection"}"#

        let expected = FeatureCollection([
            Feature(id: .number(7.0), geometry: nil, properties: ["area": 4.5, "floors": 7.0, "rooms": 7, "population": 1234567890123456789]),
            Feature(id: 7, geometry: nil),
        ])

        #expect(try decoded(FeatureCollection.self, from: json) == expected)
    }
}
