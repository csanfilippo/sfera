# Changelog

All notable changes to `sfera` are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/): while the version is below 1.0, a breaking change bumps the minor version.

## 0.2.0 – 2026-10-09

### Added

- `LineString(validating:)` and `LinearRing(validating:)` build a line string or a ring from positions known only at runtime, and throw `AtLeastError.minimumNotMet` when there are too few. The unlabelled literal forms still check the count at compile time. More generally, `AtLeast(validating:)` builds any `AtLeast` from an array.
- `JSONNumber`, a JSON number with exact 64-bit integers. Read it with `int64Value` (exact, or `nil`) or `doubleValue`.

### Changed

- **Breaking:** `JSONValue` and `Feature.Identifier` replace their `.integer(Int64)` and `.number(Double)` cases with a single `.number(JSONNumber)`. Literals are unchanged (`"population": 2_800_000`, `id: 42`). To migrate, write `.integer(n)` as `.number(JSONNumber(n))` and `.number(x)` as `.number(try JSONNumber(x))`, and read values with `int64Value` or `doubleValue`.
- **Breaking:** building a `JSONNumber` from a `Double` throws `JSONNumberError.notFinite` for NaN and infinities, so a `JSONNumber` always encodes. A float literal that overflows to infinity traps.
- Decoding a NaN or an infinity, which only a `JSONDecoder` with a `nonConformingFloatDecodingStrategy` can produce, fails with a `DecodingError` whose underlying error is the `JSONNumberError`.

### Fixed

- A whole number given as a `Double`, such as `.number(2.0)`, now equals itself after an encode and decode round trip: `2` and `2.0` are the same number, as they are in JSON.

## 0.1.0 – 2026-10-04

Initial release: RFC 7946 GeoJSON as `Codable`, `Sendable` and `Hashable` value types (positions, the seven geometry types, features, feature collections and the `GeoJSON` top-level enum), valid by construction, on iOS, macOS, watchOS and tvOS 26, Linux and WebAssembly.
