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

public enum PositionError: Error {
    case latitudeOutOfRange
    case longitudeOutOfRange
    case altitudeNotFinite
}

public struct Position: Sendable {
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double?
    
    public init(latitude: Double, longitude: Double, altitude: Double? = nil) throws(PositionError) {
        
        guard (-90...90).contains(latitude) else {
            throw .latitudeOutOfRange
        }
        
        guard (-180...180).contains(longitude) else {
            throw .longitudeOutOfRange
        }
        
        if let altitude, !altitude.isFinite {
            throw .altitudeNotFinite
        }
        
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
    }
}

extension Position: Encodable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(longitude)
        try container.encode(latitude)
        
        if let altitude {
            try container.encode(altitude)
        }
    }
}
