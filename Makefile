
default: test

build:
	xcodebuild -sdk iphonesimulator -target JsonSerializer build

test:
	#xcodebuild -sdk iphonesimulator -scheme JsonSerializerTests test
	xctool -sdk iphonesimulator -arch i386 -scheme JsonSerializerTests test

clean:
	xcodebuild -sdk iphonesimulator clean

.PHONY: build test clean default
