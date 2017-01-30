# Pastr

A library wrapping the Pastebin.com API.

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
Pastr.pasteBinApiKey = "<API key>"
```

If you're accessing apis that requires an authenticated user, you have to set the user key:

```swift
Pastr.pastebinUserKey = "<User key>"
```

### Create a Paste

```swift
Pastr.post(text: "Hey I'm posting this to Pastebin!") { result in
	switch result {
	case .failure(let error): fatalError() // Handle
	case .success(let key): print("Posted paste with key \(key)")
	}
}
```

This function accepts the following parameters:

* `name` - To give the paste a name
* `scope` - Private, public or unlisted (enum `PastrScope`)
* `format` - Pastebin supports syntax highlighting. A list of supported types are available in `Pastr.Format`
* `expiration` - Sets when the post should expire (default is never) (enum `PastrExpiration`).

### Retrieve a Paste

```swift
Pastr.get(paste: "<a paste key>") { result in
	switch result {
	case .failure(let error): fatalError() // Handle
	case .success(let content): print("Retrieved: \(content)")
  }
}
```

### Login to pastebin

This function will authenticate a user with pastebin and return a "user key" to be used
for functions that require this token.

```swift
Pastr.delete(paste: "<a paste key>") { result in
	…
}
```

### Delete paste (User key required)

```swift
Pastr.delete(paste: "<a paste key>") { result in
	…
}
```

### Retrieve users pastes (User key required)

```swift
Pastr.getUserPastes { result in
	…
}
```

Will return a raw string containing XML.

### Retrieve trending pastes

Retrieves the 18 currently trending pastes.

```swift
Pastr.getTrendingPastes { result in
	…
}
```

Will return a raw string containing XML.

### Retrieve user information

```swift
Pastr.getUserInfo { result in
	…
}
```

Will return a raw string containing XML.

## Contribute

If you find a bug or have some ideas for improvements, create a new issue or open a pull request.

## License

Pastr is available under the MIT license. See the LICENSE file for more info.
