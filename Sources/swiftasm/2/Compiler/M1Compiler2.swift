import Darwin

extension M1Compiler2 : CompilerUtilities2 {
    
}

protocol CompilerUtilities2 {
    func appendDebugPrintAligned4(_ val: String, builder: CpuOpBuffer);
}

typealias Registers2 = [any HLTypeProvider]

let OEnumIndex_impl: (@convention(c)(OpaquePointer)->(Int32)) = {
    _enum in
    
    let enumPtr: UnsafePointer<venum> = .init(_enum)
    return enumPtr.pointee.index
}

fileprivate func get_dyncast( to kind: HLTypeKind ) -> OpaquePointer {
    switch( kind ) {
    case .f32:
        return unsafeBitCast(LibHl._hl_dyn_castf, to: OpaquePointer.self)
    case .f64:
        return unsafeBitCast(LibHl._hl_dyn_castd, to: OpaquePointer.self)
    case .i32, .u16, .u8, .bool:
        return unsafeBitCast(LibHl._hl_dyn_casti, to: OpaquePointer.self)
    default:
        return unsafeBitCast(LibHl._hl_dyn_castp, to: OpaquePointer.self)
    }
}

let OInstanceClosure_impl: (@convention(c)(OpaquePointer)->(Int32)) = {
    _enum in
    
    let enumPtr: UnsafePointer<venum> = .init(_enum)
    return enumPtr.pointee.index
}

let OEnumField_impl: (@convention(c)(OpaquePointer, Int32, Int32)->(OpaquePointer)) = {
    _enum, constructIndex, fieldIndex in
    
    let enumPtr: UnsafePointer<venum> = .init(_enum)
    let constructPtr = enumPtr.pointee.t.pointee.tenum.pointee.constructs.advanced(by: Int(constructIndex))
    let result = constructPtr.pointee.offsets.advanced(by: Int(fieldIndex))
    return .init(result)
}

let OSetEnumField_impl: (@convention(c) (
    OpaquePointer,  // type
    Int32,          // field index
    Int32           // source
)->()) = {
    (_type, fieldIndex, source) in
    let type: UnsafePointer<venum> = .init(_type)
    let fieldPtr = type.pointee.t.pointee.tenum.pointee.constructs.pointee.offsets.advanced(by: Int(fieldIndex))
    let mFieldPtr: UnsafeMutablePointer<Int32> = .init(mutating: fieldPtr)
    mFieldPtr.pointee = source
    print("Done")
}

let OEnumAlloc_impl: (@convention(c) (
    OpaquePointer,  // type
    Int32           // construct index
)->(OpaquePointer)) = {
    _type, index in
    
    let type: UnsafePointer<HLType_CCompat> = .init(_type)
    let result = LibHl.hl_alloc_enum(.init(type), index)
    
    return .init(result)
}

let OMakeEnum_impl: (@convention(c) (
    OpaquePointer,  // type
    Int32,          // construct index
    Int32,          // arg count
    OpaquePointer,  // args (reg)
    OpaquePointer   // args (values in int64)
)->(OpaquePointer)) = {
    _type, index, argCount, _argRegs, _argValues in
    
    let argRegs: UnsafeMutableBufferPointer<Reg> =  .init(start: .init(_argRegs), count: Int(argCount))
    let argValues: UnsafeMutableBufferPointer<Int64> = .init(start: .init(_argValues), count: Int(argCount))
    let type: UnsafePointer<HLType_CCompat> = .init(_type)
    defer {
        argRegs.deallocate()
        argValues.deallocate()
        print("Deallocated")
    }
    
    let result = LibHl.hl_alloc_enum(.init(type), index)
    
    let cPtr = type.pointee.tenum.pointee.constructs.advanced(by: Int(index))
    assert(cPtr.pointee.nparams == argCount)
    
    let mutatingConstruct: UnsafeMutablePointer<HLEnumConstruct_CCompat> = .init(mutating: cPtr)
    for paramIx in (0..<Int(cPtr.pointee.nparams)) {
        let argValueInt32 = Int32(argValues[paramIx])
        let offsetPtr = cPtr.pointee.offsets.advanced(by: paramIx)
        let mutatingOffsetPtr: UnsafeMutablePointer<Int32> = .init(mutating: offsetPtr)
        mutatingOffsetPtr.pointee = argValueInt32
    }
    
    return .init(result)
}

let OToDyn_impl: (@convention(c) (/*dstType*/UnsafeRawPointer, /*srcType*/UnsafeRawPointer, /*dstVal*/Int64, /*srcVal*/Int64)->(UnsafeRawPointer)) = {
    (dstType, srcType, dst, src) in
    
    let dstTypeB = dstType.bindMemory(to: HLType_CCompat.self, capacity: 1)
    let srcTypeB = srcType.bindMemory(to: HLType_CCompat.self, capacity: 1)
    
    /*
     dst must be:
     - dyn
     - null (see mod2 fn@3)
     */
    assert(dstTypeB.kind == .dyn || dstTypeB.kind == .null)
    let res = LibHl.hl_alloc_dynamic(srcTypeB)  // use the source type
    
    var mutatingRes: UnsafeMutableRawPointer = .init(mutating: res)
    
    print("Setting to source: \(src)")
    
    switch(srcTypeB.pointee.kind) {
    case .i32:
        let srcI32 = Int32(truncatingIfNeeded: src)
        mutatingRes.advanced(by: 8).bindMemory(to: Int32.self, capacity: 1).pointee = srcI32
        mutatingRes.advanced(by: 8).bindMemory(to: Int32.self, capacity: 1).pointee = srcI32
        assert(res.pointee.i == srcI32)
    case .bool, .u8:
        let srcU8 = UInt8(truncatingIfNeeded: src)
        mutatingRes.advanced(by: 8).bindMemory(to: UInt8.self, capacity: 1).pointee = srcU8
        assert(res.pointee.b == (srcU8 > 0))
        assert(res.pointee.ui8 == srcU8)
    default:
        fatalError("Casting ToDyn from \(srcTypeB.pointee.kind) not implemented")
    }
    
    print("Checking for type. Actual: \(res.pointee.t.pointee.kind). Expected: \(srcTypeB.pointee.kind)")
    assert(res.pointee.t.pointee.kind == srcTypeB.pointee.kind)
    
    return .init(res)
}

// x0 through x7
let ARG_REGISTER_COUNT = 8
extension M1Compiler2 {
    /// Stack space should be allocated for first 8 function args (will be filled from registers) and
    /// any register, which is not part of args.
    /// - Parameters:
    ///   - regs:
    ///   - args:
    /// - Returns:
    func calcStackArgReq(regs unfilteredRegs: [any HLTypeKindProvider], args unfilteredArgs: [any HLTypeKindProvider])
    -> (Int16, [any HLTypeKindProvider])
    {
        let regs = unfilteredRegs.filter { $0.kind != .void }
        let args = unfilteredArgs.filter { $0.kind != .void }
        guard regs.prefix(args.count).map({ $0.kind }) == args.prefix(args.count).map({$0.kind}) else {
            fatalError(
                "Args must match the first registers (got \(args) and \(regs) respectively)"
            )
        }
        let stackArgs = Array( /* regs should be aligned with args */
            // IMPORTANT: args must come first
            args.prefix(ARG_REGISTER_COUNT) + regs.dropFirst(args.count)
        )
        
        let result = stackArgs.reduce(0) { $0 + Int16($1.hlRegSize) }
        return (StackInfo.roundUpStackReservation(result), stackArgs)
    }
    
    func appendLoad(reg: Register64, from vreg: Reg, kinds: [any HLTypeKindProvider], mem: CpuOpBuffer) {
        let offset = getRegStackOffset(kinds, vreg)
        appendLoad(reg: reg, from: vreg, kinds: kinds, offset: offset, mem: mem)
    }
    
    func appendLoad(reg: RegisterFP64, from vreg: Reg, kinds: [any HLTypeKindProvider], mem: CpuOpBuffer) {
        let offset = getRegStackOffset(kinds, vreg)
        appendLoad(reg: reg, from: vreg, kinds: kinds, offset: offset, mem: mem)
    }
    
    func appendSignMode(_ signed: Bool, reg: Register64, from vreg: Reg, kinds: [any HLTypeKindProvider], mem: CpuOpBuffer) {
        let vregKind = requireTypeKind(reg: vreg, from: kinds)
        switch(vregKind.hlRegSize, signed) {
        case (8, _):
            break
        case (4, true):
            mem.append(M1Op.sxtw(reg, reg.to32))
        case (4, false):
            mem.append(M1Op.uxtw(reg.to32, reg.to32))
        case (2, true):
            mem.append(M1Op.sxth(reg, reg.to32))
        case (2, false):
            mem.append(M1Op.uxth(reg.to32, reg.to32))
        case (1, true):
            mem.append(M1Op.sxtb(reg, reg.to32))
        case (1, false):
            mem.append(M1Op.uxtb(reg.to32, reg.to32))
        default:
            fatalError("Unknown size for setting size mode modifier")
        }
    }
    
    func appendLoad(reg: Register64, from vreg: Reg, kinds: [any HLTypeKindProvider], offset: ByteCount, mem: CpuOpBuffer) {
        let vregKind = requireTypeKind(reg: vreg, from: kinds)
        print("Loading \(reg) from vreg \(vreg) at offset \(offset) size \(vregKind.hlRegSize)")
        if vregKind.hlRegSize == 8 {
            mem.append(
                M1Op.ldr(reg, .reg64offset(.sp, offset, nil))
            )
        } else if vregKind.hlRegSize == 4 {
            mem.append(
                M1Op.ldr(reg.to32, .reg64offset(.sp, offset, nil))
            )
        } else if vregKind.hlRegSize == 2 {
            mem.append(
                M1Op.ldrh(reg.to32, .imm64(.sp, offset, nil))
            )
        } else if vregKind.hlRegSize == 1 {
            mem.append(
                M1Op.ldrb(reg.to32, .imm64(.sp, offset, nil))
            )
        } else if vregKind.hlRegSize == 0 {
            // nop
        } else {
            fatalError("Size must be 8, 4, 2, 1, or 0")
        }
    }
    
    func appendLoad(reg: RegisterFP64, from vreg: Reg, kinds: [any HLTypeKindProvider], offset: ByteCount, mem: CpuOpBuffer) {
        let vregKind = requireTypeKind(reg: vreg, from: kinds)
        print("Loading \(reg) from vreg \(vreg) at offset \(offset) size \(vregKind.hlRegSize)")
        if vregKind.hlRegSize == 8 {
            mem.append(
                M1Op.ldr(reg, .reg64offset(.sp, offset, nil))
            )
        } else if vregKind.hlRegSize == 4 {
            fatalError("32-bit load not implemented for fp registers")
//            mem.append(
//                M1Op.ldr(reg.to32, .reg64offset(.sp, offset, nil))
//            )
        } else if vregKind.hlRegSize == 2 {
            fatalError("16-bit load not implemented for fp registers")
//            mem.append(
//                M1Op.ldrh(reg.to32, .imm64(.sp, offset, nil))
//            )
        } else if vregKind.hlRegSize == 1 {
            fatalError("8-bit load not implemented for fp registers")
//            mem.append(
//                M1Op.ldrb(reg.to32, .imm64(.sp, offset, nil))
//            )
        } else if vregKind.hlRegSize == 0 {
            // nop
        } else {
            fatalError("Size must be 8, 4, 2, 1, or 0")
        }
    }
    
    func appendStore(reg: Register64, into vreg: Reg, kinds: [any HLTypeKindProvider], mem: CpuOpBuffer) {
        let vregKind = requireTypeKind(reg: vreg, from: kinds)
        let offset = getRegStackOffset(kinds, vreg)
        
        if vregKind.hlRegSize == 8 {
            mem.append(
                PseudoOp.debugMarker("Storing 8 bytes in vreg \(vreg)"),
                M1Op.str(reg, .reg64offset(.sp, offset, nil))
            )
        } else if vregKind.hlRegSize == 4 {
            mem.append(
                PseudoOp.debugMarker("Storing 4 bytes in vreg \(vreg)"),
                M1Op.str(reg.to32, .reg64offset(.sp, offset, nil))
            )
        } else if vregKind.hlRegSize == 2 {
            mem.append(
                PseudoOp.debugMarker("Storing 2 bytes in vreg \(vreg)"),
                M1Op.strh(reg.to32, .imm64(.sp, offset, nil))
            )
        } else if vregKind.hlRegSize == 1 {
            mem.append(
                PseudoOp.debugMarker("Storing 1 byte in vreg \(vreg)"),
                M1Op.strb(reg.to32, .imm64(.sp, offset, nil))
            )
        } else if vregKind.hlRegSize == 0 {
            // nop
        } else {
            fatalError("Size must be 8, 4, 2, 1, or 0")
        }
    }
    
