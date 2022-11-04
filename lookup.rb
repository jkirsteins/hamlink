def p(num, bits, offset)
    mask = bits.times.collect { |x| x }.reduce(0) { |x,y| x | (0b1 << y) }
    res = (num >> offset) & mask
    res = res.to_s(2)
    res.rjust(bits, "0")
end

def match(pattern, valIn)
    val = valIn.gsub(" ", "")
    pattern.gsub!(" ", "")
    pattern.gsub!("\t", "")
    if val.size != pattern.size 
        abort("#{val} not same len as #{pattern}")
    end
    pattern.each_char.with_index do |pchar,ix|
        if pchar == "x" 
            next
        end
        if pchar != val[ix]
            return false
        end
    end

    true
end

def lookup_loads_store_register__unsigned_immediate(val)
    size = p(val, 2, 30)
    v = p(val, 1, 26)
    opc = p(val, 2, 22)
    imm12 = p(val, 12, 10)
    rn = p(val, 5, 5)
    rt = p(val, 5, 0)
    
    puts("Loads and stores: https://developer.arm.com/documentation/ddi0596/2020-12/Index-by-Encoding/Loads-and-Stores?lang=en#ldst_pos")
    puts("    size = #{size}")
    puts("    v = #{v}")
    puts("    opc = #{opc}")
    puts("    imm12 = #{imm12}")
    puts("    rn = #{rn}")
    puts("    rt = #{rt}")
    
    valStr = "#{size}#{v}#{opc}"
    if match("x1 1 1x", valStr)
        abort("UNALLOCATED")
    elsif match("00 0 00", valStr) 
        abort("STRB (immediate)")
    elsif match("00 0 01", valStr) 
        abort("LDRB (immediate)")
    elsif match("00 0 10", valStr) 
        abort("LDRSB (immediate) — 64-bit")
    elsif match("00 0 11", valStr) 
        abort("LDRSB (immediate) — 32-bit")
    elsif match("00 1 00", valStr) 
        abort("STR (immediate, SIMD&FP) — 8-bit")
    elsif match("00 1 01", valStr)  
        abort("LDR (immediate, SIMD&FP) — 8-bit")
    elsif match("00 1 10", valStr)  
        abort("STR (immediate, SIMD&FP) — 128-bit")
    elsif match("00 1 11", valStr)  
        abort("LDR (immediate, SIMD&FP) — 128-bit")
    elsif match("01 0 00", valStr)  
        abort("STRH (immediate)")
    elsif match("01 0 01", valStr)  
        puts("LDRH (immediate)")
        puts("    https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/LDRH--immediate---Load-Register-Halfword--immediate--?lang=en")
    elsif match("01 0 10", valStr)  
        abort("LDRSH (immediate) — 64-bit")
    elsif match("01 0 11", valStr)  
        abort("LDRSH (immediate) — 32-bit")
    elsif match("01 1 00", valStr)  
        abort("STR (immediate, SIMD&FP) — 16-bit")
    elsif match("01 1 01", valStr)  
        abort("LDR (immediate, SIMD&FP) — 16-bit")
    elsif match("1x 0 11", valStr)  
        abort("UNALLOCATED")
    elsif match("1x 1 1x", valStr)  
        abort("UNALLOCATED")
    elsif match("10 0 00", valStr)  
        abort("STR (immediate) — 32-bit")
    elsif match("10 0 01", valStr)  
        abort("LDR (immediate) — 32-bit")
    elsif match("10 0 10", valStr)  
        abort("LDRSW (immediate)")
    elsif match("10 1 00", valStr)  
        abort("STR (immediate, SIMD&FP) — 32-bit")
    elsif match("10 1 01", valStr)  
        abort("LDR (immediate, SIMD&FP) — 32-bit")
    elsif match("11 0 00", valStr)  
        abort("STR (immediate) — 64-bit")
    elsif match("11 0 01", valStr)  
        abort("LDR (immediate) — 64-bit")
    elsif match("11 0 10", valStr)  
        abort("PRFM (immediate)")
    elsif match("11 1 00", valStr)  
        abort("STR (immediate, SIMD&FP) — 64-bit")
    elsif match("11 1 01", valStr)  
        abort("LDR (immediate, SIMD&FP) — 64-bit")
    else
        abort("UNALLOCATED")
    end
    
