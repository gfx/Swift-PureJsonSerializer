
XCODEBUILD:=xctool

default: test

build:
	$(XCODEBUILD) -sdk iphoneos -scheme JsonSerializer build
	$(XCODEBUILD) -sdk iphoneos -scheme SwiftFeed build

test:
	$(XCODEBUILD) -sdk iphonesimulator -arch i386 -scheme JsonSerializerTests test
	$(XCODEBUILD) -sdk iphonesimulator -arch i386 -scheme SwiftFeedTests test

clean:
	$(XCODEBUILD) -sdk iphonesimulator -scheme JsonSerializer clean
	$(XCODEBUILD) -sdk iphonesimulator -scheme SwiftFeed clean
	$(XCODEBUILD) -sdk iphoneos -scheme JsonSerializer clean
	$(XCODEBUILD) -sdk iphoneos -scheme SwiftFeed clean

.PHONY: build test clean default
