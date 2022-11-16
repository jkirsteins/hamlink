import XCTest

@testable import swiftasm

class RealHLTestCase : XCTestCase {
    class var HL_FILE: String { fatalError("Override HL_FILE to point to a file in TestResources") }
    
    class func getCtx() -> CCompatJitContext? {
        fatalError("Override getCtx")
    }
    
    class func setCtx(_ ctx: CCompatJitContext?) {
        fatalError("Override setCtx")
    }
    
    static var logger = LoggerFactory.create(RealHLTestCase.self)
    
    var ctx: CCompatJitContext { Self.getCtx()! }
    
    var code: UnsafePointer<HLCode_CCompat> {
        self.ctx.mainContext.pointee.code!
    }
    
    func sut(strip: Bool) throws -> M1Compiler2 {
        M1Compiler2(ctx: self.ctx, stripDebugMessages: strip)
    }
    
    override class func setUp() {
        logger.info("Setting up HL file for testing: \(HL_FILE)")
        let mod = Bundle.module.url(forResource: HL_FILE, withExtension: "hl")!.path
        setCtx(try! Bootstrap.start2(mod, args: []))
    }

    override class func tearDown() {
        logger.info("Tearing down HL file after testing: \(HL_FILE)")
        Bootstrap.stop(ctx: getCtx()!)
        setCtx(nil)
    }
}

final class CompileMod2Tests: RealHLTestCase {
    
    override class var HL_FILE: String { "mod2" }
    
    static var ctx: CCompatJitContext?
    override class func getCtx() -> CCompatJitContext? {
        ctx
    }
    override class func setCtx(_ ctx: CCompatJitContext?) {
        self.ctx = ctx
    }
    
    static let TEST_ARRAY_LENGTH_IX = 44
    static let TEST_TRAP_IX = 32
    static let TEST_GET_SET_FIELD_IX = 51
    
    static let TEST_GET_ARRAY_INT32_IX = 46
    static let TEST_GET_ARRAY_INT64HAXE_IX = 47
    static let TEST_GET_ARRAY_INT64HL_IX = 50
    
    static let TEST_FIELD_ACCESS = 43
    
    func _compileDeps(strip: Bool, mem: CpuOpBuffer = CpuOpBuffer(), _ ixs: [RefFun]) throws -> CpuOpBuffer {
        let compiler = try sut(strip: strip)
        for fix in ixs {
            try compiler.compile(findex: fix, into: mem)
        }
        return mem
    }
    
    func _compileAndLink(strip: Bool, mem: CpuOpBuffer = CpuOpBuffer(), _ ixs: [RefFun], _ callback: (UnsafeMutableRawPointer) throws->()) throws {
        let buff = try self._compileDeps(strip: strip, ixs)
        let mapper = BufferMapper(ctx: self.ctx, buffer: buff)
        let mem = try mapper.getMemory()
        
        try callback(mem)
        
        try mapper.freeMemory()
    }
    
    func testCompile__testGetSetField() throws {
        try _compileAndLink(
            strip: false,
            [
                // deps
                27,
                // function under test
                Self.TEST_GET_SET_FIELD_IX
            ]
        ) {
            mem in
            
            try mem.jit(ctx: ctx, fix: Self.TEST_GET_SET_FIELD_IX) {
                (entrypoint: (@convention(c) (Int32) -> Int32)) in
                
                XCTAssertEqual(46, entrypoint(23))
            }
        }
    }

    func testCompile__testGetSetArray__32() throws {
        typealias _JitFunc = (@convention(c) (Int32, Int64, Int32) -> Int64)
        try _compileAndLink(
            strip: false,
            [
                // function under test
                Self.TEST_GET_ARRAY_INT32_IX
            ]
        ) {
            mem in
            
            try mem.jit(ctx: ctx, fix: Self.TEST_GET_ARRAY_INT32_IX) {
                (entrypoint: _JitFunc) in
                
                XCTAssertEqual(1239, entrypoint(10, 1234, 5))
            }
        }
    }
    
