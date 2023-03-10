# ``SwiftFileSystemEvents``

A thin Swift wrapper for a subset of the File System Events API.

## Overview

The File System Events API provides the ability to receive notifications of file
system events at the directory granularity level. The API allows for restricting
to listening to events from a particular device connected to the file system
(device-level), or listening to events from all devices (host-level).

SwiftFileSystemEvents is a Swift wrapper for the File System Events API for
working at the host-level. It is a thin wrapper in the sense that
SwiftFileSystemEvents types and methods generally map to File System Events
types and functions in a one-to-one way. Consequently, if you know how to use
the File System Events API, you should have no difficulty adopting
SwiftFileSystemEvents. Also, anything you can do with File System Events you
should be able to do with SwiftFileSystemEvents, as long as it pertains to
working at the host-level. The main utility of SwiftFileSystemEvents is
taking care of various pointer operations and type conversions between Swift and
C necessary for using File System Events from Swift.

The mechanics of the File System Events API is somewhat complex, so I recommend
you read the File System Events Programming Guide before using
SwiftFileSystemEvents. At minimum, read the “Technology Overview” section and
skim the “Using the File System Events API section”. The programming guide can
be found by going to
[Appleʼs Documentation Archive](https://developer.apple.com/library/archive/navigation/)
and searching for “File System Events Programming Guide”.

## Usage

To register for notifications of file system events, you create an instance of
``FileSystemEventStream`` with its initialiser
``FileSystemEventStream/init(directoriesToWatch:sinceWhen:latency:flags:handler:)``.
You then schedule the stream on a dispatch queue with
``FileSystemEventStream/setDispatchQueue(_:)`` and start the stream with
``FileSystemEventStream/start()``. Once you no longer wish to listen for events,
you stop the stream with ``FileSystemEventStream/stop()``. While the stream is
stopped, you can schedule it on a different queue with
``FileSystemEventStream/setDispatchQueue(_:)`` or unschedule it from its existing
queue by passing `nil` to ``FileSystemEventStream/setDispatchQueue(_:)``. Once
you are finished with the stream, you invalidate it by calling
``FileSystemEventStream/invalidate()``.

The code below showcases the use pattern described above.

```swift
let url = URL(filePath: "/path/to/directory/to/watch")
let handler: (FileSystemEvent) -> Void = { event in
    print(event)
}
let queue: DispatchQueue = .global(qos: .background)
let stream = FileSystemEventStream(directoriesToWatch: [url], handler: handler)
stream.setDispatchQueue(queue)
stream.start()
// Now `handler` will be called on events that occur.
stream.stop()
stream.invalidate()
```

> Warning: If you have scheduled a stream on a queue, you must invalidate the
stream before it is deallocated. A stream may only be invalidated if is
currently scheduled on a queue. Thus, it is an error to unschedule the stream
immediately before invalidating it.

## Topics

### Types

- ``FileSystemEventStream``

- ``FileSystemEventStream/Flags``

- ``FileSystemEvent``

- ``FileSystemEvent/ID-swift.struct``

- ``FileSystemEvent/Flags-swift.struct``
