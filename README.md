# Pastr

Post/get pastes from pastebin.com

## Requirements
Xcode 8 or greater

## Installation

### Manually
- Clone the repository
- Copy `Pastr.swift` into your project

### CocoaPods

Pastr is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Pastr"
```

## Usage

### Setup

`import Pastr` (if using CocoaPods)

Configure Pastr with your Pastebin api key. Read more about it and how you obtain one [here](http://pastebin.com/api)

```swift
pasteBinApiKey = "<Your API key>"
```

### Create a Paste

```swift
PasteRequest(content: "Hey I'm posting this to Pastebin!").post { result in
	switch result {
	case .failure(let error): fatalError("Oh! Todo: handle this")
	case .success(let key): print("Posted paste with key \(key)")
	}
}
```

### Retrieve a Paste

```swift
let key = …
getPaste(for: key) { result in
	switch result {
	case .failure(let error): fatalError() // Todo: Perhaps one should handle this...
	case .success(let content): print("Retrieved: \(content)")
	}
}
```

## More features

The module also supports:
* Name of a paste
* Scope (if you give it the scope "private", you'll have to configure your pastebin user api key)
* Format
* Expiration (default is `never`)

## Contribute

If you find a bug or have some ideas for improvements, create a new issue or open a pull request.

## License

Pastr is available under the MIT license. See the LICENSE file for more info.
