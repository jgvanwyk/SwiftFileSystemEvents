//
//  FileSystemEvent.swift
//  SwiftFileSystemEvents
//
//  Created by jgvanwyk on 2023-02-10.
//  


import Foundation
import CoreServices.FSEvents


// MARK: FileSystemEvent

/// A file system event.
///
/// Whenever an event occurs in a directory being watched by
/// ``FileSystemEventStream``, the handler passed to the stream is called with a
/// ``FileSystemEvent`` encapsulating the event.
public struct FileSystemEvent: Hashable {
   
    /// The URL of the directory in which the event occured.
    public let url: URL
    
    
    /// The ID for the event.
    public let id: ID
    
    /// Flags set for the event.
    ///
    /// If no flags are set, then there was some change in the directory in which
    /// the event occured.
    public let flags: Flags
    
    /// The ID of a file system event.
    ///
    /// This wraps `FSEventStreamID`. Each file system event has a unique ID. Event IDs
    /// all come from a single global source. They are monotonically increasing per
    /// system, even across reboots and drives coming and going. An event ID may be
    /// passed as the `sinceWhen` parameter to
    /// ``FileSystemEventStream/init(directoriesToWatch:sinceWhen:latency:flags:handler:)``
    /// to register the stream for notifications of all events after the event with the
    /// given ID.
    ///
    /// `FSEventStreamID` is just a `UInt64`, so integer wrapping may occur. See
    /// ``Flags-swift.struct/eventIdsWrapped``.
    public struct ID: RawRepresentable, Hashable, Comparable {
        public let rawValue: FSEventStreamEventId
        
        public static func < (lhs: FileSystemEvent.ID, rhs: FileSystemEvent.ID) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        
        public init(rawValue: FSEventStreamEventId) {
            self.rawValue = rawValue
        }
        
        public static let zero = Self.init(rawValue: 0)
        
        /// A special event ID that may be passed as the `sinceWhen` parameter to
        /// ``FileSystemEventStream/init(directoriesToWatch:sinceWhen:latency:flags:handler:)``
        /// in order to receive notifications of all events "since now".
        public static let now = Self.init(rawValue: FSEventStreamEventId(kFSEventStreamEventIdSinceNow))
        
        /// The most recently generated event ID.
        ///
        /// This fetches the most recently generated event ID, system-wide. By the time the ID is
        /// fetched, you have already received events with newer IDs.
        public static var current: Self {
            Self.init(rawValue: FSEventsGetCurrentEventId())
        }
    }
    
    /// Possible flags for a file system event.
    ///
    /// This wraps `FSEventStreamEventFlags`.
    public struct Flags: OptionSet, Hashable {
        public let rawValue: FSEventStreamEventFlags
        
        public init(rawValue: FSEventStreamEventFlags) {
            self.rawValue = rawValue
        }
        
