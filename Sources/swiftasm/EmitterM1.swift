import Darwin 

public protocol Register: CustomDebugStringConvertible {
    associatedtype Shift

    var rawValue: UInt8 { get }
    var is32: Bool { get }
}

extension Register {
    var is64: Bool { !is32 }
}

typealias X = Register64 
typealias W = Register32

extension OpBuilder
{
    @discardableResult
    func append(_ ops: M1Op...) -> OpBuilder
    {
        let x = ops.map { $0 as any CpuOp }
        return self.append(x)
    }
}

// TODO: wrong, fix w Shift64_Real
public enum Shift64: Int, CustomDebugStringConvertible {
    case _0 = 0
    case _16 = 16
    case _32 = 32
    case _48 = 48
    
    public var debugDescription: String {
        "\(self.rawValue)"
    }
}

typealias ShiftAmount = UInt8

enum ExtendOp32 : CustomDebugStringConvertible {
    case sxtw(ShiftAmount)  // ExtendSigned32To64
    case uxtw(ShiftAmount)  // ExtendUnsigned32To64
    
    var debugDescription: String {
        switch(self) {
        case .sxtw(let shift):
            return "sxtw #\(shift)"
        case .uxtw(let shift):
            return "uxtw #\(shift)"
        }
    }
}

enum ExtendOp64 : CustomDebugStringConvertible {
    case sxtx(ShiftAmount)  // ExtendSigned64To64
    
    var debugDescription: String {
        switch(self) {
        case .sxtx(let shift):
            return "sxtx #\(shift)"
        }
    }
}

public enum Shift64_Real : CustomDebugStringConvertible {
    case lsl(Int) 
    case lsr(Int) 
    case asr(Int) 
    case ror(Int)
    
    public var debugDescription: String {
        switch(self) {
        case .lsl(let v): return "lsl #\(v)"
        case .lsr(let v): return "lsr #\(v)"
        case .asr(let v): return "asr #\(v)"
        case .ror(let v): return "ror #\(v)"
        }
    }
}


public enum Shift32: Int, CustomDebugStringConvertible {
    case _0 = 0
    case _16 = 16
    
    public var debugDescription: String {
        "\(self.rawValue)"
    }
}

enum Register64: UInt8, Register {
    typealias Shift = Shift64
    typealias ExtendOp = ExtendOp64

    var is32: Bool { false }
    
    var to32: Register32 {
        Register32(rawValue: rawValue)!
    }

    case x0 = 0
    case x1 = 1
    case x2 = 2
    case x3 = 3
    case x4 = 4
    case x5 = 5
    case x6 = 6
    case x7 = 7
    case x8 = 8
    case x9 = 9
    case x10 = 10
    case x11 = 11
    case x12 = 12
    case x13 = 13
    case x14 = 14
    case x15 = 15
    case x16 = 16
    case x17 = 17
    case x18 = 18
    case x19 = 19
    case x20 = 20
    case x21 = 21
    case x22 = 22
    case x23 = 23
    case x24 = 24
    case x25 = 25
    case x26 = 26
    case x27 = 27
    case x28 = 28
    case x29_fp = 29  // frame pointer
    case x30_lr = 30  // /link register
    case sp = 31

    var debugDescription: String {
        switch(self) {
            case .sp:
                return "sp"
            case .x29_fp:
                return "x29"
            case .x30_lr:
                return "x30"
            default:
                return "x\(self.rawValue)"
        }
    }
}

enum IndexingMode {
    // If specified, the offset we can use must be in the range -256 to 255
    case pre
    case post
}

enum Register32: UInt8, Register {
    typealias Shift = Shift32
    typealias ExtendOp = ExtendOp32
    var is32: Bool { true }

    var debugDescription: String {
        return "w\(self.rawValue)"
    }
    
    var to64: Register64 {
        Register64(rawValue: self.rawValue)!
    }

    case w0 = 0
    case w1 = 1
    case w2 = 2
    case w3 = 3
    case w4 = 4
    case w5 = 5
    case w6 = 6
    case w7 = 7
    case w8 = 8
    case w9 = 9
    case w10 = 10
    case w11 = 11
    case w12 = 12
    case w13 = 13
    case w14 = 14
    case w15 = 15
    case w16 = 16
    case w17 = 17
    case w18 = 18
    case w19 = 19
    case w20 = 20
    case w21 = 21
    case w22 = 22
    case w23 = 23
    case w24 = 24
    case w25 = 25
    case w26 = 26
    case w27 = 27
    case w28 = 28
    case wZR = 31 // 0b11111
}

enum LdrMode {
    case _32(Register32, Register64, Offset?)  // e.g. w0 <- [x1]
    case _64(Register64, Register64, Offset?)  // e.g. x0 <- [x1]
}

