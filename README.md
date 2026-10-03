# sfera
Sfera (Сфера, "sphere") was a series of Soviet geodetic satellites, launched between 1968 and 1980 to measure the shape of the Earth

`sfera` is a Swift library for building, encoding and decoding [GeoJSON](https://geojson.org/) (RFC 7946).

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

| Object | Encoding | Decoding |
|---|---|---|
| Position | ✅ | ✅ |
| Point | ✅ | ✅ |
| LineString | ✅ | ✅ |
| Polygon | ✅ | ✅ |
| MultiPoint | ✅ | ✅ |
| MultiLineString | ✅ | ✅ |
| MultiPolygon | ✅ | ✅ |
| GeometryCollection | ✅ | ✅ |
| Feature | ✅ | ✅ |
| FeatureCollection | ✅ | ✅ |

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

RFC 7946 requires exterior rings to be counter-clockwise and holes clockwise (the right-hand rule: walking a ring, the polygon's area is always on your left). `Polygon` applies the rule for you: a ring given in the opposite direction is reversed, keeping its first vertex, so you can give the vertices either way round. The order itself must still follow the boundary, since reversing is the only change made. `exterior` and `holes` return the corrected rings. A ring whose vertices all lie on one line has no direction and is kept as given.

### MultiPolygon

A `MultiPolygon` is an array of polygons, each with its own exterior ring and holes. Like the other Multi* geometries, it can be empty:

```swift
let orchard = LinearRing([
    try Position(latitude: 0, longitude: 20),
    try Position(latitude: 0, longitude: 30),
    try Position(latitude: 10, longitude: 20),
])

let farm = Geometry.multiPolygon([
    Polygon(exterior: field, holes: [pond]),
    Polygon(exterior: orchard),
])
// {"type":"MultiPolygon","coordinates":[[[[0,0],[10,0],[10,10],[0,10],[0,0]],[[2,2],[2,4],[4,4],[4,2],[2,2]]],[[[20,0],[30,0],[20,10],[20,0]]]]}
```

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

### Feature

A `Feature` pairs a geometry with properties and an optional identifier:

```swift
let city = Feature(
    id: "rome",
    geometry: .point(rome),
    properties: [
        "name": "Rome",
        "population": 2_800_000,
        "capital": true,
        "districts": ["Centro", "Trastevere"],
    ]
)
// {"type":"Feature","id":"rome","geometry":{"type":"Point","coordinates":[12.4964,41.9028]},"properties":{"name":"Rome","population":2800000,"capital":true,"districts":["Centro","Trastevere"]}}
```

- `properties` is a JSON object whose values are `JSONValue`s. Strings, numbers, booleans, arrays and nested objects can be written as literals; use `.null` for a null value. Whole numbers are stored as `.integer(Int)` and other numbers as `.number(Double)`, so large integers such as 64-bit identifiers are read and written exactly.
- `id` is a string or a number (`.string`, `.integer` or `.number`, with the same integer handling as properties). When absent, it is left out of the JSON.
- `geometry` and `properties` are always written. When absent they are `null`, as RFC 7946 requires: `Feature(geometry: nil)` encodes as `{"type":"Feature","geometry":null,"properties":null}`.

### FeatureCollection

A `FeatureCollection` is an ordered list of features, and is the usual top-level object of a GeoJSON file. It can be empty:

```swift
let milan = try Position(latitude: 45.4642, longitude: 9.19)

let cities = FeatureCollection([
    Feature(id: "rome", geometry: .point(rome), properties: ["name": "Rome"]),
    Feature(id: "milan", geometry: .point(milan), properties: ["name": "Milan"]),
])
// {"type":"FeatureCollection","features":[{"type":"Feature","id":"rome","geometry":{"type":"Point","coordinates":[12.4964,41.9028]},"properties":{"name":"Rome"}},{"type":"Feature","id":"milan","geometry":{"type":"Point","coordinates":[9.19,45.4642]},"properties":{"name":"Milan"}}]}
```

### GeoJSON

`GeoJSON` represents any GeoJSON object: a geometry, a feature or a feature collection. Use it where any of the three is accepted, such as a list of documents to write. It encodes exactly as the object it wraps, adding nothing around it:

```swift
let documents: [GeoJSON] = [
    .geometry(.point(rome)),
    .feature(Feature(id: "rome", geometry: .point(rome))),
    .featureCollection(cities),
]

let first = try JSONEncoder().encode(documents[0])
// {"type":"Point","coordinates":[12.4964,41.9028]}
```

### Decoding

Every type is `Codable`. When the input could be any GeoJSON object, decode `GeoJSON` and switch on what it contains:

```swift
let json = Data(#"{"type":"Feature","geometry":{"type":"Point","coordinates":[12.4964,41.9028]},"properties":{"name":"Rome"}}"#.utf8)

switch try JSONDecoder().decode(GeoJSON.self, from: json) {
case .feature(let feature):
    print(feature.properties?["name"])   // Optional(JSONValue.string("Rome"))
case .geometry, .featureCollection:
    break
}
```

If you know what to expect, decode it directly: `JSONDecoder().decode(FeatureCollection.self, from: json)`.

Decoding applies the same rules as building values in code, so a decoded value is always valid:

- Out-of-range coordinates and non-finite altitudes are rejected with a `DecodingError` whose underlying error is the `PositionError`.
- A line string needs at least two positions, and a ring at least four, ending with its first position.
- A polygon needs an exterior ring. Rings with the wrong winding are accepted and corrected, as RFC 7946 asks of parsers.
- An unknown geometry `type`, or a `type` that does not match the requested object, is rejected.

Where the input is merely incomplete, decoding is lenient: a Feature without `geometry` or `properties` is read as having `null` for them, and position elements after the altitude are ignored.

## References

- [GeoJSON](https://geojson.org/) — the GeoJSON format specification (RFC 7946)
- [GeoJSON validator](https://www.itb.ec.europa.eu/json/geojson/upload) — the European Commission's Interoperability Test Bed validator, useful for checking the output of `sfera` against the specification
