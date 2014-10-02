
default: build

build:
	xcodebuild -sdk iphonesimulator -target JsonSerializer build

test:
	xcodebuild -sdk iphonesimulator -scheme JsonSerializerTests test

clean:
	xcodebuild -sdk iphonesimulator clean

.PHONY: build test clean default