    func testCompile__testGetSetArray__64hl() throws {
        typealias _JitFunc = (@convention(c) (Int32, Int64, Int32) -> Int64)
        try _compileAndLink(
            strip: false,
            [
                // function under test
                Self.TEST_GET_ARRAY_INT64HL_IX
            ]
        ) {
            mem in
            
            try mem.jit(ctx: ctx, fix: Self.TEST_GET_ARRAY_INT64HL_IX) {
                (entrypoint: _JitFunc) in
                
                XCTAssertEqual(5681, entrypoint(10, 5678, 3))
            }
        }
    }
    
    func testCompile__testGetSetArray__64haxe() throws {
        typealias _JitFunc = (@convention(c) (Int32, UnsafeRawPointer, Int32) -> UnsafeRawPointer)
        
        struct _haxeInt64 {
            let tptr: UnsafeRawPointer
            let high: Int32
            let low: Int32
        }
        
        let int64In: Int64 = 5678
        let haxeInt64 = _haxeInt64(
            tptr: code.pointee.getType(87),
            high: Int32(truncatingIfNeeded: (int64In >> 32)),
            low: Int32(truncatingIfNeeded: int64In)
        )
        
        try _compileAndLink(
            strip: false,
            [
                // deps
                49, 48,
                // function under test
                Self.TEST_GET_ARRAY_INT64HAXE_IX
            ]
        ) {
            mem in
            
            try mem.jit(ctx: ctx, fix: Self.TEST_GET_ARRAY_INT64HAXE_IX) {
                (entrypoint: _JitFunc) in
        
                withUnsafePointer(to: haxeInt64) { haxeInt64In in
                    let haxeInt64_out = entrypoint(10, haxeInt64In, 3).bindMemory(to: _haxeInt64.self, capacity: 1)
                    var int64Out: Int64 = 0
                    int64Out = int64Out | (Int64(haxeInt64_out.pointee.high) &<< 32)
                    int64Out = int64Out | (Int64(haxeInt64_out.pointee.low))
                    XCTAssertEqual(5681, int64Out)
                }
            }
        }
    }
    
    func testCompile__testArrayLength() throws {
        typealias _JitFunc = (@convention(c) (Int32) -> Int32)
        try _compileAndLink(
            strip: false,
            [
                // function under test
                Self.TEST_ARRAY_LENGTH_IX
            ]
        ) {
            mem in
            
            try mem.jit(ctx: ctx, fix: Self.TEST_ARRAY_LENGTH_IX) {
                (entrypoint: _JitFunc) in
         
                XCTAssertEqual(5, entrypoint(5))
            }
        }
    }
    
    /// Test traps
    func testCompile__testTrap() throws {
        typealias _JitFunc = (@convention(c) () -> Int32)
        try _compileAndLink(
            strip: false,
            [
                // deps
                40, 329, 5,
                // function under test
                Self.TEST_TRAP_IX
            ]
        ) {
            mem in
            
            try mem.jit(ctx: ctx, fix: Self.TEST_TRAP_IX) {
                (entrypoint: _JitFunc) in
         
                XCTAssertEqual(1, entrypoint())
            }
        }
    }
    
    /// Test parsing a type that refers to itself in a field (See `__previousException`)
    func testParseRecursiveType() throws {
        let excT = try ctx.getType(29)
        
        XCTAssertEqual(excT.objProvider?.nameProvider.stringValue, "haxe.Exception")
        XCTAssertNotNil(excT.ccompatAddress)
    }
    
    ///
    func testCompile_testGetUI16() throws {
        typealias _JitFunc = (@convention(c) (Int32) -> Int32)
        let sutFix = 31
        try _compileAndLink(
            strip: false,
            [
                // deps
                29, 3, 39, 30, 42, 327, 36, 40, 248, 14, 329, 5,
                // function under test
                sutFix
            ]
        ) {
            mem in
            
            try mem.jit(ctx: ctx, fix: sutFix) {
                (entrypoint: _JitFunc) in
                
                XCTAssertEqual(entrypoint(0), 0x1211)
                XCTAssertEqual(entrypoint(1), 0x1312)
                XCTAssertEqual(entrypoint(2), 0x1413)
                XCTAssertEqual(entrypoint(3), 0x0014)
            }
        }
    }
    
