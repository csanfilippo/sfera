# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`sfera` is a Swift package for modelling, encoding and decoding GeoJSON as defined by [RFC 7946](https://datatracker.ietf.org/doc/html/rfc7946). Encoded output can be checked manually against the [EC Interoperability Test Bed GeoJSON validator](https://www.itb.ec.europa.eu/json/geojson/upload).

## Commands

```sh
swift build
swift test
swift test --filter PositionTests                 # one suite
swift test --filter 'PositionTests/`latitude'    # a single test (regex over the test ID)
swift test list                                   # print test IDs
make test-linux                                   # full suite on Linux, in Docker
make test-wasm                                    # full suite on wasm32, in Docker
```

- The `make` targets run in the official `swift` image so no second toolchain is installed locally (Xcode stays the only one). They need Docker running, mount the sources read-only and build inside the container, so they never touch the local `.build`. The Wasm SDK is installed once into the `sfera-swiftpm` Docker volume. `SWIFT_VERSION` and the Wasm SDK checksum in the `Makefile` must be bumped together.
- `test-wasm` always runs the full suite: `--filter` does not work on wasm32 (SwiftPM tries to execute the `.wasm` to list tests). It passes `--disable-xctest`, because the XCTest runner traps in Foundation's `Bundle.main` on WASI even with no XCTest tests.
- CI (`.github/workflows/tests.yml`) runs on pushes to `main` and on pull requests. Its Linux and Wasm jobs call the same `make` targets, so the `Makefile` is the only place their Swift version lives; its macOS job runs `swift test` with the default Xcode of the `xcode-27` runner image (preview), the first one shipping Swift 6.4.

Test IDs have the form ``sferaTests.PositionTests/`latitude outside -90…90 is rejected`(latitude:)``. Raw-identifier names keep their backticks in the ID, so a filter on the name must include the leading backtick; a bare word also matches parameter labels.

There is no linter configured.

## Platform constraints

- Swift tools 6.4, deployment targets iOS/macOS/watchOS/tvOS 26. The 26 minimum is required: `AtLeast` uses value generics (`let minimum: Int`) and `InlineArray`, which need the OS 26 Swift runtime. Do not lower the platforms without removing those.
- Linux and wasm32 (WASI, full Swift SDK) are supported and tested in CI. Embedded Swift is not: it has no `Codable`. `Int` is 32 bits on wasm32 (and arm64_32 watchOS), so a value that must hold 64 bits uses `Int64`, never `Int`.
- Public domain types are `Sendable` and `Hashable` (value objects with value equality; `AtLeast` conforms conditionally on its element, comparing elements regardless of how they are split between storage). The library sources import only the standard library: `Codable` needs no Foundation, which is only used by tests (and callers) for `JSONEncoder`/`JSONDecoder`.
- `Sources/sfera/PrivacyInfo.xcprivacy` is an Apple privacy manifest that declares nothing (no tracking, no required-reason APIs, no collected data). `sfera` is not required to ship one; it is kept so Apple-platform consumers see an explicit declaration. Being a resource, it makes SwiftPM generate a `Bundle.module` accessor that imports Foundation. `Package.swift` adds it only under `#if canImport(Darwin)`, which is evaluated on the build host, not the target: SwiftPM has no per-platform resources, so every Apple build (always hosted on macOS) gets it, and so does a Linux or Wasm cross-build from a Mac. The latter is harmless: verified that a wasm32 build with the resource passes the suite, and nothing reads `Bundle.module`.

## Architecture

Domain types map one-to-one to RFC 7946 concepts, and each type owns its own GeoJSON encoding and decoding:

