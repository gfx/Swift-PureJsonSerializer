
test:
	xcodebuild -sdk iphonesimulator -scheme JsonSerializer build
	xcodebuild -sdk iphonesimulator -scheme JsonSerializerTests test