    func appendStore(reg: RegisterFP64, into vreg: Reg, kinds: [any HLTypeKindProvider], mem: CpuOpBuffer) {
        let vregKind = requireTypeKind(reg: vreg, from: kinds)
        let offset = getRegStackOffset(kinds, vreg)
        
        if vregKind.hlRegSize == 8 {
            mem.append(
                PseudoOp.debugMarker("Storing 8 bytes in vreg \(vreg)"),
                M1Op.str(reg, .reg64offset(.sp, offset, nil))
            )
        } else if vregKind.hlRegSize == 4 {
            fatalError("32-bit str not implemented for fp registers")
//            mem.append(
//                PseudoOp.debugMarker("Storing 4 bytes in vreg \(vreg)"),
//                M1Op.str(reg.to32, .reg64offset(.sp, offset, nil))
//            )
        } else if vregKind.hlRegSize == 2 {
            fatalError("16-bit str not implemented for fp registers")
//            mem.append(
//                PseudoOp.debugMarker("Storing 2 bytes in vreg \(vreg)"),
//                M1Op.strh(reg.to32, .imm64(.sp, offset, nil))
//            )
        } else if vregKind.hlRegSize == 1 {
            fatalError("8-bit str not implemented for fp registers")
//            mem.append(
//                PseudoOp.debugMarker("Storing 1 byte in vreg \(vreg)"),
//                M1Op.strb(reg.to32, .imm64(.sp, offset, nil))
//            )
        } else if vregKind.hlRegSize == 0 {
            // nop
        } else {
            fatalError("Size must be 8, 4, 2, 1, or 0")
        }
    }
    
    /// Holds information about the stack reservations for a function.
    struct StackInfo {
        /// Unrounded space used for virtual regs
        let reservedForVreg: ByteCount
        
        /// Unrounded stack space used for trap contexts
        let reservedForTrapContexts: ByteCount
        
        var unroundedTotal: ByteCount {
            reservedForVreg + reservedForTrapContexts
        }
        
        /// Rounded value that can be used to move the stack pointer
        var total: ByteCount {
            ByteCount(Self.roundUpStackReservation(Int16(unroundedTotal)))
        }
        
        var trapContextOffset: Int16 {
            Int16(reservedForVreg)
        }
        
        /// Stack pointer (SP) movements must be aligned to 16-bytes
        /// - Parameter val: unrounded byte count needed for the stack
        /// - Returns: value rounded up to nearest multiple of 16
        static func roundUpStackReservation(
            _ val: Int16
        ) -> Int16 {
            guard val % 16 != 0 else { return val }
            return (val + (16 &- 1)) & (0 &- 16)
        }
    }
    
    /*
     First 7 args are in registers [x0;x7]. Others are on the stack.
     Stack should be extended to account for data which is in registers.
     Subsequently data should be moved from regs to stack, to enable use of all registers.
     */
    @discardableResult func appendStackInit(
        _ unfilteredRegs: [any HLTypeKindProvider],
        args unfilteredArgs: [any HLTypeKindProvider],
        builder: CpuOpBuffer,
        prologueSize: ByteCount,
        trapContextsNeeded: Int = 0
    ) throws -> StackInfo {
        // test mismatched before filtering
        let unfilteredArgRegCount = min(unfilteredArgs.count, ARG_REGISTER_COUNT)
        guard
            unfilteredRegs.prefix(unfilteredArgRegCount).map({ $0.kind })
        == unfilteredArgs.prefix(unfilteredArgRegCount).map({ $0.kind })
        else {
            throw GlobalError.invalidOperation(
                "Up to first \(ARG_REGISTER_COUNT) registers must be the same for a function and its type.args"
            )
        }
        
        // move ALL args in continuous space (either from regs, or on sp)
        let vregStackSize_unr = unfilteredRegs.reduce(Int16(0)) { $0 + Int16($1.hlRegSize) }
        
        let trapCtxStackSize_unr = Int16(trapContextsNeeded) * Int16(MemoryLayout<HLTrapCtx_CCompat>.size)
        
        let stackInfo = StackInfo(
            reservedForVreg: ByteCount(vregStackSize_unr),
            reservedForTrapContexts: ByteCount(trapCtxStackSize_unr))
        
        guard stackInfo.total > 0 else {
            builder.append(PseudoOp.debugMarker("No extra stack space needed"))
            return stackInfo
        }
        
        builder.append(
            PseudoOp.debugMarker("Reserving \(stackInfo.total) bytes for entire stack"),
            M1Op.subImm12(X.sp, X.sp, try .i(stackInfo.total))
        )
        
        var offset: ByteCount = 0
        var overflowOffset: ByteCount = stackInfo.total + prologueSize // for regs passed in via stack
        
        // Now move all data from (stack/registers) to (stack) in the expected layout
        for (ix, reg) in unfilteredRegs.filter({ $0.hlRegSize > 0 }).enumerated() {

            Swift.assert(reg.hlRegSize > 0, "empty registers have to be filtered out earlier to not affect register index")

            let needLoad = ix >= ARG_REGISTER_COUNT
            let regToUse: Register64 = needLoad ? .x1 : Register64(rawValue: UInt8(ix))!
            switch (needLoad, reg.hlRegSize) {
            case (false, _):
                break
            case (true, let regSize):
                print("stack init ldrVreg. overflow offset: \(overflowOffset)")
                builder.append(PseudoOp.ldrVreg(regToUse, overflowOffset, regSize))
                overflowOffset += regSize
            }

            print("stack init strVreg. overflow offset: \(offset)")
            builder.append(PseudoOp.strVreg(regToUse, offset, reg.hlRegSize))

            print("Inc offset by \(reg.hlRegSize) from \(reg)")
            offset += reg.hlRegSize
        }
        
        return stackInfo
    }
    
    func appendDebugPrintRegisterAligned4(_ reg: Register64, prepend: String? = nil, builder: CpuOpBuffer) {
        guard let printfAddr = dlsym(dlopen(nil, RTLD_LAZY), "printf") else {
            fatalError("No printf addr")
        }
        
        var adr = RelativeDeferredOffset()
        var jmpTarget = RelativeDeferredOffset()
        let str: String
        if let prepend = prepend {
            str = "[jitdebug] [\(prepend)] Register \(reg): %p (%llu)\n\0"
        } else {
            str = "[jitdebug] Register \(reg): %p (%llu)\n\0"
        }
        
        guard stripDebugMessages == false else {
            builder.append(PseudoOp.debugMarker("(debug message printing stripped)"))
            return
        }
        builder.append(PseudoOp.debugMarker("Printing debug register: \(reg)"))
        
        guard reg.rawValue <= X.x18.rawValue else {
            fatalError("reg \(reg) not supported")
        }
        
        builder.append(
            // Stash registers we'll use (so we can reset)
            M1Op.subImm12(X.sp, X.sp, Imm12Lsl12(160)),
            M1Op.str(Register64.x0, .reg64offset(.sp, 8, nil)),
            M1Op.str(reg, .reg64offset(.sp, 0, nil)),
            M1Op.stp((Register64.x1, Register64.x2), .reg64offset(.sp, 16, nil)),
            M1Op.stp((Register64.x3, Register64.x4), .reg64offset(.sp, 32, nil)),
            M1Op.stp((Register64.x5, Register64.x6), .reg64offset(.sp, 48, nil)),
            M1Op.stp((Register64.x7, Register64.x8), .reg64offset(.sp, 64, nil)),
            M1Op.stp((Register64.x9, Register64.x10), .reg64offset(.sp, 80, nil)),
            M1Op.stp((Register64.x11, Register64.x12), .reg64offset(.sp, 96, nil)),
            M1Op.stp((Register64.x13, Register64.x14), .reg64offset(.sp, 112, nil)),
            M1Op.stp((Register64.x15, Register64.x16), .reg64offset(.sp, 128, nil)),
            M1Op.stp((Register64.x17, Register64.x18), .reg64offset(.sp, 144, nil))
        )
        adr.start(at: builder.byteSize)
        builder.append(M1Op.adr64(.x0, adr))
        builder.append(M1Op.adr64(.x1, adr))
        
        builder.append(
            PseudoOp.mov(.x16, printfAddr),
            M1Op.blr(.x16),
            // restore
            M1Op.ldr(Register64.x0, .reg64offset(.sp, 8, nil)),
            M1Op.ldp((Register64.x1, Register64.x2), .reg64offset(.sp, 16, nil)),
            M1Op.ldp((Register64.x3, Register64.x4), .reg64offset(.sp, 32, nil)),
            M1Op.ldp((Register64.x5, Register64.x6), .reg64offset(.sp, 48, nil)),
            M1Op.ldp((Register64.x7, Register64.x8), .reg64offset(.sp, 64, nil)),
            M1Op.ldp((Register64.x9, Register64.x10), .reg64offset(.sp, 80, nil)),
            M1Op.ldp((Register64.x11, Register64.x12), .reg64offset(.sp, 96, nil)),
            M1Op.ldp((Register64.x13, Register64.x14), .reg64offset(.sp, 112, nil)),
            M1Op.ldp((Register64.x15, Register64.x16), .reg64offset(.sp, 128, nil)),
            M1Op.ldp((Register64.x17, Register64.x18), .reg64offset(.sp, 144, nil)),
            try! M1Op._add(X.sp, X.sp, 160)
        )
        
        jmpTarget.start(at: builder.byteSize)
        builder.append(M1Op.b(jmpTarget))
        adr.stop(at: builder.byteSize)
        builder.append(PseudoOp.ascii(str)).align(4)
        
        Swift.assert(builder.byteSize % 4 == 0)
        jmpTarget.stop(at: builder.byteSize)
    }
    
    func appendDebugPrintAligned4(_ val: String, builder: CpuOpBuffer) {
        var adr = RelativeDeferredOffset()
        var jmpTarget = RelativeDeferredOffset()
        let str = "[jitdebug] \(val)\n"
        builder.append(PseudoOp.debugMarker("Printing debug message: \(val)"))
        guard stripDebugMessages == false else {
            builder.append(PseudoOp.debugMarker("(debug message printing stripped)"))
            return
        }
        builder.append(
            // Stash registers we'll use (so we can reset)
            M1Op.subImm12(X.sp, X.sp, Imm12Lsl12(160)),
            M1Op.str(Register64.x0, .reg64offset(.sp, 8, nil)),
            M1Op.str(Register64.x19, .reg64offset(.sp, 0, nil)),
            M1Op.stp((Register64.x1, Register64.x2), .reg64offset(.sp, 16, nil)),
            M1Op.stp((Register64.x3, Register64.x4), .reg64offset(.sp, 32, nil)),
            M1Op.stp((Register64.x5, Register64.x6), .reg64offset(.sp, 48, nil)),
            M1Op.stp((Register64.x7, Register64.x8), .reg64offset(.sp, 64, nil)),
            M1Op.stp((Register64.x9, Register64.x10), .reg64offset(.sp, 80, nil)),
            M1Op.stp((Register64.x11, Register64.x12), .reg64offset(.sp, 96, nil)),
            M1Op.stp((Register64.x13, Register64.x14), .reg64offset(.sp, 112, nil)),
            M1Op.stp((Register64.x15, Register64.x16), .reg64offset(.sp, 128, nil)),
            M1Op.stp((Register64.x17, Register64.x18), .reg64offset(.sp, 144, nil))
        )
        
        builder.append(
            // unix write system call
            M1Op.movz64(.x0, 1, nil)
        )
        adr.start(at: builder.byteSize)
        builder.append(
            M1Op.adr64(.x1, adr),
            M1Op.movz64(.x2, UInt16(str.count), nil),
            M1Op.movz64(.x16, 4, nil),
            M1Op.svc(0x80),
            
            // restore
            M1Op.ldr(Register64.x0, .reg64offset(.sp, 8, nil)),
            M1Op.ldr(Register64.x19, .reg64offset(.sp, 0, nil)),
            M1Op.ldp((Register64.x1, Register64.x2), .reg64offset(.sp, 16, nil)),
            M1Op.ldp((Register64.x3, Register64.x4), .reg64offset(.sp, 32, nil)),
            M1Op.ldp((Register64.x5, Register64.x6), .reg64offset(.sp, 48, nil)),
            M1Op.ldp((Register64.x7, Register64.x8), .reg64offset(.sp, 64, nil)),
            M1Op.ldp((Register64.x9, Register64.x10), .reg64offset(.sp, 80, nil)),
            M1Op.ldp((Register64.x11, Register64.x12), .reg64offset(.sp, 96, nil)),
            M1Op.ldp((Register64.x13, Register64.x14), .reg64offset(.sp, 112, nil)),
            M1Op.ldp((Register64.x15, Register64.x16), .reg64offset(.sp, 128, nil)),
            M1Op.ldp((Register64.x17, Register64.x18), .reg64offset(.sp, 144, nil)),
            try! M1Op._add(X.sp, X.sp, 160)
        )
        jmpTarget.start(at: builder.byteSize)
        builder.append(M1Op.b(jmpTarget))
        adr.stop(at: builder.byteSize)
        builder.append(PseudoOp.ascii(str)).align(4)
        
        jmpTarget.stop(at: builder.byteSize)
    }
    
    func appendSystemExit(_ code: UInt8, builder: CpuOpBuffer) {
        builder.append(
            M1Op.movz64(.x0, UInt16(code), nil),
            M1Op.movz64(.x16, 1, nil),
            M1Op.svc(0x80)
        )
    }
    
    func appendSystemExit_CodeInX0(builder: CpuOpBuffer) {
        builder.append(
            M1Op.movz64(.x16, 1, nil),
            M1Op.svc(0x80)
        )
    }
    
    /// Returns the amount of change for SP
    func appendPrologue(builder: CpuOpBuffer) -> ByteCount {
        appendDebugPrintAligned4("Starting prologue and reserving 16", builder: builder)
        builder.append(
            M1Op.stp((.x29_fp, .x30_lr), .reg64offset(.sp, -16, .pre)),
            M1Op.movr64(.x29_fp, .sp)
        )
        return 16
    }
    
