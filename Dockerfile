FROM swiftlang/swift:nightly-5.7-focal as build
WORKDIR /build
COPY . .
RUN swift build -c debug
ENTRYPOINT ["sleep", "12h"]