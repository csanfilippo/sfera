<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset=".github/assets/sfera-lockup-dark.svg">
    <img src=".github/assets/sfera-lockup.svg" alt="sfera" width="307">
  </picture>
</h1>

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fcsanfilippo%2Fsfera%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/csanfilippo/sfera)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fcsanfilippo%2Fsfera%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/csanfilippo/sfera)

![Swift 6.4](https://img.shields.io/badge/Swift-6.4-F05138?logo=swift&logoColor=white)
![Platforms](https://img.shields.io/badge/platforms-iOS%2026%20·%20macOS%2026%20·%20watchOS%2026%20·%20tvOS%2026%20·%20Linux%20·%20Wasm-blue)
[![Tests](https://github.com/csanfilippo/sfera/actions/workflows/tests.yml/badge.svg)](https://github.com/csanfilippo/sfera/actions/workflows/tests.yml)
![License](https://img.shields.io/badge/license-MIT-green)

**GeoJSON for Swift, valid by construction.**

`sfera` models [RFC 7946](https://datatracker.ietf.org/doc/html/rfc7946) GeoJSON as Swift value types. The rules of the format live in the types:

- Coordinates are validated the moment a `Position` is created.
- A line string needs two positions, and a ring three vertices. The compiler checks both, and positions known only at runtime are checked when the value is built.
- Rings close themselves, and polygons follow the right-hand rule automatically.
- Large integer identifiers and properties survive a round trip exactly.

Every type is `Codable`, `Sendable` and `Hashable`. There are no third-party dependencies, and the sources use only the Swift standard library.

## Quick start

```swift
import Foundation
import sfera

let rome = try Position(latitude: 41.9028, longitude: 12.4964)
let city = Feature(id: "rome", geometry: .point(rome), properties: ["name": "Rome"])

let data = try JSONEncoder().encode(FeatureCollection([city]))
// {"type":"FeatureCollection","features":[{"type":"Feature","id":"rome","geometry":{"type":"Point","coordinates":[12.4964,41.9028]},"properties":{"name":"Rome"}}]}

let document = try JSONDecoder().decode(GeoJSON.self, from: data)
```

## Installation

`sfera` requires Swift 6.4. It runs on iOS, macOS, watchOS and tvOS 26, on Linux, and on WebAssembly (WASI) with the full Swift SDK for Wasm; Embedded Swift is not supported, because it has no `Codable`. Add it with Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/csanfilippo/sfera.git", from: "0.1.0"),
],
targets: [
    .target(name: "YourTarget", dependencies: [
        .product(name: "sfera", package: "sfera"),
    ]),
]
```

## Guide

The examples build on each other, starting from four positions:

```swift
let rome     = try Position(latitude: 41.9028, longitude: 12.4964)
let florence = try Position(latitude: 43.7696, longitude: 11.2558)
let milan    = try Position(latitude: 45.4642, longitude: 9.19)
let naples   = try Position(latitude: 40.8518, longitude: 14.2681)
```

### Positions

A `Position` is a latitude, a longitude and an optional altitude in meters. Values outside the WGS 84 ranges are rejected with a typed error:

```swift
do {
    _ = try Position(latitude: 91, longitude: 0)
} catch .latitudeOutOfRange {
    // latitudes run from -90 to 90
}
```

| `PositionError` | Cause |
|---|---|
| `.latitudeOutOfRange` | latitude outside -90…90, or NaN |
| `.longitudeOutOfRange` | longitude outside -180…180, or NaN |
| `.altitudeNotFinite` | altitude is infinite or NaN |

As GeoJSON requires, positions are written longitude first: Rome is `[12.4964,41.9028]`.

### Geometries

`Geometry` has one case for each GeoJSON geometry type:

| GeoJSON | Swift | Rule |
|---|---|---|
| Point | `.point(Position)` | |
| LineString | `.lineString(LineString)` | two or more positions, checked at compile time, or at runtime from an array |
| Polygon | `.polygon(Polygon)` | an exterior ring and optional holes |
| MultiPoint | `.multiPoint([Position])` | may be empty |
| MultiLineString | `.multiLineString([LineString])` | may be empty |
| MultiPolygon | `.multiPolygon([Polygon])` | may be empty |
| GeometryCollection | `.geometryCollection([Geometry])` | may be empty, and may nest |

#### Line strings

The first two positions form a fixed-size array, so a line string that is too short does not compile:

```swift
var route = LineString([rome, florence])
route.append(milan)

LineString([rome])   // error: expected '2' elements in inline array literal, but got '1'
```

#### Polygons

A polygon is an exterior `LinearRing` with optional holes. Give each vertex once: the ring closes itself when encoded.

```swift
let field = LinearRing([
    try Position(latitude: 0, longitude: 0),
    try Position(latitude: 0, longitude: 10),
    try Position(latitude: 10, longitude: 10),
], [
    try Position(latitude: 10, longitude: 0),
])

let pond = LinearRing([
    try Position(latitude: 2, longitude: 2),
    try Position(latitude: 2, longitude: 4),
    try Position(latitude: 4, longitude: 4),
], [
    try Position(latitude: 4, longitude: 2),
])

let farm = Geometry.polygon(Polygon(exterior: field, holes: [pond]))
// {"type":"Polygon","coordinates":[[[0,0],[10,0],[10,10],[0,10],[0,0]],[[2,2],[2,4],[4,4],[4,2],[2,2]]]}
```

Vertices can be listed in either direction. GeoJSON's right-hand rule wants the polygon's area on the left of every ring, so the exterior runs counter-clockwise and holes clockwise. `Polygon` reverses any ring that runs the other way, keeping its first vertex. The pond above was given counter-clockwise and is written clockwise. The vertices must still follow the boundary, and a ring whose vertices all lie on one line has no direction and is kept as given.

#### From runtime data

When positions arrive at runtime, from a file or a sensor, the compiler cannot count them. `init(validating:)` checks the minimum when the value is built and throws `AtLeastError.minimumNotMet` when there are too few. A ring's vertices are still given without repeating the first one.

```swift
let gpsLog: [Position] = [naples, rome, florence]

let track  = try LineString(validating: gpsLog)
let region = try LinearRing(validating: gpsLog)

do {
    _ = try LineString(validating: [rome])
} catch .minimumNotMet {
    // a line string needs at least two positions
}
```

#### Collections

```swift
let stops   = Geometry.multiPoint([rome, florence, milan])
let network = Geometry.multiLineString([route, LineString([rome, naples])])
let trip    = Geometry.geometryCollection([.point(rome), .lineString(route)])
```

A geometry collection writes its members under `geometries` rather than `coordinates`. Collections may nest: RFC 7946 discourages it but does not forbid it.

### Features

A `Feature` pairs a geometry with properties and an optional identifier. A `FeatureCollection` is an ordered list of features, and the usual top level of a GeoJSON file.

```swift
let city = Feature(
    id: "rome",
    geometry: .point(rome),
    properties: [
        "name": "Rome",
        "population": 2_800_000,
        "capital": true,
        "districts": ["Centro", "Trastevere"],
        "mayor": .null,
    ]
)

let cities = FeatureCollection([city, Feature(id: 2, geometry: .point(milan))])
```

- **Properties** are `JSONValue`s written as literals. A null value is `.null`, because `nil` would be confused with `Optional`.
- **Numbers** are `JSONNumber`s. JSON has a single number type, so `2` and `2.0` are equal. Whole numbers are kept exact up to 64 bits, so identifiers survive a round trip, also on 32-bit platforms such as WebAssembly. Read one with `int64Value` (exact, or `nil`) or `doubleValue`.
- **`id`** is a string or a number, and is left out when absent. `geometry` and `properties` are always written, as `null` when absent, as RFC 7946 requires.

### Any GeoJSON object

`GeoJSON` holds a geometry, a feature or a feature collection, and encodes exactly as the object it holds. Decode it when the input could be any of the three:

```swift
let data = try JSONEncoder().encode(cities)

switch try JSONDecoder().decode(GeoJSON.self, from: data) {
case .geometry(let geometry):
    print(geometry)
case .feature(let feature):
    print(feature.properties ?? [:])
case .featureCollection(let collection):
    print(collection.features.count)
}
```

When you know what to expect, decode the type directly, for example `JSONDecoder().decode(FeatureCollection.self, from: data)`.

### Decoding rules

Decoding enforces the same rules as the initializers, so a decoded value is always valid. It is strict about values and lenient about missing structure:

| Input | Result |
|---|---|
| Coordinate out of range, or non-finite altitude | rejected, with the `PositionError` as the underlying error |
| LineString with fewer than two positions | rejected |
| Ring with fewer than four positions, or not closed | rejected |
| Polygon without rings | rejected |
| Unknown `type`, or the wrong one for the requested type | rejected |
| Ring wound the wrong way | accepted and corrected, as RFC 7946 asks of parsers |
| Feature without `geometry` or `properties` | accepted, as `null` |
| Number with a zero fraction or an exponent, such as `2.0` or `1e2` | accepted, equal to the integer |
| Position elements after the altitude | ignored |
| `bbox` and foreign members | ignored, so they are lost in a round trip |

Rejections are thrown as `DecodingError`, with the coding path of the offending value.

### Output

`JSONEncoder` does not guarantee the order of object keys; set `outputFormatting = .sortedKeys` for stable output. JSON has no NaN or infinity, so encoding a `JSONNumber` that holds one throws. To check what `sfera` produces against the specification, use the [GeoJSON validator](https://www.itb.ec.europa.eu/json/geojson/upload) of the European Commission's Interoperability Test Bed.

## Development

```sh
swift test          # macOS, with Xcode
make test-linux     # Linux, in Docker
make test-wasm      # WebAssembly (WASI), in Docker
```

CI runs all three on every push to `main` and on pull requests.

## About the name

Sfera (Сфера, "sphere") was a series of Soviet geodetic satellites, launched between 1968 and 1980 to measure the shape of the Earth.

## References

- [geojson.org](https://geojson.org/), the home of the format
- [RFC 7946](https://datatracker.ietf.org/doc/html/rfc7946), The GeoJSON Format
- [GeoJSON validator](https://www.itb.ec.europa.eu/json/geojson/upload), EC Interoperability Test Bed

## License

`sfera` is available under the MIT license. See [LICENSE](LICENSE) for details.
