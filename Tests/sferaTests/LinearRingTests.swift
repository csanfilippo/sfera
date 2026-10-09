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

@Suite struct LinearRingTests {
    @Test func `ring is closed by repeating the first vertex`() throws {
        let triangle = LinearRing([try at(0, 0), try at(1, 0), try at(0, 1)])

        let jsonString = try #require(String(data: JSONEncoder().encode(triangle), encoding: .utf8))

        #expect(jsonString == "[[0,0],[1,0],[0,1],[0,0]]")
    }

    @Test func `closed ring is decoded without its closing position`() throws {
        let ring = try decoded(LinearRing.self, from: "[[0,0],[1,0],[0,1],[0,0]]")

        #expect(ring.vertices.count == 3)
    }

    @Test func `unclosed ring is rejected when decoding`() {
        #expect(throws: DecodingError.self) {
            try decoded(LinearRing.self, from: "[[0,0],[1,0],[0,1],[1,1]]")
        }
    }

    @Test func `ring with fewer than four positions is rejected when decoding`() {
        #expect(throws: DecodingError.self) {
            try decoded(LinearRing.self, from: "[[0,0],[1,0],[0,0]]")
        }
    }

    @Test(arguments: [
        [],
        [try at(0, 0)],
        [try at(0, 0), try at(10, 0)],
    ])
    func `fewer than three vertices are rejected`(vertices: [Position]) {
        #expect(throws: AtLeastError.minimumNotMet) {
            try LinearRing(validating: vertices)
        }
    }

    @Test(arguments: [
        [try at(0, 0), try at(10, 0), try at(10, 10)],
        [try at(0, 0), try at(10, 0), try at(10, 10), try at(0, 10)],
    ])
    func `vertices from an array keep their order`(vertices: [Position]) throws {
        let ring = try LinearRing(validating: vertices)

        #expect(Array(ring.vertices) == vertices)
    }
}
