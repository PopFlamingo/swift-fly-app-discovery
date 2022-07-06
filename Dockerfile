FROM swiftlang/swift:nightly-5.7-focal as build
WORKDIR /build
COPY . .
RUN swift build -c release
ENTRYPOINT ["sleep", "12h"]