end

def lookup_loads_store_register__register_offset(val)
    size = p(val, 2, 30)
    v = p(val, 1, 26)
    opc = p(val, 2, 22)
    rm = p(val, 5, 16)
    opt = p(val, 3, 13)
    s = p(val, 1, 12)
    rn = p(val, 5, 5)
    rt = p(val, 5, 0)

    puts("Loads and stores: https://developer.arm.com/documentation/ddi0596/2020-12/Index-by-Encoding/Loads-and-Stores?lang=en#ldst_regoff")
    puts("    size = #{size}")
    puts("    v = #{v}")
    puts("    opc = #{opc}")
    puts("    rm = #{rm}")
    puts("    opt = #{opt}")
    puts("    s = #{s}")
    puts("    rn = #{rn}")
    puts("    rt = #{rt}")
    
    valStr = "#{size}#{v}#{opc}#{opt}"
    if match("x1 1 1x xxx", valStr)
        abort("UNALLOCATED")
    elsif match("00 0 00 xxx", valStr) and !match("xx x xx 011", valStr)
        abort("STRB (register) — extended register")
    elsif match("00 0 00 011", valStr)
        abort("STRB (register) — shifted register")
    elsif match("00 0 01 xxx", valStr) and !match("xx x xx 011", valStr)
        puts("LDRB (register) — extended register")
        puts("    https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/LDRB--register---Load-Register-Byte--register--")
    elsif match("00 0 01 011", valStr)
        puts("LDRB (register) — shifted register")
        puts("    https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/LDRB--register---Load-Register-Byte--register--")
    elsif match("00 0 10 xxx", valStr) and !match("xx x xx 011", valStr)
        abort("LDRSB (register) — 64-bit with extended register offset")
    elsif match("00 0 10 011", valStr)
        abort("LDRSB (register) — 64-bit with shifted register offset")
    elsif match("00 0 11 xxx", valStr) and !match("xx x xx 011", valStr)
        abort("LDRSB (register) — 32-bit with extended register offset")
    elsif match("00 0 11 011", valStr)
        abort("LDRSB (register) — 32-bit with shifted register offset")
    elsif match("00 1 00 xxx", valStr) and !match("xx x xx 011", valStr)
        abort("STR (register, SIMD&FP)")
    elsif match("00 1 00 011", valStr)
        abort("STR (register, SIMD&FP)")
    elsif match("00 1 01 xxx", valStr) and !match("xx x xx 011", valStr)
        abort("LDR (register, SIMD&FP)")
    elsif match("00 1 01 011", valStr)
        abort("LDR (register, SIMD&FP)")
    elsif match("00 1 10 xxx", valStr)
        abort("STR (register, SIMD&FP)")
    elsif match("00 1 11 xxx", valStr)
        abort("LDR (register, SIMD&FP)")
    elsif match("01 0 00 xxx", valStr)
        abort("STRH (register)")
    elsif match("01 0 01 xxx", valStr)
        puts("LDRH (register)")
        puts("    https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/LDRH--register---Load-Register-Halfword--register--?lang=en")
    elsif match("01 0 10 xxx", valStr)
        abort("LDRSH (register) — 64-bit")
    elsif match("01 0 11 xxx", valStr)
        abort("LDRSH (register) — 32-bit")
    elsif match("01 1 00 xxx", valStr)
        abort("STR (register, SIMD&FP)")
    elsif match("01 1 01 xxx", valStr)
        abort("LDR (register, SIMD&FP)")
    elsif match("1x 0 11 xxx", valStr)
        abort("UNALLOCATED")
    elsif match("1x 1 1x xxx", valStr)
        abort("UNALLOCATED")
    elsif match("10 0 00 xxx", valStr)
        puts("STR (register) — 32-bit")
        puts("    https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/STR--register---Store-Register--register--?lang=en")
    elsif match("10 0 01 xxx", valStr)
        puts("LDR (register) — 32-bit")
        puts("    https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/LDR--register---Load-Register--register--?lang=en")
    elsif match("10 0 10 xxx", valStr)
        abort("LDRSW (register)")
    elsif match("10 1 00 xxx", valStr)
        abort("STR (register, SIMD&FP)")
    elsif match("10 1 01 xxx", valStr)
        abort("LDR (register, SIMD&FP)")
    elsif match("11 0 00 xxx", valStr)
        puts("STR (register) — 64-bit")
        puts("    https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/STR--register---Store-Register--register--?lang=en")
    elsif match("11 0 01 xxx", valStr)
        puts("LDR (register) — 64-bit")
        puts("    https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/LDR--register---Load-Register--register--?lang=en")
    elsif match("11 0 10 xxx", valStr)
        abort("PRFM (register)")
    elsif match("11 1 00 xxx", valStr)
        abort("STR (register, SIMD&FP)")
    elsif match("11 1 01 xxx", valStr)
        abort("LDR (register, SIMD&FP)")
    else 
        abort("Unknown")
    end
