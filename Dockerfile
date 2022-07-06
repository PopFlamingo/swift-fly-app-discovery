FROM swiftlang/swift:nightly-5.7-focal as build
WORKDIR /build
COPY . .
RUN swift build -c debug -Xswiftc -static-executable

FROM ubuntu:focal as runtime
WORKDIR /runtime
COPY --from=build /build/.build ./
ENTRYPOINT ["sleep", "12h"]