FROM swiftlang/swift:nightly-5.7-focal as build
WORKDIR /build
COPY . .
RUN swift build --configuration release -Xswiftc -static-executable

FROM swift:focal-slim as runtime
WORKDIR /runtime
COPY --from=build /build/.build ./
ENTRYPOINT ["sleep", "12h"]