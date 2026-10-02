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

@Suite struct PositionTests {
    @Test(arguments: [-90.1, 90.1, .nan])
    func `latitude outside -90…90 is rejected`(latitude: Double) {
        #expect(throws: PositionError.latitudeOutOfRange) {
            try Position(latitude: latitude, longitude: 10)
        }
    }
    
    @Test(arguments: [-180.1, 180.1, .nan])
    func `longitude outside -180…180 is rejected`(longitude: Double) {
        #expect(throws: PositionError.longitudeOutOfRange) {
            try Position(latitude: 10, longitude: longitude)
        }
    }
    
    @Test(arguments: [Double.infinity, -.infinity, .nan])
    func `non-finite altitude is rejected`(altitude: Double) {
        #expect(throws: PositionError.altitudeNotFinite) {
            try Position(latitude: 1, longitude: 1, altitude: altitude)
        }
    }
    
    @Test(arguments: [(-90.0, -180.0), (90.0, 180.0)])
    func `boundary coordinates are accepted`(latitude: Double, longitude: Double) {
        #expect(throws: Never.self) {
            try Position(latitude: latitude, longitude: longitude)
        }
    }

    @Test func `position is decoded longitude first`() throws {
        #expect(try decoded(Position.self, from: "[12.5,41.9]") == Position(latitude: 41.9, longitude: 12.5))
    }

    @Test func `altitude is decoded when present`() throws {
        #expect(try decoded(Position.self, from: "[12.5,41.9,100]") == Position(latitude: 41.9, longitude: 12.5, altitude: 100))
    }

    @Test func `elements after the altitude are ignored when decoding`() throws {
        #expect(try decoded(Position.self, from: "[12.5,41.9,100,7]") == Position(latitude: 41.9, longitude: 12.5, altitude: 100))
    }

    @Test func `out-of-range position is rejected when decoding`() {
        #expect(throws: DecodingError.self) {
            try decoded(Position.self, from: "[0,91]")
        }
    }

    @Test func `position with fewer than two numbers is rejected when decoding`() {
        #expect(throws: DecodingError.self) {
            try decoded(Position.self, from: "[12.5]")
        }
    }
}
