FROM swiftlang/swift:nightly-5.7-focal
WORKDIR /build
COPY . .
RUN swift build --build-tests
ENTRYPOINT ["sleep", "12h"]