end
    

# https://developer.arm.com/documentation/ddi0596/2020-12/Index-by-Encoding/Loads-and-Stores?lang=en
def lookup_loads_stores(val)
    op0 = p(val, 4, 28)
    op1 = p(val, 1, 26)
    op2 = p(val, 2, 23)
    op3 = p(val, 6, 16)
    op4 = p(val, 2, 10)

    puts("Loads and stores:")
    puts("    op0 = #{op0}")
    puts("    op1 = #{op1}")
    puts("    op2 = #{op2}")
    puts("    op3 = #{op3}")
    puts("    op4 = #{op4}")
    valStr = "#{op0}#{op1}#{op2}#{op3}#{op4}"
    if match("0x00 1 00 000000 xx", valStr)
        abort("Advanced SIMD load/store multiple structures")
    elsif match("0x00 1 01 0xxxxx xx", valStr)
        abort("Advanced SIMD load/store multiple structures (post-indexed)")
    elsif match("0x00 1 0x 1xxxxx xx", valStr)
        abort("UNALLOCATED")
    elsif match("0x00 1 10 x00000 xx", valStr)
        abort("Advanced SIMD load/store single structure")
    elsif match("0x00 1 x0 x1xxxx xx", valStr)
        abort("UNALLOCATED")
    elsif match("0x00 1 x0 xx1xxx xx", valStr)
        abort("UNALLOCATED")
    elsif match("0x00 1 x0 xxx1xx xx", valStr)
        abort("UNALLOCATED")
    elsif match("0x00 1 x0 xxxx1x xx", valStr)
        abort("UNALLOCATED")
    elsif match("0x00 1 x0 xxxxx1 xx", valStr)
        abort("UNALLOCATED")
    elsif match("1101 0 1x 1xxxxx xx", valStr)
        abort("Load/store memory tags")
    elsif match("1x00 1 xx xxxxxx xx", valStr)
        abort("UNALLOCATED")
    elsif match("xx00 0 0x xxxxxx xx", valStr)
        abort("Load/store exclusive")
    elsif match("xx01 0 1x 0xxxxx 00", valStr)
        abort("LDAPR/STLR (unscaled immediate)")
    elsif match("xx01 x 0x xxxxxx xx", valStr)
        abort("Load register (literal)")
    elsif match("xx10 x 00 xxxxxx xx", valStr)
        abort("Load/store no-allocate pair (offset)")
    elsif match("xx10 x 01 xxxxxx xx", valStr)
        abort("Load/store register pair (post-indexed)")
    elsif match("xx10 x 10 xxxxxx xx", valStr)
        abort("Load/store register pair (offset)")
    elsif match("xx10 x 11 xxxxxx xx", valStr)
        abort("Load/store register pair (pre-indexed)")
    elsif match("xx11 x 01 0xxxxx 00", valStr)
        abort("Load/store register (unscaled immediate)")
    elsif match("xx11 x 0x 0xxxxx 01", valStr)
        abort("Load/store register (immediate post-indexed)")
    elsif match("xx11 x 0x 0xxxxx 10", valStr)
        abort("Load/store register (unprivileged)")
    elsif match("xx11 x 0x 0xxxxx 11", valStr)
        abort("Load/store register (immediate pre-indexed)")
    elsif match("xx11 x 0x 1xxxxx 00", valStr)
        abort("Atomic memory operations")
    elsif match("xx11 x 0x 1xxxxx 10", valStr)
        lookup_loads_store_register__register_offset(val)
    elsif match("xx11 x 0x 1xxxxx x1", valStr)
        abort("Load/store register (pac)")
    elsif match("xx11 x 1x xxxxxx xx", valStr)
        lookup_loads_store_register__unsigned_immediate(val)
    else 
        abort("Unknown #{val}")
    end