    func appendEpilogue(builder: CpuOpBuffer) {
        appendDebugPrintAligned4("Starting epilogue", builder: builder)
        builder.append(
            M1Op.ldp((.x29_fp, .x30_lr), .reg64offset(.sp, 16, .post))
        )
        appendDebugPrintAligned4("Finished epilogue", builder: builder)
    }
}

class M1Compiler2 {
    let emitter = EmitterM1()
    let ctx: CCompatJitContext
    let stripDebugMessages: Bool
    
    static let logger = LoggerFactory.create(M1Compiler2.self)
    
    init(ctx: CCompatJitContext, stripDebugMessages: Bool = false) {
        self.stripDebugMessages = stripDebugMessages
        self.ctx = ctx
    }
    
    func assertEnoughRegisters(_ ix: Reg, regs: Registers2) {
        guard ix < regs.count else {
            fatalError("Not enough registers. Expected \(ix) to be available. Got: \(regs)")
        }
    }
    
    func requireTypeMemory(reg: Reg, regs: Registers2) -> UnsafeRawPointer /*UnsafePointer<HLType_CCompat>*/ {
        assertEnoughRegisters(reg, regs: regs)
        
        let reg = regs[Int(reg)]
        return reg.ccompatAddress
    }
    
    func requireType(reg: Reg, regs: Registers2) -> any HLTypeProvider {
        assertEnoughRegisters(reg, regs: regs)
        
        return regs[Int(reg)]
    }
    
    func requireFieldOffset(fieldRef: Int, objIx: Reg, regs: Registers2) -> Int64 {
        let typ = requireType(reg: objIx, regs: regs)
        
        let ptr: UnsafePointer<HLType_CCompat> = .init(OpaquePointer(typ.ccompatAddress))
        
        switch(typ.kind) {
        case .obj:
            fallthrough
        case .struct:
            // if this is not set, the module has not
            // been initialized
            let rt = ptr.pointee.obj.pointee.getRt(ptr)
            return Int64(rt.pointee.fields_indexes.advanced(by: fieldRef).pointee)
        default:
            fatalError("Can not get field offset for obj type \(ptr.pointee.kind)")
        }
    }
    
    func requireTypeAddress(reg: Reg, from regs: [any HLTypeProvider]) -> UnsafeRawPointer {
        guard reg < regs.count else {
            let _debug = regs as [any OverrideCustomDebugStringConvertible]
            fatalError("requireTypeAddress(reg:from:): Not enough registers. Expected \(reg) to be available. Got: \(_debug._overrideDebugDescription)")
        }
        
        return regs[Int(reg)].ccompatAddress
    }
    
    func requireTypeKind(reg: Reg, from resolvedRegs: [any HLTypeKindProvider]) -> HLTypeKind {
        guard reg < resolvedRegs.count else {
            let _debug = resolvedRegs as [any OverrideCustomDebugStringConvertible]
            fatalError("requireType(reg:from:): Not enough registers. Expected \(reg) to be available. Got: \(_debug._overrideDebugDescription)")
        }
        
        return resolvedRegs[Int(reg)].kind
    }
    
    func requireTypeSizeLsl(reg: Reg, from resolvedRegs: [any HLTypeKindProvider]) -> UInt8 {
        let kind = requireTypeKind(reg: reg, from: resolvedRegs)
        switch(kind.hlRegSize) {
        case 8: return 3
        case 4: return 2
        case 2: return 1
        case 1: return 0
        default:
            fatalError("Unsupported size")
        }
    }
    
    func requireTypeKind(reg: Reg, from resolvedRegs: [any HLTypeKindProvider], shouldMatch: any HLTypeKindProvider) -> any HLTypeKindProvider {
        let kind = requireTypeKind(reg: reg, from: resolvedRegs)
        guard kind.kind == shouldMatch.kind else {
            fatalError("Expected reg \(reg) to be \(shouldMatch) but was \(kind)")
        }
        return kind
    }
    
    func assertKind(_ op: HLOpCode, _ actual: any HLTypeKindProvider, _ expected: HLTypeKind) {
        guard expected.kind == actual.kind else {
            fatalError("\(op): type kind must be \(expected) but got \(actual)")
        }
    }
    
    func assert(reg: Reg, from: [any HLTypeKindProvider], matchesCallArg argReg: Reg, inFun callable: any Callable2) {
        assert(reg: reg, from: from, matchesCallArg: argReg, inFunArgs: callable.argsProvider)
    }
    
    func assert(reg: Reg, from: [any HLTypeKindProvider], matchesCallArg argReg: Reg, inFunArgs argsProvider: [any HLTypeProvider]) {
        guard from.count > reg else {
            fatalError(
                "Register with index \(reg) does not exist. Available registers: \(from)."
            )
        }
        guard argsProvider.count > argReg else {
            fatalError("Expected args to have index \(argReg) but got \(argsProvider)")
        }
        let regKind = from[Int(reg)]
        let argKind = argsProvider[Int(argReg)].kind
        guard argKind == .dyn || regKind.kind == .dyn || regKind.kind == argKind.kind else {
            fatalError(
                "Register \(reg) kind \(regKind) expected to match arg \(argReg) but arg was \(argKind) "
            )
        }
    }
    
    func assert(reg: Reg, from: [any HLTypeKindProvider], matches type: any HLTypeKindProvider) {
        guard from.count > reg else {
            fatalError(
                "Register with index \(reg) does not exist. Available registers: \(from)."
            )
        }
        guard from[Int(reg)].kind == type.kind else {
            fatalError(
                "Register \(reg) expected to be \(type.kind) but is \(from[Int(reg)])"
            )
        }
    }
    
    func assert(reg: Reg, from: [any HLTypeKindProvider], is target: any HLTypeKindProvider) {
        guard from.count > reg else {
            fatalError(
                "Register with index \(reg) does not exist. Available registers: \(from)."
            )
        }
        guard target.kind == .dyn || from[Int(reg)].kind == .dyn || target.kind == from[Int(reg)].kind else {
            fatalError(
                "Register \(reg) expected to be \(target.kind) but is \(from[Int(reg)].kind)"
            )
        }
    }
    
    func assert(reg: Reg, from: [any HLTypeKindProvider], in targets: [any HLTypeKindProvider]) {
        guard from.count > reg else {
            fatalError(
                "Register with index \(reg) does not exist. Available registers: \(from)."
            )
        }
        
        guard targets.contains(where: { $0.kind == from[Int(reg)].kind }) else {
            fatalError(
                "Register \(reg) expected to be one of \(targets) but is \(from[Int(reg)])"
            )
        }
    }
    
    func getRegStackOffset(_ regs: [any HLTypeKindProvider], _ ix: Reg) -> ByteCount {
        var result = ByteCount(0)
        for i in 0..<ix {
            result += regs[Int(i)].hlRegSize
        }
        printerr("Stack offset for \(ix) is \(result)")
        return result
    }
    
    func getFieldOffset(_ objData: any HLTypeObjProvider, _ field: Int) -> ByteCount {
        var startOffset = ByteCount(8)  // hl_type* pointer at start of obj/struct
        for ix in 0..<field {
            let fieldToSkip = objData.fieldsProvider[ix].typeProvider.kind.hlRegSize
            startOffset += fieldToSkip
        }
        return startOffset
    }
    
    func push(to buffer: ByteBuffer, _ ops: M1Op...) throws {
        for op in ops { buffer.push(try emitter.emit(for: op)) }
    }
    
    /// Will compile and update the JIT context with the functions addresses.
    /// - Parameters:
    ///   - findex:
    ///   - mem:
    /// - Returns:
    func compile(findex fix: RefFun, into mem: CpuOpBuffer) throws
    {
        guard let compilable = try ctx.getCompilable(findex: fix) else {
            throw GlobalError.invalidValue("Function (findex=\(fix)) not found.")
        }
        
        // TODO: mark as compiled
        try compile(compilable: compilable, into: mem)
    }
    
