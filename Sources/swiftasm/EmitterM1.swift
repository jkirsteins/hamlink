public protocol Register {
    associatedtype Shift

    var rawValue: UInt8 { get }
}

public enum Shift64 : Int {
    case _0 = 0
    case _16 = 16
    case _32 = 32
    case _48 = 48
}

public enum Shift32 : Int {
    case _0 = 0
    case _16 = 16
}

public enum Register64 : UInt8, Register {
    public typealias Shift = Shift64

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
    case x29_fp = 29   // frame pointer
    case x30_lr = 30   // /link register
    case sp = 31
}

enum ExtendOp32 {
    case sxtw(Register32.Shift?)    // ExtendSigned32To64
    case uxtw(Register32.Shift?)    // ExtendUnsigned32To64
}

enum IndexingMode {
    // If specified, the offset we can use must be in the range -256 to 255
    case pre
    case post
}

enum Register32 : UInt8, Register {
    typealias Shift = Shift32
    typealias ExtendOp = ExtendOp32    

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
}

enum Op {
    case nop
    case ret 

    // https://developer.arm.com/documentation/dui0802/a/A64-General-Instructions/MOVZ
    case movz32(Register32, UInt16, Register32.Shift?)
    case movz64(Register64, UInt16, Register64.Shift?)

    // https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/MOVK--Move-wide-with-keep-
    case movk64(Register64, UInt16, Register64.Shift?)

    /* 
    # LDR (immediate)
    
    Loads a word or doubleword from memory and writes it to a register. 
    
    The address that is used for the load is calculated from a base register and an immediate offset. 

    Overview:
      - https://thinkingeek.com/2016/11/13/exploring-aarch64-assembler-chapter-5/
    
    Encoding:
        - https://developer.arm.com/documentation/ddi0596/2021-06/Index-by-Encoding/Loads-and-Stores?lang=en#ldst_pos
        - https://developer.arm.com/documentation/ddi0596/2021-06/Base-Instructions/LDR--immediate---Load-Register--immediate--?lang=en        
    */
    case ldr(LdrMode)
}

enum LdrMode {
    case _32(Register32, Register64, Offset?)   // e.g. w0 <- [x1]
    case _64(Register64, Register64, Offset?)   // e.g. x0 <- [x1]
}

enum Offset {
    case immediate(Int16)
    case reg64(Register64, Register64.Shift?, IndexingMode?)
    case reg32(Register32, Register32.ExtendOp, IndexingMode?)
}

public enum EmitterM1Error: Error, Equatable {
    case invalidShift
    case unsupportedOp
    case invalidOffset(_ reason: String)
}

public class EmitterM1
{
    private static func returnAsArray(_ val: Int64) -> [UInt8] {
        let length: Int = 4 * MemoryLayout<UInt8>.size  
        let result = withUnsafeBytes(of: val) { bytes in
            Array(bytes.prefix(length))
        }
        print("Returning \(result.map { String($0, radix: 16).leftPadding(toLength: 2, withPad: "0") })")
        return result
    }

    static func emit(for op: Op) throws -> [UInt8] {
        switch(op) {
            case .nop:
            return [0x1f, 0x20, 0x03, 0xd5]
            case .ret:
            return [0xc0, 0x03, 0x5f, 0xd6]

// Register32, Register64, Offset?)   // e.g. w0 <- [x1]
//     case _64(Register64, Register64, Offset?)   // e.g. x0 <- [x1]

            case .ldr(let ldrMode):
                let size: Int64
                let Rt: any Register
                let Rn: Register64
                let offset: Offset?
                switch(ldrMode) {
                    case ._32(let _rt, let _rn, let _offset):
                        size = 0b10
                        Rt = _rt
                        Rn = _rn
                        offset = _offset
                    case ._64(let _rt, let _rn, let _offset):
                        size = 0b11
                        Rt = _rt
                        Rn = _rn
                        offset = _offset
                }

                let is32b = size == 0b10

                switch(offset) {
                    case .immediate(let imm):
                    guard imm >= -256 else {
                        throw EmitterM1Error.invalidOffset("Offset can't be less than -256")
                    }
                    guard (!is32b) || (imm <= 255 && imm >= -256) || (imm >= 0 && imm <= 16380 && imm % 4 == 0) else {
                        throw EmitterM1Error.invalidOffset("Offset in 32-bit mode must be a multiple of 4 in range 0...16380")
                    }
                    guard (is32b) || (imm <= 255 && imm >= -256) || (imm >= 0 && imm <= 32760 && imm % 8 == 0) else {
                        throw EmitterM1Error.invalidOffset("Offset in 64-bit mode must be a multiple of 8 in range 0...32760")
                    }
                    default:
                    break
                }
                
                let sizeOffset: Int64 = 30
                let v: Int64 = 0
                let vOffset: Int64 = 26
                let opc: Int64 = 0b01
                let opcOffset: Int64 = 22
                let mask: Int64 = 0b0011_1001_0000_0000_0000_0000_0000_0000

                let encodedRt: Int64 = (Int64)(0b11111 & Rt.rawValue)
                let encodedRn: Int64 = (Int64)((0b11111 & Rn.rawValue) << 5)

                let encoded: Int64  = (size << sizeOffset) | (v << vOffset) | (opc << opcOffset) | mask | encodedRt | encodedRn
                return returnAsArray(encoded)
            case .movk64(let register, let val, let shift):
                // xx1x 0010 1xxi iiii iiii iiii iiid dddd
                let encodedR: Int64 = (Int64)(0b11111 & register.rawValue)
                let encodedVal: Int64 = (Int64(val) << 5) & 0b0001_1111_1111_1111_1110_0000
                let mask: Int64     = 0b1111_0010_1000_0000_0000_0000_0000_0000
                let hwMask: Int64   = 0b0000_0000_0110_0000_0000_0000_0000_0000
                
                let shiftVal: Int64

                if let shift = shift {
                    let shiftValPre = (Int64)((shift.rawValue / 16) << 21) 
                    shiftVal = shiftValPre & hwMask
                } else {
                    shiftVal = 0
                }

                let encoded: Int64  = encodedR | encodedVal | shiftVal | mask                
                return returnAsArray(encoded)
            case .movz64(let register, let val, let shift):
                // https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/MOVZ--Move-wide-with-zero-?lang=en#MOVZ_32_movewide

                // x10x 0010 1xxi iiii iiii iiii iiid dddd  -  movz Rd HALF
                let encodedR: Int64 = (Int64)(0b11111 & register.rawValue)
                let encodedVal: Int64 = (Int64(val) << 5) & 0b0001_1111_1111_1111_1110_0000
                let mask: Int64     = 0b1101_0010_1000_0000_0000_0000_0000_0000
                let hwMask: Int64   = 0b0000_0000_0110_0000_0000_0000_0000_0000
                
                let shiftVal: Int64

                if let shift = shift {
                    let shiftValPre = (Int64)((shift.rawValue / 16) << 21) 
                    shiftVal = shiftValPre & hwMask
                } else {
                    shiftVal = 0
                }

                let encoded: Int64  = encodedR | encodedVal | shiftVal | mask                
                return returnAsArray(encoded)
            default:
            throw EmitterM1Error.unsupportedOp
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
}