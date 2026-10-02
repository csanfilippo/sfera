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

@Suite struct GeoJSONTests {
    @Test func `geometry object is encoded as the geometry itself`() throws {
        let object: GeoJSON = .geometry(.point(try at(12.5, 41.9)))

        #expect(try geoJSON(object) == #"{"coordinates":[12.5,41.9],"type":"Point"}"#)
    }

    @Test func `feature object is encoded as the feature itself`() throws {
        let object: GeoJSON = .feature(Feature(id: "rome", geometry: .point(try at(12.5, 41.9))))

        #expect(try geoJSON(object) == #"{"geometry":{"coordinates":[12.5,41.9],"type":"Point"},"id":"rome","properties":null,"type":"Feature"}"#)
    }

    @Test func `feature collection object is encoded as the feature collection itself`() throws {
        let object: GeoJSON = .featureCollection(FeatureCollection([]))

        #expect(try geoJSON(object) == #"{"features":[],"type":"FeatureCollection"}"#)
    }

    @Test func `geometry object is decoded by its type`() throws {
        let json = #"{"coordinates":[12.5,41.9],"type":"Point"}"#

        let object = try decoded(GeoJSON.self, from: json)

        guard case .geometry = object else {
            Issue.record("Expected a geometry, got \(object)")
            return
        }
        #expect(try geoJSON(object) == json)
    }

    @Test func `feature object is decoded by its type`() throws {
        let json = #"{"geometry":null,"properties":null,"type":"Feature"}"#

        let object = try decoded(GeoJSON.self, from: json)

        guard case .feature = object else {
            Issue.record("Expected a feature, got \(object)")
            return
        }
        #expect(try geoJSON(object) == json)
    }

    @Test func `feature collection object is decoded by its type`() throws {
        let json = #"{"features":[],"type":"FeatureCollection"}"#

        let object = try decoded(GeoJSON.self, from: json)

        guard case .featureCollection = object else {
            Issue.record("Expected a feature collection, got \(object)")
            return
        }
        #expect(try geoJSON(object) == json)
    }
}