- `Position` is an immutable value object. Its `throws(PositionError)` initializer enforces the invariants (latitude in -90…90, longitude in -180…180, altitude finite when present), so an invalid `Position` cannot exist. It encodes itself as an unkeyed array in RFC order: `[longitude, latitude, altitude?]`.
- `Geometry` is an enum of geometry kinds. Its encoder writes `type` and delegates the payload to the contained value's own encoding instead of reaching into its fields: `coordinates` for every kind except `.geometryCollection`, which writes its member geometries under `geometries`. GeometryCollection is a `Geometry` case, not a separate type, because RFC 7946 classifies it as a Geometry object (so it can nest and can be a Feature's geometry).
- Multi* geometries are typealiases over arrays (`MultiPoint = [Position]`, `MultiLineString = [LineString]`, `MultiPolygon = [Polygon]`). The RFC allows them, and GeometryCollection, to be empty; that is deliberate and covered by tests. RFC SHOULDs (e.g. avoid nested GeometryCollections) are not enforced.
- `LinearRing` holds `AtLeast<3, Position>` distinct vertices and encodes them followed by the first vertex again, so the RFC's "closed, four or more positions" rule holds by construction rather than by validation. `Polygon` is a struct with an `exterior` ring and `holes` (exterior first, as the RFC requires); it encodes as a flat array of rings. `Polygon.init` normalizes winding order (RFC right-hand rule): the exterior becomes counter-clockwise and holes clockwise via the internal `LinearRing.oriented(_:)`, which uses the planar shoelace signed area (longitude as x, latitude as y) and reverses a ring while keeping its first vertex. Zero-area (collinear) rings have no orientation and are left as given. Orientation is internal API and is tested through `Polygon` encoding.
- `Feature` (RFC 7946 §3.2) holds an optional `Geometry`, optional `properties: [String: JSONValue]` and an optional `Feature.Identifier` (`.string`, `.integer` or `.number`). `geometry` and `properties` are required members, so they are encoded as `null` when absent; `id` is omitted when absent. `JSONValue` models any JSON value, with literal conformances so properties read as dictionary literals; it deliberately does not conform to `ExpressibleByNilLiteral` (`.null` is explicit) to avoid confusion with `Optional`. Numbers have two cases, `.integer(Int64)` and `.number(Double)`, in both `JSONValue` and `Feature.Identifier`: decoding tries `Int64` before `Double` and integer literals produce `.integer`, so integers beyond 2^53 (e.g. 64-bit ids) round-trip exactly. The case is `Int64`, not `Int`, because `Int` is 32 bits on wasm32 (and arm64_32 watchOS), where large integers would fall back to `Double`. Consequently `.integer(1)` and `.number(1.0)` are different values.
- `FeatureCollection` (RFC 7946 §3.3) wraps an ordered, possibly empty `[Feature]` and encodes it under `features`.
- `GeoJSON` (RFC 7946 §3) is the top-level enum over `.geometry`, `.feature` and `.featureCollection`. It encodes transparently as the wrapped object (each already writes its own `type`), so it adds no JSON structure. It is the entry point for decoding input of unknown kind: it reads `type` and dispatches to `Feature`, `FeatureCollection`, or otherwise `Geometry`.
- The `type` member values live only in the internal `GeoJSONType` enum (RFC 7946 §1.4 "GeoJSON types"). Encoders write a `GeoJSONType` case and decoders decode one, so no type name appears as a string literal elsewhere; switches over it are exhaustive, so adding a type forces every decoder to handle it.
- Decoding enforces the same invariants as the initializers, so a decoded value is always valid; it is strict about values and lenient about missing structure (robustness principle). Invalid positions surface as `DecodingError.dataCorrupted` with the `PositionError` as underlying error; `AtLeast` checks its minimum count; `LinearRing` requires four or more positions with first == last and drops the closing position; `Polygon` requires an exterior ring and normalizes winding instead of rejecting it (RFC 7946 asks parsers not to reject); `Feature`, `FeatureCollection` and `Geometry` check `type`. Feature `geometry`/`properties` may be absent, and position elements after the altitude are ignored. Validation errors are built with the internal `DecodingError.invalid(_:in:underlyingError:)` helper (`DecodingError+Invalid.swift`), which attaches the decoder's coding path. The README's "Decoding rules" table mirrors this list.
- `AtLeast<minimum, Element>` is a collection guaranteed to hold at least `minimum` elements: the first `minimum` live in an `InlineArray` (a `let`), the rest in an `Array`, and only the tail can grow. It conditionally conforms to `Sendable`, `Hashable` and `Codable` (as a flat array of its elements). Its internal failable `init?(_ elements: [Element])` builds one from runtime data and is what decoding uses. `LineString` is `AtLeast<2, Position>`, so the RFC's "two or more positions" rule is enforced at compile time.

