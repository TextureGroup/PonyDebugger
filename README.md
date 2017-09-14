# Weaver

[![Version](https://img.shields.io/cocoapods/v/Weaver.svg)](http://cocoadocs.org/docsets/Weaver)
[![License](https://img.shields.io/cocoapods/l/Weaver.svg)](http://cocoadocs.org/docsets/Weaver)
[![Platform](https://img.shields.io/cocoapods/p/Weaver.svg)](http://cocoadocs.org/docsets/Weaver)

Weaver is a remote debugging tool for [Texture](http://texturegroup.org) apps. It is a client library and gateway server combination that uses Chrome DevTools on your browser to debug your application's layout hierarchy. 

Demo video: https://youtu.be/zdACP6dQlQ8

Weaver is a hard fork of [PonyDebugger](https://github.com/square/PonyDebugger). It was trimmed down and modified to work with layout elements from both UIKit and Texture.

To use Weaver, you must enable the client in your iOS application and connect it to the gateway server called "ponyd".

## Quick Start

### Install ponyd

- Prerequisites: Python 2, pip, virtualenv
  
1. Create a temporary directory:
```sh
$ mkdir ponyd && cd ponyd
```

2. Download required dependencies
```sh
$ curl -O https://pypi.python.org/packages/11/b6/abcb525026a4be042b486df43905d6893fb04f05aac21c32c638e939e447/pip-9.0.1.tar.gz && \
curl -O https://pypi.python.org/packages/25/5d/cc55d39ac39383dd6e04ae80501b9af3cc455be64740ad68a4e12ec81b00/setuptools-0.6c11-py2.7.egg && \
curl -O https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/pybonjour/pybonjour-1.1.1.tar.gz && \
tar xvf pybonjour-1.1.1.tar.gz && \
mv pybonjour-1.1.1 pybonjour
```

- 2.1. If you're on Ubuntu, you need to install `libavahi-compat-libdnssd1` as well:
```sh
$ sudo apt-get install libavahi-compat-libdnssd1
```

3. Download and run ponyd's boostrap script:
```
$ curl -s https://raw.githubusercontent.com/TextureGroup/Weaver/master/scripts/bootstrap-ponyd.py | python - --never-download ~/Library/Weaver
```

4. Install dependencies
```
$ ~/Library/Weaver/bin/easy_install -U backports_abc && \
~/Library/Weaver/bin/easy_install -U certifi && \
~/Library/Weaver/bin/easy_install -U singledispatch && \
~/Library/Weaver/bin/easy_install -U pybonjour
```

5. Add `ponyd` symlink
```
$ sudo mkdir -p /usr/local/bin
$ ln -s ~/Library/Weaver/bin/ponyd /usr/local/bin/ponyd
```

6. Install DevTools
```
$ ponyd update-devtools
```

7. Start the ponyd server

```sh
$ ponyd serve -i 0.0.0.0 -p 9229
```

In your browser, navigate to `http://localhost:9229`. You should see the
ponyd lobby. Now you need to integrate the client to your application.

For more detailed instructions, check out the gateway server
[README_ponyd](https://github.com/TextureGroup/Weaver/blob/master/README_ponyd.rst).

### Weaver iOS Client

The Weaver iOS client lets you to debug your application's layout hierarchy.

#### Technical

- Requires iOS 8.0 or above
- Uses ARC (Automatic Reference Counting).
- Uses SocketRocket as a WebSocket client.

#### Installing via CocoaPods

Weaver is available on [CocoaPods](https://cocoapods.org/pods/Weaver). Add the following to your Podfile:

```ruby
target 'MyApp' do
  pod 'Texture'
  pod 'Weaver'
end
```

Quit Xcode completely before running the following command in the project directory

```sh
$ pod install
```

in the project directory in Terminal.  

To update your version of Weaver, run the following command in the project directory

```sh
$ pod update Weaver
```

Don't forget to use the workspace `.xcworkspace` file, _not_ the project `.xcodeproj` file.

#### Usage

Weaver's main entry points exist in the `WVDebugger` singleton.
```objective-c
WVDebugger *debugger = [WVDebugger defaultInstance];
```

Then enable layout debugging by calling `enableLayoutElementDebuggingWithApplication` and passing your UIApplication to it:
```objective-c
[debugger enableLayoutElementDebuggingWithApplication:application];
```

To connect automatically to ponyd on your LAN (via Bonjour):
```objective-c
[debugger autoConnect];
```

Or to open the connection to a specific host, for instance
`ws://localhost:9229/device`:

```objective-c
[debugger connectToURL:[NSURL URLWithString:@"ws://localhost:9229/device"]];
```

To manually close the connection:

```objective-c
[debugger disconnect];
```

#### Integration example
You can find an example on how to integrate Weaver into an existing app [here](https://github.com/TextureGroup/Texture/pull/412).

## Getting Help
We use Slack for real-time debugging, community updates, and general talk about Texture and Weaver. [Signup](http://asdk-slack-auto-invite.herokuapp.com) yourself and join #weaver channel.

## Contributing
We welcome any contributions. See the [CONTRIBUTING](https://github.com/TextureGroup/Weaver/blob/master/CONTRIBUTING.md) file for how to get involved.

## License

The Weaver project was created by Pinterest as a continuation, under a different name, of the PonyDebugger codebase originally developed by Square.  PonyDebugger was originally released by Square under the Apache License, Version 2.0.  All code contributed to Weaver after 5/15/2017 is released by Pinterest under the same license, Apache 2.0 license (http://www.apache.org/licenses/LICENSE-2.0.html).

## Some useful links:

- [Chrome Remote Debugging Documentation](https://chromedevtools.github.io/debugger-protocol-viewer/tot/)
- [WebKit Inspector Protocol Definition on GitHub](https://github.com/WebKit/webkit/blob/master/Source/JavaScriptCore/inspector/protocol/Inspector.json)