enum RegModifier {
    case r64ext(Register64, Register64.ExtendOp)
    case r32ext(Register32, Register32.ExtendOp)
    // TODO: rename rshift ?
    case r64shift(any Register, Shift64_Real)
    case imm(Int64, IndexingMode?)
}

// TODO: this should be more accurately named M1Address or something like that (to signify
// it represents where source data comes from, which is not necessarily an offset)

fileprivate func getIxModeDebugDesc(_ r: any Register, _ immVal: Int64, _ ix: IndexingMode?) -> String {
    switch(ix) {
    case .post:
        return "[\(r)], #\(immVal)"
    case .pre:
        return "[\(r), #\(immVal)]!"
    case nil:
        if immVal == 0 {
            return "[\(r)]"
        } else {
            return "[\(r), #\(immVal)]"
        }
    }
}

enum Offset : CustomDebugStringConvertible {

    // Register base + immediate offset
    case imm64(/*Xn|SP*/Register64, Int64, IndexingMode?)
    
    // Register base + register offset
    case reg64(/*Xn|SP*/Register64, /*Wm|Xm...*/RegModifier?)
    
    // DEPRECATED
    case immediate(Int16)
    case reg64offset(Register64, Int64, IndexingMode?)
    case reg32shift(Register32, Register32.Shift?)
    case reg64shift(Register64, Register64.Shift?)
    case reg32(Register32, Register32.ExtendOp, IndexingMode?)
    
    var debugDescription: String {
        switch(self) {
        
        case .imm64(let Rt, let immVal, let ixMode):
            return getIxModeDebugDesc(Rt, immVal, ixMode)
        case .reg64(let Rt, .r64shift(let Rn, .lsl(0))):
            return "[\(Rt), \(Rn)]"
        case .reg64(let Rt, .r64shift(let Rn, let shift)):
            return "[\(Rt), \(Rn), \(shift)]"
        case .reg64(let Rt, nil):
            return "[\(Rt)]"
        case .reg64(let Rt, .r64ext(let Rn as any Register, let ext as CustomDebugStringConvertible)):
            fallthrough
        case .reg64(let Rt, .r32ext(let Rn as any Register, let ext as CustomDebugStringConvertible)):
            return "[\(Rt), \(Rn), \(ext)]"
        case .reg64(let Rt, .imm(let immVal, let ixMode)):
            return getIxModeDebugDesc(Rt, immVal, ixMode)
            
        // DEPRECATED
        case .immediate(_):
            return "imm DEPRECATED"
        case .reg64offset(_, _, _):
            return "reg64offset DEPRECATED"
        case .reg32shift(_, _):
            return "reg32shift DEPRECATED"
        case .reg64shift(_, _):
            return "reg64shift DEPRECATED"
        case .reg32(_, _, _):
            return "reg32 DEPRECATED"
        }
    }
}

public enum EmitterM1Error: Error, Equatable {
    case invalidShift
    case unsupportedOp
    case invalidRegister(_ reason: String)
    case invalidOffset(_ reason: String)
    case invalidValue(_ reason: String)
}

public class EmitterM1 {
    private static func returnAsArray(_ val: Int64) -> [UInt8] {
        let length: Int = 4 * MemoryLayout<UInt8>.size
        let result = withUnsafeBytes(of: val) { bytes in Array(bytes.prefix(length)) }
//         print(
//             "Returning \(result.map { String($0, radix: 16).leftPadding(toLength: 2, withPad: "0") })"
//         )
        return result
    }

    static func encodeReg(_ reg: any Register, shift: Int64) -> Int64 {
        (Int64(0b11111) & Int64(reg.rawValue)) << shift
    }
    
    static func sizeMask(is64: Bool, offset: Int = 31) -> Int64 {
        (is64 ? 1 : 0) << offset
    }

    static func truncateOffset(_ val: Int64, divisor: Int64, bits: Int64) throws
        -> Int64
    {
        if val % divisor != 0 {
            throw EmitterM1Error.invalidOffset(
                "truncateOffset: offset immediate must be a multiple of \(divisor) but was \(val)"
            )
        }

        let divided = val / divisor
        let mask: Int64 = ((1 << bits) - 1)
        // Check if we fit in required number of bits
        let compare: Int64
        if divided >= 0 {
            compare = divided & mask
        }
        else {
            let rmask: Int64 = (~mask | 0b1000000)
            compare = (divided & mask) | rmask
        }
        guard compare == divided else {
            throw EmitterM1Error.invalidOffset(
                "Offset immediate \(val) must fit in \(bits) bits"
            )
        }

        // apply mask otherwise a negative value will contain leading 1s,
        // which can mess up when shifting left later
        return (mask & divided)
    }

    // 0b0b10101010000000100000001111100000

    func emit(for op: M1Op) throws -> [UInt8] {
        try Self.emit(for: op)
    }

