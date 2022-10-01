import Foundation

// protocol ModuleHeader : CustomDebugStringConvertible {
//     var version: UInt8 { get }
//     var	flags: Int32 { get }
//     var	nints: Int32 { get }
//     var	nfloats: Int32 { get }
//     var	nstrings: Int32 { get }
//     var	nbytes: Int32 { get }
//     var	ntypes: Int32 { get }
//     var	nglobals: Int32 { get }
//     var	nnatives: Int32 { get }
//     var	nfunctions: Int32 { get }
//     var	nconstants: Int32 { get }
//     var	entrypoint: Int32 { get }
// }

struct Constants {

}

struct ModuleHeader : CustomDebugStringConvertible {
    let signature: ModuleSignature
    var version: UInt8 { signature.v }

    let	flags: Int32
    let	nints: Int32
    let	nfloats: Int32
    let	nstrings: Int32
    
    // only v5 upwards
    let	nbytes: Int32

    let	ntypes: Int32
    let	nglobals: Int32
    let	nnatives: Int32
    let	nfunctions: Int32
    let	nconstants: Int32
    let	entrypoint: Int32

    // [i32]
    let constInts: [Int32]
    // [f64]
    let constFloats: [Double]
    let constStrings: [String]

    var debugDescription: String {
return """
hl v\(version)
entry @\(entrypoint)
\(nstrings) strings
\(0) bytes
\(nints) ints
\(constInts.enumerated().map { (ix, el) in "    @\(ix) : \(el)" }.joined(separator: "\n"))
\(nfloats) floats
\(constFloats.enumerated().map { (ix, el) in "    @\(ix) : \(el)" }.joined(separator: "\n"))
\(nglobals) globals
\(nnatives) natives
\(nfunctions) functions
??? objects protos (not types)
\(nconstants) constant values
strings
\(constStrings.enumerated().map { (ix, el) in "    @\(ix) : \(el)" }.joined(separator: "\n"))
"""
    }
}

struct ModuleSignature {
    let h: UInt8
    let l: UInt8
    let b: UInt8
    let v: UInt8
}

class ByteReader
{
    let data: Data
    var pointer = 0
    
    init(_ data: Data) {
        self.data = data
    }

    func readVarInt() throws -> Int32 {
        let b = try readOctetAsInt32()
        if b & 0x80 == 0 {
            return b & 0x7F
        } else if b & 0x40 == 0 {
            let v = (try readOctetAsInt32()) | ((b & 31) << 8);
            
            if b & 0x20 == 0 { return v } else { return -v }
        } else {
            let c = try readOctetAsInt32()
            let d = try readOctetAsInt32()
            let e = try readOctetAsInt32()
            let v = ((b & 31) << 24) | (c << 16) | (d << 8) | e;
            
            if b & 0x20 == 0 { return v } else { return -v }
        }
    }

