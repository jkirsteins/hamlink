import Foundation

struct HLTypeField: Equatable, CustomDebugStringConvertible, Hashable {
    let name: Resolvable<String>
    let type: Resolvable<HLType>

    var debugDescription: String {
        "\(name.value): <\(type.value.debugName)>@\(type.ix)"
    }
}

struct HLTypeBinding: Equatable, CustomDebugStringConvertible, Hashable {
    let fieldRefIx: Int32
    let functionIx: Int32

    var debugDescription: String { "HLTypeBinding<\(fieldRefIx), \(functionIx)>" }
}

struct HLTypeProto: Equatable, CustomDebugStringConvertible, Hashable {
    let name: Resolvable<String>
    let functionIx: Int32
    let pIx: Int32

    var debugDescription: String { "\(name.value): <fun>@\(functionIx) (\(pIx))" }
}

struct HLTypeEnumConstruct: Equatable, CustomDebugStringConvertible, Hashable {
    let name: Resolvable<String>
    let params: [Resolvable<HLType>]

    var debugDescription: String { "enumConstruct(\(name.value))" }
}

struct HLTypeEnumData: Equatable, CustomDebugStringConvertible, Hashable {
    let name: Resolvable<String>
    let global: Int32
    let constructs: [HLTypeEnumConstruct]
    var debugDescription: String { return "\(name.value)" }
}

struct HLTypeRefData: Equatable, CustomDebugStringConvertible, Hashable {
    let type: Resolvable<HLType>

    var debugDescription: String { type.value.debugName }
}

struct HLTypeNullData: Equatable, CustomDebugStringConvertible, Hashable {
    let type: Resolvable<HLType>

    var debugDescription: String { "null<\(type.value.debugName)>" }
}

struct HLTypeAbstractData: Equatable, CustomDebugStringConvertible, Hashable {
    let name: Resolvable<String>
    var debugDescription: String { return "\(name.value)" }
}

struct HLTypeVirtualData: Equatable, CustomDebugStringConvertible, Hashable {
    let fields: [HLTypeField]
    var debugDescription: String {
        return
            "virtual<\(fields.map { "\($0.name.value): \($0.type.debugDescription)" }.joined(separator: ", "))>"
    }
}

struct HLTypeFunData: Equatable, CustomDebugStringConvertible, Hashable {
    let args: [Resolvable<HLType>]
    let ret: Resolvable<HLType>

    var debugDescription: String {
        return
            "(\(args.map { $0.debugDescription }.joined(separator: ", "))) -> (\(ret.debugDescription))"
    }
}

extension Resolvable<String> {
    var debugDescription: String { "\(self.value)@\(self.ix)" }
}

extension Resolvable<HLType> {
    var debugDescription: String {
        let t = self.value
        switch t {
        case .obj(let data): return "\(data.name.value)@\(self.ix)"
        default: return "\(t.debugDescription)@\(self.ix)"
        }
    }
}

///
/// Reference to writing the data: https://github.com/HaxeFoundation/haxe/blob/c35bbd4472c3410943ae5199503c23a2b7d3c5d6/src/generators/genhl.ml#L3840
struct HLTypeObjData: Equatable, CustomDebugStringConvertible, Hashable {
    let name: Resolvable<String>
    let superType: Resolvable<HLType>?
    let global: Int32?

    let fields: [HLTypeField]
    let protos: [HLTypeProto]
    let bindings: [HLTypeBinding]

    var debugDescription: String {
        """
        \(name.debugDescription) \(superType == nil ? "" : "extends \(superType!.debugDescription)")
        global: \(global?.debugDescription ?? "nil")
        fields: \(fields.count > 0 ? "\n" : "")\((fields.map { "  \($0.debugDescription)" }).joined(separator: "\n"))
        protos: \(protos.count > 0 ? "\n" : "")\(protos.map { "  \($0.debugDescription)" }.joined(separator: "\n"))
        bindings: \(bindings.count > 0 ? "\n" : "")\(bindings.map { "  \($0.debugDescription)" }.joined(separator: "\n"))
        """
    }
}

protocol HLRegisterSizeProvider: Equatable, Hashable { var hlRegSize: ByteCount { get } }