    /// This tests proper GetI8 behaviour in the wild.
    func testCompile__testGetUI8() throws {
        typealias _JitFunc =  (@convention(c) (Int32) -> Int32)
        let sutFix = 28
        try _compileAndLink(
            strip: false,
            [
                // deps
                29, 30, 3, 39, 42, 328, 36, 40, 14, 249, 330, 5, 
                // function under test
                sutFix
            ]
        ) {
            mem in
            
            try mem.jit(ctx: ctx, fix: sutFix) {
                (entrypoint: _JitFunc) in
                
                XCTAssertEqual(entrypoint(0), 0x11)
                XCTAssertEqual(entrypoint(1), 0x12)
                XCTAssertEqual(entrypoint(2), 0x13)
                XCTAssertEqual(entrypoint(3), 0x14)
            }
        }
    }
    
    func testCompile__testGetUI8_2() throws {
        typealias _JitFunc =  (@convention(c) () -> Int32)
        let sutFix = 32
        try _compileAndLink(
            strip: false,
            [
                // deps
                29, 30, 3, 39, 42, 328, 36, 40, 14, 249, 330, 5,
                // function under test
                sutFix
            ]
        ) {
            mem in
            
            try mem.jit(ctx: ctx, fix: sutFix) {
                (entrypoint: _JitFunc) in
                
                XCTAssertEqual(entrypoint(), 336794129)
            }
        }
    }
    
    func testCompile__testTrace() throws {
        typealias _JitFunc =  (@convention(c) () -> ())
        let sutFix = 55
        try _compileAndLink(
            strip: false,
            [
                // deps
                
                // function under test
                sutFix
            ]
        ) {
            mem in
            
            try mem.jit(ctx: ctx, fix: sutFix) {
                (entrypoint: _JitFunc) in
                
                entrypoint()
            }
        }
    }
    
    func testCompile__testFieldClosure() throws {
        typealias _JitFunc =  (@convention(c) (Int32) -> (Int32))
        let sutFix = 255
        try _compileAndLink(
            strip: false,
            [
                // deps
                28,
                // function under test
                sutFix
            ]
        ) {
            mem in
            
            try mem.jit(ctx: ctx, fix: sutFix) {
                (entrypoint: _JitFunc) in
                
                XCTAssertEqual(28, entrypoint(14))
            }
        }
    }
    
    /// This tests proper GetI8 behaviour in the wild.
    func testCompile__testGlobal() throws {
        let fix = 52
        
        typealias _JitFunc =  (@convention(c) () -> UnsafeRawPointer)
        try _compileAndLink(
            strip: false,
            [
                // deps
                // ...
                // entrypoint
                fix
            ]
        ) {
            mem in
            
            struct _String {
                let t: UnsafePointer<HLType_CCompat>
                let b: UnsafeRawPointer
                let length: Int32
            }
            
            try mem.jit(ctx: ctx, fix: fix) {
                (entrypoint: _JitFunc) in
                
                let x = entrypoint()
                let expected = "Hello Globals"
                let inst = x.bindMemory(to: _String.self, capacity: 1)
                
                XCTAssertEqual(Int(inst.pointee.length), expected.lengthOfBytes(using: .utf8))
                let s = String._wrapUtf16(from: .init(OpaquePointer(inst.pointee.b)))
                XCTAssertEqual(expected, s)
            }
        }
    }
    
    /// Test field access.
    func testCompile__testFieldAccess() throws {
        typealias _JitFunc =  (@convention(c) () -> Int32)
        try _compileAndLink(
            strip: false,
            [
                // deps
                27,
                // function under test
                Self.TEST_FIELD_ACCESS
            ]
        ) {
            mem in
            
            try mem.jit(ctx: ctx, fix: Self.TEST_FIELD_ACCESS) {
                (entrypoint: _JitFunc) in
                
                XCTAssertEqual(2, entrypoint())
            }
        }
    }
    
    func testCompile__testEnum() throws {
        typealias _JitFunc =  (@convention(c) () -> Int32)
        let sutFix = 256
        try _compileAndLink(
            strip: false,
            [
                // deps
                292,
                //
                sutFix
            ]
        ) {
            mem in
            
            try mem.jit(ctx: ctx, fix: sutFix) {
                (entrypoint: _JitFunc) in
                
                XCTAssertEqual(42, entrypoint())
            }
        }
    }
}