    func readHeader() throws -> ModuleHeader {
        guard self.pointer == 0 else {
            fatalError("Don't read the header if pointer not at start")
        }
        
        let sig = ModuleSignature(
            h: try self.readUInt8(), 
            l: try self.readUInt8(), 
            b: try self.readUInt8(), 
            v: try self.readUInt8())

        let firstB = String(bytes: [sig.h, sig.l, sig.b], encoding: .ascii)!
        guard firstB == "HLB" else {
            fatalError("Invalid header (first three bytes must be HLB but got \(firstB))")
        }

        guard sig.v == 4 else {
            fatalError("Supported version is 4")
        }

        let flags = try self.readVarInt()
        let nints = try self.readVarInt()
        let nfloats = try self.readVarInt()
        let nstrings = try self.readVarInt()
        let nbytes = sig.v >= 5 ? try self.readVarInt() : 0
        let ntypes = try self.readVarInt()
        let nglobals = try self.readVarInt()
        let nnatives = try self.readVarInt()
        let nfunctions = try self.readVarInt()
        let nconstants = sig.v >= 4 ? try self.readVarInt() : 0
        let entrypoint = try self.readVarInt()
        let constInts = try Array(repeating: 0, count: Int(nints)).map { _ in try self.readInt32() } 
        let constFloats = try Array(repeating: 0, count: Int(nfloats)).map { _ in try self.readDouble() } 
        
        let constStrings = try self.readStrings(nstrings)

        if sig.v >= 5 {
            fatalError("byte reading not implemented")
        }
        // 24
        let hasdebug = (flags & 1 != 0)
        if hasdebug {
            let debugEntryCount = try self.readVarInt()
            let debugEntries = try self.readStrings(debugEntryCount)
            // print("Got it in \(skipped): \(x)")
            fatalError("Got \(debugEntries) \(debugEntryCount)")
            // print(try self.readVarInt())
            // print(try self.readVarInt())
            // print(try self.readVarInt())
            let _debugEntryStringSize = try self.readInt32()
            // print("Debug entries \(debugEntries)")
            for _ in 0..<3 { print(try self.readString().count) }
            let debugStrings = try Array(repeating: 0, count: Int(24)).map { _ in try self.readString() } 
            print(" \(debugStrings)")
            fatalError("Yo \(debugEntries) \(_debugEntryStringSize)")
        }

        // print("ntypes", ntypes)
        // fatalError("wat")

        /*
        
ntypes * type	types	types definitions
var * nglobals	globals	types of each globals
nnatives * native	natives	Native functions to be loaded from external libraries
nfunctions* function	functions	Function definitions
nconstants* constant	constants	Constant definitions
        */


        let result = ModuleHeader(
            signature: sig, 
            flags: flags, 
            nints: nints,
            nfloats: nfloats,
            nstrings: nstrings,
            nbytes: nbytes,
            ntypes: ntypes,
            nglobals: nglobals,
            nnatives: nnatives,
            nfunctions: nfunctions,
            nconstants: nconstants,
            entrypoint: entrypoint,
            constInts: constInts,
            constFloats: constFloats,
            constStrings: constStrings)

        return result
    }

    private func skip(_ amount: Int) {
        self.pointer += amount
    }

    private func readStrings(_ count: Int32) throws -> [String] {
        try readStrings(Int(count))
    }

    private func readStrings(_ count: Int) throws -> [String] {
        let stringDataSize = try self.readUInt32()
        let expectedPostDataPointer = UInt32(pointer) + UInt32(stringDataSize)
        let strings = try Array(repeating: 0, count: count).map { _ in try self.readString() } 
        guard expectedPostDataPointer == pointer else {
            fatalError("Invalid string read")
        }
        for i in 0..<count {
            let siz = try self.readVarInt()
            guard siz == strings[strings.startIndex.advanced(by: Int(i))].count else {
                fatalError("Invalid file. String length encoding doesn't match at index \(i)")
            }
        }
        return strings
    }

    private func readString() throws -> String {
        var bytes = [UInt8]()
        while (try peekUInt8() != 0) {
            bytes += [try readUInt8()]
        } 

        try readUInt8() // skip the 0 terminator
        
        guard let result = String(bytes: bytes, encoding: .ascii) else {
            fatalError("Failed to decode string")
        }

        return result 
    }

    private func parseLEUIntX<Result>(_: Result.Type, advance: Bool = true) throws -> Result
            where Result: UnsignedInteger
    {
        let expected = MemoryLayout<Result>.size

        guard data.count >= pointer + expected else { fatalError("Not enough data before seeking") }

        let result = self.data[
            self.data.startIndex.advanced(by: pointer)..<self.data.startIndex.advanced(by: pointer+expected)]

        defer { 
            if advance {
                pointer += expected 
            }
        }
        guard result.count >= expected else { fatalError("Not enough data") }

        return result
                .prefix(expected)
                .reversed()
                .reduce(0, { soFar, new in
                        (soFar << 8) | Result(new)
                })
    }

    func readOctetAsInt32() throws -> Int32 {
        return Int32(try readUInt8())
    }

    func readUInt32() throws -> UInt32 {
        try parseLEUIntX(UInt32.self)
    }

    func readUInt64() throws -> UInt64 {
        try parseLEUIntX(UInt64.self)
    }

    func readInt32() throws -> Int32 {
        Int32(bitPattern: try readUInt32())
    }

    func readDouble() throws -> Double {
        Double(bitPattern: try readUInt64())
    }

    func readUInt8() throws -> UInt8 {
        try parseLEUIntX(UInt8.self)
    }

    func readUInt16() throws -> UInt16 {
        try parseLEUIntX(UInt16.self)
    }

    func readInt16() throws -> Int16 {
        Int16(bitPattern: try readUInt16())
    }

    func peekUInt8() throws -> UInt8 {
        try parseLEUIntX(UInt8.self, advance: false)
    }
}