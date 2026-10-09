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

import Foundation
import sfera
import Testing

@Suite struct JSONNumberTests {
    @Test func `a whole number built from a Double equals the same integer`() {
        #expect(JSONNumber(10.0) == JSONNumber(Int64(10)))
    }
    
    @Test func `equal numbers have the same hash`() {
        let numberA = JSONNumber(10.0)
        let numberB = JSONNumber(Int64(10))
        
        #expect(numberA.hashValue == numberB.hashValue)
    }
    
    @Test func `a fractional number differs from the nearest integer`() {
        #expect(JSONNumber(2.65) != JSONNumber(Int64(3)))
    }
    
    @Test func `an integer beyond 2^53 differs from the Double nearest to it`() {
        #expect(JSONNumber(Int64(9_007_199_254_740_993)) != JSONNumber(9_007_199_254_740_992.0))
    }
    
    @Test func `negative zero equals zero`() {
        #expect(JSONNumber(-0.0) == JSONNumber(Int64(0)))
    }
    
    @Test(arguments: [
        (JSONNumber(11.0), Int64(11)),
        (JSONNumber(-9_223_372_036_854_775_808.0), Int64.min),
        (JSONNumber(Int64.min), Int64.min),
        (JSONNumber(Int64.max), Int64.max),
    ])
    func `int64Value is the exact integer for whole numbers, including Int64.min and Int64.max`(number: JSONNumber, integer: Int64) {
        #expect(number.int64Value == integer)
    }
    
    @Test(arguments: [
        JSONNumber(11.6701),
        JSONNumber(9_223_372_036_854_775_808.0),
        JSONNumber(-1e20),
    ])
    func `int64Value is nil for fractional numbers and for whole numbers outside the Int64 range`(number: JSONNumber) {
        #expect(number.int64Value == nil)
    }
    
    @Test(arguments: [
        (JSONNumber(2.65), 2.65),
        (JSONNumber(Int64(7)), 7.0),
        (JSONNumber(9_223_372_036_854_775_808.0), 9_223_372_036_854_775_808.0),
        (JSONNumber(Int64(9_007_199_254_740_993)), 9_007_199_254_740_992.0)
    ])
    func `doubleValue is the number as a Double`(number: JSONNumber, expected: Double) {
        #expect(number.doubleValue == expected)
    }
    
    @Test func `an integer literal builds the exact integer`() {
        let id: JSONNumber = 9_007_199_254_740_993

        #expect(id.int64Value == 9_007_199_254_740_993)
    }

    @Test func `a float literal builds the number it spells`() {
        let area: JSONNumber = 2.65
        let whole: JSONNumber = 2.0

        #expect(area.doubleValue == 2.65)
        #expect(whole == JSONNumber(Int64(2)))
    }
    
    @Test(arguments: [
        (JSONNumber(Int64.max), "9223372036854775807"),
        (JSONNumber(2.65), "2.65"),
        (JSONNumber(2.0), "2"),
    ])
    func `integers are encoded exactly and fractional numbers as decimals`(number: JSONNumber, json: String) throws {
        #expect(try geoJSON(number) == json)
    }
    
    @Test(arguments: [
        (JSONNumber(Int64(2)), "2"),
        (JSONNumber(Int64(2)), "2.0"),
        (JSONNumber(Int64(100)), "1e2"),
        (JSONNumber(Int64(0)), "-0.0"),
        (JSONNumber(Int64.max), "9223372036854775807"),
        (JSONNumber(Int64.min), "-9223372036854775808"),
        (JSONNumber(2.65), "2.65"),
        (JSONNumber(9_223_372_036_854_775_808.0), "9223372036854775808"),
    ])
    func `a JSON number written with a zero fraction or an exponent decodes equal to the integer`(number: JSONNumber, json: String) throws {
        #expect(try decoded(JSONNumber.self, from: json) == number)
        
    }
    
    @Test(arguments: [#""2""#, "true", "null"])
    func `a JSON value that is not a number is rejected when decoding`(json: String) {
        #expect(throws: DecodingError.self) {
            try decoded(JSONNumber.self, from: json)
        }
    }
    
    @Test(arguments: [Double.nan, .infinity, -.infinity])
    func `a non-finite Double is rejected`(value: Double) {
        #expect(throws: JSONNumberError.notFinite) {
            try JSONNumber(value)
        }
    }

    @Test(arguments: [Double.greatestFiniteMagnitude, -.greatestFiniteMagnitude, .leastNonzeroMagnitude, -.leastNonzeroMagnitude])
    func `the largest and smallest finite Doubles are accepted`(value: Double) throws {
        #expect(try JSONNumber(value).doubleValue == value)
    }

    @Test(arguments: [10.0, -10.0, 0.0])
    func `a whole Double equals the same integer`(whole: Double) throws {
        #expect(try JSONNumber(whole) == JSONNumber(Int64(whole)))
    }

    #if !os(WASI)
    // Exit tests need a child process, which WASI cannot spawn.
    @Test func `a float literal that overflows to infinity traps`() async {
        await #expect(processExitsWith: .failure) {
            _ = JSONNumber(floatLiteral: .infinity)
        }
    }
    #endif

    // Standard JSON has no NaN or infinity; only a decoder configured to accept them can produce one.
    @Test(arguments: [#""NaN""#, #""Infinity""#, #""-Infinity""#])
    func `a non-finite number from a lenient decoder is rejected with its reason`(json: String) {
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")

        let error = #expect(throws: DecodingError.self) {
            try decoder.decode(JSONNumber.self, from: Data(json.utf8))
        }

        guard case .dataCorrupted(let context) = error else {
            Issue.record("Expected dataCorrupted, got \(String(describing: error))")
            return
        }
        #expect(context.underlyingError as? JSONNumberError == .notFinite)
    }
}
