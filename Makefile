

test:
	xcodebuild -sdk iphonesimulator -scheme JsonSerializerTests test

build:
	xcodebuild -sdk iphonesimulator -scheme JsonSerializer build

.PHONY: build test
