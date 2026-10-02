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

@Suite struct AtLeastTests {
    @Test func `count is the size of the guaranteed elements if no tail is present`() {
        let atLeast2: AtLeast<2, Int> = .init([1,2])
        
        #expect(atLeast2.count == 2)
    }
    
    @Test func `count is the size of the guaranteed elements plus the tail if present`() {
        let atLeast2: AtLeast<2, Int> = .init([1,2], [22])
        
        #expect(atLeast2.count == 3)
    }
    
    @Test func `elements are the guaranteed ones followed by the rest`() {
        let atLeast2 = AtLeast<2, Int>([1, 2], [3, 4])

        #expect(Array(atLeast2) == [1, 2, 3, 4])
    }
    
    @Test func `appended elements go at the end`() {
        var atLeast2 = AtLeast<2, Int>([1, 2], [3, 4])
        
        atLeast2.append(5)

        #expect(Array(atLeast2) == [1, 2, 3, 4, 5])
    }

    @Test func `guaranteed and tail elements are encoded as one flat array`() throws {
        let atLeast2 = AtLeast<2, Int>([1, 2], [3, 4])

        let json = try #require(String(data: JSONEncoder().encode(atLeast2), encoding: .utf8))

        #expect(json == "[1,2,3,4]")
    }

    @Test func `decoded elements keep their order`() throws {
        #expect(Array(try decoded(AtLeast<2, Int>.self, from: "[1,2,3]")) == [1, 2, 3])
    }

    @Test func `fewer elements than the minimum are rejected when decoding`() {
        #expect(throws: DecodingError.self) {
            try decoded(AtLeast<2, Int>.self, from: "[1]")
        }
    }
}