extension HLType: HLRegisterSizeProvider {
    var hlRegSize: ByteCount {
        switch self {
        case .void: return 0  // void not really a value, used for typing purpose

        case .bool, .u8: return 1  // an unsigned 8 bits integer (0-255)

        case .u16: return 2
        case .i32, .f32: return 4
        case .i64, .f64: return 8

        // All the following values are memory addresse pointers and takes either 4 bytes in x86 mode or 8 bytes in x86-64 mode:

        case .bytes: fallthrough
        case .dyn, .fun, .array, .obj, .dynobj, .virtual, .enum, .ref, .null, .type,
            .abstract:
            return 8

        default: fatalError("Register size not available for \(self.debugName)")
        }
    }
}


/*
union {
    const uchar *abs_name;
    hl_type_fun *fun;
    hl_type_obj *obj;
    hl_type_enum *tenum;
    hl_type_virtual *virt;
    hl_type	*tparam;
};
*/

struct HLString {
    let ix: Int
}



/*
Memory layout should match

struct hl_type {
	hl_type_kind kind;
	union {
		const uchar *abs_name;
		hl_type_fun *fun;
		hl_type_obj *obj;
		hl_type_enum *tenum;
		hl_type_virtual *virt;
		hl_type	*tparam;
	};
	void **vobj_proto;
	unsigned int *mark_bits;
};
*/

struct HLTypeKind: HLRegisterSizeProvider, CustomDebugStringConvertible, ExpressibleByIntegerLiteral, Equatable, Hashable {  // not an enum because we need to force the size it takes
    let rawValue: UInt32

    init(integerLiteral value: UInt32) { self.init(rawValue: value) }

    init(rawValue value: UInt32) { self.rawValue = value }

    static let void = HLTypeKind(rawValue: 0)
    static let u8 = HLTypeKind(rawValue: 1)
    static let u16 = HLTypeKind(rawValue: 2)
    static let i32 = HLTypeKind(rawValue: 3)
    static let i64 = HLTypeKind(rawValue: 4)
    static let f32 = HLTypeKind(rawValue: 5)
    static let f64 = HLTypeKind(rawValue: 6)
    static let bool = HLTypeKind(rawValue: 7)
    static let bytes = HLTypeKind(rawValue: 8)
    static let dyn = HLTypeKind(rawValue: 9)
    static let fun = HLTypeKind(rawValue: 10)
    static let obj = HLTypeKind(rawValue: 11)
    static let array = HLTypeKind(rawValue: 12)
    static let type = HLTypeKind(rawValue: 13)
    static let ref = HLTypeKind(rawValue: 14)
    static let virtual = HLTypeKind(rawValue: 15)
    static let dynobj = HLTypeKind(rawValue: 16)
    static let abstract = HLTypeKind(rawValue: 17)
    static let `enum` = HLTypeKind(rawValue: 18)
    static let null = HLTypeKind(rawValue: 19)
    static let method = HLTypeKind(rawValue: 20)
    static let `struct` = HLTypeKind(rawValue: 21)
    static let packed = HLTypeKind(rawValue: 22)
    // -----------------
    static let last = HLTypeKind(rawValue: 23)
    static let _H_FORCE_INT = HLTypeKind(rawValue: 0x7FFF_FFFF)

    var hlRegSize: ByteCount {
        switch self {
        case .void: return 0  // void not really a value, used for typing purpose

        case .bool, .u8: return 1  // an unsigned 8 bits integer (0-255)

        case .u16: return 2
        case .i32, .f32: return 4
        case .i64, .f64: return 8

        // All the following values are memory addresse pointers and takes either 4 bytes in x86 mode or 8 bytes in x86-64 mode:

        case .bytes: fallthrough
        case .dyn, .fun, .array, .obj, .dynobj, .virtual, .enum, .ref, .null, .type,
            .abstract:
            return 8

        default: fatalError("Register size not available for \(self.debugDescription)")
        }
    }

    var debugDescription: String {
        switch self {
        case .void: return "void"
        case .u8: return "u8"
        case .u16: return "u16"
        case .i32: return "i32"
        case .i64: return "i64"
        case .f32: return "f32"
        case .f64: return "f64"
        case .bool: return "bool"
        case .bytes: return "bytes"
        case .dyn: return "dynamic"
        case .fun: return "fun"
        case .obj: return "obj"
        case .array: return "array"
        case .type: return "type"
        case .ref: return "ref"
        case .virtual: return "virtual"
        case .dynobj: return "dynobj"
        case .abstract: return "abs"
        case .`enum`: return "enum"
        case .null: return "null"
        case .method: return "method"
        case .`struct`: return "struct"
        default:
            fatalError("unknown HLTypeKind \(rawValue)")
}
    }
}