end

# https://developer.arm.com/documentation/ddi0596/2020-12/Index-by-Encoding/Data-Processing----Immediate?lang=en#log_imm
def lookup_data_processing__immediate__logical(val)
    sf = p(val, 1, 31)
    opc = p(val, 2, 29)
    n = p(val, 1, 22)
    immr = p(val, 6, 16)
    imms = p(val, 6, 10)
    rn = p(val, 5, 5)
    rd = p(val, 5, 0)

    puts("Logical (immediate): https://developer.arm.com/documentation/ddi0596/2020-12/Index-by-Encoding/Data-Processing----Immediate?lang=en#log_imm")
    puts("    sf = #{sf}")
    puts("    opc = #{opc}")
    puts("    n = #{n}")
    puts("    immr = #{immr}")
    puts("    imms = #{imms}")
    puts("    rn = #{rn}")
    puts("    rd = #{rd}")
    valStr = "#{sf}#{opc}#{n}"

    if match("0 xx 1", valStr)
        abort("UNALLOCATED")
    elsif match("0 00 0", valStr)
        abort("AND (immediate) — 32-bit")
    elsif match("0	01	0", valStr)
        abort("ORR (immediate) — 32-bit")
    elsif match("0	10	0", valStr)
        abort("EOR (immediate) — 32-bit")
    elsif match("0	11	0", valStr)
        abort("ANDS (immediate) — 32-bit")
    elsif match("1	00 x", valStr) 
        puts("AND (immediate) — 64-bit")
        puts("    https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/AND--immediate---Bitwise-AND--immediate--?lang=en")
    elsif match("1	01 x", valStr)
        abort("ORR (immediate) — 64-bit")
    elsif match("1	10 x", valStr)
        abort("EOR (immediate) — 64-bit")
    elsif match("1	11 x", valStr)
        abort("ANDS (immediate) — 64-bit")
    else 
        abort("Unknown")
    end 
end

