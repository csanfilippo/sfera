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
| LineString | — |
| Polygon | — |
| MultiPoint | — |
| MultiLineString | — |
| MultiPolygon | — |
| GeometryCollection | — |
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
// {"coordinates":[12.4964,41.9028],"type":"Point"}
```

As RFC 7946 requires, coordinates are written longitude first, followed by the altitude when present:

```swift
let summit = Geometry.point(everest)
// {"coordinates":[86.925,27.9881,8848.86],"type":"Point"}
```

## References

- [GeoJSON](https://geojson.org/) — the GeoJSON format specification (RFC 7946)
- [GeoJSON validator](https://www.itb.ec.europa.eu/json/geojson/upload) — the European Commission's Interoperability Test Bed validator, useful for checking the output of `sfera` against the specification
