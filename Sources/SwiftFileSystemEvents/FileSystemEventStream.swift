//
//  FileSystemEventStream.swift
//  SwiftFileSystemEvents
//
//  Created by jgvanwwyk on 2023-02-05.
//


import Foundation
import CoreServices.FSEvents


// MARK: FileSystemEventStream

/// Register for a stream of notifications of file system events in a list of directories.
public final class FileSystemEventStream {
    
    private var streamRef: FSEventStreamRef! // Will be non-nil after initialisation completes.
    private let handler: (FileSystemEvent) -> Void
    
    /// Creates a new file system event stream with the given parameters.
    ///
    /// This calls `FSEventStreamCreate(_:_:_:_:_:_:_:)`.
    ///
    /// - Parameters:
    ///   - directoriesToWatch: An array of URLs representing the directories you wish to
    ///     monitor.
    ///   - sinceWhen: The service will supply events that have happened after the given
    ///     event ID. To ask for events since now pass ``FileSystemEvent/ID-swift.struct/now``.
    ///     Defaults to ``FileSystemEvent/ID-swift.struct/now``.
    ///   - latency: The number of seconds the service should wait after hearing about an
    ///     event from the kernel before passing it to the handler. Specifying a larger
    ///     value may result in more effective temporal coalescing, resulting in fewer
    ///     callbacks and greater overall efficiency. Defaults to 0.
    ///   - flags: Flags that modify the behaviour of the stream being created. See
    ///     ``FileSystemEventStream/Flags``. Defaults to `[]`.
    ///   - handler: A block that will be called on each event that occurs in the
    ///     directories being monitored.
    @available(macOS 10.5, *)
    public init(directoriesToWatch: [URL],
                sinceWhen: FileSystemEvent.ID = .now,
                latency: TimeInterval = 0,
                flags: Flags = [],
                handler: @escaping (FileSystemEvent) -> Void) {
        self.handler = handler
        let pathsToWatch: CFArray
        if #available(macOS 13.0, *) {
            pathsToWatch = directoriesToWatch.map { $0.path(percentEncoded: false) } as CFArray
        } else {
            pathsToWatch = directoriesToWatch.map { $0.path } as CFArray
        }
        // We pass an unmanaged pointer to `self` as context info to the stream.
        // `FileSystemEventStream.callback` uses this to call `handler` with each event.
        // As the memory for `self` is managed by Swift, we pass `nil` for both `retain`
        // and `release`.
        var context = FSEventStreamContext(version: 0,
                                           info: Unmanaged.passUnretained(self).toOpaque(),
                                           retain: nil,
                                           release: nil,
                                           copyDescription: nil)
        // While the return value of `FSEventStreamCreate` is imported in Swift as
        // `FSEventStreamRef?`, the documentation for `FSEventStreamCreate` asserts that
        // its return value will always be a valid `FSEventStreamRef`, so we unwrap the
        // return value here.
        self.streamRef = FSEventStreamCreate(kCFAllocatorDefault,
                                             Self.callback,
                                             &context,
                                             pathsToWatch,
                                             sinceWhen.rawValue,
                                             latency,
                                             flags.rawValue)!
    }
    
    deinit {
        FSEventStreamRelease(streamRef)
    }
    
    private static let callback: FSEventStreamCallback = { _, info, numEvents, eventPaths, eventFlags, eventIDs in
        guard let info = info else { return }
        let eventPaths = eventPaths.assumingMemoryBound(to: UnsafeMutablePointer<CChar>.self)
        let stream = Unmanaged<FileSystemEventStream>.fromOpaque(info).takeUnretainedValue()
        for index in 0..<numEvents {
            let url = URL(fileURLWithFileSystemRepresentation: eventPaths[index],
                          isDirectory: true,
                          relativeTo: nil)
            let flags = FileSystemEvent.Flags(rawValue: eventFlags[index])
            let id = FileSystemEvent.ID(rawValue: eventIDs[index])
            let event = FileSystemEvent(url: url, id: id, flags: flags)
            stream.handler(event)
        }
    }
    
    /// Fetches the `sinceWhen` property of the stream.
    ///
    /// Upon receiving an event (and just before invoking the client's callback) this
    /// attribute is updated to the highest-numbered event ID mentioned in the event.
    ///
    /// This calls `FSEventStreamGetLatestEventId`.
    @available(macOS 10.5, *)
    public var latestEventID: FileSystemEvent.ID {
        FileSystemEvent.ID(rawValue: FSEventStreamGetLatestEventId(streamRef))
    }
    
    /// Fetches the directories supplied to the stream.
    ///
    /// This calls `FSEventStreamCopyPathsBeingWatched`.
    @available(macOS 10.5, *)
    public var directoriesBeingWatched: [URL] {
        // `FSEventStreamCopyPathsBeingWatched` returns a `CFArray` of `CFStringRef`, which
        // can always be converted to `[String]`.
        let paths = FSEventStreamCopyPathsBeingWatched(streamRef) as! [String]
        let urls: [URL]
        if #available(macOS 13.0, *) {
            urls = paths.map { URL(filePath: $0, directoryHint: .isDirectory) }
        } else {
            urls = paths.map { URL(fileURLWithPath: $0, isDirectory: true) }
        }
        return urls
    }
        
    /// Schedules the stream on the specified dispatch queue.
    ///
    /// The caller is responsible for ensuring that the stream is scheduled on a dispatch
    /// queue and that the queue is started. If there is a problem scheduling the stream
    /// on the queue an error will be returned when you try to start the stream. To start
    /// receiving events on the stream, call ``FileSystemEventStream/start()``. To remove
    /// the stream from the queue on which it was scheduled, call
    /// ``FileSystemEventStream/setDispatchQueue(_:)`` with a `nil` queue parameter or
    /// call ``FileSystemEventStream/invalidate()`` which will do the same thing.
    ///
    /// Note: you must eventually call ``FileSystemEventStream/invalidate()``, and it is
    /// an error to call ``FileSystemEventStream/invalidate()`` without having the stream
    /// either scheduled on a dispatch queue, so do not set the dispatch queue to `nil`
    /// before calling ``FileSystemEventStream/invalidate()``.
    ///
    /// This calls `FSEventStreamSetDispatchQueue(_:,_:)`.
    ///
    /// - Parameters:
    ///   - dispatchQueue: The dispatch queue to use to receive events (or `nil` to stop
    ///     receiving events from the stream).
    @available(macOS 10.6, *)
    public func setDispatchQueue(_ dispatchQueue: DispatchQueue?) {
        FSEventStreamSetDispatchQueue(streamRef, dispatchQueue)
    }
  
    /// Invalidate the stream.
    ///
    /// The stream will be unscheduled on any dispatch queue on which it has been scheduled.
    /// This may only be called if the stream has been scheduled on a dispatch queue with
    /// ``FileSystemEventStream/setDispatchQueue(_:)``.
    ///
    /// This calls `FSEventStreamInvalidate(_:)`.
    @available(macOS 10.5, *)
    public func invalidate() {
        FSEventStreamInvalidate(streamRef)
    }
    
    /// Start the stream.
    ///
    /// Attempts to register with the File System Events service to receive events per the
    /// parameters in the stream. This can only be called once the stream has been
    /// scheduled on a dispatch queue. Once started, the stream can be stopped with
    /// ``FileSystemEventStream/stop()``.
    ///
    /// This ought to always succeed, but if it does not, you should have appropriate
    /// fallback in place.
    ///
    /// This calls `FSEventStreamStart(_:)`.
    ///
    /// - Throws:
    ///   - ``Error/couldNotStartStream`` if the stream could not be started.
    @available(macOS 10.5, *)
    public func start() throws {
        guard FSEventStreamStart(streamRef) else { throw Error.couldNotStartStream }
    }
    
    /// Asks the File System Events service to flush out any events that have occurred but
    /// have not yet been delivered.
    ///
    /// Events may be delayed due to the latency parameter that was supplied when the stream
    /// was created. This flushing occurs asynchronously -- do not expect the events to have
    /// already been delivered by the time this call returns.
    ///
    /// This may only be called after you have started the stream with ``start()``.
    ///
    /// This calls `FSEventStreamFlushAsync(_:)`.
    ///
    /// - Returns: The largest event ID of any event ever queued for this stream, otherwise
    ///   zero if no events have been queued for this stream.
    @available(macOS 10.5, *)
    public func flushAsync() -> FileSystemEvent.ID {
        FileSystemEvent.ID(rawValue: FSEventStreamFlushAsync(streamRef))
    }
    
    /// Asks the File System Events service to flush out any events that have occurred
    /// but have not yet been delivered.
    ///
    /// Events may be delayed due to the latency parameter that was supplied when the stream
    /// was created. This flushing occurs synchronously -- by the time this call returns,
    /// your handler will have been invoked for every event that had already/ occurred at
    /// the time you made this call.
    ///
    /// This may only be called after you have started the stream with ``start()``.
    ///
    /// This calls `FSEventStreamFlushSync(_:)`.
    @available(macOS 10.5, *)
    public func flushSync() {
        FSEventStreamFlushSync(streamRef)
    }
    
    /// Unregisters with the File System Events service.
    ///
    /// Your handler will not be called for this stream while it is stopped. This can only
    /// be called if the stream has been started via ``FileSystemEventStream/start()``.
    /// Once stopped, the stream can be restarted via ``FileSystemEventStream/start()``, at
    /// which point it will resume receiving events from where it left off ("sinceWhen").
    ///
    /// This calls `FSEventStreamStop(_:)`.
    @available(macOS 10.5, *)
    public func stop() {
        FSEventStreamStop(streamRef)
    }
    
    /// Prints a description of the supplied stream to stderr.
    ///
    /// For debugging only.
    ///
    /// This calls `FSEventStreamShow()`.
    @available(macOS 10.5, *)
    public func show() {
        FSEventStreamShow(streamRef)
    }
    
    /// Sets directories to be filtered from the event stream.
    ///
    /// A maximum of eight directories may be specified.
    ///
    /// This calls `FSEventStreamSetExclusionPaths(_:,_:)`.
    @available(macOS 10.9, *)
    public func setExclusionDirectories(_ directoryURLs: [URL]) throws {
        let paths: CFArray
        if #available(macOS 13.0, *) {
            paths = directoryURLs.map { $0.path(percentEncoded: false) } as CFArray
        } else {
            paths = directoryURLs.map { $0.path } as CFArray
        }
        guard FSEventStreamSetExclusionPaths(streamRef, paths) else { throw Error.couldNotExcludeDirectories }
    }
    
    /// Errors that may be thrown by ``FileSystemEventStream`` methods.
    public enum Error: Swift.Error {
        /// Thrown by ``FileSystemEventStream/start()`` if the stream could not be
        /// started.
        case couldNotStartStream
        case couldNotExcludeDirectories
    }
    
    /// Flags that can be passed to the file system event stream to modify its behaviour.
    ///
    /// This wraps `FSEventStreamCreateFlags`.
    public struct Flags: OptionSet {
        public let rawValue: FSEventStreamCreateFlags
        
        public init(rawValue: FSEventStreamCreateFlags) {
            self.rawValue = rawValue
        }
        
        /// The default.
        ///
        /// This wraps `kFSEventStreamCreateFlagNone`.
        public static let none = Self.init(rawValue: FSEventStreamCreateFlags(kFSEventStreamCreateFlagNone))
        
        // public static let useCFTypes = Self.init(rawValue: FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes))
                
        /// Change the meaning of the latency parameter.
        ///
        /// If you specify this flag and more than latency seconds have elapsed since the
        /// last event, your app will receive the event immediately. The delivery of the
        /// event resets the latency timer and any further events will be delivered after
        /// latency seconds have elapsed. This flag is useful for apps that are interactive
        /// and want to react immediately to changes but avoid getting swamped by
        /// notifications when changes are occurringin rapid succession. If you do not
        /// specify this flag, then when an event occurs after a period of no events, the
        /// latency timer is started. Any events that occur during the next latency seconds
        /// will be delivered as one group (including that first event). The delivery of the
        /// group of events resets the latency timer and any further events will be
        /// delivered after latency seconds. This is the default behavior and is more
        /// appropriate for background, daemon or batch processing apps.
        public static let noDefer = Self.init(rawValue: FSEventStreamCreateFlags(kFSEventStreamCreateFlagNoDefer))
        
        /// Request notifications of changes along the path to the directory or directories
        /// being watched.
        ///
        /// For example, with this flag, if you watch `/foo/bar` and it is renamed to
        /// `/foo/bar.old`, you would receive a RootChanged event. The same is true if the
        /// directory `/foo` were renamed. The event you receive is a special event: the URL
        /// for the event is the original URL you specified, the flag
        /// `FileSystemEvent.Flags.rootChanged` is set, and the event ID `FileSystemEvent.ID`
        /// is zero. RootChanged events are useful to indicate that you should rescan a
        /// particular hierarchy because it changed completely (as opposed to the things
        /// inside of it changing). If you want to track the current location of a directory,
        /// it is best to open the directory before creating the stream so that you have a
        /// file descriptor for it and can issue an `F_GETPATH` `fcntl()` to find the current
        /// path.
        public static let watchRoot = Self.init(rawValue: FSEventStreamCreateFlags(kFSEventStreamCreateFlagWatchRoot))
        
        /// Do not send events that were triggered by the current process.
        ///
        /// This is useful for reducing the volume of events that are sent. It is only
        /// useful if your process might modify the file system hierarchy beneath the
        /// path or paths being monitored. This has no effect on historical events, i.e.,
        /// those delivered before the HistoryDone sentinel event. Also, this does not apply
        /// to RootChanged events because the WatchRoot feature uses a separate mechanism
        /// that is unable to provide information about the responsible process.
        @available(macOS 10.6, *)
        public static let ignoreSelf = Self.init(rawValue: FSEventStreamCreateFlags(kFSEventStreamCreateFlagIgnoreSelf))
        
        /// Request file-level notifications.
        ///
        /// Your stream will receive events about individual files in the hierarchy you are
        /// watching instead of only receiving directory level notifications. Use this flag
        /// with care as it will generate significantly more events than without it.
        @available(macOS 10.7, *)
        public static let fileEvents = Self.init(rawValue: FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents))
        
        /// Tag events that were triggered by the current process with the "OwnEvent" flag.
        ///
        /// This is only useful if your process might modify the file system hierarchy
        /// beneath the path(s) being monitored and you wish to know which events were
        /// triggered by your process. Note: this has no effect on historical events, i.e.,
        /// those delivered before the HistoryDone sentinel event.
        @available(macOS 10.9, *)
        public static let markSelf = Self.init(rawValue: FSEventStreamCreateFlags(kFSEventStreamCreateFlagMarkSelf))
        
        // @available(macOS 10.13, *)
        // public static let useExtendedData = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamCreateFlagUseExtendedData))
        
        /// Reguest full event history.
        ///
        /// When requesting historical events it is possible that some events may get
        /// skipped due to the way they are stored.  With this flag all historical events
        /// in a given chunk are returned even if their event ID is less than the
        /// `sinceWhen` ID.  Put another way, deliver all the events in the first chunk of
        /// historical events that contains the `sinceWhen` ID so that none are skipped even
        /// if their id is less than the `sinceWhen` ID.  This overlap avoids any issue with
        /// missing events that happened at/near the time of an unclean restart of the
        /// client process.
        @available(macOS 10.15, *)
        public static let fullHistory = Self.init(rawValue: FSEventStreamEventFlags(kFSEventStreamCreateFlagFullHistory))
    }
    
}
