# :bulb: spot-seuranta

This repository holds the source code for a Swift app which can be used to track Finland's electricity spot prices for 'today' and 'tomorrow'. The data is fetched from [ENTSO-E](https://transparency.entsoe.eu/) in XML-format, using their RESTful API, parsed, and then displayed in 
the SwiftUI. The main language in the app at the moment is only Finnish. 

## :question: How to use 
As the app is not released in the Apple App Store, the only way to try this app is locally on a macOS equipped device. With that in order, you can locally
then build that app in Xcode, and additionally test it with a physical device.

In order to use the app you must first submit a ticket to ENTSO-E to receive your own security token (API key). After obtaining the key, the program 
can be used after placing the key in an `entso.plist` file in the project directory.

The file's contents should be as follows, replacing the string value with your own security token:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>API_KEY</key>
	<string>your security token here</string>
</dict>
</plist>
```

<i>Alternatively in Xcode: Right-click the Spot-Seuranta folder > New File, scroll down to find `Property List` file, save it as `entso`. After the file is
created, add new entry with the key `API_KEY` and with your personal security token in the value section.</i>


After previous steps are completed, the program can be ran through Xcode or through a personal device.

<hr>

<p float="left">
	<img src="spot-seuranta-mockup-today.png" width=340 height=686>
	<img src="spot-seuranta-mockup-tomorrow.png" width=340 height=686>
</p>
