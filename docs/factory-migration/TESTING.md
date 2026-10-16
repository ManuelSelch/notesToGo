# Factory Test Isolation

## Isolation rules
- DI-using Swift Testing suites use `@Suite(.container)`. FactoryTesting provides a fresh task-local container for every test, including each parameterized case.
- Create mutable repositories inside the test or its helpers, register them before constructing `@Injected` consumers, and await all middleware work before returning. Never reset the process-wide container or change a global live/mock mode.
- Router and repository factories remain `.cached` within each container. A test's navigation and registrations must not affect another test or the app host.
- Real storage tests continue using real repositories and UUID temporary directories. Constructor-injected filesystem fakes remain constructor-injected.
- UIKit/PaperKit tests retain `@MainActor`. Removing `.serialized` allows async tests to interleave across suspension points; it does not move main-actor work onto background threads.
- UI-test configuration remains explicit launch-environment data consumed in the app process. Unit tests pass environment dictionaries directly; they do not mutate the runner's process environment.

## Async lifecycle
`EditorTests` are reducer/middleware tests. They create local fixtures, explicitly reduce requests and responses, await middleware calls, and verify persisted repository contents. They no longer depend on lazy suite properties, `FluxTestStore`'s unstructured effects, or its synchronous deinit teardown, which could block main-actor progress.

`FactoryIsolationTests` additionally exercises dispatch-style `Task { ... }` inheritance in overlapping container scopes. Each child task is retained and awaited, with parent cancellation forwarded to the child. A cancellation-aware rendezvous prevents either save completing before both have started. Both repositories deliberately use the same note URL and different documents, detecting service leakage independently of filesystem-path isolation. The parent container is checked after both scopes finish.

This tests the Factory scoping and reducer/middleware boundary without modifying Flux. Full app-store and UI behavior still require the iPad verification in migration slice 4.

## Verification
The existing simulator-testing pause still applies. Build-only checks compile these tests but do not execute their assertions or prove a successful parallel run.

After explicit authorization, run unit tests on an iPad destination with parallel testing enabled, for example:

```sh
xcodebuild -project notesToGo.xcodeproj -scheme notesToGo \
  -destination 'platform=iOS Simulator,id=46FA7F93-092B-4F31-A08D-37EC0ECAA115' \
  -only-testing:notesToGoTests -parallel-testing-enabled YES test
```

Swift Testing controls parallel cases within its test process; Xcode's worker settings additionally control test-runner processes. Repeat the unit run to check for order-dependent failures. Run UI tests separately rather than treating a unit-test build as UI verification.
