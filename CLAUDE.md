# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`sfera` is a Swift package for modelling and encoding GeoJSON as defined by [RFC 7946](https://geojson.org/). Encoded output can be checked manually against the [EC Interoperability Test Bed GeoJSON validator](https://www.itb.ec.europa.eu/json/geojson/upload).

## Commands

```sh
swift build
swift test
swift test --filter PositionTests                 # one suite
swift test --filter 'PositionTests/`latitude'    # a single test (regex over the test ID)
swift test list                                   # print test IDs
```

Test IDs have the form ``sferaTests.PositionTests/`latitude outside -90…90 is rejected`(latitude:)``. Raw-identifier names keep their backticks in the ID, so a filter on the name must include the leading backtick; a bare word also matches parameter labels.

There is no linter configured.

## Platform constraints

- Swift tools 6.4, deployment targets iOS/macOS/watchOS/tvOS 26. The 26 minimum is required: `AtLeast` uses value generics (`let minimum: Int`) and `InlineArray`, which need the OS 26 Swift runtime. Do not lower the platforms without removing those.
- Public domain types are `Sendable`.

## Architecture

Domain types map one-to-one to RFC 7946 concepts, and each type owns its own GeoJSON encoding:

- `Position` is an immutable value object. Its `throws(PositionError)` initializer enforces the invariants (latitude in -90…90, longitude in -180…180, altitude finite when present), so an invalid `Position` cannot exist. It encodes itself as an unkeyed array in RFC order: `[longitude, latitude, altitude?]`.
- `Geometry` is an enum of geometry kinds. Its encoder writes `type` and delegates the payload to the contained value's own encoding instead of reaching into its fields: `coordinates` for every kind except `.geometryCollection`, which writes its member geometries under `geometries`. GeometryCollection is a `Geometry` case, not a separate type, because RFC 7946 classifies it as a Geometry object (so it can nest and can be a Feature's geometry).
- Multi* geometries are typealiases over arrays (`MultiPoint = [Position]`, `MultiLineString = [LineString]`). The RFC allows them, and GeometryCollection, to be empty; that is deliberate and covered by tests. RFC SHOULDs (e.g. avoid nested GeometryCollections) are not enforced.
- `AtLeast<minimum, Element>` is a collection guaranteed to hold at least `minimum` elements: the first `minimum` live in an `InlineArray`, the rest in an `Array`, and only the tail can grow. It conditionally conforms to `Sendable` and `Encodable` (as a flat array of its elements). `LineString` is `AtLeast<2, Position>`, so the RFC's "two or more positions" rule is enforced at compile time.

## Tests

- Swift Testing, with raw-identifier test names that state the behaviour (e.g. `` `point coordinates are encoded longitude first` ``). One suite per type, in a file named after the suite.
- Tests use `import sfera`, not `@testable import`, so they exercise only the public API.
- Encoding tests compare against a JSON string produced with `.sortedKeys` (via the shared `geoJSON(_:)` helper in `GeometryEncoding.swift`). Without `.sortedKeys`, `JSONEncoder`'s key order changes between runs. `JSONEncoder` writes whole-valued doubles without a fractional part (`10`, not `10.0`).
- Invariant tests are parameterised and cover both sides of each range, NaN and infinities, plus a test that the boundary values are accepted.

## Conventions

- Every Swift file starts with the MIT license header (copy it from an existing file).
- One main type per file, named after the type; closely related types (e.g. `PositionError`) live with it.
- The README documents usage for every supported GeoJSON capability. When a capability is added (a new geometry, Feature, decoding, …), update its row in the "Supported GeoJSON" table and add a Usage example in the same change. Verify the example compiles and that the output shown matches what `JSONEncoder` actually produces.
- Commit messages: lowercase, imperative, short (e.g. `define Point geometry`).
- The repository owner drives TDD by writing tests; when asked to "check" work, review it and run `swift test` rather than editing unprompted.
