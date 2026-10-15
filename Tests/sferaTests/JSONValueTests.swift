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

@Suite struct JSONValueTests {
    @Test(arguments: [
        (JSONValue.null, "null"),
        (true, "true"),
        (false, "false"),
        (2_800_000, "2800000"),
        (2.65, "2.65"),
        ("Città", #""Città""#),
    ])
    func `a scalar is described as JSON`(value: JSONValue, json: String) {
        #expect(String(describing: value) == json)
    }

    @Test func `quotes, backslashes and control characters are escaped in a string`() {
        let value: JSONValue = "say \"hi\"\\\n\t\r\u{1}"

        #expect(String(describing: value) == #""say \"hi\"\\\n\t\r\u0001""#)
    }

    @Test func `array is described with its elements in order`() {
        let value: JSONValue = ["Centro", 2, .null]

        #expect(String(describing: value) == #"["Centro", 2, null]"#)
    }

    @Test func `object is described with its members in key order`() {
        let value: JSONValue = ["name": "Rome", "capital": true, "districts": ["Centro"], "\"quoted\"": 1]

        #expect(String(describing: value) == #"{"\"quoted\"": 1, "capital": true, "districts": ["Centro"], "name": "Rome"}"#)
    }
}
