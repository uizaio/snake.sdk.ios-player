<p align="center">
<img src="https://d3co7cvuqq9u2k.cloudfront.net/public/image/logo/snake_logo_color.png" data-canonical-src="https://uiza.io" width="450" height="220" />
</p>


[![License BSD](https://img.shields.io/badge/license-BSD-AB2B28.svg?style=flat)](https://raw.githubusercontent.com/uizaio/uiza-android-broadcast-sdk/master/LICENSE)&nbsp;
[![Version](https://img.shields.io/cocoapods/v/UZPlayer.svg?style=flat&color=EE3322)](http://cocoapods.org/pods/UZPlayer)
[![Build Status](https://travis-ci.org/uizaio/snake.sdk.ios-player.svg?branch=master)](https://travis-ci.org/uizaio/snake.sdk.ios-player)
![Swift](https://img.shields.io/badge/%20in-swift%205.0-FA7343.svg)
![Platform](https://img.shields.io/badge/platform-ios-success.svg)&nbsp;
[![Support](https://img.shields.io/badge/ios-9-success.svg)](https://www.apple.com/nl/ios/)&nbsp;

UZPlayer is a framework allows you to play video with fully customizable controls.

## Compatibility

__UZPlayer__ requires Swift 4.2+ and iOS 9+

## Installation


### CocoaPods

To integrate UZPlayer into your Xcode project using [CocoaPods](http://cocoapods.org), specify it in your `Podfile`:

```ruby
pod 'UZPlayer'
```

Then run the following command:

```bash
$ pod install
```

## Usage

``` swift
let playerViewController = UZPlayerViewController()		
playerViewController.player.controlView.theme = UZTheme1()
playerViewController.player.loadVideo(url: VIDEO_URL)
present(playerViewController, animated: true, completion: nil)
```

 You might have to add these lines to `Info.plist` to disable App Transport Security (ATS) to be able to play video:
``` xml
<key>NSAppTransportSecurity</key>  
<dict>  
  <key>NSAllowsArbitraryLoads</key><true/>  
</dict>
```

## Change Player Themes
``` swift
let playerViewController = UZPlayerViewController()
playerViewController.player.controlView.theme = UZTheme1()
```

UZPlayer currently has 7 built-in themes:

[UZTheme1](https://github.com/uizaio/snake.sdk.ios-player/blob/master/themes/theme1.jpg)

[UZTheme2](https://github.com/uizaio/snake.sdk.ios-player/blob/master/themes/theme2.jpg)

[UZTheme3](https://github.com/uizaio/snake.sdk.ios-player/blob/master/themes/theme3.jpg)

[UZTheme4](https://github.com/uizaio/snake.sdk.ios-player/blob/master/themes/theme4.jpg)

[UZTheme5](https://github.com/uizaio/snake.sdk.ios-player/blob/master/themes/theme5.jpg)

[UZTheme6](https://github.com/uizaio/snake.sdk.ios-player/blob/master/themes/theme6.jpg)

[UZTheme7](https://github.com/uizaio/snake.sdk.ios-player/blob/master/themes/theme7.jpg)

## Create CustomTheme

You can create your own custom theme by creating a class inheriting from [UZPlayerTheme Protocol](https://uizaio.github.io/uiza-sdk-player-ios/Protocols/UZPlayerTheme.html) following this template: [UZCustomTheme](https://github.com/uizaio/uiza-sdk-player-ios/blob/master/themes/UZCustomTheme.swift)

You can also create your custom end screen by subclassing `UZEndscreenView`, then set an instance to `player.controlView.endscreenView`
``` swift
playerViewController.player.controlView.endscreenView = MyCustomEndScreen()
```

## Create Player with Floating Mode

You can create player with "drag down to floating mode" like Facebook or Youtube, by subclassing [UZFloatingPlayerViewController](https://uizaio.github.io/uiza-sdk-player-ios/Classes/UZFloatingPlayerViewController.html), then you can add more UI for displaying video details and add them to  `detailsContainerView` 

Then present using this code:
``` swift
UZFloatingPlayerViewController().present(with: videoItem, playlist: playlist)
```

See [Example](https://github.com/uizaio/snake.sdk.ios-player/blob/master/UZPlayerExample)

For API details, check [API Document](https://uizaio.github.io/uiza-ios-player-sdk/)

## Google ChromeCast supports
If developing using Xcode 10 and targeting iOS devices running iOS 12 or higher, the "Access WiFi Information" capability is required in order to discover and connect to Cast devices
![](https://developers.google.com/cast/images/xcode_wifi_capability_error.png)

## Support
namnh@uiza.io

## License

UZPlayer is released under the BSD license. See [LICENSE](https://github.com/uizaio/snake.sdk.ios-player/blob/master/LICENSE) for details.
