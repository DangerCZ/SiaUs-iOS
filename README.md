# SiaUs-iOS

Main purpose of this repository is to show you how to work with Sia `us` framework on simple demo project. `Us.Framework` is compiled version of `us` project written in `go` (https://github.com/lukechampine/us) and it is alternative and low level API for `Sia` (decentralized cloud storage platform).

This demo iOS app works with Sia `shard server` and `contract data` (string of 192 characters) you can prepare on your personal Sia node and use them to upload selected photo from your iPhone's photo library directly to the host. After doing so, it will locally store the `.usa` file which is required in order to download the photo later.

TLDR: You can upload and download photos on the Sia platform! Yay!

# Prerequisites

This project was created with Xcode 10.2 and doesn't have any pods or dependencies. All resources you need are in the project already so it works out of the box. It should serve as inspiration for you.

What you will definitely need are the `shard server` and `contract data` mentioned earlier. If you don't know how to get them or you got to this repo accidentally, make sure to check the full tutorial which this readme is part of: https://medium.com/p/6c7077da6c18

# Updating and importing the framework

You don't need to do it right now because the framework version in this project has all features this demo needs. But if you are going to build more advanced apps and require the framework to expose more of the `us` functions, you will need to know how you update it, compile and import new framework version into your project. You can find more details about it in the article linked above or check the `us-bindings` repository directly: https://github.com/lukechampine/us-bindings.

If you already have the `Us.Framework` compiled, all you need to do is to open `SiaUs-iOS / SiaUs / Frameworks` folder and replace the `Us.Framework` there. Alternatively, you can just delete old one and drag the new version in the Xcode directly. You will need to do this each time you compile the framework unless you make some script to automate this for you.

# Running the app

Next step is to open the project `SiaUs-iOS / SiaUs.xcodeproj`, build it and run it in simulator.

Once launched, just enter the `host address` and `contract data`. As writing 192 characters is quite difficult, you can use any of these two options:

- open `Constants.swift` and change value of `testContract` to your 192 characters long string (return it to nil if you want to stop pre-filling it after launch)
- use the `Scan Contract (QR Code)` button in the app, for example to scan QR code with the contract data you generated on your computer

Now all you need to do is write name of the file. Whatever you choose, it will be used as a name of the selected photo and `.png` automatically added to it.

Then you can select any photo from your library (if you run on actual iPhone, else it will show you default library with few images of nature that come with the simulator) and touch `Upload` button. For average photo this can take some time (see in the video), so be patient, but no worries. The app ignores any touches during the upload/download. Also it remembers your previously filled values after restart.

# How does it work?

The process is pretty straight forward. In order to upload or download file, you need to do few things, so let's look at them as they are written in the demo project.

1. Decode the contract data that are encoded as hex string.

`let contract = UsContract(Data(fromHexEncodedString: contractValue)`

2. Prepare new (empty) host set with `shard server` address as a parameter and add new host to it using the decoded `contract`. If you wanted to use multiple contracts, here is the place where you can add them.

`let host = UsNewHostSet(shardServer, &error)`

`try host?.addHost(contract)`

3) Prepare file system with two parameters. One is root folder (check the `getRootFolder` function that checks for existence of `document directory` and creates it if not present) and second is the host set we prepared in previous step. The document directory is very important as after each successful upload it stores `.usa` file in it. These files are kind of key that is needed in order to download the file later. If you plan to download the file from other device, you will need to figure out way how to get this file to the other device first.

`let fileSystem = UsFileSystem.init(rootFolder, hs: host)`

4) Call the `upload` method on the `fileSystem`. You need to provide the `file name` and any `data` you want the file to contain. In this demo it is photo, but the choice is yours. Finally, `minHosts` is set to `1` as we work with single contract.

`try fileSystem?.upload(fileName, data: self.getSelectedPictureData(), minHosts: 1)`

Alternatively, you can call `download` function instead that works similarly, but expects only the `file name` and returns you the `data` that you can decode into actual photo (in this demo).

5) You need to `close` the `file system`. if you don't do this, the uploaded file won't be saved.

`try fileSystem?.close()`

And that's it!

# Troubleshooting

I don't expect issues with the app but can imagine some issues coming from your Sia node. For example, insufficient funding as each upload and download costs you something in SC for the host's bandwidth. Just let me know if you run into issues and I will update the repo as neccessary.