        /// There was some change in the directory at the specific URL supplied in this event.
        ///
        /// This wraps `kFSEventStreamEventFlagNone`.
        public static let none = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagNone))
        
        /// Your application must rescan not just the directory given in the event, but all
        /// its children, recursively.
        ///
        /// This can happen if there was a problem whereby events were coalesced
        /// hierarchically. For example, an event in `/Users/jsmith/Music` and an event in
        /// `/Users/jsmith/Pictures` might be coalesced into an event with this flag set
        /// and path `/Users/jsmith`. If this flag is set you may be able to get an idea of
        /// whether the bottleneck happened in the kernel (less likely) or in your client
        /// (more likely) by checking for the presence of the informational flags
        /// `userDropped` or `kernelDropped`.
        ///
        /// This wraps `kFSEventStreamEventFlagMustScanSubDirs`.
        public static let mustScanSubDirs = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagMustScanSubDirs))

        /// A problem occured in buffering the event in user space.
        ///
        /// See ``mustScanSubDirs``.
        ///
        /// This wraps `kFSEventStreamEventFlagUserDropped`.
        public static let userDropped = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagUserDropped))
        
        /// A problem occured in buffering the event in kernel space.
        ///
        /// See ``mustScanSubDirs``.
        ///
        /// This wraps `kFSEventStreamEventFlagKernelDropped`.
        public static let kernelDropped = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagKernelDropped))
        
        /// The 64-bit event ID counter wrapped around.
        ///
        /// If this flag is present, previously-issued event ID's are no longer valid
        /// values for the `sinceWhen` parameter to
        /// ``FileSystemEventStream/init(directoriesToWatch:sinceWhen:latency:flags:handler:)``.
        ///
        /// This wraps `kFSEventStreamEventFlagEventIdsWrapped`.
        public static let eventIdsWrapped = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagEventIdsWrapped))
        
        /// Marks a sentinel event sent to mark the end of the historical events.
        ///
        /// If a ``FileSystemEvent/ID-swift.struct`` was passed as the `sinceWhen` parameter
        /// to the call to
        /// ``FileSystemEventStream/init(directoriesToWatch:sinceWhen:latency:flags:handler:)``
        /// that created this stream, and this value was not
        /// ``FileSystemEvent/ID-swift.struct/now``, then the handler will be called with
        /// each event before `now` (the "historial events"). Once this is finised, the
        /// handler will be invoked with an event (the "history sentinel event") with this
        /// flag set. The URL provided with this event should be ignored.
        ///
        /// This wraps `kFSEventStreamEventFlagHistoryDone`.
        public static let historyDone = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagHistoryDone))
        
        /// Marks a special event sent when there is a change to one of the directories
        /// along the path to one of the directories you asked to watch.
        ///
        /// When this flag is set, the event ID is zero and the path corresponds to one of
        /// the paths you asked to watch (specifically, the one that changed). The path may
        /// no longer exist because it or one of its parents was deleted or renamed. Events
        /// with this flag set will only be sent if you passed the
        /// ``FileSystemEventStream/Flags/watchRoot`` when creating the stream with
        /// ``FileSystemEventStream/init(directoriesToWatch:sinceWhen:latency:flags:handler:)``.
        ///
        /// This wraps `kFSEventStreamEventFlagRootChanged`.
        public static let rootChanged = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagRootChanged))
        
        /// Marks a special event sent when a volume is mounted underneath one of the paths
        /// being monitored.
        /// The `URL` represents the path to the newly-mounted volume. You will receive
        /// one of these notifications for every volume mount event inside the kernel
        /// (independent of DiskArbitration).
        ///
        /// This wraps `kFSEventStreamEventFlagMount`.
        public static let mount = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagMount))
        
        /// Marks a special event sent when a volume is unmounted underneath one of the
        /// paths being monitored.
        ///
        /// The path in the event is the path to the directory from which the volume was
        /// unmounted. You will receive one of these notifications for every volume unmount
        /// event inside the kernel.
        ///
        /// This wraps `kFSEventStreamEventFlagUnmount`.
        public static let unmount = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagUnmount))
        
        /// A file system object was created at the specific URL supplied in this event.
        ///
        /// This flag is only ever set if you specified the ``FileSystemEventStream/Flags/fileEvents``
        /// flag when creating the stream.
        ///
        /// This wraps `kFSEventStreamEventFlagItemCreated`.
        @available(macOS 10.7, *)
        public static let itemCreated = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemCreated))
        
        /// A file system object was removed at the specific URL supplied in this event.
        ///
        /// This flag is only ever set if you specified the ``FileSystemEventStream/Flags/fileEvents``
        /// flag when creating the stream.
        ///
        /// This wraps `kFSEventStreamEventFlagItemRemoved`.
        @available(macOS 10.7, *)
        public static let itemRemoved = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemRemoved))
        
        /// A file system object at the specific URL supplied in this event had its metadata modified.
        ///
        /// This flag is only ever set if you specified the ``FileSystemEventStream/Flags/fileEvents``
        /// flag when creating the stream.
        ///
        /// This wraps `kFSEventStreamEventFlagItemInodeMetaMod`.
        @available(macOS 10.7, *)
        public static let itemInodeMetaMod = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemInodeMetaMod))
        
        /// A file system object was renamed at the specific URL supplied in this event.
        ///
        /// This flag is only ever set if you specified the ``FileSystemEventStream/Flags/fileEvents``
        /// flag when creating the stream.
        ///
        /// This wraps `kFSEventStreamEventFlagItemRenamed`.
        @available(macOS 10.7, *)
        public static let itemRenamed = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemRenamed))
        
        /// A file system object at the specific URL supplied in this event had its data modified.
        ///
        /// This flag is only ever set if you specified the ``FileSystemEventStream/Flags/fileEvents``
        /// flag when creating the stream.
        ///
        /// This wraps `kFSEventStreamEventFlagItemModified`.
        @available(macOS 10.7, *)
        public static let itemModified = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemModified))
        
        /// A file system object at the specific URL supplied in this event had its
        /// FinderInfo data modified.
        ///
        /// This flag is only ever set if you specified the ``FileSystemEventStream/Flags/fileEvents``
        /// flag when creating the stream.
        ///
        /// This wraps `kFSEventStreamEventFlagItemFinderInfoMod`.
        @available(macOS 10.7, *)
        public static let itemFinderInfoMod = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemFinderInfoMod))
        
        /// A file system object at the specific URL supplied in this event had its
        /// ownership changed.
        ///
        /// This flag is only ever set if you specified the ``FileSystemEventStream/Flags/fileEvents``
        /// flag when creating the stream.
        ///
        /// This wraps `kFSEventStreamEventFlagItemChangeOwner`.
        @available(macOS 10.7, *)
        public static let itemChangeOwner = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemChangeOwner))
        
        /// A file system object at the specific URL supplied in this event had its
        /// extended attributes modified.
        ///
        /// This flag is only ever set if you specified the ``FileSystemEventStream/Flags/fileEvents``
        /// flag when creating the stream.
        ///
        /// This wraps `kFSEventStreamEventFlagItemXattrMod`.
        @available(macOS 10.7, *)
        public static let itemXattrMod = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemXattrMod))
        
        /// The file system object at the specific URL supplied in this event is a regular file.
        ///
        /// This flag is only ever set if you specified the ``FileSystemEventStream/Flags/fileEvents``
        /// flag when creating the stream.
        ///
        /// This wraps `kFSEventStreamEventFlagItemIsFile`.
        @available(macOS 10.7, *)
        public static let itemIsFile = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsFile))
        
        /// The file system object at the specific URL supplied in this event is a directory.
        ///
        /// This flag is only ever set if you specified the ``FileSystemEventStream/Flags/fileEvents``
        /// flag when creating the stream.
        ///
        /// This wraps `kFSEventStreamEventFlagItemIsDir`.
        @available(macOS 10.7, *)
        public static let itemIsDir = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsDir))
        
        /// The file system object at the specific URL supplied in this event is a symbolic link.
        ///
        /// This flag is only ever set if you specified the ``FileSystemEventStream/Flags/fileEvents``
        /// flag when creating the stream.
        ///
        /// This wraps `kFSEventStreamEventFlagItemIsSymlink`.
        @available(macOS 10.7, *)
        public static let itemIsSymlink = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsSymlink))
        
        /// Indicates the event was triggered by the current process.
        ///
        /// This flag is only ever set if you specified the ``FileSystemEventStream/Flags/markSelf``
        /// flag when creating the stream.
        ///
        /// This wraps `kFSEventStreamEventFlagOwnEvent`.
        @available(macOS 10.9, *)
        public static let ownEvent = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagOwnEvent))
        
        /// The file system object at the specific URL supplied in this event is a hard link.
        ///
        /// This flag is only ever set if you specified the ``FileSystemEventStream/Flags/fileEvents``
        /// flag when creating the stream.
        ///
        /// This wraps `kFSEventStreamEventFlagItemIsHardlink`.
        @available(macOS 10.10, *)
        public static let itemIsHardlink = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsHardlink))
        
        /// The file system object at the specific URL supplied in this event was the last hard link.
        ///
        /// This flag is only ever set if you specified the ``FileSystemEventStream/Flags/fileEvents``
        /// flag when creating the stream.
        ///
        /// This wraps `kFSEventStreamEventFlagItemIsLastHardlink`.
        @available(macOS 10.10, *)
        public static let itemIsLastHardlink = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsLastHardlink))
        
        /// The file system object at the specific path supplied in this event is a clone or was cloned.
        ///
        /// This flag is only ever set if you specified the ``FileSystemEventStream/Flags/fileEvents``
        /// flag when creating the stream.
        ///
        /// This wraps `kFSEventStreamEventFlagItemCloned`.
        @available(macOS 10.13, *)
        public static let itemCloned = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemCloned))
    }
    
}