    static func emit(for op: M1Op) throws -> [UInt8] {
        switch op.resolveFinalForm() {  // resolve potential aliases
        case .subImm12(let Rd, let Rn, let offset):
            guard Rd.is32 == Rn.is32 else {
                throw EmitterM1Error.invalidRegister("Rd and Rn must have same size")
            }
            guard offset.imm.isPositive else {
                return try emit(for: .add(Rd, Rn, Imm12Lsl12(offset.imm.flippedSign, lsl: offset.lsl)))
            }

            //                  S          sh imm12        Rn    Rd
            let mask: Int64 = 0b0_10100010_0__000000000000_00000_00000
            let encodedRd: Int64 = encodeReg(Rd, shift: 0)
            let encodedRn: Int64 = encodeReg(Rn, shift: 5)
            let size: Int64 = (Rd.is32 ? 0 : 1) << 31
            let sh: Int64 = (offset.lsl == ._0 ? 0 : 1) << 22
            let imm: Int64 = offset.imm.shiftedLeft(10)
            let encoded: Int64 = mask | encodedRd | encodedRn | size | sh | imm
            return returnAsArray(encoded)
        case .add(let Rd, let Rn, let offset):
            guard Rd.is32 == Rn.is32 else {
                throw EmitterM1Error.invalidRegister("Rd and Rn must have same size")
            }
            guard offset.imm.isPositive else {
                return try emit(for: .subImm12(Rd, Rn, Imm12Lsl12(offset.imm.flippedSign, lsl: offset.lsl)))
            }
            
            //                  S          sh imm12        Rn    Rd
            let mask: Int64 = 0b0_00100010_0__000000000000_00000_00000
            let encodedRd: Int64 = encodeReg(Rd, shift: 0)
            let encodedRn: Int64 = encodeReg(Rn, shift: 5)
            let size: Int64 = (Rd.is32 ? 0 : 1) << 31
            let sh: Int64 = (offset.lsl == ._0 ? 0 : 1) << 22
            let imm: Int64 = offset.imm.shiftedLeft(10)
            let encoded: Int64 = mask | encodedRd | encodedRn | size | sh | imm
            return returnAsArray(encoded)
        case .stur(let Rt, let Rn, let offset ):
            //                    S           imm9         Rn    Rt
            let mask: Int64 = 0b1_0_111000000_000000000_00_00000_00000
            let encodedRt = encodeReg(Rt, shift: 0)
            let encodedRn = encodeReg(Rn, shift: 5)
            let offs = (try truncateOffset(Int64(offset), divisor: 1, bits: 9)) << 12
            let size: Int64 = (Rt.is32 ? 0 : 1) << 30
            let encoded = mask | encodedRt | encodedRn | offs | size
            return returnAsArray(encoded)
        case .str(let Rt, let offset ):
            guard case .reg64offset(let Rn, let offsetCount, let ixMode) = offset else {
                throw EmitterM1Error.invalidOffset(
                    "STR can only have .reg64offset offset (todo: this is deprecated. Should implement other offset cases)"
                )
            }
            let mask: Int64
            switch(ixMode) {
                case nil: 
                    return try Self.emit(for: .stur(Rt, Rn, Int16(offsetCount)))
                    // TODO: stur should only be used when not divisible by 9 ^^^
                case .pre: 
                    //         S           imm9         Rn    Rt
                    mask = 0b1_0_111000000_000000000_11_00000_00000
                case .post: 
                    //         S           imm9         Rn    Rt
                    mask = 0b1_0_111000000_000000000_01_00000_00000
            }
            let encodedRt = encodeReg(Rt, shift: 0)
            let encodedRn = encodeReg(Rn, shift: 5)
            let offs = (try truncateOffset(Int64(offsetCount), divisor: 1, bits: 9)) << 12
            let size: Int64 = (Rt.is32 ? 0 : 1) << 30
            let encoded = mask | encodedRt | encodedRn | offs | size
            return returnAsArray(encoded)
        case .svc(let imm16):
            //                              imm16
            let mask: Int64 = 0b11010100000_0000000000000000_00001
            let encoded = mask | Int64(bitPattern: UInt64(imm16)) << 5
            return returnAsArray(encoded)
        case .adr64(let Rd, let offset):
            guard Rd != .sp else {
                throw EmitterM1Error.invalidRegister("Rd can not be SP for adr")
            }
            let immlo: Int64 = (Int64(offset.value) & 0b11) << 29
            let immhi: Int64 = (Int64(offset.value) & 0b111111111111111111100) << 3
            let encodedRd = encodeReg(Rd, shift: 0)
            let mask: Int64 = 1 << 28
            let encoded = mask | encodedRd | immlo | immhi 
            return returnAsArray(encoded)
        case .orr64(let Rd, let WZr, let Rn, let shift) where WZr == .sp && shift == nil:
            fallthrough
        case .movr64(let Rd, let Rn) where Rd == .sp || Rn == .sp: 
            let mask: Int64 = 0b10010001_00000000_00000000_00000000
            let encodedRd = encodeReg(Rd, shift: 0)
            let encodedRn = encodeReg(Rn, shift: 5)
            let imm12: Int64 = 0
            let encoded = mask | encodedRd | encodedRn | imm12
            return returnAsArray(encoded)
        case .movr64(let Rd, let Rm) where Rd != .sp && Rm != .sp:
            let mask: Int64 = 0b10101010_00000000_00000000_00000000
                              
            let encodedRd = encodeReg(Rd, shift: 0)
            let encodedRn = encodeReg(Register64.sp, shift: 5) // 0b11111
            let encodedRm = encodeReg(Rm, shift: 16) 
            let imm6: Int64 = 0
            let encoded = mask | encodedRm | encodedRd | encodedRn | imm6
            return returnAsArray(encoded)
        case .ldp(let pair, let offset):
            guard case .reg64offset(let Rn, let offsetCount, let ixMode) = offset else {
                throw EmitterM1Error.invalidOffset(
                    "LDP can only have .reg64offset offset"
                )
            }

            let divisor: Int64 = 8  // 64-bit ops. 32-bit ops have divisor 4
            let truncated = try truncateOffset(offsetCount, divisor: divisor, bits: 7)

            let (Rt1, Rt2) = pair
            
            let mask: Int64
            switch ixMode {
            case nil: 
                //       o      ixm imm7    Rt2   Rn    Rt1
                mask = 0b0010100101_0000000_00000_00000_00000
            case .pre: 
                //       o      ixm imm7    Rt2   Rn    Rt1
                mask = 0b0010100111_0000000_00000_00000_00000
            case .post: 
                //       o      ixm imm7    Rt2   Rn    Rt1
                mask = 0b0010100011_0000000_00000_00000_00000
            }

            let opc: Int64 = 0b10   // 64-bit hardcoded (otherwise 0b00)
            let opcOffset: Int64 = 30
            let encodedRt1: Int64 = encodeReg(Rt1, shift: 0)
            let encodedRt2: Int64 = encodeReg(Rt2, shift: 10)
            let encodedRn: Int64 = encodeReg(Rn, shift: 5)
            let imm: Int64 = truncated << 15
            let encoded =
                encodedRt1 | encodedRt2 | encodedRn | (opc << opcOffset) | mask | imm
            return returnAsArray(encoded)
        case .stp(let pair, let offset):
            guard case .reg64offset(let Rn, let offsetCount, let ixMode) = offset else {
                throw EmitterM1Error.invalidOffset(
                    "STP can only have .reg64offset offset"
                )
            }

            let divisor: Int64 = 8  // 64-bit ops. 32-bit ops have divisor 4
            let truncated = try truncateOffset(offsetCount, divisor: divisor, bits: 7)
            let (Rt1, Rt2) = pair
            let encodedRt1: Int64 = encodeReg(Rt1, shift: 0)
            let encodedRt2: Int64 = encodeReg(Rt2, shift: 10)
            let encodedRn: Int64 = encodeReg(Rn, shift: 5)
            let opc: Int64 = 0b10
            let opcOffset: Int64 = 30

            let mask: Int64
            switch ixMode {
            case nil: mask = 0b0010_1001_0000_0000_0000_0000_0000_0000
            case .pre: mask = 0b0010_1001_1000_0000_0000_0000_0000_0000
            case .post: mask = 0b0010_1000_1000_0000_0000_0000_0000_0000
            }
            let imm: Int64 = truncated << 15
            let encoded =
                encodedRt1 | encodedRt2 | encodedRn | (opc << opcOffset) | mask | imm
            return returnAsArray(encoded)
        case .b(let imm26):
            let imm = try truncateOffset(Int64(imm26.value), divisor: 4, bits: 26)
            //                         imm26
            let mask: Int64 = 0b000101_00000000000000000000000000
            let encoded = mask | imm
            return returnAsArray(encoded)
        case .bl(let imm26):
            guard (imm26.immediate & 0x3FFFFFF) == imm26.immediate else {
                throw EmitterM1Error.invalidValue(
                    "BL requires the immediate to fit in 26 bits"
                )
            }
            guard imm26.immediate % 4 == 0 else {
                throw EmitterM1Error.invalidValue(
                    "BL requires the immediate to be a multiple of 4"
                )
            }
            let mask: Int64 = 0b1001_0100_0000_0000_0000_0000_0000_0000
            return returnAsArray(mask | Int64(imm26.immediate / 4))
        case .blr(let Rn):
            let mask: Int64 = 0b1101_0110_0011_1111_0000_0000_0000_0000
            let encodedRn = encodeReg(Rn, shift: 5)
            return returnAsArray(mask | encodedRn)
        case .nop: return [0x1f, 0x20, 0x03, 0xd5]
        case .ret: return [0xc0, 0x03, 0x5f, 0xd6]
        case .ldur(let Rt, let Rn, let offset ):
            //                    S           imm9         Rn    Rt
            let mask: Int64 = 0b1_0_111000010_000000000_00_00000_00000
            let encodedRt = encodeReg(Rt, shift: 0)
            let encodedRn = encodeReg(Rn, shift: 5)
            let offs = offset.immediate.shiftedLeft(12)
            let size: Int64 = (Rt.is32 ? 0 : 1) << 30
            let encoded = mask | encodedRt | encodedRn | offs | size
            return returnAsArray(encoded)
        case .ldr(let Rt, let offset):
        
            guard case .reg64offset(let Rn, let offsetCount, let ixMode) = offset else {
                throw EmitterM1Error.invalidOffset(
                    "LDR can only have .reg64offset offset"
                )
            }

            let mask: Int64
            let immBits: Int64
            let immShift: Int64
            let divider: Int64
            switch(ixMode) {
                case nil: 
                    //         S          imm12        Rn    Rt
                    mask = 0b1_0_11100101_000000000000_00000_00000
                    immBits = 12
                    immShift = 10
                    divider = Rt.is32 ? 4 : 8 // pimm
                case .pre: 
                    //         S           imm9
                    mask = 0b1_0_111000010_000000000_11_00000_00000
                    immBits = 9
                    immShift = 12
                    divider = 1 // simm
                case .post: 
                    //         S           imm9         Rn    Rt
                    mask = 0b1_0_111000010_000000000_01_00000_00000
                    immBits = 9
                    immShift = 12
                    divider = 1 // simm
            }
            let encodedRt = encodeReg(Rt, shift: 0)
            let encodedRn = encodeReg(Rn, shift: 5)
            let imm = (try truncateOffset(Int64(offsetCount), divisor: divider, bits: immBits)) << immShift
            let size: Int64 = (Rt.is32 ? 0 : 1) << 30
            let encoded = mask | encodedRt | encodedRn | imm | size
            return returnAsArray(encoded)
        case .movk64(let register, let val, let shift):
            // xx1x 0010 1xxi iiii iiii iiii iiid dddd
            let encodedR = encodeReg(register, shift: 0)
            let encodedVal: Int64 = (Int64(val) << 5) & 0b0001_1111_1111_1111_1110_0000
            let mask: Int64 = 0b1111_0010_1000_0000_0000_0000_0000_0000
            let hwMask: Int64 = 0b0000_0000_0110_0000_0000_0000_0000_0000
            let shiftVal: Int64

            if let shift = shift {
                let shiftValPre = (Int64)((shift.rawValue / 16) << 21)
                shiftVal = shiftValPre & hwMask
            }
            else {
                shiftVal = 0
            }

            let encoded: Int64 = encodedR | encodedVal | shiftVal | mask
            return returnAsArray(encoded)
        case .movz64(let register, let val, let shift):
            // https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/MOVZ--Move-wide-with-zero-?lang=en#MOVZ_32_movewide

            // x10x 0010 1xxi iiii iiii iiii iiid dddd  -  movz Rd HALF
            let encodedR = encodeReg(register, shift: 0)
            let encodedVal: Int64 = (Int64(val) << 5) & 0b0001_1111_1111_1111_1110_0000
            let mask: Int64 = 0b1101_0010_1000_0000_0000_0000_0000_0000
            let hwMask: Int64 = 0b0000_0000_0110_0000_0000_0000_0000_0000
            let shiftVal: Int64

            if let shift = shift {
                let shiftValPre = (Int64)((shift.rawValue / 16) << 21)
                shiftVal = shiftValPre & hwMask
            }
            else {
                shiftVal = 0
            }

            let encoded: Int64 = encodedR | encodedVal | shiftVal | mask
            return returnAsArray(encoded)
        case .subs(let Rd, let Rn, .reg64shift(let Rm, nil)):
            guard Rd.is32 == Rn.is32 && Rd.is32 == Rm.is32 else {
                fatalError("All registers must be the same size")
            }
            let mask: Int64 = 0b01101011000000000000000000000000
            let encodedRd: Int64 = encodeReg(Rd, shift: 0)
            let encodedRn: Int64 = encodeReg(Rn, shift: 5)
            let encodedRm: Int64 = encodeReg(Rm, shift: 16)
            let imm6: Int64 = 0
            let shift: Int64 = 0
            let size: Int64 = (Rd.is32 ? 0 : 1) << 31
            let encoded: Int64 = mask | size | shift | encodedRm | imm6 | encodedRn | encodedRd
            return returnAsArray(encoded)
        case .b_lt(let imm):
            //                           imm19                 cond
            let mask: Int64 = 0b01010100_0000000000000000000_0_1011
            let imm16: Int64 = (imm.shiftedRight(2) /* div by 4 */) << 5
            let encoded = mask | imm16
            return returnAsArray(encoded)
        case .b_eq(let imm):
            //                           imm19                 cond
            let mask: Int64 = 0b01010100_0000000000000000000_0_0000
            let imm16: Int64 = (imm.shiftedRight(2) /* div by 4 */) << 5
            let encoded = mask | imm16
            return returnAsArray(encoded)
        case .b_ne(let imm):
            //                           imm19                 cond
            let mask: Int64 = 0b01010100_0000000000000000000_0_0001
            let imm16: Int64 = (imm.shiftedRight(2) /* div by 4 */) << 5
            let encoded = mask | imm16
            return returnAsArray(encoded)
        case .b_gt(let imm):
            //                           imm19                 cond
            let mask: Int64 = 0b01010100_0000000000000000000_0_1100
            let imm16: Int64 = (imm.shiftedRight(2) /* div by 4 */) << 5
            let encoded = mask | imm16
            return returnAsArray(encoded)
        case .b_ge(let imm):
            //                           imm19                 cond
            let mask: Int64 = 0b01010100_0000000000000000000_0_1010
            let imm16: Int64 = (imm.shiftedRight(2) /* div by 4 */) << 5
            let encoded = mask | imm16
            return returnAsArray(encoded)
        case .b_le(let imm):
            //                           imm19                 cond
            let mask: Int64 = 0b01010100_0000000000000000000_0_1101
            let imm16: Int64 = (imm.shiftedRight(2) /* div by 4 */) << 5
            let encoded = mask | imm16
            return returnAsArray(encoded)
        case .ubfm(let Rd, let Rn, let immr, let imms):
            guard Rd.is32 == Rn.is32 else { fatalError("Registers must have the same size") }
            let N: Int64
            if Rd.is32 {
                guard immr.immediate >= 0 && immr.immediate < 32 else {
                    fatalError("immediate must be an integer in range [0, 31]")
                }
                N = 0 << 22
                
                guard imms.immediate != 0b011111 else {
                    fatalError("imms can not be 011111 in 32-bit mode")
                }
            }
            else if Rd.is64 {
                guard immr.immediate >= 0 && immr.immediate < 64 else {
                    fatalError("immediate must be an integer in range [0, 63]")
                }
                N = 1 << 22
                
                guard imms.immediate != 0b111111 else {
                    fatalError("imms can not be 111111 in 64-bit mode")
                }
            } else {
                fatalError("Registers must be either 32 bit or 64 bit")
            }
            //                  S          N immr   imms   Rn    Rd
            let mask: Int64 = 0b0_10100110_0_000000_000000_00000_00000
            let size: Int64 = (Rd.is32 ? 0 : 1) << 31
            let encodedRd = encodeReg(Rd, shift: 0)
            let encodedRn = encodeReg(Rn, shift: 5)
            let encoded = size | mask | N | immr.shiftedLeft(16) | imms.shiftedLeft(10) | encodedRd | encodedRn
            return returnAsArray(encoded)
        case .lslv(let Rd, let Rn, let Rm):
            //                  S            Rm           Rn    Rd
            let mask: Int64 = 0b0_0011010110_00000_001000_00000_00000
            let encodedRd = encodeReg(Rd, shift: 0)
            let encodedRn = encodeReg(Rn, shift: 5)
            let encodedRm = encodeReg(Rm, shift: 16)
            let size = sizeMask(is64: Rd.is64)
            let encoded = mask | encodedRd | encodedRn | encodedRm | size
            return returnAsArray(encoded)
        case .ldrb(let Wt, .imm64(let Xn, let immRaw, let ixMode)):
            let mask: Int64
            let imm: any Immediate
            let immShift: Int
            switch(ixMode) {
            case .post:
                //                   imm9         Rn    Rt
                mask = 0b00111000010_000000000_01_00000_00000
                imm = try Immediate9(immRaw)
                immShift = 12
            case .pre:
                //                   imm9         Rn    Rt
                mask = 0b00111000010_000000000_11_00000_00000
                imm = try Immediate9(immRaw)
                immShift = 12
            case nil:
                //                  imm12        Rn    Rt
                mask = 0b0011100101_000000000000_00000_00000_
                imm = try Immediate12(immRaw)
                immShift = 10
            }
            let encodedRt = encodeReg(Wt, shift: 0)
            let encodedRn = encodeReg(Xn, shift: 5)
            let encodedImm = imm.shiftedLeft(immShift)
            let encoded = encodedRt | encodedRn | encodedImm | mask
            return returnAsArray(encoded)
        case .ldrb(let Wt, .reg64(let Xn, let mod)):
            //                              Rm    opt      Rn    Rt
            let mask: Int64 = 0b00111000011_00000_000_0_10_00000_00000
            let option: Int64
            let Rm: any Register
            let S: Int64
            switch(mod) {
            case .r64ext(let _Rm, let mod):
                Rm = _Rm
                switch(mod) {
                case .sxtx(0):
                    S = 1
                    option = 0b111
                case .sxtx:
                    fatalError("Expected .sxtx #0")
                }
            case .r32ext(let _Rm, let mod):
                Rm = _Rm
                S = 1
                switch(mod) {
                case .uxtw(0):
                    option = 0b010
                case .sxtw(0):
                    option = 0b110
                case .sxtw:
                    fatalError("Expected .sxtw #0")
                case .uxtw:
                    fatalError("Expected .uxtw #0")
                }
            case .r64shift(let _Rm, .lsl(0)):
                Rm = _Rm
                option = 0b011
                S = 0
            case nil:
                Rm = X.x0
                S = 0
                option = 0b000
            default:
                fatalError("not implemented")
            }
            let shiftedS: Int64 = S << 12
            let shiftedOpt = option << 13
            let encodedRn = encodeReg(Xn, shift: 5)
            let encodedRt = encodeReg(Wt, shift: 0)
            let encodedRm = encodeReg(Rm, shift: 16)
            
            let encoded = mask | encodedRn | encodedRt | encodedRm | shiftedOpt | shiftedS
            return returnAsArray(encoded)
        case .ldrh(let Wt, .imm64(let Xn, let immRaw, let ixMode)):
            let mask: Int64
            let imm: any Immediate
            let immShift: Int
            switch(ixMode) {
            case .post:
                //                   imm9         Rn    Rt
                mask = 0b01111000010_000000000_01_00000_00000
                imm = try Immediate9(immRaw)
                immShift = 12
            case .pre:
                //                   imm9         Rn    Rt
                mask = 0b01111000010_000000000_11_00000_00000
                imm = try Immediate9(immRaw)
                immShift = 12
            case nil:
                //                  imm12        Rn    Rt
                mask = 0b0111100101_000000000000_00000_00000_
                imm = try Immediate12(immRaw)
                immShift = 9 // shift left +10 for the position, but shift -1 back cause pimm==imm*2. So total shift 9
            }
            let encodedRt = encodeReg(Wt, shift: 0)
            let encodedRn = encodeReg(Xn, shift: 5)
            let encodedPimm = imm.shiftedLeft(immShift)
            let encoded = encodedRt | encodedRn | encodedPimm | mask
            return returnAsArray(encoded)
        case .ldrh(let Wt, .reg64(let Xn, let mod)):
            //                              Rm    opt      Rn    Rt
            let mask: Int64 = 0b01111000011_00000_000_0_10_00000_00000
            let option: Int64
            let Rm: any Register
            let S: Int64
            switch(mod) {
            case .r64shift(let _Rm, .lsl(let lslAmount)):
                Rm = _Rm
                guard lslAmount == 0 || lslAmount == 1 else {
                    fatalError("Expected .lsl #0 or #1")
                }
                S = Int64(lslAmount)
                option = 0b011
            case .r64ext(let _Rm, let mod):
                Rm = _Rm
                switch(mod) {
                case .sxtx(0):
                    S = 0
                    option = 0b111
                case .sxtx(1):
                    S = 1
                    option = 0b111
                case .sxtx:
                    fatalError("Expected .sxtx #0 or #1")
                }
            case .r32ext(let _Rm, let mod):
                Rm = _Rm
                switch(mod) {
                case .uxtw(0):
                    S = 0
                    option = 0b010
                case .uxtw(1):
                    S = 1
                    option = 0b010
                case .sxtw(0):
                    S = 0
                    option = 0b110
                case .sxtw(1):
                    S = 1
                    option = 0b110
                case .sxtw:
                    fatalError("Expected .sxtw #0 or #1")
                case .uxtw:
                    fatalError("Expected .uxtw #0 or #1")
                }
            case nil:
                Rm = X.x0
                S = 0
                option = 0b000
            default:
                fatalError("not implemented")
            }
            let shiftedS: Int64 = S << 12
            let shiftedOpt = option << 13
            let encodedRn = encodeReg(Xn, shift: 5)
            let encodedRt = encodeReg(Wt, shift: 0)
            let encodedRm = encodeReg(Rm, shift: 16)
            
            let encoded = mask | encodedRn | encodedRt | encodedRm | shiftedOpt | shiftedS
            return returnAsArray(encoded)
        case .and(let Rd, let Rn, .imm(let imm, nil)):
            let sf = sizeMask(is64: Rd.is64)
            //                  S          N immr   imms   Rn    Rd
            let mask: Int64 = 0b0_00100100_0_000000_000000_00000_00000
            
            guard Rd.is32 == Rn.is32 else {
                fatalError("Rd and Rn must be the same size for AND (immediate)")
            }
            
            let bmi = try! BitmaskImmediate(UInt64(bitPattern: imm))
            guard (Rd.is32 && bmi.n == 0) || Rd.is64 else {
                fatalError("n can't be 1 for 32-bit operation")
            }
            
            let encodedRn = encodeReg(Rn, shift: 5)
            let encodedRd = encodeReg(Rd, shift: 0)
            let encoded = sf | mask | (Int64(bmi.n) << 22) | Int64(bmi.imms) << 10 | Int64(bmi.immr) << 16 | encodedRn | encodedRd
            return returnAsArray(encoded)
        case .and(let Rd, let Rn, .r64shift(let Rm, let shift)):
            let sf = sizeMask(is64: Rd.is64)
            //                  S        SH N Rm    imm6   Rn    Rd
            let mask: Int64 = 0b00001010_00_0_00000_000000_00000_00000
                              
            let imm6: Int64
            let sh: Int64
            switch(shift) {
            case .lsl(let amt):
                sh = 0b00
                imm6 = Int64(amt)
            case .lsr(let amt):
                sh = 0b01
                imm6 = Int64(amt)
            case .asr(let amt):
                sh = 0b10
                imm6 = Int64(amt)
            case .ror(let amt):
                sh = 0b11
                imm6 = Int64(amt)
            }
            
            guard Rd.is32 == Rn.is32, Rd.is32 == Rm.is32 else {
                fatalError("Rd, Rn, Rm must be the same size for AND (shifted register)")
            }
            
            let encodedRd = encodeReg(Rd, shift: 0)
            let encodedRn = encodeReg(Rn, shift: 5)
            let encodedRm = encodeReg(Rm, shift: 16)
            let encoded = sf | mask | (Int64(imm6) << 10) | encodedRm | encodedRn | encodedRd | (sh << 22)
            return returnAsArray(encoded)
        case .sbfm(let Rd, let Rn, let immr, let imms):
            //                  S        N immr   imms  Rn    Rd
            let mask: Int64 = 0b0001001100_000000_000000_00000_00000
            guard Rd.is32 == Rn.is32 else {
                fatalError("\(Rd) must be same size as second register. Received: \(Rn)")
            }
            let s = sizeMask(is64: Rd.is64)
            let n: Int64 = Rd.is64 ? 1 : 0
            let encodedRd = encodeReg(Rd, shift: 0)
            let encodedRn = encodeReg(Rn, shift: 5)
            let encoded = mask | s | (n << 22) | immr.shiftedLeft(16) | imms.shiftedLeft(10) | encodedRn | encodedRd
            return returnAsArray(encoded)
        case .sub(let Rd, let Rn, .r64shift(let Rm, let shift)):
            //                  S        SH   Rm    imm6   Rn    Rd
            let mask: Int64 = 0b01001011_00_0_00000_000000_00000_00000
            let s = sizeMask(is64: Rd.is64)
            let imm6: Immediate6
            let sh: Int64
            switch(shift) {
            case .lsl(let shiftAmt):
                sh = 0b00
                imm6 = try! Immediate6(shiftAmt)
            case .lsr(let shiftAmt):
                sh = 0b01
                imm6 = try! Immediate6(shiftAmt)
            case .asr(let shiftAmt):
                sh = 0b11
                imm6 = try! Immediate6(shiftAmt)
            default:
                fatalError("Unsupported shift")
            }
            let encodedRd = encodeReg(Rd, shift: 0)
            let encodedRn = encodeReg(Rn, shift: 5)
            let encodedRm = encodeReg(Rm, shift: 16)
            let encoded = s | mask | (sh << 22) | encodedRd | encodedRm | encodedRn | imm6.shiftedLeft(10)
            return returnAsArray(encoded)
        default: throw EmitterM1Error.unsupportedOp
        }
    }
}

extension String {
    func splitString(_ withSize: Int) -> [String] {
        let a = self[self.startIndex..<self.index(self.startIndex, offsetBy: withSize)]
        let b = self[self.index(self.startIndex, offsetBy: withSize)..<self.endIndex]
        return [String(a), String(b)]
    }

    func leftPadding(toLength: Int, withPad: String = " ") -> String {

        guard toLength > self.count else { return self }

        let padding = String(repeating: withPad, count: toLength - self.count)
        return padding + self
    }

    func rightPadding(toLength: Int, withPad: String = " ") -> String {

        guard toLength > self.count else { return self }

        let padding = String(repeating: withPad, count: toLength - self.count)
        return self + padding
    }
}
