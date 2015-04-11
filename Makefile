
XCODEBUILD:=xctool

default: buildcheck test

buildcheck:
	$(XCODEBUILD) -sdk iphoneos -scheme SwiftFeed build

test:
	$(XCODEBUILD) -sdk iphonesimulator -arch i386 -scheme JsonSerializerTests test
	$(XCODEBUILD) -sdk iphonesimulator -arch i386 -scheme SwiftFeed test

clean:
	$(XCODEBUILD) -sdk iphonesimulator -scheme JsonSerializer clean
	$(XCODEBUILD) -sdk iphonesimulator -scheme SwiftFeed clean
	$(XCODEBUILD) -sdk iphoneos -scheme JsonSerializer clean
	$(XCODEBUILD) -sdk iphoneos -scheme SwiftFeed clean

.PHONY: build test clean default
