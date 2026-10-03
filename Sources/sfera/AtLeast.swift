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

/// A collection that always holds at least `minimum` elements.
///
/// The first `minimum` elements are stored in a fixed-size `InlineArray`, so an array literal with the wrong count
/// does not compile. Elements can be appended but never removed, so the minimum always holds.
public struct AtLeast<let minimum: Int, Element> {
    private let guaranteed: InlineArray<minimum, Element>
    private var rest: [Element]

    /// Creates a collection from its required elements and any that follow them.
    ///
    /// - Parameters:
    ///   - guaranteed: Exactly `minimum` elements.
    ///   - rest: Any further elements.
    public init(_ guaranteed: InlineArray<minimum, Element>, _ rest: [Element] = []) {
        self.guaranteed = guaranteed
        self.rest = rest
    }

    /// Adds an element at the end.
    public mutating func append(_ element: Element) {
        rest.append(element)
    }
}

extension AtLeast: RandomAccessCollection {
    public var startIndex: Int { 0 }
    public var endIndex: Int { minimum + rest.count }

    public subscript(position: Int) -> Element {
        position < minimum ? guaranteed[position] : rest[position - minimum]
    }
}

extension AtLeast: Sendable where Element: Sendable {}

extension AtLeast: Equatable where Element: Equatable {
    public static func == (lhs: AtLeast, rhs: AtLeast) -> Bool {
        lhs.elementsEqual(rhs)
    }
}

extension AtLeast: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(count)
        for element in self {
            hasher.combine(element)
        }
    }
}

extension AtLeast: Encodable where Element: Encodable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(contentsOf: self)
    }
}

extension AtLeast {
    init?(_ elements: [Element]) {
        guard elements.count >= minimum else {
            return nil
        }
        self.init(InlineArray { elements[$0] }, Array(elements.dropFirst(minimum)))
    }
}

extension AtLeast: Decodable where Element: Decodable {
    public init(from decoder: any Decoder) throws {
        let elements = try [Element](from: decoder)
        guard let atLeast = AtLeast(elements) else {
            throw DecodingError.invalid("Expected at least \(minimum) elements, found \(elements.count)", in: decoder)
        }
        self = atLeast
    }
}
