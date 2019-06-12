# SiaUs-iOS

This repository demonstrates how to use the [`us` mobile bindings](https://github.com/lukechampine/us-bindings) to create a simple iOS app that stores data on Sia. The app scans a file contract from a QR code, connects to a [`shard` server](https://github.com/lukechampine/shard), and uses the Sia renter-host protocol to upload and download an image chosen from the user's photo library.

# Prerequisites

This project was created with Xcode 10.2 and doesn't have any pods or dependencies. All resources you need are in the project already, so it works out of the box.

However, in order to use the app, you will need a file contract and a `shard` server to connect to. The [us-bindings](https://github.com/lukechampine/us-bindings) repo has instructions for obtaining a file contract. As for the `shard` server, you can run one yourself or connect to a public instance.

# Updating and importing the framework

This repo includes `Us.framework`, which is generated from the `us-bindings` repo by the `gomobile` tool. You may want to rebuild this framework if the `us` mobile bindings are updated with bug fixes or new functionality. To do so, run these commands:

```
go get -u lukechampine.com/us-bindings/gomobile
gomobile bind -target=ios lukechampine.com/us-bindings/gomobile
```

This will generate a new `Us.framework`, which you should place in `SiaUs-iOS / SiaUs / Frameworks` in Xcode. Alternatively, you can delete the existing framework and drag the new version into Xcode. You will need to do this each time you rebuild the framework.

# Running the app

Once you have `Us.framework` in Xcode, you can build and run the app in simulator. You can then scan the contract QR code you generated previously and enter the address of the `shard` server you are using. You can also simply hard-code the contract and server values in the app source code, which you can find in `Constants.swift`.

Next, enter a name for your file, select the image from your library, and hit Upload. After a moment, the upload will complete. You can then download the file, causing it to appear at the bottom of the screen. Note that the app will ignore any touches during the upload/download. 

# Using the `us` Bindings

The `us` bindings do not provide much functionality yet, but they are sufficient for a simple app like this. We need to do three things: import a file contract, connect to hosts, and upload/download a file.

### Importing contracts

Contracts are created with the `UsContract` constructor, which accepts a 96-byte array. Contracts are typically provided as a 192-byte hexadecimal string, so we need to handle that as well:

```swift
let contract = UsContract(Data(fromHexEncodedString: contractValue)
```

### Connecting to hosts

A host set is a group of hosts that will collectively store a file. Each host has an associated contract. We also make use of our `shard` server to resolve the host's public keys to their IP addresses. First, we initialize an empty host set with the address of our `shard` server:

```swift
let hostSet = UsNewHostSet(shardServer, &error)
```

Then, we connect to the host by adding our contract:

```swift
try hostSet?.addHost(contract)
```

If your app uses multiple contracts, you should call `addHost` on each of them.

### Creating the virtual filesystem

With the host set ready, we can create a virtual filesystem that stores files on Sia. The virtual filesystem needs to store a piece of metadata for each file we upload to Sia, so we pass it a root directory in addition to the host set:

```swift
let fileSystem = UsFileSystem.init(rootFolder, hs: host)
```

This directory should be the app's document directory; otherwise, you may get a permissions error when the filesystem attempts to save its metadata. You will need this metadata to download your files later, so consider syncing it across the user's devices.

It is very important that you call `close` on the filesystem before quitting the app. This method flushes any unwritten data to Sia hosts and saves the corresponding metadata to local storage. Failing to call `close` may cause data loss!

Once you have a filesystem, uploading and downloading are straightforward:

```swift
try fileSystem?.upload(fileName, data: fileData, minHosts: 1)
let data = try fileSystem?.download(fileName)
```

The only interesting parameter here is `minHosts`, which controls the redundancy of the file. If you have six contracts and `minHosts = 2`, then you will be able to download the file from any two hosts; i.e. the file will have 3x redundancy.

That's it! Now you're ready to start using Sia in your own mobile app. :)
