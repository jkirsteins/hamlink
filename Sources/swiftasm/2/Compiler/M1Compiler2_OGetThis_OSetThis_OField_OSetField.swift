extension M1Compiler2 {
    /// Reusable implem for OGetThis and OField
    func __ogetthis_ofield(
        dstReg: Reg,
        objReg: Reg,
        fieldRef: RefField,
        regs: [any HLTypeProvider],
        mem: CpuOpBuffer
    ) throws {
        let objRegKind = requireTypeKind(reg: objReg, from: regs)
        
        /* See comments on `OSetField` for notes on accessing field indexes */

        switch(objRegKind) {
        case .obj: fallthrough
        case .struct:
            // offset from obj address
            let fieldOffset = requireFieldOffset(fieldRef: fieldRef, objIx: objReg, regs: regs)
            appendLoad(reg: X.x0, from: objReg, kinds: regs, mem: mem)
            mem.append(M1Op.ldr(X.x1, .reg64offset(.x0, fieldOffset, nil)))
            appendStore(1, into: dstReg, kinds: regs, mem: mem)
        case .virtual:
            let dstType = requireTypeKind(reg: dstReg, from: regs)
            let getFunc = get_dynget(to: dstType.kind)
                
            // x0 -> points to ((*_vvirtual)(obj))+1
            appendLoad(reg: X.x0, from: objReg, kinds: regs, mem: mem)
            appendDebugPrintRegisterAligned4(X.x0, prepend: "ofield/virtual", builder: mem)
            
            // x1 point to field base (right after the (vvirtual) content at x0
            mem.append(M1Op.add(X.x1, X.x0, .imm(Int64(MemoryLayout<vvirtual>.stride), nil)))
            appendDebugPrintRegisterAligned4(X.x1, prepend: "ofield/virtual field base", builder: mem)
            
            // x2 load field index multiplied by size of (void*)
            let fieldOffsetInBytes = fieldRef * MemoryLayout<OpaquePointer>.stride
            mem.append(M1Op.movz64(X.x2, UInt16(fieldOffsetInBytes), nil))
            appendDebugPrintAligned4("ofield/virtual field index: \(fieldRef)", builder: mem)
            appendDebugPrintRegisterAligned4(X.x2, prepend: "ofield/virtual field offset: \(fieldOffsetInBytes) bytes", builder: mem)
            
            // add field offset to base
            mem.append(M1Op.add(X.x1, X.x1, .r64shift(X.x2, .lsl(0))))
            appendDebugPrintRegisterAligned4(X.x1, prepend: "ofield/virtual field \(fieldRef)", builder: mem)
            
            // field source is pointer to a pointer, so we need to dereference it once before
            // we check if it is null or not (and if null - don't use)
            mem.append(M1Op.ldr(X.x1, .reg(X.x1, .imm(0, nil))))
            appendDebugPrintRegisterAligned4(X.x1, prepend: "ofield/virtual dereferenced address", builder: mem)
                        
            // compare x1 to 0
            var jmpTarget_hlvfieldNoAddress = RelativeDeferredOffset()
            var jmpTarget_postCheck = RelativeDeferredOffset()
            mem.append(M1Op.movz64(X.x2, 0, nil))
            mem.append(M1Op.cmp(X.x1, X.x2))
            
            mem.append(
                PseudoOp.withOffset(
                    offset: &jmpTarget_hlvfieldNoAddress,
                    mem: mem,
                    M1Op.b_eq(try! Immediate21(jmpTarget_hlvfieldNoAddress.value))
                )
            )
            appendDebugPrintAligned4("ofield/virtual HAS ADDRESS", builder: mem)
            
            // load field value into x2
            appendLoad(2, as: dstReg, addressRegister: X.x1, offset: 0, kinds: regs, mem: mem)
            appendStore(2, into: dstReg, kinds: regs, mem: mem)
            appendDebugPrintRegisterAligned4(2, kind: dstType, prepend: "ofield/virtual result", builder: mem)
            
            // finish this branch
            mem.append(
                PseudoOp.withOffset(
                    offset: &jmpTarget_postCheck,
                    mem: mem,
                    M1Op.b(jmpTarget_postCheck)
                )
            )
            
            // marker for other branch
            jmpTarget_hlvfieldNoAddress.stop(at: mem.byteSize)
            
            appendDebugPrintAligned4("ofield/virtual HAS NO ADDRESS (TODO)", builder: mem)
            
            var _fieldHashGetter: (@convention(c)(OpaquePointer, Int32)->(Int64)) = {
                opPtr, field in
                
                let p: UnsafePointer<vvirtual> = .init(opPtr)
                
                return p.pointee.t.pointee.virt.pointee.fields.advanced(by: Int(field)).pointee.hashedName
            }
            
            // fetch the field hash name
            appendLoad(reg: X.x0, from: objReg, kinds: regs, mem: mem)
            mem.append(M1Op.movz64(X.x1, UInt16(fieldRef), nil))
            mem.append(
                PseudoOp.mov(X.x2, unsafeBitCast(_fieldHashGetter, to: OpaquePointer.self)),
                M1Op.blr(X.x2)
            )
            let dstTypeAddr = requireType(reg: dstReg, regs: regs).ccompatAddress
            
            // x1 = field hash name
            mem.append(M1Op.movr64(X.x0, X.x1))
            // x0 = obj
            appendLoad(reg: X.x0, from: objReg, kinds: regs, mem: mem)
            // x2 = dst type (only needed for f32/f64)
            mem.append(PseudoOp.mov(X.x2, dstTypeAddr))
            
            mem.append(
                PseudoOp.mov(X.x10, getFunc),
                M1Op.blr(X.x10))
            
            appendStore(0, into: dstReg, kinds: regs, mem: mem)
            appendDebugPrintRegisterAligned4(X.x0, prepend: "ofield/virtual result", builder: mem)
            
            jmpTarget_postCheck.stop(at: mem.byteSize)
            appendDebugPrintAligned4("ofield virtual EXITING", builder: mem)
        default:
            fatalError("OField not implemented for \(objRegKind)")
        }
    }
    
    /// Reusable implem for OSetThis and OSetField
    func __osetthis_osetfield(
        objReg: Reg,
        fieldRef: RefField,
        srcReg: Reg,
        regs: [any HLTypeProvider],
        mem: CpuOpBuffer
    ) throws {
        let objRegKind = requireTypeKind(reg: objReg, from: regs)

        /**
         field indexes are fetched from runtime_object,
         and match what you might expect. E.g. for String:

         Example offsets for 0) bytes, 1) i32

         (lldb) p typePtr.pointee.obj.pointee.rt?.pointee.fields_indexes.pointee
         (Int32?) $R0 = 8   // <----- first is 8 offset, on account of hl_type* at the top
         (lldb) p typePtr.pointee.obj.pointee.rt?.pointee.fields_indexes.advanced(by: 1).pointee
         (Int32?) $R1 = 16 // <----- second is 8 more offset, cause bytes is a pointer
         (lldb)

         NOTE: keep alignment in mind. E.g. 0) int32 and 1) f64 will have 8 and 16 offsets respectively.
         But 0) int32, 1) u8, 2) u8, 3) u16, 4) f64 will have 8, 12, 13, 14, 16 offsets respectively.

         See below:

         (lldb) p typePtr.pointee.obj.pointee.rt?.pointee.fields_indexes.advanced(by: 0).pointee
         (Int32?) $R0 = 8
         (lldb) p typePtr.pointee.obj.pointee.rt?.pointee.fields_indexes.advanced(by: 1).pointee
         (Int32?) $R1 = 12
         (lldb) p typePtr.pointee.obj.pointee.rt?.pointee.fields_indexes.advanced(by: 2).pointee
         (Int32?) $R2 = 13
         (lldb) p typePtr.pointee.obj.pointee.rt?.pointee.fields_indexes.advanced(by: 3).pointee
         (Int32?) $R3 = 14
         (lldb) p typePtr.pointee.obj.pointee.rt?.pointee.fields_indexes.advanced(by: 4).pointee
         (Int32?) $R4 = 16
         */

        switch(objRegKind.kind) {
        case .obj: fallthrough
        case .struct:
            // offset from obj address
            let fieldOffset = requireFieldOffset(fieldRef: fieldRef, objIx: objReg, regs: regs)

            appendLoad(reg: X.x0, from: srcReg, kinds: regs, mem: mem)
            appendLoad(reg: X.x1, from: objReg, kinds: regs, mem: mem)
            mem.append(M1Op.str(X.x0, .reg64offset(.x1, fieldOffset, nil)))
        case .virtual:
            /*
             typedef struct _vvirtual vvirtual;
             struct _vvirtual {
                 hl_type *t;
                 vdynamic *value;
                 vvirtual *next;
             };

             #define hl_vfields(v) ((void**)(((vvirtual*)(v))+1))
             */
            /* ASM for -->
             f( hl_vfields(o)[f] )
                *hl_vfields(o)[f] = v;
             else
                hl_dyn_set(o,hash(field),vt,v);
             */
            
            let srcType = requireTypeKind(reg: srcReg, from: regs)
            let setFunc = get_dynset(from: srcType.kind)
                
            // x0 -> points to ((*_vvirtual)(obj))+1
            appendLoad(reg: X.x0, from: objReg, kinds: regs, mem: mem)
            appendDebugPrintRegisterAligned4(X.x0, prepend: "osetfield/virtual", builder: mem)
            
            // x1 point to field base (right after the (vvirtual) content at x0
            mem.append(M1Op.add(X.x1, X.x0, .imm(Int64(MemoryLayout<vvirtual>.stride), nil)))
            appendDebugPrintRegisterAligned4(X.x1, prepend: "osetfield/virtual field base", builder: mem)
            
            // x2 load field index multiplied by size of (void*)
            let fieldOffsetInBytes = fieldRef * MemoryLayout<OpaquePointer>.stride
            mem.append(M1Op.movz64(X.x2, UInt16(fieldOffsetInBytes), nil))
            appendDebugPrintAligned4("ofield/virtual field index: \(fieldRef)", builder: mem)
            appendDebugPrintRegisterAligned4(X.x2, prepend: "osetfield/virtual field offset: \(fieldOffsetInBytes) bytes", builder: mem)
            
            // add field offset to base
            mem.append(M1Op.add(X.x1, X.x1, .r64shift(X.x2, .lsl(0))))
            appendDebugPrintRegisterAligned4(X.x1, prepend: "osetfield/virtual field \(fieldRef)", builder: mem)
            
            // field source is pointer to a pointer, so we need to dereference it once before
            // we check if it is null or not (and if null - don't use)
            mem.append(M1Op.ldr(X.x1, .reg(X.x1, .imm(0, nil))))
            appendDebugPrintRegisterAligned4(X.x1, prepend: "osetfield/virtual dereferenced address", builder: mem)
            
            // compare x1 to 0
            var jmpTarget_hlvfieldNoAddress = RelativeDeferredOffset()
            var jmpTarget_postCheck = RelativeDeferredOffset()
            mem.append(M1Op.movz64(X.x2, 0, nil))
            mem.append(M1Op.cmp(X.x1, X.x2))
            
            mem.append(
                PseudoOp.withOffset(
                    offset: &jmpTarget_hlvfieldNoAddress,
                    mem: mem,
                    M1Op.b_eq(try! Immediate21(jmpTarget_hlvfieldNoAddress.value))
                )
            )
            appendDebugPrintAligned4("osetfield/virtual HAS ADDRESS", builder: mem)
            
            // load field value into x2 and store at x1
            appendLoad(2, from: srcReg, kinds: regs, mem: mem)
            appendStore(2, as: srcReg, intoAddressFrom: X.x1, offsetFromAddress: 0, kinds: regs, mem: mem)
            
            // finish this branch
            mem.append(
                PseudoOp.withOffset(
                    offset: &jmpTarget_postCheck,
                    mem: mem,
                    M1Op.b(jmpTarget_postCheck)
                )
            )
            
            // marker for other branch
            jmpTarget_hlvfieldNoAddress.stop(at: mem.byteSize)
            
            appendDebugPrintAligned4("osetfield/virtual HAS NO ADDRESS", builder: mem)
            appendSystemExit(11, builder: mem)
            
            jmpTarget_postCheck.stop(at: mem.byteSize)
            appendDebugPrintAligned4("osetfield/virtual EXITING", builder: mem)
        default:
            fatalError("OSetField not implemented for \(objRegKind)")
        }
    }
}