enum HLType: Equatable, Hashable, CustomDebugStringConvertible {

    case void  // 0
    case u8  // 1
    case u16  // 2
    case i32  // 3
    case i64  // 4
    case f32  // 5
    case f64  // 6
    case bool  // 7
    case bytes  // 8
    case dyn  // 9
    case fun(HLTypeFunData)  // 10
    case obj(HLTypeObjData)  // 11
    case array  // 12
    case type  // 13
    case ref(HLTypeRefData)  // 14
    case virtual(HLTypeVirtualData)  // 15
    case dynobj  // 16
    case abstract(HLTypeAbstractData)  // 17
    case `enum`(HLTypeEnumData)  // 18
    case null(HLTypeNullData)  // 19
    case method  // 20
    case `struct`(HLTypeObjData)  // 21

    // todo: find usages and move to debugDescription
    var debugName: String { debugDescription }
    
    var objData: HLTypeObjData? {
        switch(self) {
        case .obj(let objData), .struct(let objData): return objData
        default: return nil
        }
    }
    
    var funData: HLTypeFunData? {
        switch(self) {
        case .fun(let data): return data
        default: return nil
        }
    }

    var kind: HLTypeKind {
        switch self {
        case .void: return .void
        case .u8: return .u8
        case .u16: return .u16
        case .i32: return .i32
        case .i64: return .i64
        case .f32: return .f32
        case .f64: return .f64
        case .bool: return .bool
        case .bytes: return .bytes
        case .dyn: return .dyn
        case .fun: return .fun
        case .obj: return .obj
        case .array: return .array
        case .type: return .type
        case .ref: return .ref
        case .virtual: return .virtual
        case .dynobj: return .dynobj
        case .abstract: return .abstract
        case .enum: return .enum
        case .null: return .null
        case .method: return .method
        case .struct: return .struct
        }
    }

    var debugDescription: String {
        switch self {
        case .void: return "void"
        case .u8: return "u8"
        case .u16: return "u16"
        case .i32: return "i32"
        case .i64: return "i64"
        case .f32: return "f32"
        case .f64: return "f64"
        case .bool: return "bool"
        case .bytes: return "bytes"
        case .dyn: return "dynamic"
        case .fun: return "fun"
        case .obj(let data): return "obj(\(data.name.value))"
        case .array: return "array"
        case .type: return "type"
        case .ref: return "ref"
        case .virtual: return "virtual"
        case .dynobj: return "dynobj"
        case .abstract(let data): return "abs(\(data.name.value))"
        case .`enum`(let data): return "enum(\(data.name.value))"
        case .null(let data): return "null(\(data.type.value.debugName))"
        case .method: return "method"
        case .`struct`: return "struct"
        }
    }

    var debugDescriptionDetailed: String {
        switch self {
        case .obj(let data): return data.debugDescription
        case .virtual(let data): return data.debugDescription
        case .fun(let data): return data.debugDescription
        default: return self.debugName
        }
    }

    static func read(
        from reader: ByteReader,
        strings: TableResolver<String>,
        types: TableResolver<HLType>
    ) throws -> HLType {
        let typeKind = try reader.readUInt8()
        switch HLTypeKind(rawValue: UInt32(typeKind)) {
        case .void: return .void
        case .u8: return .u8
        case .u16: return .u16
        case .i32: return .i32
        case .i64: return .i64
        case .f32: return .f32
        case .f64: return .f64
        case .bool: return .bool
        case .bytes: return .bytes
        case .dyn: return .dyn
        case .fun: return .fun(try readFunData(from: reader, types: types))
        case .obj:
            return .obj(try readObjData(from: reader, strings: strings, types: types))
        case .array: return .array
        case .type: return .type
        case .ref: return .ref(try readRefData(from: reader, types: types))
        case .virtual:
            return .virtual(
                try readVirtualData(from: reader, strings: strings, types: types)
            )
        case .abstract:
            return .abstract(try readAbstractData(from: reader, strings: strings))
        case .enum:
            return .enum(try readEnumData(from: reader, strings: strings, types: types))
        case .null: return .null(try readNullData(from: reader, types: types))
        default: fatalError("Type kind \(typeKind) not supported")
        }
    }

    static func readRefData(from reader: ByteReader, types: TableResolver<HLType>)
        throws -> HLTypeRefData
    {
        let ix = try reader.readIndex()
        return HLTypeRefData(type: types.getResolvable(ix))
    }

