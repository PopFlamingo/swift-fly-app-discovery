FROM swiftlang/swift:nightly-5.7-focal
WORKDIR /build
COPY . .
RUN swift build --configuration debug
ENTRYPOINT ["sleep", "12h"]