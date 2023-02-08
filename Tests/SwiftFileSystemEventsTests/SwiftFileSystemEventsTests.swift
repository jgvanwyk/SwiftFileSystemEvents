//
//  SwiftFileSystemEventsTests.swift
//  SwiftFileSystemEvents
//
//  Created by jgvanwwyk on 2023-02-05.
//


import XCTest


@testable import SwiftFileSystemEvents


final class SwiftFileSystemEventsTests: XCTestCase {

    func testFileSystemEventStreamFlagsDescription() {
        let flags0: FileSystemEventStream.Flags = []
        let flags1: FileSystemEventStream.Flags = [.noDefer, .watchRoot]
        XCTAssert(flags0.description == "[]")
        XCTAssert(flags1.description == "[noDefer, watchRoot]")
    }
    
    func testFileSystemEventFlagsDescription() {
        let flags0: FileSystemEvent.Flags = []
        let flags1: FileSystemEvent.Flags = [.itemCreated, .itemCloned]
        XCTAssert(flags0.description == "[]")
        XCTAssert(flags1.description == "[itemCreated, itemCloned]")
    }
    
    func testFileSystemEventStreamDirectoriesBeingWatched() {
        let url = FileManager.default.temporaryDirectory
        let stream = FileSystemEventStream(directoriesToWatch: [url], handler: { print($0) })
        XCTAssert(stream.directoriesBeingWatched == [url])
    }
    
}