## Tests

- Swift Testing, with raw-identifier test names that state the behaviour (e.g. `` `point coordinates are encoded longitude first` ``). One suite per type, in a file named after the suite.
- Tests use `import sfera`, not `@testable import`, so they exercise only the public API.
- Encoding tests compare against a JSON string produced with `.sortedKeys` via the shared `geoJSON(_:)` helper in `GeoJSONEncoding.swift`, which accepts any `Encodable`. Without `.sortedKeys`, `JSONEncoder`'s key order changes between runs. `JSONEncoder` writes whole-valued doubles without a fractional part (`10`, not `10.0`).
- Decoding tests live in each type's suite and use the shared `decoded(_:from:)` helper (same file), usually as a string round trip through `geoJSON(_:)`. Since the types are `Hashable`, a test can also compare values directly (`decoded(...) == original`).
- Test positions are built with the shared `at(longitude, latitude)` helper in `Positions.swift`, so inputs read in the same order as the expected JSON. Test rings are correctly wound unless the test is about winding.
- Invariant tests are parameterised and cover both sides of each range, NaN and infinities, plus a test that the boundary values are accepted.

## Conventions

- Every Swift file starts with the MIT license header (copy it from an existing file).
- One main type per file, named after the type; closely related types (e.g. `PositionError`) live with it.
- Public API has `///` doc comments that state the domain rules a caller cannot infer from names and types (ranges, units, minimum counts, closing and winding rules, null and number handling). Members whose name says it all are left undocumented. When behaviour changes, update the doc comment in the same change.
- The README documents every supported GeoJSON capability. When one is added or changed (a new geometry, a Feature member, a decoding rule, …), update the README in the same change: the Geometries table for geometry types, the Decoding rules table for decoding behaviour, the Guide for usage, and the Installation section and platform badge for platforms. The Quick start is standalone; Guide snippets build on each other (the four city positions, `route`, `field`, `pond`, `cities`, `data`), so declare each name once within the Guide. Before committing, paste the Quick start and the Guide snippets (in order) into separate tests into a temporary test file in `Tests/sferaTests`, run it with `swift test --filter`, print the encoded output, then delete the file. Output comments must match what `JSONEncoder` actually produces (shown `type`-first).
- Commit messages: lowercase, imperative, short (e.g. `define Point geometry`).
- The repository owner usually drives TDD by writing tests. When asked to "check" work, review it and run `swift test` rather than editing unprompted. When asked to implement something (including its tests), write the failing tests first, confirm they fail, then implement.

## Release status

- No tags yet. The README installation snippet uses `branch: "main"`; switch it to `from: "<version>"` in the same change that tags the first release (planned `0.1.0`).
- Known open decisions: `.number(.nan)` and infinities can be built in `JSONValue` and `Feature.Identifier` but fail to encode (only values computed at runtime can hit it; the README's Output section says so); `bbox` (RFC 7946 §5) and foreign members (§6.1) are not modelled.
- Android is planned for a later stage, not supported yet; do not claim it in the README until CI tests it. Findings so far (Swift SDK for Android 6.4.0, NDK r30): the library sources compile for Android with no changes expected (`Int64` already covers 32-bit armv7). Tests need an Android emulator, which needs KVM, so they can only run in CI: use `swiftlang/github-workflows` (`enable_android_sdk_build` and `enable_android_sdk_checks`, API 28 triples), on GitHub's x86_64 Ubuntu runners. Building tests with `--static-swift-stdlib` (as swift.org's example does) fails with `no such module 'Testing'`; the official workflow omits that flag. Local Docker on Apple silicon cannot link, because the NDK's Linux tools are x86_64-only.