def lookup_data_processing__immediate__bitfield(val)
    sf = p(val, 1, 31)
    opc = p(val, 2, 29)
    n = p(val, 1, 22)
    immr = p(val, 6, 16)
    imms = p(val, 6, 10)
    rn = p(val, 5, 5)
    rd = p(val, 5, 0)

    puts("Bitfield: https://developer.arm.com/documentation/ddi0596/2020-12/Index-by-Encoding/Data-Processing----Immediate?lang=en#bitfield")
    puts("    sf = #{sf}")
    puts("    opc = #{opc}")
    puts("    n = #{n}")
    puts("    immr = #{immr}")
    puts("    imms = #{imms}")
    puts("    rn = #{rn}")
    puts("    rd = #{rd}")

    valStr = "#{sf}#{opc}#{n}"	
    if match("x 11 x", valStr)
        abort("UNALLOCATED")
    elsif match("0 xx 1", valStr)
        abort("UNALLOCATED")
    elsif match("0 00 0", valStr)
        abort("SBFM — 32-bit")
    elsif match("0 01 0", valStr)
        abort("BFM — 32-bit")
    elsif match("0 10 0", valStr)
        puts("UBFM — 32-bit")
        puts("    https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/UBFM--Unsigned-Bitfield-Move-?lang=en")
    elsif match("1 xx 0", valStr)
        abort("UNALLOCATED")
    elsif match("1 00 1", valStr)
        puts("SBFM — 64-bit")
        puts("    https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/SBFM--Signed-Bitfield-Move-?lang=en")
    elsif match("1 01 1", valStr)
        abort("BFM — 64-bit")
    elsif match("1 10 1", valStr)
        puts("UBFM — 64-bit")
        puts("    https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/UBFM--Unsigned-Bitfield-Move-?lang=en")
    else 
        abort("UNALLOCATED")
    end
end

def lookup_data_processing__register__addsub_shifted_register(val)
    puts("Add/subtract (shifted register): https://developer.arm.com/documentation/ddi0596/2020-12/Index-by-Encoding/Data-Processing----Register?lang=en#addsub_shift")
    sf = p(val, 1, 31)
    op = p(val, 1, 30)
    s = p(val, 1, 29)
    sh = p(val, 2, 22)
    rm = p(val, 5, 16)
    imm6 = p(val, 6, 10)
    rn = p(val, 5, 5)
    rd = p(val, 5, 0)
    puts("    sf: #{sf}")
    puts("    op: #{op}")
    puts("    S: #{s}")
    puts("    shift: #{sh}")
    puts("    Rm: #{rm}")
    puts("    imm6: #{imm6}")
    puts("    Rn: #{rn}")
    puts("    Rd: #{rd}")

    valStr = "#{sf} #{op} #{s} #{sh} #{imm6}"
    if match("x x x 11 xxxxxx", valStr)
        abort("UNALLOCATED")
    elsif match("0 x x xx 1xxxxx", valStr)
        abort("UNALLOCATED")
    elsif match("0 0 0 xx xxxxxx", valStr)
        puts("ADD (shifted register) — 32-bit")
        puts("    https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/ADD--shifted-register---Add--shifted-register--?lang=en")
    elsif match("0 0 1 xx xxxxxx", valStr)
        abort("ADDS (shifted register) — 32-bit")
    elsif match("0 1 0 xx xxxxxx", valStr)
        abort("SUB (shifted register) — 32-bit")
    elsif match("0 1 1 xx xxxxxx", valStr)
        abort("SUBS (shifted register) — 32-bit")
    elsif match("1 0 0 xx xxxxxx", valStr)
        puts("ADD (shifted register) — 64-bit")
        puts("    https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/ADD--shifted-register---Add--shifted-register--?lang=en")
    elsif match("1 0 1 xx xxxxxx", valStr)
        abort("ADDS (shifted register) — 64-bit")
    elsif match("1 1 0 xx xxxxxx", valStr)
        puts("SUB (shifted register) — 64-bit")
        puts("    https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/SUB--shifted-register---Subtract--shifted-register--?lang=en")
    elsif match("1 1 1 xx xxxxxx", valStr)
        abort("SUBS (shifted register) — 64-bit")
    else 
        abort("Unknown")
    end
end

