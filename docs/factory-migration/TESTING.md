# Factory Test Isolation

## Isolation rules
- DI-using Swift Testing suites use `@Suite(.container)`. FactoryTesting provides a fresh task-local container for every test, including each parameterized case.
- Create mutable repositories inside the test or its helpers, register them before constructing `@Injected` consumers, and await all middleware work before returning. Never reset the process-wide container or change a global live/mock mode.
- Router and repository factories remain `.cached` within each container. A test's navigation and registrations must not affect another test or the app host.
- Real storage tests continue using real repositories and UUID temporary directories. Constructor-injected filesystem fakes remain constructor-injected.
- UIKit/PaperKit tests retain `@MainActor`. Removing `.serialized` allows async tests to interleave across suspension points; it does not move main-actor work onto background threads.
- UI-test configuration remains explicit launch-environment data consumed in the app process. Unit tests pass environment dictionaries directly; they do not mutate the runner's process environment.

## Async lifecycle
`EditorTests` use a local `TestStore` per test with the usual dispatch/receive assertions and repository roundtrip checks. The `.container` trait registers fresh services before the store captures its middleware. A small `withStore` helper creates the store inside that scope and awaits `finish()` on both success and thrown errors, rethrowing the original error after finishing. Tests need no explicit finish/teardown calls, lazy suite properties, or deinit-based cleanup. This provides an explicit lifecycle boundary before each test returns, independent of fixture lifetime. Finishing waits for middleware with a bounded timeout; it does not consume unexpected actions, which still fail the test.

`FluxTestStore` tracks its middleware tasks, including follow-up actions, on the main actor. `finish()` yields while waiting for all tasks, then checks unreceived actions. Its default timeout is five seconds; timeout or cancellation reports pending work and requests task cancellation. Middleware must cooperate with cancellation; work that ignores it cannot be forcibly stopped. Cancelled responses are not dispatched. `tearDown()` only checks and never waits.

`FactoryIsolationTests` additionally exercises dispatch-style `Task { ... }` inheritance in overlapping container scopes. Each child task is retained and awaited, with parent cancellation forwarded to the child. A cancellation-aware rendezvous prevents either save completing before both have started. Both repositories deliberately use the same note URL and different documents, detecting service leakage independently of filesystem-path isolation. The parent container is checked after both scopes finish.

These isolation regressions exercise Factory scoping and the reducer/middleware boundary. Production Flux dispatch and its Action-based API are unchanged; the async lifecycle changes are confined to FluxTestStore. Full app-store and UI behavior still require the iPad verification in migration slice 4.

## Local Flux development
The Xcode project currently uses the editable Flux package at `../../../50 Coding/52 iOS/52.01 Packages/Flux`, relative to the NotesToGo project directory. The published Flux 1.0.10 does not provide async `finish()`; keep this local reference until a release containing the change is available. Other developer checkouts need the same relative layout or an updated package reference. The Action-based API is unchanged.

## Verification
Flux's package-level finish/teardown regression tests can run on macOS with `swift test` in its checkout, without starting an iOS simulator.

The existing simulator-testing pause still applies. Build-only checks compile these tests but do not execute their assertions or prove a successful parallel run.

After explicit authorization, run unit tests on an iPad destination with parallel testing enabled, for example:

```sh
xcodebuild -project notesToGo.xcodeproj -scheme notesToGo \
  -destination 'platform=iOS Simulator,id=46FA7F93-092B-4F31-A08D-37EC0ECAA115' \
  -only-testing:notesToGoTests -parallel-testing-enabled YES test
```

Swift Testing controls parallel cases within its test process; Xcode's worker settings additionally control test-runner processes. Repeat the unit run to check for order-dependent failures. Run UI tests separately rather than treating a unit-test build as UI verification.
