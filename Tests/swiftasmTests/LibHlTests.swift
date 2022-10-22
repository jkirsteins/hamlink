import XCTest

@testable import swiftasm

extension String {
    static func testResourcePath(_ file: String) -> String {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("TestData", isDirectory: true).appendingPathComponent(file, isDirectory: false).path
    }
}

final class LibHlTests: XCTestCase {
    override class func setUp() {
        LibHl.hl_global_init()
    }

    override class func tearDown() {
        LibHl.hl_global_free()
    }

    func test__load_code__mod1() throws {
//        let p = String.testResourcePath("mod1.hl")
        let p = "/Users/janis.kirsteins/Projects/swiftasm/TestData/mod1.hl"
        print("Res path \(p)")
        let res = LibHl.load_code(p)
        printerr("Loading \(p) and got \(res)")
        
        /*
        version: 4
debug: true
nints: 55
nfloats: 1
nstrings: 404
ntypes: 456
nnatives: 47
nfunctions: 358
nconstants: 53

        */
        XCTAssert(res.pointee.hasdebug)
        XCTAssertEqual(res.pointee.nints, 55)
        XCTAssertEqual(res.pointee.nfloats, 1)
        XCTAssertEqual(res.pointee.nstrings, 404)
        XCTAssertEqual(res.pointee.ntypes, 456)
        XCTAssertEqual(res.pointee.nnatives, 47)
        XCTAssertEqual(res.pointee.nfunctions, 358)
        XCTAssertEqual(res.pointee.nconstants, 53)

        XCTAssertEqual(res.pointee.getString(5), "charAt")
        XCTAssertEqual(res.pointee.getString(2), "length")
        XCTAssertEqual(res.pointee.getString(10), "split")
        XCTAssertEqual(res.pointee.getString(10), "split")

        XCTAssertEqual(res.pointee.getInt(52), 44)
        
        XCTAssertEqual(res.pointee.getFloat(0), 0)
        
        // test func
        let fn = res.pointee.getFunction(18)
        let fnType = fn.pointee.type
        
        XCTAssertEqual(fn.pointee.findex, 0)
        XCTAssertEqual(fn.pointee.regs.count, 5)
        XCTAssertEqual(fn.pointee.ops.count, 9)
        XCTAssertEqual(fnType.fun.args.count, 1)
        
        XCTAssertEqual(fnType.kind, .fun)
        XCTAssertEqual(fnType.fun.closure_type, HLType_CCompat_Fun_ClosureType(kind: .void, p: nil))
        XCTAssertEqual(fnType.fun.closure, HLType_CCompat_Fun_Closure(argsPtr: nil, ret: nil, nargs: 0, parent: nil))
//        XCTAssertEqual(fnType.fun.args, [])
        print(fnType.fun.ret)
        XCTAssertEqual(fnType.fun.parent, nil)
//        XCTAssertEqual(fnType.fun.ret.obj.name, "yo")
        print(fnType.fun.closure)
        XCTAssertEqual(fnType.vobjProto, nil)
        XCTAssertEqual(fnType.markBits, nil)
        
//        XCTAssertEqual(fn.pointee.ops, [])
//        XCTAssertEqual(fn.pointee.regs, [])
        XCTAssertEqual(fn.pointee.field__name, nil)
        XCTAssertEqual(fn.pointee.field__ref, nil)
        

        let pathType = res.pointee.getType(82)
        
        XCTAssertEqual(pathType.pointee.kind, HLTypeKind.obj)
        XCTAssertEqual(pathType.pointee.obj.nfields, 4)
        XCTAssertEqual(pathType.pointee.obj.name, "Path")
        XCTAssertEqual(pathType.pointee.obj.superType, nil)

        let pathType2 = res.pointee.getType(84)
        XCTAssertEqual(pathType2.pointee.obj.name, "Path2")
        XCTAssertEqual(pathType2.pointee.obj.superType, pathType.pointee)

        // test the objects point to the same memory
        let pathTypeAddr = Int(bitPattern: res.pointee.types.advanced(by: 82))
        let path2SuperTypeAddr = Int(bitPattern: pathType2.pointee.obj.superTypePtr)
        XCTAssertEqual(pathTypeAddr, path2SuperTypeAddr)

        // native
        let hlnative = res.pointee.getNative(5)
        XCTAssertEqual("std", hlnative.pointee.lib)
        XCTAssertEqual("bytes_compare16", hlnative.pointee.name)
        XCTAssertEqual(
            res.pointee.getType(118), 
            hlnative.pointee.typePtr)
    }

    func test__hl_to_utf16__appendZero() throws {
        let string = "Hello World"


        let ptr = LibHl.hl_to_utf16(string)
        let arr = Array(UnsafeBufferPointer<UInt16>(start: ptr, count: string.count + 1))
        let reloadedString = String(utf16CodeUnits: arr, count: string.count + 1)
        let len = LibHl.hl_ucs2length(ptr, 0)
        XCTAssertEqual(len, 11)
        XCTAssertEqual(reloadedString.count, 12)
        XCTAssertEqual(reloadedString, "\(string)\0")
        XCTAssertEqual(arr, [
            0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x20, 0x57, 0x6f,
            0x72, 0x6c, 0x64, 0x00
        ]) 
    }
}