def lookup_data_processing__register__logical_shifted_register(val)
    puts("Logical (shifted register): https://developer.arm.com/documentation/ddi0596/2020-12/Index-by-Encoding/Data-Processing----Register?lang=en#log_shift")
    sf = p(val, 1, 31)
    opc = p(val, 2, 29)
    sh = p(val, 2, 22)
    n = p(val, 1, 21)
    rm = p(val, 5, 16)
    imm6 = p(val, 6, 10)
    rn = p(val, 5, 5)
    rd = p(val, 5, 0)
    puts("    sf: #{sf}")
    puts("    opc: #{opc}")
    puts("    shift: #{sh}")
    puts("    n: #{n}")
    puts("    Rm: #{rm}")
    puts("    imm6: #{imm6}")
    puts("    Rn: #{rn}")
    puts("    Rd: #{rd}")

    valStr = "#{sf} #{opc} #{n} #{imm6}"
    matches = {
        ["0	xx	x	1xxxxx"] => "UNALLOCATED",
        ["0	00	0	xxxxxx"] => "AND (shifted register) — 32-bit",
        ["0	00	1	xxxxxx"] => "BIC (shifted register) — 32-bit",
        ["0	01	0	xxxxxx"] => "ORR (shifted register) — 32-bit",
        ["0	01	1	xxxxxx"] => "ORN (shifted register) — 32-bit",
        ["0	10	0	xxxxxx"] => ["EOR (shifted register) — 32-bit", "https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/EOR--shifted-register---Bitwise-Exclusive-OR--shifted-register--?lang=en"],
        ["0	10	1	xxxxxx"] => "EON (shifted register) — 32-bit",
        ["0	11	0	xxxxxx"] => "ANDS (shifted register) — 32-bit",
        ["0	11	1	xxxxxx"] => "BICS (shifted register) — 32-bit",
        ["1	00	0	xxxxxx"] => "AND (shifted register) — 64-bit",
        ["1	00	1	xxxxxx"] => "BIC (shifted register) — 64-bit",
        ["1	01	0	xxxxxx"] => "ORR (shifted register) — 64-bit",
        ["1	01	1	xxxxxx"] => "ORN (shifted register) — 64-bit",
        ["1	10	0	xxxxxx"] => ["EOR (shifted register) — 64-bit", "https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/EOR--shifted-register---Bitwise-Exclusive-OR--shifted-register--?lang=en"],
        ["1	10	1	xxxxxx"] => "EON (shifted register) — 64-bit",
        ["1	11	0	xxxxxx"] => "ANDS (shifted register) — 64-bit",
        ["1	11	1	xxxxxx"] => "BICS (shifted register) — 64-bit",
    }
    _handle_matches(matches, valStr)
end

