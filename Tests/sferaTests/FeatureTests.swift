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

@Suite struct FeatureTests {
    @Test func `feature without properties is encoded with null properties and no id`() throws {
        let feature = Feature(geometry: .point(try at(12.5, 41.9)))

        #expect(try geoJSON(feature) == #"{"geometry":{"coordinates":[12.5,41.9],"type":"Point"},"properties":null,"type":"Feature"}"#)
    }

    @Test func `unlocated feature is encoded with null geometry`() throws {
        let feature = Feature(geometry: nil, properties: ["name": "Nowhere"])

        #expect(try geoJSON(feature) == #"{"geometry":null,"properties":{"name":"Nowhere"},"type":"Feature"}"#)
    }

    @Test func `properties are encoded as a JSON object`() throws {
        let feature = Feature(geometry: nil, properties: [
            "name": "Rome",
            "population": 2_800_000,
            "area": 1285.3,
            "capital": true,
            "districts": ["Centro", "Trastevere"],
            "founded": ["year": -753],
            "mayor": .null,
        ])

        #expect(try geoJSON(feature) == #"{"geometry":null,"properties":{"area":1285.3,"capital":true,"districts":["Centro","Trastevere"],"founded":{"year":-753},"mayor":null,"name":"Rome","population":2800000},"type":"Feature"}"#)
    }

    @Test func `string id is encoded as a string`() throws {
        let feature = Feature(id: "rome", geometry: nil)

        #expect(try geoJSON(feature) == #"{"geometry":null,"id":"rome","properties":null,"type":"Feature"}"#)
    }

    @Test func `numeric id is encoded as a number`() throws {
        let feature = Feature(id: 42, geometry: nil)

        #expect(try geoJSON(feature) == #"{"geometry":null,"id":42,"properties":null,"type":"Feature"}"#)
    }

    @Test func `feature is decoded with its id, geometry and properties`() throws {
        let json = #"{"geometry":{"coordinates":[12.5,41.9],"type":"Point"},"id":"rome","properties":{"area":1285.3,"capital":true,"districts":["Centro","Trastevere"],"founded":{"year":-753},"mayor":null,"name":"Rome"},"type":"Feature"}"#

        #expect(try geoJSON(decoded(Feature.self, from: json)) == json)
    }

    @Test func `numeric id is decoded as a number`() throws {
        let json = #"{"geometry":null,"id":42,"properties":null,"type":"Feature"}"#

        #expect(try geoJSON(decoded(Feature.self, from: json)) == json)
    }

    @Test func `missing geometry and properties are decoded as null`() throws {
        #expect(try geoJSON(decoded(Feature.self, from: #"{"type":"Feature"}"#)) == #"{"geometry":null,"properties":null,"type":"Feature"}"#)
    }

    @Test func `object of another type is rejected when decoding a feature`() {
        #expect(throws: DecodingError.self) {
            try decoded(Feature.self, from: #"{"coordinates":[0,0],"type":"Point"}"#)
        }
    }
}