    // MARK: compile
    func compile(compilable: any Compilable2, into mem: CpuOpBuffer) throws
    {
        defer {
            ctx.funcTracker.compiled(compilable.findex)
        }
        
        /* we need to allocate trap contexts on the stack 
         */
        var availableTrapIx: Int64 = 0  // each OTrap will increment, and OEndTrap will decrement
        let trapCount = compilable.ops.filter({
            guard case .OTrap(_, _) = $0 else {
                return false
            }
            return true
        }).count
        let endtrapCount = compilable.ops.filter({
            guard case .OEndTrap(_) = $0 else {
                return false
            }
            return true
        }).count
        Swift.assert(trapCount == endtrapCount)
        
        // grab it before it changes from prologue
        // let memory = mem.getDeferredPosition()
        let regs = compilable.regsProvider
        let args = compilable.argsProvider
        
        let fix = compilable.findex

        // Check memory
        regs.forEach { print("reg \($0.kind) == mem \($0.ccompatAddress)") }
        args.forEach { print("arg \($0.kind) == mem \($0.ccompatAddress)") }
        
        guard !compilable.linkableAddress.hasOffset else {
            throw GlobalError.invalidOperation("Can not compile function (findex=\(fix)) because it already has been compiled and linked. \(compilable.address)")
        }
        
        compilable.linkableAddress.setOffset(mem.byteSize)

        // if we need to return early, we jump to these
        var retTargets: [RelativeDeferredOffset] = []

        print("Compiling function \(fix) at linkable address \(compilable.address)")
        print("REGS: \n--" + regs.map { String(reflecting: $0) }.joined(separator: "\n--"))
        //        print("OPS: \n--" + funPtr.pointee.ops.map { String(reflecting: $0) }.joined(separator: "\n--"))

        mem.append(PseudoOp.debugMarker("==> STARTING FUNCTION \(fix)"))
        let prologueSize = appendPrologue(builder: mem)
        let stackInfo = try appendStackInit(
            regs,
            args: compilable.argsProvider,
            builder: mem,
            prologueSize: prologueSize,
            trapContextsNeeded: trapCount
        )

        appendDebugPrintAligned4(
            "Entering function \(fix)@\(compilable.address)",
            builder: mem
        )
        

        let addrBetweenOps: [DeferredImmediate<Immediate19>] = (0..<compilable.ops.count).map { _ in
            return DeferredImmediate()
        }

        for (currentInstruction, op) in compilable.ops.enumerated() {

            addrBetweenOps[currentInstruction].finalize(try Immediate19(mem.byteSize))

            mem.append(
                PseudoOp.debugMarker("Marking position for \(currentInstruction) at \(mem.byteSize)")
            )

            print("f\(compilable.findex): #\(currentInstruction): \(op.debugDescription)")
            appendDebugPrintAligned4("f\(compilable.findex): #\(currentInstruction): \(op.debugDescription)", builder: mem)
            
            switch op {
            case .ORet(let dst):
                // store
                let dstStackOffset = getRegStackOffset(regs, dst)
                let dstKind = requireTypeKind(reg: dst, from: regs)
                
                if dstKind.hlRegSize > 0 {
                    if dstKind.kind == .f64 || dstKind.kind == .f32 {
                        appendDebugPrintAligned4("Returning FP stack offset \(dstStackOffset)", builder: mem)
                        appendLoad(reg: D.d0, from: dst, kinds: regs, mem: mem)
                    } else {
                        appendDebugPrintAligned4("Returning I stack offset \(dstStackOffset)", builder: mem)
                        appendLoad(reg: X.x0, from: dst, kinds: regs, mem: mem)
                        appendDebugPrintRegisterAligned4(X.x0, prepend: "ORet", builder: mem)
                    }
                }

                // jmp to end (NOTE: DO NOT ADD ANYTHING BETWEEN .start() and mem.append()
                var retTarget = RelativeDeferredOffset()
                print("Starting retTarget at \(mem.byteSize)")
                retTarget.start(at: mem.byteSize)
                retTargets.append(retTarget)
                mem.append(M1Op.b(retTarget)
                )

            case .OCall0(let dst, let funRef):
                let fn = try ctx.requireCallable(findex: funRef)
                
                ctx.funcTracker.referenced2(fn)
  
                assert(
                    reg: dst,
                    from: regs,
                    matches: fn.retProvider
                )

                let dstStackOffset = getRegStackOffset(regs, dst)
                let dstKind = requireTypeKind(reg: dst, from: regs)

                mem.append(
                    PseudoOp.debugMarker("Call0 fn@\(funRef) -> \(dst)"),
                    PseudoOp.mov(.x10, fn.address),
                    M1Op.blr(.x10),
                    PseudoOp.strVreg(X.x0, dstStackOffset, dstKind.hlRegSize)
                )
            case .OCall1(let dst, let fun, let arg0):
                try __ocalln(
                    dst: dst,
                    funIndex: fun,
                    regs: regs,
                    args: [arg0],
                    reservedStackBytes: stackInfo.total,
                    mem: mem)
            case .OCall3(let dst, let fun, let arg0, let arg1, let arg2):
                
                if compilable.findex == 342 && currentInstruction == 27 {
                    struct _String {
                        let t: UnsafePointer<HLType_CCompat>
                        let bytes: UnsafePointer<CChar16>
                        let length: Int32
                    }
                    let _c: (@convention(c) (OpaquePointer, OpaquePointer, Int32)->()) = {
                        strAPtr, strBPtr, ix in
                        
                        let a: UnsafePointer<_String> = .init(strAPtr)
                        let b: UnsafePointer<_String> = .init(strBPtr)
                        
                        print("Ac:", a.pointee.length)
                        print("A: ", a.pointee.bytes.stringValue)
                        print("Bc:", b.pointee.length)
                        print("B: ", b.pointee.bytes.stringValue)
                        
                        fatalError("here")
                    }
                    appendLoad(reg: X.x0, from: arg0, kinds: regs, mem: mem)
                    appendLoad(reg: X.x1, from: arg1, kinds: regs, mem: mem)
                    appendLoad(reg: X.x2, from: arg1, kinds: regs, mem: mem)
                    mem.append(
                        PseudoOp.mov(X.x10, unsafeBitCast(_c, to: OpaquePointer.self)),
                        M1Op.blr(X.x10)
                    )
                }
                
                
                try __ocalln(
                    dst: dst,
                    funIndex: fun,
                    regs: regs,
                    args: [arg0, arg1, arg2],
                    reservedStackBytes: stackInfo.total,
                    mem: mem)
            case .OCall4(let dst, let fun, let arg0, let arg1, let arg2, let arg3):
                try __ocalln(
                    dst: dst,
                    funIndex: fun,
                    regs: regs,
                    args: [arg0, arg1, arg2, arg3],
                    reservedStackBytes: stackInfo.total,
                    mem: mem)
            case .OCallClosure(let dst, let closureObject, let args):
                assert(reg: closureObject, from: regs, matches: HLTypeKind.fun)
                
                let dstType = self.requireType(reg: dst, regs: regs)
                let clType = self.requireType(reg: closureObject, regs: regs)
                assert(reg: closureObject, from: regs, is: HLTypeKind.fun)
                
                // vclosure offsets
                let funOffset: Int64 = 8
                let hasValueOffset: Int64 = 16
                let valueOffset: Int64 = 24
                
                if (dstType.kind == .dyn) {
                    /*
                     needs:
                     // ASM for {
                     //    vdynamic *args[] = {args};
                     //  vdynamic *ret = hl_dyn_call(closure,args,nargs);
                     //  dst = hl_dyncast(ret,t_dynamic,t_dst);
                     // }
                     */
                    fatalError("not implemented")
                } else {
                    // ASM for  if( c->hasValue ) c->fun(value,args) else c->fun(args)
                    
                    appendLoad(reg: X.x10, from: closureObject, kinds: regs, mem: mem)
                    appendDebugPrintRegisterAligned4(X.x10, builder: mem)
                    
                    var jmpTargetHasValue = RelativeDeferredOffset()
                    var jmpTargetFinish = RelativeDeferredOffset()

                    mem.append(
                        M1Op.ldr(X.x0, .reg64offset(X.x10, hasValueOffset, nil)),
                        M1Op.movz64(X.x1, 0, nil),
                        M1Op.cmp(X.x0, X.x1)
                    )

                    appendDebugPrintAligned4("CHECKING TARGET VALUE", builder: mem)
                    mem.append(
                        PseudoOp.withOffset(
                            offset: &jmpTargetHasValue,
                            mem: mem,
                            M1Op.b_ne(try! Immediate19(jmpTargetHasValue.value))
                        )
                    )
                    appendDebugPrintAligned4("TARGET HAS NO VALUE", builder: mem)
                    // MARK: no target value
                    try __ocall_impl(
                        dst: dst,
                        funType: clType,
                        appendCall: { buff in
                            appendLoad(reg: X.x10, from: closureObject, kinds: regs, mem: buff)
                            buff.append(
                                M1Op.ldr(X.x15, .reg64offset(X.x10, funOffset, nil)),
                                M1Op.blr(X.x15)
                            )
                        },
                        regs: regs,
                        preArgs: [],
                        args: args,
                        reservedStackBytes: stackInfo.total,
                        mem: mem
                    )
                    
                    mem.append(
                        PseudoOp.withOffset(
                            offset: &jmpTargetFinish,
                            mem: mem,
                            M1Op.b(jmpTargetFinish)
                        )
                    )

                    jmpTargetHasValue.stop(at: mem.byteSize)
                    appendDebugPrintAligned4("TARGET HAS VALUE", builder: mem)
                    try __ocall_impl(
                        dst: dst,
                        funType: clType,
                        appendCall: { buff in
                            appendLoad(reg: X.x10, from: closureObject, kinds: regs, mem: buff)
                            buff.append(
                                M1Op.ldr(X.x15, .reg64offset(X.x10, funOffset, nil)),
                                M1Op.blr(X.x15)
                            )
                        },
                        regs: regs,
                        preArgs: [
                            ({
                                buff, reg in
                                
                                guard reg != X.x19 else { fatalError("X.x19 can not be loaded") }
                                
                                self.appendLoad(reg: X.x19, from: closureObject, kinds: regs, mem: buff)
                                buff.append(
                                    M1Op.ldr(reg, .reg64offset(X.x19, valueOffset, nil))
                                )
                            },
                             HLTypeKind.dyn
                             )
                        ],
                        args: args,
                        reservedStackBytes: stackInfo.total,
                        mem: mem
                    )
                    
                    jmpTargetFinish.stop(at: mem.byteSize)
                    appendDebugPrintAligned4("Exiting OCallClosure", builder: mem)
                }
            case .OCallN(let dst, let fun, let args):
                try __ocalln(
                    dst: dst,
                    funIndex: fun,
                    regs: regs,
                    args: args,
                    reservedStackBytes: stackInfo.total,
                    mem: mem)
            case .OCall2(let dst, let fun, let arg0, let arg1):
                try __ocalln(
                    dst: dst,
                    funIndex: fun,
                    regs: regs,
                    args: [arg0, arg1],
                    reservedStackBytes: stackInfo.total,
                    mem: mem)
                
                // MARK: --
                if compilable.findex == 33 {
                    let _c: (@convention(c)(OpaquePointer)->()) = {
                        _ptr in
                        
                        let ptr: UnsafePointer<vdynamic> = .init(_ptr)
                        print("# OSafeCast result OCall2: ", ptr.pointee.i)
                    }
                    let _cAddr = unsafeBitCast(_c, to: OpaquePointer.self)
                    mem.append(PseudoOp.mov(X.x15, _cAddr), M1Op.blr(X.x15))
                }
                // MARK: --
                
            case .ONew(let dst):
                appendDebugPrintAligned4("Entering ONew", builder: mem)
                // LOOK AT: https://github.com/HaxeFoundation/hashlink/blob/284301f11ea23d635271a6ecc604fa5cd902553c/src/jit.c#L3263
                let typeToAllocate = requireTypeKind(reg: dst, from: regs)

                let allocFunc_jumpTarget: UnsafeRawPointer

                // Do we need to move the dst value in X0 for the alloc func (e.g. hl_alloc_dynobj
                // takes no args, but hl_alloc_obj does)
                var needX0 = true

                switch(typeToAllocate.kind) {
                case .struct:
                    fallthrough
                case .obj:
                    mem.append(
                        PseudoOp.debugMarker("Using hl_alloc_obj to allocate reg \(dst))")
                    )
                    allocFunc_jumpTarget = unsafeBitCast(LibHl._hl_alloc_obj, to: UnsafeRawPointer.self)
                case .dynobj:
                    mem.append(
                        PseudoOp.debugMarker("Using hl_alloc_dynobj to allocate reg \(dst))")
                    )
                    allocFunc_jumpTarget = unsafeBitCast(LibHl._hl_alloc_dynobj, to: UnsafeRawPointer.self)
                    needX0 = false
                case .virtual:
                    mem.append(
                        PseudoOp.debugMarker("Using hl_alloc_virtual to allocate reg \(dst))")
                    )
                    allocFunc_jumpTarget = unsafeBitCast(LibHl._hl_alloc_virtual, to: UnsafeRawPointer.self)
                default:
                    fatalError("ONew not implemented for \(typeToAllocate)")
                }

                if needX0 {
                    let dstTypeAddr = requireTypeAddress(reg: dst, from: regs)
                    mem.append(
                        PseudoOp.debugMarker("Moving reg address \(dstTypeAddr) in .x0"),
                        PseudoOp.mov(.x0, dstTypeAddr)
                    )
                } else {
                    mem.append(
                        PseudoOp.debugMarker("Not moving reg \(dst) in x0 b/c alloc func doesn't need it")
                    )
                }

                let dstOffset = getRegStackOffset(regs, dst)

                mem.append(
                    PseudoOp.debugMarker("Moving alloc address in x1"),
                    PseudoOp.mov(.x1, allocFunc_jumpTarget),
                    PseudoOp.debugMarker("Jumping to the alloc func")
                )
                appendDebugPrintAligned4("Jumping to alloc func and storing result", builder: mem)
                mem.append(
                    M1Op.blr(.x1),
                    M1Op.str(X.x0, .reg64offset(X.sp, dstOffset, nil))
                )

            case .OGetThis(let dstReg, let fieldRef):
                try __ogetthis_ofield(
                    dstReg: dstReg,
                    objReg: 0,
                    fieldRef: fieldRef,
                    regs: regs,
                    mem: mem)
            case .OField(let dstReg, let objReg, let fieldRef):
                try __ogetthis_ofield(
                    dstReg: dstReg,
                    objReg: objReg,
                    fieldRef: fieldRef,
                    regs: regs,
                    mem: mem)
                // TODO: remove
                appendLoad(reg: X.x16, from: dstReg, kinds: regs, mem: mem)
                appendDebugPrintRegisterAligned4(X.x16, builder: mem)
            case .OInt(let dst, let iRef):
                
                if (currentInstruction == 8 && compilable.findex == 37) {
//                    appendDebugPrintAligned4("ARRIVED HERE", builder: mem)
//                    let _c: (@convention(c) ()->()) = {
//                        print("Hello world")
//                        fatalError("end")
//                    }
//                    let _cAddr = unsafeBitCast(_c, to: OpaquePointer.self)
//                    mem.append(
//                        PseudoOp.mov(X.x0, _cAddr),
//                        M1Op.blr(X.x0)
//                    )
                }
                
                assert(reg: dst, from: regs, is: HLTypeKind.i32)
                let c = try ctx.requireInt(iRef)
                let regStackOffset = getRegStackOffset(regs, dst)
                appendDebugPrintAligned4("--> Storing int \(iRef) (val \(c)) in \(dst)", builder: mem)
                mem.append(
                    PseudoOp.debugMarker(
                        "Mov \(c) into \(X.x0) and store in stack for HL reg \(iRef) at offset \(regStackOffset)"
                    ),
                    PseudoOp.mov(X.x0, c),
                    M1Op.str(W.w0, .reg64offset(X.sp, regStackOffset, nil))
                )
            case .OSetThis(field: let fieldRef, src: let srcReg):
                try __osetthis_osetfield(objReg: 0, fieldRef: fieldRef, srcReg: srcReg, regs: regs, mem: mem)
            case .OSetField(let objReg, let fieldRef, let srcReg):
                try __osetthis_osetfield(objReg: objReg, fieldRef: fieldRef, srcReg: srcReg, regs: regs, mem: mem)
            case .OJNotEq(let a, let b, let offset):
                fallthrough
            case .OJEq(let a, let b, let offset):
                fallthrough
            case .OJSGte(let a, let b, let offset):
                fallthrough
            case .OJSLte(let a, let b, let offset):
                fallthrough
            case .OJSLt(let a, let b, let offset):
                fallthrough
            case .OJULt(let a, let b, let offset):

                let wordsToSkip = Int(offset) + 1
                let targetInstructionIx = currentInstruction + wordsToSkip
                guard targetInstructionIx < addrBetweenOps.count else {
                    fatalError("Jump going to an invalid op (\(targetInstructionIx))")
                }

                let regOffsetA = getRegStackOffset(regs, a)
                let regOffsetB = getRegStackOffset(regs, b)

                let kindA = requireTypeKind(reg: a, from: regs)
                let kindB = requireTypeKind(reg: b, from: regs)

                let sizeA = kindA.hlRegSize
                let sizeB = kindB.hlRegSize

                appendDebugPrintAligned4("\(op.id) <\(a)@\(regOffsetA), \(b)@\(regOffsetB)> --> \(offset) (target instruction: \(targetInstructionIx))", builder: mem)
                
                appendLoad(reg: X.x0, from: a, kinds: regs, mem: mem)
                appendLoad(reg: X.x1, from: b, kinds: regs, mem: mem)

                switch(op) {
                case .OJSGte:
                    fallthrough
                case .OJSLte:
                    fallthrough
                case .OJSLt:
                    switch(kindA) {
                    case .i32:
                        mem.append(M1Op.sxtw(.x0, .w0))
                    case .u16:
                        mem.append(M1Op.sxth(.x0, .w0))
                    case .u8:
                        mem.append(M1Op.sxtb(.x0, .w0))
                    default:
                        break
                    }
                    switch(kindB) {
                    case .i32:
                        mem.append(M1Op.sxtw(.x1, .w1))
                    case .u16:
                        mem.append(M1Op.sxth(.x1, .w1))
                    case .u8:
                        mem.append(M1Op.sxtb(.x1, .w1))
                    default:
                        break
                    }
                default:
                    break
                }

                appendDebugPrintRegisterAligned4(X.x0, builder: mem)
                appendDebugPrintRegisterAligned4(X.x1, builder: mem)

                mem.append(M1Op.cmp(X.x0, X.x1))

                
                // calculate what to skip
                let jumpOffset_partA = try Immediate19(mem.byteSize)
                let jumpOffset_partB = addrBetweenOps[targetInstructionIx]
                let jumpOffset = try DeferredImmediateSum(
                    jumpOffset_partB,
                    jumpOffset_partA,
                    -1,
                    -Int(0))
                //


                mem.append(
                    PseudoOp.deferred(4) {
                        switch(op.id) {
                        case .OJSLt:
                            fallthrough
                        case .OJULt:
                            return M1Op.b_lt(try Immediate19(jumpOffset.immediate))
                        case .OJSLte:
                            return M1Op.b_le(try Immediate19(jumpOffset.immediate))
                        case .OJSGte:
                            return M1Op.b_ge(try Immediate19(jumpOffset.immediate))
                        case .OJEq:
                            return M1Op.b_eq(try Immediate19(jumpOffset.immediate))
                        case .OJNotEq:
                            return M1Op.b_ne(try Immediate19(jumpOffset.immediate))
                        default:
                            fatalError("Unsupported jump id \(op.id)")
                        }
                    })
                
                appendDebugPrintAligned4("NOT JUMPING", builder: mem)

            // TODO: somehow combine all the jumps with fallthroughs?
            case .OJNotNull(let reg, let offset):
                fallthrough
            case .OJFalse(let reg, let offset):
                fallthrough
            case .OJNull(let reg, let offset):

                let wordsToSkip = Int(offset) + 1
                let targetInstructionIx = currentInstruction + wordsToSkip
                guard targetInstructionIx < addrBetweenOps.count else {
                    fatalError("Jump going to an invalid op (\(targetInstructionIx))")
                }

                let regOffset = getRegStackOffset(regs, reg)

                mem.append(
                    PseudoOp.debugMarker("\(op.id) \(reg)@\(regOffset) --> \(offset) (target instruction: \(targetInstructionIx))"))
                mem.append(M1Op.movz64(X.x0, 0, nil))
                appendLoad(reg: X.x1, from: reg, kinds: regs, mem: mem)
                
                appendDebugPrintAligned4("Jump comparing x0 and x1", builder: mem)
                appendDebugPrintRegisterAligned4(X.x0, builder: mem)
                appendDebugPrintRegisterAligned4(X.x1, builder: mem)

                mem.append(M1Op.cmp(X.x0, X.x1))

                // calculate what to skip
                let jumpOffset_partA = try Immediate19(mem.byteSize)
                let jumpOffset_partB = addrBetweenOps[targetInstructionIx]
                let jumpOffset = try DeferredImmediateSum(
                    jumpOffset_partB,
                    jumpOffset_partA,
                    -1,
                    -Int(0))
                //


                mem.append(
                    PseudoOp.deferred(4) {
                        switch(op.id) {
                        case .OJFalse:
                            fallthrough
                        case .OJNull:
                            return M1Op.b_eq(try Immediate19(jumpOffset.immediate))
                        case .OJNotNull:
                            return M1Op.b_ne(try Immediate19(jumpOffset.immediate))
                        default:
                            fatalError("Unsupported jump id \(op.id)")
                        }
                    })
                
                appendDebugPrintAligned4("NOT JUMPING", builder: mem)
            // TODO: combine with above jumps
            case .OJAlways(let offset):
                let wordsToSkip = Int(offset) + 1
                let targetInstructionIx = currentInstruction + wordsToSkip
                guard targetInstructionIx < addrBetweenOps.count else {
                    fatalError("Jump going to an invalid op (\(targetInstructionIx))")
                }

                // calculate what to skip
                let jumpOffset_partA = try Immediate19(mem.byteSize)
                let jumpOffset_partB = addrBetweenOps[targetInstructionIx]
                let jumpOffset = try DeferredImmediateSum(
                    jumpOffset_partB,
                    jumpOffset_partA,
                    -1,
                    -Int(0))
                //


                mem.append(
                    PseudoOp.deferred(4) {
                        return M1Op.b(jumpOffset.immediate)
                    })
            case .OGetGlobal(let dst, let globalRef):
                let globalInstanceAddress = try ctx.requireGlobalData(globalRef)
                assert(reg: dst, from: regs, in: [HLTypeKind.dyn, HLTypeKind.obj, HLTypeKind.struct])
                mem.append(PseudoOp.mov(.x0, UnsafeRawPointer(globalInstanceAddress)))
                mem.append(M1Op.ldr(X.x0, .reg64offset(X.x0, 0, nil)))
                appendStore(reg: X.x0, into: dst, kinds: regs, mem: mem)
            case .OShl(let dst, let a, let b):
                appendLoad(reg: .x0, from: a, kinds: regs, mem: mem)
                appendLoad(reg: .x1, from: b, kinds: regs, mem: mem)
                mem.append(M1Op.lsl_r(X.x2, X.x0, X.x1))
                appendStore(reg: X.x2, into: dst, kinds: regs, mem: mem)
                
                appendLoad(reg: X.x15, from: a, kinds: regs, mem: mem)
                appendDebugPrintRegisterAligned4(X.x15, prepend: "db_OShl a", builder: mem)
                
                appendLoad(reg: X.x15, from: b, kinds: regs, mem: mem)
                appendDebugPrintRegisterAligned4(X.x15, prepend: "db_OShl b", builder: mem)
                
                appendLoad(reg: X.x15, from: dst, kinds: regs, mem: mem)
                appendDebugPrintRegisterAligned4(X.x15, prepend: "db_OShl out", builder: mem)
                
            case .OSetI8(let bytes, let index, let src):
                fallthrough
            case .OSetI16(let bytes, let index, let src):
                assert(reg: bytes, from: regs, is: HLTypeKind.bytes)
                assert(reg: index, from: regs, is: HLTypeKind.i32)
                
                if op.id == .OSetI16 {
                    assert(reg: src, from: regs, in: [HLTypeKind.u16, HLTypeKind.i32])
                } else if op.id == .OSetI8 {
                    assert(reg: src, from: regs, in: [HLTypeKind.u8, HLTypeKind.u16, HLTypeKind.i32])
                }
                
                appendLoad(reg: X.x0, from: bytes, kinds: regs, mem: mem)
                appendLoad(reg: X.x1, from: index, kinds: regs, mem: mem)
                appendLoad(reg: X.x2, from: src, kinds: regs, mem: mem)
                
                if op.id == .OSetI8 {
                    mem.append(
                        M1Op.strb(W.w2, .reg(X.x0, .r64shift(X.x1, .lsl(0))))
                    )
                } else if op.id == .OSetI16 {
                    mem.append(
                        M1Op.strh(W.w2, .reg(X.x0, .r64shift(X.x1, .lsl(0))))
                    )
                } else {
                    fatalError("Unexpected op \(op.id)")
                }
                
                if (compilable.findex == 33 && currentInstruction == 61) {
                    let _c: (@convention(c) (OpaquePointer)->()) = {
                        _ptr in
                        
                        let bptr: UnsafePointer<UInt8> = .init(_ptr)
                        print("Got \(bptr.advanced(by: 0).pointee)")
                        print("Got \(bptr.advanced(by: 1).pointee)")
                        print("Got \(bptr.advanced(by: 2).pointee)")
                        print("Got \(bptr.advanced(by: 3).pointee)")
                    }
                    let _cAddr = unsafeBitCast(_c, to: OpaquePointer.self)
                    mem.append(PseudoOp.mov(X.x15, _cAddr))
                    mem.append(M1Op.blr(X.x15))
                    print("OSetX in \(compilable.findex)@\(currentInstruction)")
                }
            case .OGetMem(let dst, let bytes, let index):
                fallthrough
            case .OGetI8(let dst, let bytes, let index):
                fallthrough
            case .OGetI16(let dst, let bytes, let index):
                
                appendLoad(reg: X.x15, from: index, kinds: regs, mem: mem)
                appendDebugPrintRegisterAligned4(X.x15, prepend: "db_OGetI*", builder: mem)
                
                assert(reg: bytes, from: regs, is: HLTypeKind.bytes)
                assert(reg: index, from: regs, is: HLTypeKind.i32)
                if op.id == .OGetI16 {
                    assert(reg: dst, from: regs, in: [HLTypeKind.u16, HLTypeKind.i32])
                } else if op.id == .OGetI8 {
                    assert(reg: dst, from: regs, in: [HLTypeKind.u8, HLTypeKind.u16, HLTypeKind.i32])
                }

                let dstOffset = getRegStackOffset(regs, dst)
                let byteOffset = getRegStackOffset(regs, bytes)
                let indexOffset = getRegStackOffset(regs, index)

                mem.append(
                    // Load byte address (base) in X.x0. It is 8 bytes
                    M1Op.ldr(X.x0, .reg64offset(.sp, byteOffset, nil)),
                    // Load index into X.x1. It is 4 bytes
                    M1Op.ldr(W.w1, .reg64offset(.sp, indexOffset, nil))
                )
                
                if op.id == .OGetI8 {
                    appendDebugPrintAligned4("about to load from bytes (off: \(byteOffset))", builder: mem)
                    appendDebugPrintRegisterAligned4(X.x0, builder: mem)
                    
                    mem.append(
                        M1Op.ldrb(W.w0, .reg(X.x0, .r64shift(X.x1, .lsl(0))))
                    )
                    appendDebugPrintAligned4("loaded", builder: mem)
                } else if op.id == .OGetI16 {
                    mem.append(
                        M1Op.ldrh(W.w0, .reg(X.x0, .r64shift(X.x1, .lsl(0))))
                    )
                } else if op.id == .OGetMem {
                    // TODO: add test
                    assert(reg: dst, from: regs, is: HLTypeKind.i32)
                    mem.append(
                        M1Op.ldr(W.w0, .reg(X.x0, .r64shift(X.x1, .lsl(0))))
                    )
                }
                
                let size = requireTypeKind(reg: dst, from: regs).hlRegSize
                if size == 4 {
                    mem.append(M1Op.str(W.w0, .reg64offset(.sp, dstOffset, nil)))
                } else if size == 8 {
                    mem.append(M1Op.str(X.x0, .reg64offset(.sp, dstOffset, nil)))
                } else if size == 2 {
                    mem.append(M1Op.strh(W.w0, .imm64(.sp, dstOffset, nil)))
                } else if size == 1 {
                    mem.append(M1Op.strb(W.w0, .imm64(.sp, dstOffset, nil)))
                } else {
                    fatalError("Invalid register size")
                }
            case .ONullCheck(let dst):
                let dstOffset = getRegStackOffset(regs, dst)
                let size = requireTypeKind(reg: dst, from: regs).hlRegSize
                if size == 4 {
                    mem.append(M1Op.ldr(W.w0, .reg64offset(.sp, dstOffset, nil)))
                } else if size == 8 {
                    mem.append(M1Op.ldr(X.x0, .reg64offset(.sp, dstOffset, nil)))
                } else if size == 2 {
                    mem.append(M1Op.ldrh(W.w0, .imm64(.sp, dstOffset, nil)))
                } else if size == 1 {
                    mem.append(M1Op.ldrb(W.w0, .imm64(.sp, dstOffset, nil)))
                } else {
                    fatalError("Invalid size for null check")
                }

                mem.append(
                    M1Op.movz64(X.x1, 0, nil),
                    M1Op.cmp(X.x0, X.x1)
                )
                var jumpOverDeath = RelativeDeferredOffset()
                jumpOverDeath.start(at: mem.byteSize)
                mem.append(
                    PseudoOp.deferred(4) {
//                        guard compilable.findex != 28 else {
//                            // TODO: remove after testing
//                            return M1Op.nop
//                        }
                        return M1Op.b_ne(try Immediate19(jumpOverDeath.value))
                    }
                )
                appendDebugPrintAligned4("Null access exception", builder: mem)
                
                // MARK: ------ tmp
                struct _ByteStruct {
                    let t: UnsafeRawPointer
                    let length: Int32
                    let bytes: UnsafeRawPointer
                }
                let testFunc: (@convention(c) (UnsafeRawPointer)->()) = {
                    rawPtr in
                    
                    _ = rawPtr.bindMemory(to: _ByteStruct.self, capacity: 1)
                    
                    print("Got byte struct")
                    fatalError()
                }
                let testFuncTarget = unsafeBitCast(testFunc, to: UnsafeRawPointer.self)
                
                mem.append(
                    PseudoOp.mov(.x1, testFuncTarget),
                    M1Op.blr(.x1)
                )
                // MARK: ------
                
                /*
                 // ideally we jump to hl_null_access() here, BUT
                 // we need hl_throw() to work before that, which means
                 // we need the handlers set up.
                let allocFunc_jumpTarget = unsafeBitCast(LibHl.hl_null_access, to: UnsafeRawPointer.self)
                
                mem.append(
                    PseudoOp.mov(.x1, allocFunc_jumpTarget),
                    M1Op.blr(.x1)
                )
                */
                
                // tmp crash on null access
                appendSystemExit(1, builder: mem)
                jumpOverDeath.stop(at: mem.byteSize)
            case .OAnd(let dst, let a, let b):
                // MARK: --
                if compilable.findex == 33 {
                    let aKind = requireTypeKind(reg: a, from: regs)
                    let bKind = requireTypeKind(reg: b, from: regs)
                    let dstKind = requireTypeKind(reg: dst, from: regs)
                    print("Wat happenin \(currentInstruction): \(aKind) \(bKind) \(dstKind)")
                }
                // MARK: --
                
                appendLoad(reg: X.x0, from: a, kinds: regs, mem: mem)
                appendLoad(reg: X.x1, from: b, kinds: regs, mem: mem)
                
                mem.append(
                    //M1Op.ldr(X.x0, .reg64offset(X.sp, aOffset, nil)),
                    //M1Op.ldr(X.x1, .reg64offset(X.sp, bOffset, nil)),
                    M1Op.and(X.x2, X.x0, .r64shift(X.x1, .lsl(0)))
                    //M1Op.str(X.x2, .reg64offset(X.sp, dstOffset, nil))
                )
                appendStore(reg: X.x2, into: dst, kinds: regs, mem: mem)
            case .OThrow(let exc):
                appendLoad(reg: X.x0, from: exc, kinds: regs, mem: mem)
                mem.append(
                    PseudoOp.mov(X.x1, unsafeBitCast(LibHl._hl_throw, to: OpaquePointer.self)),
                    M1Op.blr(X.x1)
                )
            case .OTrap(let exc, let offset):
                /*
                 Roughly what needs to happen is:
                     
                        #define hl_trap(ctx,r,label) {
                            hl_thread_info *__tinf = hl_get_thread();
                            ctx.tcheck = NULL;
                            ctx.prev = __tinf->trap_current;
                            __tinf->trap_current = &ctx;
                            if( setjmp(ctx.buf) ) {
                                r = __tinf->exc_value;
                                goto label;
                            }
                        }
                 
                 The trap context needs to be on the stack, and setjmp can not be called from
                 within a child function (needs to remain in the overall function context).
                 */
                
                // Offsets into `HLTrapCtx_CCompat`
                let bufOffset: Int64 = Int64(MemoryLayout.offset(of: \HLTrapCtx_CCompat.buf)!)
                let prevOffset: Int64 = Int64(MemoryLayout.offset(of: \HLTrapCtx_CCompat.prev)!)
                let tcheckOffset: Int64 = Int64(MemoryLayout.offset(of: \HLTrapCtx_CCompat.tcheck)!)
                
                // Offsets into HLThreadInfo_CCompat
                let tinf__trapCurrent: Int64 = Int64(MemoryLayout.offset(of: \HLThreadInfo_CCompat.trap_current)!)
                let tinf__excValue: Int64 = Int64(MemoryLayout.offset(of: \HLThreadInfo_CCompat.exc_value)!)
                
                let currentTrapIx: Int64 = availableTrapIx
                availableTrapIx += 1
                
                let trapOffsetInStack = stackInfo.reservedForVreg + currentTrapIx * Int64(MemoryLayout<HLTrapCtx_CCompat>.stride)
                
                // hl_thread_info *__tinf = hl_get_thread();
                appendDebugPrintAligned4(
                    "// hl_thread_info *__tinf = hl_get_thread();", builder: mem
                )
                mem.append(
                    PseudoOp.mov(
                        X.x0,
                        unsafeBitCast(LibHl._hl_get_thread, to: OpaquePointer.self)
                    ),
                    M1Op.blr(X.x0),
                    M1Op.movr64(X.x9, X.x0) // x9 = __tinf
                )
                
                // ctx.tcheck = NULL;
                appendDebugPrintAligned4(
                    "// ctx.tcheck = NULL;", builder: mem
                )
                mem.append(
                    M1Op.movz64(X.x1, 0, nil),
                    M1Op.str(X.x1, .reg64offset(.sp, trapOffsetInStack + tcheckOffset, nil))
                )
                
                // ctx.prev = __tinf->trap_current;
                appendDebugPrintAligned4(
                    "ctx.prev = __tinf->trap_current;", builder: mem
                )
                
                appendDebugPrintAligned4("[traptest] In findex \(compilable.findex); trapoff: \(trapOffsetInStack)", builder: mem)

                // fetch trap_current
                mem.append(M1Op.ldr(X.x2, .reg64offset(X.x9, tinf__trapCurrent, nil)))
                appendDebugPrintRegisterAligned4(X.x2, prepend: "[traptest] Loaded current", builder: mem)
                // store ctx.prev
                let testOff: Int64 = trapOffsetInStack + prevOffset
                mem.append(M1Op.str(X.x2, .reg64offset(.sp, testOff, nil)))
                appendDebugPrintAligned4("[traptest] Offset: \(testOff)", builder: mem)
                // MARK: tmp
                mem.append(M1Op.ldr(X.x13, .reg64offset(.sp, testOff, nil)))
                appendDebugPrintRegisterAligned4(X.x13, prepend: "[traptest] Verify ldr", builder: mem)
                mem.append(M1Op.movr64(X.x13, X.x2))
                appendDebugPrintRegisterAligned4(X.x13, prepend: "[traptest] Verify mov", builder: mem)
                // MARK: /tmp
                
                print("[traptest] tinf__trapCurrent: \(tinf__trapCurrent)")
                print("[traptest] trapOffsetInStack: \(trapOffsetInStack)")
                print("[traptest] prevOffset: \(prevOffset)")
                //
                
                // MARK: --
                let _c: (@convention(c) (OpaquePointer?, OpaquePointer?)->()) = {
                    oPtre, optr2 in
                    guard let ptr = oPtre else { return }
                    
//                    print("traptest x9 had tinf: \(optr2)")
                    
                    let tc: UnsafePointer<HLTrapCtx_CCompat> = .init(ptr)
                    
                    let x = LibHl.hl_get_thread()
//                    print("[traptest feu] __tinf: \(x)")
                    print("[traptest feu] __tinf.cur: \(x.pointee.trap_current)")
//                    print("[traptest feu] cur: \(tc)")
                    print("[traptest feu] cur.prev: \(tc.pointee.prev)")
                    print("[traptest feu] cur.tcheck: \(tc.pointee.tcheck)")
                    return
                }
                mem.append(
                    M1Op.movr64(X.x21, X.x0),
                    M1Op.movr64(X.x20, X.x9),
                    M1Op.movr64(X.x0, .sp),
                    M1Op.add(X.x0, X.x0, .imm(trapOffsetInStack, nil)),
                    
                    // returns nil
//                    M1Op.ldr(X.x1, .reg64offset(X.x0, prevOffset, nil)),
                    
                    // so what's the val?
                    M1Op.ldr(X.x1, .reg64offset(X.x9, tinf__trapCurrent, nil)),
                    
                    PseudoOp.mov(X.x11, unsafeBitCast(_c, to: OpaquePointer.self)),
                    M1Op.blr(X.x11),
                    M1Op.movr64(X.x0, X.x21),
                    M1Op.movr64(X.x9, X.x20)
                )
                // MARK: --
                
                // __tinf->trap_current = &ctx;
                appendDebugPrintAligned4(
                    "__tinf->trap_current = &ctx;", builder: mem
                )
                mem.append(
                    PseudoOp.debugMarker("x3 = &ctx"),
                    M1Op.movr64(X.x3, .sp),
                    M1Op.add(X.x3, X.x3, .imm(trapOffsetInStack, nil))
                )
                
                appendDebugPrintAligned4("__tinf->trap_current = x3", builder: mem)
                
                mem.append(
                    PseudoOp.debugMarker("__tinf->trap_current = x3"),
                    M1Op.str(X.x3, .reg64offset(X.x9, tinf__trapCurrent, nil))
                )
                
                // setjmp(ctx.buf)
                let _setjmpAddr = unsafeBitCast(LibSystem.setjmp, to: OpaquePointer.self)
                mem.append(
                    PseudoOp.debugMarker("x3 = &ctx.buf"),
                    M1Op.movr64(X.x3, .sp),
                    M1Op.movz64(X.x4, UInt16(trapOffsetInStack) + UInt16(bufOffset), nil),
                    M1Op.add(X.x3, X.x3, .r64shift(X.x4, .lsl(0))),
                    
                    PseudoOp.debugMarker("x1 = x0 (__tinf)"),
                    M1Op.movr64(X.x1, X.x0),
                    
                    PseudoOp.debugMarker("x0 = x3 (&ctx.buf)"),
                    M1Op.movr64(X.x0, X.x3),
                    
                    PseudoOp.debugMarker("setjmp(&ctx.buf)"),
                    PseudoOp.mov(X.x10, _setjmpAddr),
                    M1Op.blr(X.x10)
                )
                
                // compare result
                mem.append(
                    M1Op.movz64(X.x1, 0, nil),
                    M1Op.cmp(X.x0, X.x1)
                )
                
                var setJmpEq0Target = RelativeDeferredOffset()
                mem.append(
                    PseudoOp.withOffset(
                        offset: &setJmpEq0Target,
                        mem: mem,
                        M1Op.b_eq(try! Immediate19(setJmpEq0Target.value))
                    )
                )
                
                appendDebugPrintAligned4("[traptest] SETJMP RETURNED !0", builder: mem)
                
                assert(reg: exc, from: regs, is: HLTypeKind.dyn)
                
                // r = __tinf->exc_value;
                appendDebugPrintAligned4("x0 (__tinf) = hl_get_thread()", builder: mem)
                mem.append(
                    PseudoOp.debugMarker("x0 (__tinf) = hl_get_thread()"),
                    PseudoOp.mov(
                        X.x0,
                        unsafeBitCast(LibHl._hl_get_thread, to: OpaquePointer.self)
                    ),
                    M1Op.blr(X.x0)
                )
                appendDebugPrintRegisterAligned4(X.x0, prepend: "__tinf", builder: mem)
                
                appendDebugPrintAligned4("r = __tinf->exc_value;", builder: mem)
                appendDebugPrintAligned4("loading", builder: mem)
                mem.append(
                    PseudoOp.debugMarker("r = __tinf->exc_value;"),
                    M1Op.ldr(X.x1, .reg64offset(X.x0, tinf__excValue, nil))
                )
                appendDebugPrintRegisterAligned4(X.x1, prepend: "exc_value", builder: mem)
                appendLoad(reg: X.x2, from: exc, kinds: regs, mem: mem)
                appendDebugPrintRegisterAligned4(X.x2, prepend: "EXC (after)", builder: mem)
                
                mem.append(M1Op.movr64(X.x12, .sp))
                appendDebugPrintRegisterAligned4(X.x12, prepend: "SP (after)", builder: mem)
                
                appendStore(reg: X.x2, into: exc, kinds: regs, mem: mem)
                appendDebugPrintAligned4("Stored x2 in x1", builder: mem)
                
                // goto label;
                let wordsToSkip = Int(offset) + 1
                let targetInstructionIx = currentInstruction + wordsToSkip
                
                appendDebugPrintAligned4("Jumping from \(currentInstruction) to \(targetInstructionIx)", builder: mem)
                appendDebugPrintAligned4("Preparing jump (words to skip \(wordsToSkip))...", builder: mem)
                
                let jumpOffset_partA = try Immediate19(mem.byteSize)
                let jumpOffset_partB = addrBetweenOps[targetInstructionIx]
                let jumpOffset = try DeferredImmediateSum(
                    jumpOffset_partB,
                    jumpOffset_partA,
                    -1,
                    -Int(0))
                mem.append(
                    PseudoOp.deferred(4) {
                        M1Op.b_v2(try Immediate26(jumpOffset.immediate))
                    }
                )
                
                // marker for other branch after setjmp()
                setJmpEq0Target.stop(at: mem.byteSize)
                appendDebugPrintAligned4("[traptest] SETJMP RETURNED 0", builder: mem)
                
                // call longjump
//                mem.append(
//                    PseudoOp.debugMarker("x0 = &ctx.buf"),
//                    M1Op.movr64(X.x0, .sp),
//                    M1Op.movz64(X.x1, UInt16(trapOffsetInStack) + UInt16(bufOffset), nil),
//                    M1Op.add(X.x0, X.x0, .r64shift(X.x1, .lsl(0))),
//
//                    PseudoOp.debugMarker("x1 = 10"),
//                    M1Op.movz64(X.x1, 14, nil),
//
//                    PseudoOp.debugMarker("longjmp"),
//                    PseudoOp.mov(X.x10, unsafeBitCast(LibSystem.longjmp, to: OpaquePointer.self)),
//                    M1Op.blr(X.x10)
//                )
//
//                appendSystemExit(15, builder: mem)
                
//
//                if( setjmp(ctx.buf) ) {
//                    r = __tinf->exc_value;
//                    goto label;
//                }
                
                
            case .OEndTrap(let exc):
                // TODO: test try/catch where nothing thrown
                availableTrapIx -= 1
                appendDebugPrintAligned4("[traptest OEndTrap weirdo]", builder: mem)
//                mem.append(
//                    M1Op.movz64(X.x0, UInt16(exc), nil),
//                    PseudoOp.mov(X.x1, _endTrapAddress),
//                    M1Op.blr(X.x1)
//                )
            case .ONull(let dst):
                mem.append(
                    M1Op.movz64(X.x0, 0, nil)
                )
                appendStore(reg: X.x0, into: dst, kinds: regs, mem: mem)
            case .OBool(let dst, let value):
                let dstOffset = getRegStackOffset(regs, dst)
                mem.append(
                    M1Op.movz64(X.x0, UInt16(value), nil),
                    M1Op.strb(W.w0, .imm64(.sp, dstOffset, nil))
                )
            case .OUnsafeCast(let dst, let src):
                fallthrough
            case .OMov(let dst, let src):
                let srcType = requireTypeKind(reg: src, from: regs)
                let dstType = requireTypeKind(reg: dst, from: regs)
                Swift.assert(srcType.kind == dstType.kind)
                
                appendLoad(reg: X.x0, from: src, kinds: regs, mem: mem)
                appendStore(reg: X.x0, into: dst, kinds: regs, mem: mem)
            case .OSafeCast(let dst, let src):
                /*
                 safecast [dst], [r] cast register r into register dst, throw an exception if there is no way to perform such operation
                 */
                
                _ = requireTypeKind(reg: src, from: regs)
                let dstType = requireTypeKind(reg: dst, from: regs)
                
//                let _st: UnsafePointer<HLType_CCompat> = .init(OpaquePointer(requireTypeMemory(reg: src, regs: regs)))
//                let _dt: UnsafePointer<HLType_CCompat> = .init(OpaquePointer(requireTypeMemory(reg: dst, regs: regs)))
//                print("Src type", _st._overrideDebugDescription)
//                print("Dst type", _dt._overrideDebugDescription)
//
//
                let srcOffset = getRegStackOffset(regs, src)
                
                // MARK: --
                if compilable.findex == 33 {
                    let _c: (@convention(c)(OpaquePointer)->()) = {
                        _ptr in
                        
                        let x1: UnsafePointer<UnsafePointer<vdynamic>> = .init(_ptr)
                        let x = x1.pointee
                        print("Data: \(x)")
                        print("Hello: \(x.pointee.t.pointee.kind)")
                        //                    print("Hello: \(x.pointee.t._overrideDebugDescription): \(x.pointee.i)")
                        print("^")
                    }
                    let _cAddr = unsafeBitCast(_c, to: OpaquePointer.self)
                    mem.append(
                        // load &src into x.0
                        M1Op.movr64(X.x0, .sp),
                        M1Op.movz64(X.x1, UInt16(srcOffset), nil),
                        M1Op.add(X.x0, X.x0, .r64shift(X.x1, .lsl(0)))
                    )
                    appendLoad(reg: X.x15, from: 14, kinds: regs, mem: mem)
                    appendDebugPrintRegisterAligned4(X.x15, prepend: "OSafeCast test reg14", builder: mem)
                    
                    mem.append(PseudoOp.mov(X.x15, _cAddr), M1Op.blr(X.x15))
                }
                // MARK: --

                let castFunc = get_dyncast(to: dstType.kind)
                appendDebugPrintAligned4("Determined cast function", builder: mem)
                
                    
                mem.append(
                    // load &src into x.0
                    M1Op.movr64(X.x0, .sp),
                    M1Op.movz64(X.x1, UInt16(srcOffset), nil),
                    M1Op.add(X.x0, X.x0, .r64shift(X.x1, .lsl(0)))
                )
                mem.append(PseudoOp.mov(X.x1, requireTypeMemory(reg: src, regs: regs)))
                
                appendDebugPrintRegisterAligned4(X.x0, prepend: "OSafeCast", builder: mem)
                appendDebugPrintRegisterAligned4(X.x1, prepend: "OSafeCast", builder: mem)
                if (dstType != .f32 && dstType != .f64) {
                    // float/double casts are the only ones that don't require the third "to" arg
                    mem.append(PseudoOp.mov(X.x2, requireTypeMemory(reg: dst, regs: regs)))
                    appendDebugPrintRegisterAligned4(X.x2, prepend: "OSafeCast", builder: mem)
                }
                appendDebugPrintAligned4("Jumping to cast function", builder: mem)
                mem.append(
                    PseudoOp.mov(X.x15, castFunc),
                    M1Op.blr(X.x15)
                )
                // TODO: check for failed cast result
                appendDebugPrintAligned4("TODO: OSafeCast should check for failed cast result", builder: mem)
                
                if compilable.findex == 33 {
                    appendDebugPrintRegisterAligned4(X.x0, prepend: "#\(currentInstruction) OSafeCast result \(dst)", builder: mem)
                }
                appendStore(reg: X.x0, into: dst, kinds: regs, mem: mem)
                
                // MARK: --
                if compilable.findex == 33 {
                    let _c2: (@convention(c)(Int32)->()) = {
                        _ptr in
                        
                        print("Result: \(_ptr)")
                        print("^")
                    }
                    let _c2Addr = unsafeBitCast(_c2, to: OpaquePointer.self)
                    mem.append(PseudoOp.mov(X.x15, _c2Addr), M1Op.blr(X.x15))
                }
                // MARK: --
            case .OLabel:
                appendDebugPrintAligned4("OLabel", builder: mem)
            case .OSub(let dst, let a, let b):
                appendLoad(reg: .x0, from: a, kinds: regs, mem: mem)
                appendLoad(reg: .x1, from: b, kinds: regs, mem: mem)

                mem.append(
                    M1Op.sub(X.x2, X.x0, .r64shift(X.x1, .lsl(0)))
                )

                appendStore(reg: .x2, into: dst, kinds: regs, mem: mem)
            case .OAdd(let dst, let a, let b):
                appendLoad(reg: .x0, from: a, kinds: regs, mem: mem)
                appendLoad(reg: .x1, from: b, kinds: regs, mem: mem)
                appendDebugPrintRegisterAligned4(X.x0, builder: mem)
                appendDebugPrintRegisterAligned4(X.x1, builder: mem)
                mem.append(M1Op.add(X.x0, X.x0, .r64shift(X.x1, .lsl(0))))
                appendStore(reg: X.x0, into: dst, kinds: regs, mem: mem)
            case .OUShr(let dst, let a, let b):
                fallthrough
            case .OSShr(let dst, let a, let b):
                appendLoad(reg: .x0, from: a, kinds: regs, mem: mem)
                appendLoad(reg: .x1, from: b, kinds: regs, mem: mem)

                if case .OSShr = op {
                    appendSignMode(true, reg: .x0, from: a, kinds: regs, mem: mem)
                    mem.append(M1Op.asrv(X.x2, X.x0, X.x1))
                } else if case .OUShr = op {
                    mem.append(M1Op.lsrv(X.x2, X.x0, X.x1))
                } else {
                    fatalError("Unknown shift op")
                }

                appendStore(reg: X.x2, into: dst, kinds: regs, mem: mem)
            case .OArraySize(let dst, let src):
                _ = requireTypeKind(reg: src, from: regs, shouldMatch: HLTypeKind.array)

                appendLoad(reg: .x0, from: src, kinds: regs, mem: mem)
                mem.append(
                    // varray: skip 2 pointers (16 bytes) and load 4 bytes
                    M1Op.ldr(W.w0, .reg(X.x0, .imm(16, nil)))
                )
                appendStore(reg: .x0, into: dst, kinds: regs, mem: mem)
            case .OType(let dst, let ty):
                let typeMemory = try ctx.getType(ty)
                print("Type IX \(ty) resulted in \(typeMemory.kind)")
                let typeMemoryVal = Int(bitPattern: typeMemory.ccompatAddress)
                print("Storing type mem \(typeMemoryVal)")
                mem.append(PseudoOp.mov(.x0, typeMemoryVal))
                appendStore(reg: .x0, into: dst, kinds: regs, mem: mem)

                let _test: (@convention(c) (UnsafeRawPointer) -> ()) = { (_ ptr: UnsafeRawPointer) in
                    let p = UnsafePointer<HLType_CCompat>(OpaquePointer(ptr))
                    print("Addr for type: \(p) \(Int(bitPattern: p))")
                    print("Got kind: \(p.pointee.kind)")
                }
                let _testAddress = unsafeBitCast(_test, to: UnsafeMutableRawPointer.self)
                mem.append(
                    PseudoOp.mov(X.x1, _testAddress),
                    M1Op.blr(X.x1))
            case .OIncr(let dst):
                appendLoad(reg: .x0, from: dst, kinds: regs, mem: mem)
                mem.append(M1Op.add(X.x0, X.x0, .imm(1, nil)))
                appendStore(reg: .x0, into: dst, kinds: regs, mem: mem)
            case .OSetArray(let array, let index, let src):
                let lsl = requireTypeSizeLsl(reg: src, from: regs)
                appendLoad(reg: .x0, from: src, kinds: regs, mem: mem)
                appendLoad(reg: .x1, from: index, kinds: regs, mem: mem)
                appendLoad(reg: .x2, from: array, kinds: regs, mem: mem)
                mem.append(
                    M1Op.lsl_i(X.x1, X.x1, try UImmediate6(lsl)),
                    M1Op.str(X.x0, .reg(X.x2, .r64ext(X.x1, .sxtx(0))))
                )
            case .OGetArray(let dst, let array, let index):
                let lsl = requireTypeSizeLsl(reg: dst, from: regs)
                appendLoad(reg: .x1, from: index, kinds: regs, mem: mem)
                appendLoad(reg: .x2, from: array, kinds: regs, mem: mem)
                mem.append(
                    M1Op.lsl_i(X.x1, X.x1, try UImmediate6(lsl)),
                    M1Op.ldr(X.x0, .reg(X.x2, .r64ext(X.x1, .sxtx(0))))
                )
                appendStore(reg: X.x0, into: dst, kinds: regs, mem: mem)
            case .ONop:
                mem.append(M1Op.nop)
            case .OXor(let dst, let a, let b):
                appendLoad(reg: .x0, from: a, kinds: regs, mem: mem)
                appendLoad(reg: .x1, from: b, kinds: regs, mem: mem)
                mem.append(M1Op.eor_r(X.x2, X.x0, X.x1, nil))
                appendStore(reg: X.x2, into: dst, kinds: regs, mem: mem)
            case .OMul(let dst, let a, let b):
                appendLoad(reg: X.x0, from: a, kinds: regs, mem: mem)
                appendLoad(reg: X.x1, from: b, kinds: regs, mem: mem)
                
                appendDebugPrintRegisterAligned4(X.x0, builder: mem)
                appendDebugPrintRegisterAligned4(X.x1, builder: mem)
                
                mem.append(M1Op.mul(X.x0, X.x0, X.x1))
                appendStore(reg: X.x0, into: dst, kinds: regs, mem: mem)
            case .OToSFloat(let dst, let src):
                fallthrough
            case .OToInt(let dst, let src):
                let dstKind = requireTypeKind(reg: dst, from: regs)
                let srcKind = requireTypeKind(reg: src, from: regs)

                appendLoad(reg: X.x0, from: src, kinds: regs, mem: mem)

                switch(srcKind, dstKind) {
                case (let a, let b) where a == b:
                    appendStore(reg: X.x0, into: dst, kinds: regs, mem: mem)
                case (.u8, .i64), (.u16, .i64), (.i32, .i64):
                    appendStore(reg: X.x0, into: dst, kinds: regs, mem: mem)
                case (.u8, .i32), (.u16, .i32), (.i64, .i32):
                    appendDebugPrintAligned4("TODO: .ToInt i64->i32: investigate if size check needed", builder: mem)
                    appendStore(reg: X.x0, into: dst, kinds: regs, mem: mem)
                case (.f64, .i32):
                    mem.append(M1Op.fcvtzs(W.w0, D.d0))
                    appendStore(reg: X.x0, into: dst, kinds: regs, mem: mem)
                case (.i32, .f64):
                    appendDebugPrintRegisterAligned4(X.x0, prepend: "OToSFloat", builder: mem)
                    mem.append(M1Op.scvtf(D.d0, W.w0))
                    appendStore(reg: D.d0, into: dst, kinds: regs, mem: mem)
                default:
                    fatalError("Don't know how to cast \(srcKind) to \(dstKind)")
                }
            case .OToDyn(let dst, let src):
                let addr = unsafeBitCast(OToDyn_impl, to: UnsafeRawPointer.self)
                let dstType = requireType(reg: dst, regs: regs)
                let srcType = requireType(reg: src, regs: regs)
                mem.append(
                    PseudoOp.mov(X.x10, addr),
                    PseudoOp.mov(X.x0, dstType.ccompatAddress),
                    PseudoOp.mov(X.x1, srcType.ccompatAddress)
                )
                appendLoad(reg: .x2, from: dst, kinds: regs, mem: mem)
                appendLoad(reg: .x3, from: src, kinds: regs, mem: mem)
                mem.append(M1Op.blr(.x10))
                appendStore(reg: .x0, into: dst, kinds: regs, mem: mem)
                
                // MARK: --
                if compilable.findex == 33 {
                    let _c: (@convention(c)(OpaquePointer)->()) = {
                        _ptr in
                        
                        let ptr: UnsafePointer<vdynamic> = .init(_ptr)
                        print("# OSafeCast result OToDyn: ", ptr.pointee.i)
                    }
                    let _cAddr = unsafeBitCast(_c, to: OpaquePointer.self)
                    mem.append(PseudoOp.mov(X.x15, _cAddr), M1Op.blr(X.x15))
                    appendDebugPrintRegisterAligned4(X.x0, prepend: "#\(currentInstruction) OSafeCast result OToDyn \(dst)", builder: mem)
                }
                // MARK: --
                
            case .OOr(let dst, let a, let b):
                appendLoad(reg: X.x0, from: a, kinds: regs, mem: mem)
                appendLoad(reg: X.x1, from: b, kinds: regs, mem: mem)
                mem.append(M1Op.orr(X.x0, X.x0, X.x1, nil))
                appendStore(reg: X.x0, into: dst, kinds: regs, mem: mem)
            case .OSwitch(let reg, let offsets, _ /*end*/):
                
                appendLoad(reg: X.x0, from: reg, kinds: regs, mem: mem)
                
                for (expectedValue, jmpOffset) in offsets.enumerated() {
                    appendDebugPrintAligned4("Comparing reg \(reg) against \(expectedValue)", builder: mem)
                    mem.append(
                        PseudoOp.mov(X.x1, expectedValue),
                        M1Op.cmp(X.x0, X.x1)
                    )
                    
                    // calculate what to skip
                    let wordsToSkip = Int(jmpOffset) + 1
                    let targetInstructionIx = currentInstruction + wordsToSkip
                    
                    let jumpOffset_partA = try Immediate19(mem.byteSize)
                    let jumpOffset_partB = addrBetweenOps[targetInstructionIx]
                    let jumpOffset = try DeferredImmediateSum(
                        jumpOffset_partB,
                        jumpOffset_partA,
                        -1,
                        -Int(0))
                    //
                    
                    mem.append(
                        PseudoOp.deferred(4) {
                            M1Op.b_eq(try Immediate19(jumpOffset.immediate))
                        }
                    )
                    
                    appendDebugPrintAligned4("Didn't jump from case \(expectedValue)", builder: mem)
                }
            case .OGetTID(let dst, let src):
                let srcType = requireType(reg: src, regs: regs)
                Swift.assert(srcType.kind == .type)
                
                /* X.x0 <- hl_type*
                 The first 32bits of that address are the kind
                 */
                appendLoad(reg: X.x0, from: src, kinds: regs, mem: mem)
                // M1Op.ldr(reg, .reg64offset(.sp, offset, nil))
                mem.append(M1Op.ldr(W.w0, .reg(X.x0, .imm(0, nil))))
                appendStore(reg: X.x0, into: dst, kinds: regs, mem: mem)
            case .OGetType(let dst, let src):
                let srcType = requireType(reg: src, regs: regs)
                switch(srcType.kind) {
                case .dyn:
                    /* X.x0 <- first 8 bytes (which are hl_type address)
                     */
                    appendLoad(reg: X.x0, from: src, kinds: regs, mem: mem)
                    mem.append(
                        M1Op.ldr(X.x0, .reg64offset(X.x0, 0, nil))
                    )
                default:
                    fatal("OGetType not supported for src \(srcType.kind)", Self.logger)
                }
                appendDebugPrintAligned4("INTTYPE test", builder: mem)
                appendDebugPrintRegisterAligned4(X.x0, builder: mem)
                appendStore(reg: X.x0, into: dst, kinds: regs, mem: mem)
            case .ORef(let dst, let src):
                let dstType = requireType(reg: dst, regs: regs)
                let srcType = requireType(reg: src, regs: regs)
                Swift.assert(dstType.kind == .ref)
                Swift.assert(srcType.kind == dstType.tparamProvider?.kind)
                
                let srcOffset = getRegStackOffset(regs, src)
                
                mem.append(
                    // x0 = [sp + srcOffset]
                    M1Op.movr64(X.x0, .sp),
                    M1Op.movz64(X.x1, UInt16(srcOffset), nil),
                    M1Op.add(X.x0, X.x0, .r64shift(X.x1, .lsl(0)))
                )
                appendStore(reg: X.x0, into: dst, kinds: regs, mem: mem)
                
            case .OSetref(let dst, let src):
                let dstType = requireType(reg: dst, regs: regs)
                let srcType = requireType(reg: src, regs: regs)
                Swift.assert(dstType.kind == .ref)
                Swift.assert(srcType.kind == dstType.tparamProvider?.kind)
                // x0 = address of ref
                appendLoad(reg: X.x0, from: dst, kinds: regs, mem: mem)
                appendLoad(reg: X.x1, from: src, kinds: regs, mem: mem)
                mem.append(
                    M1Op.str(X.x1, .reg64offset(X.x0, 0, nil))
                )
            case .OMakeEnum(let dst, let construct, let args):
                assert(reg: dst, from: regs, is: HLTypeKind.enum)
                let type = requireType(reg: dst, regs: regs)
                guard let _ = type.tenumProvider else {
                    fatalError("Enum provider must be set")
                }
                
                // these need to be deallocated in the callee
                let argBuff: UnsafeMutableBufferPointer<Reg> = .allocate(capacity: args.count)
                _ = argBuff.initialize(from: args)
                
                let argValBuff: UnsafeMutableBufferPointer<Int64> = .allocate(capacity: args.count)
                
                for (ix, arg) in args.enumerated() {
                    appendLoad(reg: X.x0, from: arg, kinds: regs, mem: mem)
                    mem.append(
                        PseudoOp.mov(X.x1, UnsafeRawPointer(argValBuff.baseAddress!.advanced(by: ix))),
                        M1Op.str(X.x0, .reg64offset(X.x1, 0, nil))
                    )
                }
                
                let _implTarget = unsafeBitCast(OMakeEnum_impl, to: UnsafeRawPointer.self)
                
                mem.append(
                    PseudoOp.mov(X.x0, type.ccompatAddress),
                    PseudoOp.mov(X.x1, construct),
                    M1Op.movz64(X.x2, UInt16(args.count), nil),
                    PseudoOp.mov(X.x3, UnsafeRawPointer(argBuff.baseAddress!)),
                    PseudoOp.mov(X.x4, UnsafeRawPointer(argValBuff.baseAddress!)),
                    
                    PseudoOp.mov(.x19, _implTarget),
                    M1Op.blr(.x19)
                )
                appendStore(reg: X.x0, into: dst, kinds: regs, mem: mem)
            case .OEnumIndex(let dst, let value):
                let _implTarget = unsafeBitCast(OEnumIndex_impl, to: UnsafeRawPointer.self)
                
                appendLoad(reg: X.x0, from: value, kinds: regs, mem: mem)
                mem.append(
                    PseudoOp.mov(.x19, _implTarget),
                    M1Op.blr(.x19)
                )
                assert(reg: dst, from: regs, is: HLTypeKind.i32)
                appendStore(reg: X.x0, into: dst, kinds: regs, mem: mem)
            case .OEnumField(let dst, let value, let construct, let field):
                let _implTarget = unsafeBitCast(OEnumField_impl, to: UnsafeRawPointer.self)
                
                // TODO: can enums have other types of assoc data? Need a test
                assert(reg: dst, from: regs, is: HLTypeKind.i32)
                
                appendLoad(reg: X.x0, from: value, kinds: regs, mem: mem)
                
                mem.append(
                    M1Op.movz64(X.x1, UInt16(construct), nil),
                    M1Op.movz64(X.x2, UInt16(field), nil),
                    
                    PseudoOp.mov(.x19, _implTarget),
                    M1Op.blr(.x19),
                    M1Op.ldr(X.x0, .reg64offset(X.x0, 0, nil))
                )
//                assert(reg: dst, from: regs, is: HLTypeKind.i32)
                appendStore(reg: X.x0, into: dst, kinds: regs, mem: mem)
            case .OEnumAlloc(let dst, let construct):
                assert(reg: dst, from: regs, is: HLTypeKind.enum)
                let type = requireType(reg: dst, regs: regs)
                guard let _ = type.tenumProvider else {
                    fatalError("Enum provider must be set")
                }
                
                let _implTarget = unsafeBitCast(OEnumAlloc_impl, to: UnsafeRawPointer.self)
                
                mem.append(
                    PseudoOp.mov(X.x0, type.ccompatAddress),
                    PseudoOp.mov(X.x1, construct),
                    PseudoOp.mov(.x19, _implTarget),
                    M1Op.blr(.x19)
                )
                appendStore(reg: X.x0, into: dst, kinds: regs, mem: mem)
            case .OSetEnumField(let value, let field, let src):
                assert(reg: src, from: regs, is: HLTypeKind.i32)
                
                let _implTarget = unsafeBitCast(OSetEnumField_impl, to: UnsafeRawPointer.self)
                
                appendLoad(reg: X.x2, from: src, kinds: regs, mem: mem)
                appendLoad(reg: X.x0, from: value, kinds: regs, mem: mem)
                mem.append(
                    PseudoOp.mov(X.x1, field),
                    PseudoOp.mov(.x19, _implTarget),
                    M1Op.blr(.x19)
                )
            case .OInstanceClosure(let dst, let fun, let obj):
                _ = unsafeBitCast(OInstanceClosure_impl, to: UnsafeRawPointer.self)
                
                
                guard let funIndex = ctx.mainContext.pointee.m?.pointee.functions_indexes.advanced(by: fun).pointee else {
                    fatalError("No real fun index")
                }
                print("Fun index \(funIndex)")
                guard let funType = ctx.mainContext.pointee.code?.pointee.functions.advanced(by: Int(funIndex)).pointee.typePtr else {
                    fatalError("No fun type")
                }
                
                print("fun \(fun); funType: \(funType.kind); \(funType._overrideDebugDescription)")
                Swift.assert(funType.kind == .fun)
                
                let callTarget = try ctx.requireCallable(findex: fun)
                ctx.funcTracker.referenced2(callTarget)
                
                print("Got fun address: \(callTarget.address)")
                
//                typealias _ClosureType = (@convention(c) (OpaquePointer)->(Int32))
//                let newInstanceClosure: _ClosureType = {
//                    objPtr in
//                    let x: UnsafePointer<vdynamic> = .init(objPtr)
//                    return 1234
//                }
//                let newClosurePtr = unsafeBitCast(newInstanceClosure, to: UnsafeRawPointer.self)
                
                // hl_alloc_closure_ptr( hl_type *fullt, void *fvalue, void *v ) {
                
                let allocClosure_jumpTarget = unsafeBitCast(LibHl._hl_alloc_closure_ptr, to: UnsafeRawPointer.self)
                
                
                appendLoad(reg: X.x2, from: obj, kinds: regs, mem: mem)
                mem.append(
                    PseudoOp.mov(X.x0, funType.ccompatAddress),
                    PseudoOp.mov(X.x1, callTarget.address),
                    
                    PseudoOp.mov(X.x3, allocClosure_jumpTarget),
                    M1Op.blr(X.x3)
                )
                appendStore(reg: X.x0, into: dst, kinds: regs, mem: mem)
                appendDebugPrintRegisterAligned4(X.x0, builder: mem)
            case .OStaticClosure(let dst, let fun):
                let mutatingMod = UnsafeMutablePointer(mutating: ctx.mainContext.pointee.m!)
                let callTarget = try ctx.requireCallable(findex: fun)
                ctx.funcTracker.referenced2(callTarget)
                
                withUnsafeMutablePointer(to: &mutatingMod.pointee.ctx.alloc) {
                    allocPtr in
                    
                    let c: UnsafeMutablePointer<vclosure> = .init(LibHl.hl_malloc(allocPtr, Int32(MemoryLayout<vclosure>.size)))
                    print("OStaticClosure hl_malloc returned \(c) == \(Int(bitPattern: c))")
                    let fidx = mutatingMod.pointee.functions_indexes.advanced(by: fun).pointee
                    
                    let nfuncs = mutatingMod.pointee.code.pointee.nfunctions
                    
                    /* The call target address is not available at compilation time, but will be available at link time.
                     
                     So instead of assigning c.pointee.fun directly (can't - no address), we append instructions to load the address
                     at runtime (at which point it will be available).
                     
                     This is equivalent to: `c.pointee.fun = .init(callTarget.address.value)` except via assembly.
                     */
                    mem.append(PseudoOp.mov(X.x0, callTarget.address))
                    mem.append(PseudoOp.mov(X.x1, OpaquePointer(c)))
                    mem.append(M1Op.str(X.x0, .reg64offset(X.x1, 8 /* offset to `fun` in vclosure */, nil)))
                    
                    c.pointee.value = nil
                    
                    if (fidx >= nfuncs) {
                        // native
                        c.pointee.t = mutatingMod.pointee.code.pointee.natives.advanced(by: Int(UInt32(fidx) - nfuncs)).pointee.typePtr
                    } else {
                        let funcPtr = mutatingMod.pointee.code.pointee.functions.advanced(by: Int(fidx))
                        c.pointee.t = funcPtr.pointee.typePtr!
                    }
                    
                    c.pointee.hasValue = 0
                    
                    mem.append(PseudoOp.mov(X.x0, OpaquePointer(c)))
                    appendStore(reg: X.x0, into: dst, kinds: regs, mem: mem)
                }
            default:
                fatalError("Can't compile \(op.debugDescription)")
            }
        }

        // initialize targets for 'ret' jumps
        for var retTarget in retTargets {
            print("Stopping retTarget at \(mem.byteSize)")
            retTarget.stop(at: mem.byteSize)
        }

        if stackInfo.total > 0 {
            appendDebugPrintAligned4("Free \(stackInfo.total) bytes (pre-epilogue)", builder: mem)
            mem.append(
                (try M1Op._add(X.sp, X.sp, stackInfo.total))
            )
        }
        else {
            appendDebugPrintAligned4("Skipping freeing stack because \(stackInfo.total) bytes were needed", builder: mem)
        }

        appendEpilogue(builder: mem)
        appendDebugPrintAligned4("Returning", builder: mem)
        mem.append(M1Op.ret)
    }
}