def lookup_data_processing__2source(val)
    puts("Data processing (2 source): https://developer.arm.com/documentation/ddi0596/2020-12/Index-by-Encoding/Data-Processing----Register?lang=en#dp_2src")
    sf = p(val, 1, 31)
    s = p(val, 1, 29)
    opcode = p(val, 6, 10)
    rm = p(val, 5, 16)
    rd = p(val, 5, 0)
    rn = p(val, 5, 5)
    valStr = "#{sf} #{s} #{opcode}"

    puts("    sf = #{sf}")
    puts("    s = #{s}")
    puts("    opcode = #{opcode}")
    puts("    rd = #{rd}")
    puts("    rn = #{rn}")
    puts("    rm = #{rm}")
    
    matches = {
        [
            "x x 000001", "x x 011xxx", "x x 1xxxxx",
            "x 0	00011x", "x 0	001101", "x 0	00111x", "x 1	00001x", "x 1	0001xx", "x 1	001xxx", "x 1	01xxxx",
            "0	x 000000",
            "0	0	00010x",
            "0	0	001100",
            "0	0	010x11",
            "1	0	010xx0",
            "1	0	010x0x"
        ] => "UNALLOCATED",
        ["0	0	000010"] => "UDIV — 32-bit",
        ["0	0	000011"] => "SDIV — 32-bit",
        ["0	0	001000"] => "LSLV — 32-bit	-",
        ["0	0	001001"] => ["LSRV — 32-bit", "https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/LSRV--Logical-Shift-Right-Variable-?lang=en"],
        ["0	0	001010"] => ["ASRV — 32-bit", "https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/ASRV--Arithmetic-Shift-Right-Variable-?lang=en"],
        ["0	0	001011"] => "RORV — 32-bit	-",
        ["0	0	010000"] => "CRC32B, CRC32H, CRC32W, CRC32X — CRC32B	-",
        ["0	0	010001"] => "CRC32B, CRC32H, CRC32W, CRC32X — CRC32H	-",
        ["0	0	010010"] => "CRC32B, CRC32H, CRC32W, CRC32X — CRC32W	-",
        ["0	0	010100"] => "CRC32CB, CRC32CH, CRC32CW, CRC32CX — CRC32CB	-",
        ["0	0	010101"] => "CRC32CB, CRC32CH, CRC32CW, CRC32CX — CRC32CH	-",
        ["0	0	010110"] => "CRC32CB, CRC32CH, CRC32CW, CRC32CX — CRC32CW	-",
        ["1	0	000000"] => "SUBP	FEAT_MTE",
        ["1	0	000010"] => "UDIV — 64-bit	-",
        ["1	0	000011"] => "SDIV — 64-bit	-",
        ["1	0	000100"] => "IRG	FEAT_MTE",
        ["1	0	000101"] => "GMI	FEAT_MTE",
        ["1	0	001000"] => "LSLV — 64-bit	-",
        ["1	0	001001"] => ["LSRV — 64-bit", "https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/LSRV--Logical-Shift-Right-Variable-?lang=en"],
        ["1	0	001010"] => ["ASRV — 64-bit", "https://developer.arm.com/documentation/ddi0596/2020-12/Base-Instructions/ASRV--Arithmetic-Shift-Right-Variable-?lang=en"],
        ["1	0	001011"] => "RORV — 64-bit	-",
        ["1	0	001100"] => "PACGA	FEAT_PAuth",
        ["1	0	010011"] => "CRC32B, CRC32H, CRC32W, CRC32X — CRC32X	-",
        ["1	0	010111"] => "CRC32CB, CRC32CH, CRC32CW, CRC32CX — CRC32CX	-",
        ["1	1	000000"] => "SUBPS"
    }
    _handle_matches(matches, valStr)
end

def _handle_matches(matches, valStr)
    matches.each do |patterns, target|
        patterns.each do |pattern|
            if match(pattern, valStr)
                if target.is_a? Array
                    puts("#{target[0]}")
                    puts("    #{target[1]}")
                else
                    abort(target)
                end
            end
        end
    end
    nil
end

def lookup_data_processing__register(val)
    op0 = p(val, 1, 29)
    op1 = p(val, 1, 28)
    op2 = p(val, 4, 21)
    op3 = p(val, 6, 10)

    valStr = "#{op0}#{op1}#{op2}#{op3}"

    puts("Data Processing -- Register: https://developer.arm.com/documentation/ddi0596/2020-12/Index-by-Encoding/Data-Processing----Register?lang=en")

    if match("0 1 0110 xxxxxx", valStr) 
        lookup_data_processing__2source(val)
    elsif match("1 1 0110 xxxxxx", valStr) 
        abort("Data-processing (1 source)")
    elsif match("x 0 0xxx xxxxxx", valStr) 
        lookup_data_processing__register__logical_shifted_register(val)
    elsif match("x 0 1xx0 xxxxxx", valStr)
        lookup_data_processing__register__addsub_shifted_register(val)
    elsif match("x 0 1xx1 xxxxxx", valStr)
        abort("Add/subtract (extended register)")
    elsif match("x 1 0000 000000", valStr)
        abort("Add/subtract (with carry)")
    elsif match("x 1 0000 x00001", valStr)
        abort("Rotate right into flags")
    elsif match("x 1 0000 xx0010", valStr)
        abort("Evaluate into flags")
    elsif match("x 1 0010 xxxx0x", valStr)
        abort("Conditional compare (register)")
    elsif match("x 1 0010 xxxx1x", valStr)
        abort("Conditional compare (immediate)")
    elsif match("x 1 0100 xxxxxx", valStr)
        abort("Conditional select")
    elsif match("x 1 1xxx xxxxxx", valStr)
        abort("Data-processing (3 source)")
    else
        abort("Unknown")
    end
