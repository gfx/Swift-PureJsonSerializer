
default: build

test:
	xcodebuild -sdk iphonesimulator -scheme JsonSerializerTests test

build:
	xcodebuild -sdk iphonesimulator -scheme JsonSerializer build

clean:
	xcodebuild -sdk iphonesimulator clean

.PHONY: build test clean default
