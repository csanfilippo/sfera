# sfera
Sfera (Сфера, "sphere") was a series of Soviet geodetic satellites, launched between 1968 and 1980 to measure the shape of the Earth

`sfera` is a Swift library for building and encoding [GeoJSON](https://geojson.org/) (RFC 7946).

## Requirements

- Swift 6.4
- iOS, macOS, watchOS or tvOS 26

## Installation

Add `sfera` to your `Package.swift` with Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/csanfilippo/sfera.git", branch: "main"),
],
targets: [
    .target(name: "YourTarget", dependencies: ["sfera"]),
]
```

## Supported GeoJSON

| Object | Encoding |
|---|---|
| Position | ✅ |
| Point | ✅ |
| LineString | ✅ |
| Polygon | ✅ |
| MultiPoint | ✅ |
| MultiLineString | ✅ |
| MultiPolygon | — |
| GeometryCollection | ✅ |
| Feature | — |
| FeatureCollection | — |

Decoding is not supported yet.

## Usage

### Position

A `Position` is a latitude, a longitude and an optional altitude. Its initializer validates the values, so an invalid position cannot be created:

```swift
import sfera

let rome = try Position(latitude: 41.9028, longitude: 12.4964)
let everest = try Position(latitude: 27.9881, longitude: 86.925, altitude: 8848.86)
```

The initializer throws a `PositionError`:

| Error | Cause |
|---|---|
| `.latitudeOutOfRange` | latitude outside -90…90, or NaN |
| `.longitudeOutOfRange` | longitude outside -180…180, or NaN |
| `.altitudeNotFinite` | altitude is infinite or NaN |

```swift
do {
    let position = try Position(latitude: 91, longitude: 0)
} catch .latitudeOutOfRange {
    // handle the invalid latitude
} catch {
    // other PositionError cases
}
```

### Point

Wrap a `Position` in a `Geometry.point` and encode it with `JSONEncoder`:

```swift
let point = Geometry.point(rome)
let json = try JSONEncoder().encode(point)
// {"type":"Point","coordinates":[12.4964,41.9028]}
```

As RFC 7946 requires, coordinates are written longitude first, followed by the altitude when present:

```swift
let summit = Geometry.point(everest)
// {"type":"Point","coordinates":[86.925,27.9881,8848.86]}
```

`JSONEncoder` does not guarantee the order of object keys, and it can change from one run to the next. Set `encoder.outputFormatting = .sortedKeys` if you need stable output.

### LineString

A `LineString` holds two or more positions. The first two are required when you create it, so a line string with fewer than two positions does not compile:

```swift
let florence = try Position(latitude: 43.7696, longitude: 11.2558)
let milan = try Position(latitude: 45.4642, longitude: 9.19)

var route = LineString([rome, florence])
route.append(milan)

let json = try JSONEncoder().encode(Geometry.lineString(route))
// {"type":"LineString","coordinates":[[12.4964,41.9028],[11.2558,43.7696],[9.19,45.4642]]}
```

Further positions can also be passed when you create it: `LineString([rome, florence], [milan])`.

### MultiPoint

A `MultiPoint` is an array of positions. Unlike a `LineString`, it has no minimum size:

```swift
let cities = Geometry.multiPoint([rome, florence, milan])
// {"type":"MultiPoint","coordinates":[[12.4964,41.9028],[11.2558,43.7696],[9.19,45.4642]]}

let nothing = Geometry.multiPoint([])
// {"type":"MultiPoint","coordinates":[]}
```

### MultiLineString

A `MultiLineString` is an array of line strings. Like `MultiPoint`, it can be empty:

```swift
let naples = try Position(latitude: 40.8518, longitude: 14.2681)

let network = Geometry.multiLineString([
    LineString([rome, florence], [milan]),
    LineString([rome, naples]),
])
// {"type":"MultiLineString","coordinates":[[[12.4964,41.9028],[11.2558,43.7696],[9.19,45.4642]],[[12.4964,41.9028],[14.2681,40.8518]]]}
```

### Polygon

A `Polygon` has an exterior ring and, optionally, holes. Each ring is a `LinearRing` of three or more distinct vertices. You do not repeat the first vertex at the end: the ring closes itself when encoded, so an open ring cannot be produced. As with `LineString`, the first three vertices go in the first argument and any others in the second:

```swift
let field = LinearRing([
    try Position(latitude: 0, longitude: 0),
    try Position(latitude: 0, longitude: 10),
    try Position(latitude: 10, longitude: 10),
], [
    try Position(latitude: 10, longitude: 0),
])

let square = Geometry.polygon(Polygon(exterior: field))
// {"type":"Polygon","coordinates":[[[0,0],[10,0],[10,10],[0,10],[0,0]]]}
```

Holes are written after the exterior ring, in the order given:

```swift
let pond = LinearRing([
    try Position(latitude: 2, longitude: 2),
    try Position(latitude: 4, longitude: 2),
    try Position(latitude: 4, longitude: 4),
], [
    try Position(latitude: 2, longitude: 4),
])

let fieldWithPond = Geometry.polygon(Polygon(exterior: field, holes: [pond]))
// {"type":"Polygon","coordinates":[[[0,0],[10,0],[10,10],[0,10],[0,0]],[[2,2],[2,4],[4,4],[4,2],[2,2]]]}
```

RFC 7946 requires exterior rings to be counter-clockwise and holes clockwise (the right-hand rule). `sfera` does not correct the orientation yet, so give the vertices in that order.

### GeometryCollection

A `GeometryCollection` groups geometries of any kind. Its members are written under `geometries` instead of `coordinates`:

```swift
let trip = Geometry.geometryCollection([
    .point(rome),
    .lineString(LineString([rome, florence], [milan])),
])
// {"type":"GeometryCollection","geometries":[{"type":"Point","coordinates":[12.4964,41.9028]},{"type":"LineString","coordinates":[[12.4964,41.9028],[11.2558,43.7696],[9.19,45.4642]]}]}
```

A collection can be empty or contain other collections. RFC 7946 advises against nesting collections, and against collections of a single geometry type where a Multi* geometry fits, but does not forbid either, so `sfera` accepts both.

## References

- [GeoJSON](https://geojson.org/) — the GeoJSON format specification (RFC 7946)
- [GeoJSON validator](https://www.itb.ec.europa.eu/json/geojson/upload) — the European Commission's Interoperability Test Bed validator, useful for checking the output of `sfera` against the specification
