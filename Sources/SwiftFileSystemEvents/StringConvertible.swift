//
//  StringConvertible.swift
//  SwiftFileSystemEvents
//
//  Created by jgvanwyk on 2023-02-10.
//    


import Foundation


extension FileSystemEventStream.Error: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .couldNotStartStream:
            return "Could not start stream"
        case .couldNotExcludeDirectories:
            return "Could not exclude directories"
        }
    }
    
}


extension FileSystemEventStream.Flags: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        var string = "["
        // if contains(.useCFTypes) { string.append("useCFTypes, ") }
        if contains(.noDefer) { string.append("noDefer, ") }
        if contains(.watchRoot) { string.append("watchRoot, ") }
        if #available(macOS 10.6, *), contains(.ignoreSelf) { string.append("ignoreSelf, ") }
        if #available(macOS 10.7, *), contains(.fileEvents) { string.append("fileEvents, ") }
        if #available(macOS 10.9, *), contains(.markSelf) { string.append("markSelf, ") }
        if #available(macOS 10.15, *), contains(.fullHistory) { string.append("fullHistory, ") }
        if string != "[" { string.removeLast(2) }
        string.append("]")
        return string
    }
    
    public var debugDescription: String {
        "FileSystemEventStream.Flags(rawValue: \(rawValue))"
    }
    
}


extension FileSystemEvent: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        if #available(macOS 13.0, *) {
            return "FileSystemEvent(path: \(url.path(percentEncoded: false)), flags: \(flags.description), id: \(id.description))"
        } else {
            return "FileSystemEvent(path: \(url.path), flags: \(flags.description), id: \(id.description))"
        }
    }
    
    public var debugDescription: String {
        if #available(macOS 13.0, *) {
            return "FileSystemEvent(path: \(url.path(percentEncoded: false)), flags: Flags(rawValue: \(flags.rawValue)), id: ID(rawValue: \(id.rawValue)))"
        } else {
            return "FileSystemEvent(path: \(url.path), flags: Flags(rawValue: \(flags.rawValue)), id: ID(rawValue: \(id.rawValue)))"
        }
    }
    
}


extension FileSystemEvent.ID: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        "\(rawValue)"
    }
    
    public var debugDescription: String {
        "FileSystemEvent.ID(rawValue: \(rawValue))"
    }
    
}


extension FileSystemEvent.Flags: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        var string = "["
        if contains(.mustScanSubDirs) { string.append("mustScanSubDirs, ") }
        if contains(.userDropped) { string.append("userDropped, ") }
        if contains(.kernelDropped) { string.append("kernelDropped, ") }
        if contains(.eventIdsWrapped) { string.append("eventIdsWrapped, ") }
        if contains(.historyDone) { string.append("historyDone, ") }
        if contains(.rootChanged) { string.append("rootChanged, ") }
        if contains(.mount) { string.append("mount, ") }
        if contains(.unmount) { string.append("unmount, ") }
        if #available(macOS 10.7, *) {
            if contains(.itemChangeOwner) { string.append("itemChangeOwner, ") }
            if contains(.itemCreated) { string.append("itemCreated, ") }
            if contains(.itemFinderInfoMod) { string.append("itemFinderInfoMod, ") }
            if contains(.itemInodeMetaMod) { string.append("itemInodeMetaMod, ") }
            if contains(.itemIsDir) { string.append("itemIsDir, ") }
            if contains(.itemIsFile) { string.append("itemIsFile, ") }
            if contains(.itemIsSymlink) { string.append("itemIsSymlink, ") }
            if contains(.itemModified) { string.append("itemModified, ") }
            if contains(.itemRemoved) { string.append("itemRemoved, ") }
            if contains(.itemRenamed) { string.append("itemRenamed, ") }
            if contains(.itemXattrMod) { string.append("itemXattrMod, ") }
        }
        if #available(macOS 10.9, *), contains(.ownEvent) { string.append("ownEvent, ") }
        if #available(macOS 10.10, *) {
            if contains(.itemIsHardlink) { string.append("itemIsHardlink, ") }
            if contains(.itemIsLastHardlink) { string.append("itemIsLastHardlink, ") }
        }
        if #available(macOS 10.13, *), contains(.itemCloned) { string.append("itemCloned, ") }
        if string != "[" { string.removeLast(2) }
        string.append("]")
        return string
    }
    
    public var debugDescription: String {
        "FileSystemEvent.Flags(rawValue: \(rawValue))"
    }
    
}