    static func readNullData(from reader: ByteReader, types: TableResolver<HLType>)
        throws -> HLTypeNullData
    {
        let ix = try reader.readIndex()
        return HLTypeNullData(type: types.getResolvable(ix))
    }
    static func readEnumData(
        from reader: ByteReader,
        strings: TableResolver<String>,
        types: TableResolver<HLType>
    ) throws -> HLTypeEnumData {
        let ix = try reader.readIndex()
        let name = strings.getResolvable(ix)
        let global = try reader.readVarInt()
        let nconstructs = try reader.readVarInt()
        let constructs = try Array(repeating: 0, count: Int(nconstructs)).map { _ in
            let name = strings.getResolvable(try reader.readIndex())
            let nparams = try reader.readVarInt()
            let params = try Array(repeating: 0, count: Int(nparams)).map { _ in
                types.getResolvable(try reader.readIndex())
            }

            return HLTypeEnumConstruct(name: name, params: params)
        }

        return HLTypeEnumData(name: name, global: global, constructs: constructs)
    }

    static func readFunData(from reader: ByteReader, types: TableResolver<HLType>)
        throws -> HLTypeFunData
    {
        let nargs = try reader.readVarInt()
        let args = try Array(repeating: 0, count: Int(nargs)).map { _ in
            types.getResolvable(try reader.readIndex())
        }
        let ret = types.getResolvable(try reader.readIndex())
        return HLTypeFunData(args: args, ret: ret)
    }

    static func readAbstractData(
        from reader: ByteReader,
        strings: TableResolver<String>
    ) throws -> HLTypeAbstractData {
        let ix = try reader.readIndex()
        let name = strings.getResolvable(ix)
        print("Loaded abstract \(name.value)")
        return HLTypeAbstractData(name: name)
    }

    static func readVirtualData(
        from reader: ByteReader,
        strings: TableResolver<String>,
        types: TableResolver<HLType>
    ) throws -> HLTypeVirtualData {

        let nfields = try reader.readVarInt()

        let fields = try Array(repeating: 0, count: Int(nfields)).map { _ in

            let name = strings.getResolvable(try reader.readIndex())
            let type = types.getResolvable(try reader.readIndex())
            return HLTypeField(name: name, type: type)
        }

        return HLTypeVirtualData(fields: fields)
    }

    static func readObjData(
        from reader: ByteReader,
        strings: TableResolver<String>,
        types: TableResolver<HLType>
    ) throws -> HLTypeObjData {
        let name = strings.getResolvable(try reader.readIndex())
        let superTypeIx = try reader.readIndex()
        let superType = superTypeIx >= 0 ? types.getResolvable(superTypeIx) : nil
        // 0 means no global
        // It is valid for base or Class types etc.
        // https://github.com/HaxeFoundation/haxe/blob/c35bbd4472c3410943ae5199503c23a2b7d3c5d6/src/generators/genhl.ml#L3848
        let globalTry = try reader.readVarInt()
        let global = globalTry != 0 ? (globalTry - 1) : nil

        let nfields = try reader.readVarInt()
        let nprotos = try reader.readVarInt()
        let nbindings = try reader.readVarInt()

        // HLTypeObjData
        // let	name: TableResolver<String>.Index
        // let	superName: TableResolver<String>.Index?
        // let	global: Int32

        // let fields: [HLTypeField]
        // let protos: [HLTypeProto]
        // let bindings: [HLTypeBinding]

        let fields = try Array(repeating: 0, count: Int(nfields)).map { _ in

            let name = strings.getResolvable(try reader.readIndex())
            let type = types.getResolvable(try reader.readIndex())
            return HLTypeField(name: name, type: type)
        }

        let protos = try Array(repeating: 0, count: Int(nprotos)).map { _ in

            let name = strings.getResolvable(try reader.readIndex())
            // print("Proto \(name.value)")
            return HLTypeProto(
                name: name,
                functionIx: try reader.readVarInt(),
                pIx: try reader.readVarInt()
            )
        }

        let bindings = try Array(repeating: 0, count: Int(nbindings)).map { _ in

            return HLTypeBinding(
                fieldRefIx: try reader.readVarInt(),
                functionIx: try reader.readVarInt()
            )
        }

        return HLTypeObjData(
            name: name,
            superType: superType,
            global: global,
            fields: fields,
            protos: protos,
            bindings: bindings
        )
    }
}