end

# https://developer.arm.com/documentation/ddi0596/2020-12/Index-by-Encoding/Data-Processing----Immediate
def lookup_data_processing__immediate(val)
    op0 = p(val, 3, 23)

    puts("Data processing (immediate):")
    puts("    https://developer.arm.com/documentation/ddi0596/2020-12/Index-by-Encoding/Data-Processing----Immediate")

    valStr = "#{op0}"	
    if match("00x", valStr)
        abort("PC-rel. addressing")
    elsif match("010", valStr)
        abort("Add/subtract (immediate)")
    elsif match("011", valStr)
        abort("Add/subtract (immediate, with tags)")
    elsif match("100", valStr)
        lookup_data_processing__immediate__logical(val)
    elsif match("101", valStr)
        abort("Move wide (immediate)")
    elsif match("110", valStr)
        lookup_data_processing__immediate__bitfield(val)
    elsif match("111", valStr)
        abort("Extract")
    else 
        abort("Unknown")
    end 
end

def lookup_branches_exception_generating_and_system_instructions(val)
    puts("Branches, Exception Generating and System instructions: https://developer.arm.com/documentation/ddi0596/2020-12/Index-by-Encoding/Branches--Exception-Generating-and-System-instructions?lang=en")
    op0 = p(val, 3, 29)
    op1 = p(val, 14, 12)
    op2 = p(val, 5, 0)
    valStr = "#{op0} #{op1} #{op2}"
    puts("op0 = #{op0}")
    puts("op1 = #{op1}")
    puts("op2 = #{op2}")

    matches = {
        ["010 0xxxxxxxxxxxxx xxxxx"] => "Conditional branch (immediate)",    		
	    ["110	00xxxxxxxxxxxx xxxxx"] => "Exception generation",
	    ["110	01000000110001 xxxxx"] => "System instructions with register argument",
        ["110	01000000110010 11111"] => "Hints",
        ["110	01000000110011 xxxxx"] => "Barriers",
        ["110	0100000xxx0100 xxxxx"] => "PSTATE",
        ["110	0100x01xxxxxxx xxxxx"] => "System instructions",
        ["110	0100x1xxxxxxxx xxxxx"] => "System register move",
        ["110	1xxxxxxxxxxxxx xxxxx"] => "Unconditional branch (register)",
        ["x00   xxxxxxxxxxxxxx xxxxx"] => ["Unconditional branch (immediate)", "https://developer.arm.com/documentation/ddi0596/2020-12/Index-by-Encoding/Branches--Exception-Generating-and-System-instructions?lang=en#branch_imm"],
        ["x01	0xxxxxxxxxxxxx xxxxx"] => "Compare and branch (immediate)",
        ["x01	1xxxxxxxxxxxxx xxxxx"] => "Test and branch (immediate)"
    }
    _handle_matches(matches, valStr)
end

def lookup(val)
    op0 = p(val, 4, 25)
    puts("https://developer.arm.com/documentation/ddi0596/2020-12/Index-by-Encoding?lang=en")
    puts("Top-level op0: #{op0}")
    case op0
    when "0000" 
        abort("Reserved")
    when "0001"
        abort("UNALLOCATED")
    when "0010"
        abort("SVE encodings")
    when "0011"
        abort("UNALLOCATED")
    when "1000", "1001" 
        lookup_data_processing__immediate(val)
    when "1010", "1011" 
        lookup_branches_exception_generating_and_system_instructions(val)
    when "0100", "0110", "1100", "1110" 
        lookup_loads_stores(val)
    when "0101", "1101" 
        lookup_data_processing__register(val)
    when "0111", "1111" 
        abort("Data Processing -- Scalar Floating-Point and Advanced SIMD")
    else
        abort("Unknown")
    end
end

puts lookup(0xca020020)
