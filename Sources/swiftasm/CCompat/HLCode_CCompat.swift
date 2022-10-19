/*
typedef struct {
	int version;
	int nints;
	int nfloats;
	int nstrings;
	int nbytes;
	int ntypes;
	int nglobals;
	int nnatives;
	int nfunctions;
	int nconstants;
	int entrypoint;
	int ndebugfiles;
	bool hasdebug;
	int*		ints;
	double*		floats;
	char**		strings;
	int*		strings_lens;
	char*		bytes;
	int*		bytes_pos;
	char**		debugfiles;
	int*		debugfiles_lens;
	uchar**		ustrings;
	hl_type*	types;
	hl_type**	globals;
	hl_native*	natives;
	hl_function*functions;
	hl_constant*constants;
	hl_alloc	alloc;
	hl_alloc	falloc;
} hl_code; 
*/

struct HLCode_CCompat {
    let version: UInt32
	let nints: UInt32
    let nfloats: UInt32
    let nstrings: UInt32
	let nbytes: UInt32
	let ntypes: UInt32
	let nglobals: UInt32
	let nnatives: UInt32
	let nfunctions: UInt32
	let nconstants: UInt32
	let entrypoint: UInt32
	let ndebugfiles: UInt32

    // bool hasdebug;
    let hasdebug: Bool
	
    // int*		ints;
    let ints: UnsafePointer<Int32>

	// double*	floats;
    let floats: UnsafePointer<Double>
    
    // char**		strings;
    let strings: UnsafePointer<UnsafePointer<CChar>>
	
    // int*		strings_lens;
	let string_lens: UnsafePointer<UInt32>
    
    // char*		bytes;
    let bytes: UnsafePointer<Int8>

	// int*		bytes_pos;
    let bytes_pos: UnsafePointer<Int32>

	// char**		debugfiles;
    let debugfiles: UnsafePointer<UnsafePointer<CChar>>

	// int*		debugfiles_lens;
    let debuffiles_lens: UnsafePointer<UInt32>

	// uchar**		ustrings;
    let ustrings: UnsafePointer<UnsafePointer<CChar16>>
    
	// hl_type*	types;
    let types: UnsafePointer<HLType_CCompat>

	// hl_type**	globals;
    let globals: UnsafePointer<UnsafePointer<HLType_CCompat>>

	// hl_native*	natives;
    let natives: UnsafeMutableRawPointer

	// hl_function* functions;
    let functions: UnsafeMutableRawPointer
	
    // hl_constant*constants;
    let constants: UnsafeMutableRawPointer

	// hl_alloc	alloc;
    let alloc: Int64   

	// hl_alloc	falloc;
    let falloc: Int64

    func getInt(_ ix: Int) -> Int32 {
        return ints.advanced(by: ix).pointee
    }

    func getFloat(_ ix: Int) -> Double {
        return floats.advanced(by: ix).pointee
    }

    func getUstring(_ ix: Int) -> String {
        let len = string_lens.advanced(by: ix).pointee
        guard ustrings.advanced(by: ix) != nil else {
            fatalError("ustring \(ix) is nil")
        }

        let strPtr = ustrings.advanced(by: ix).pointee
        
        let str = String(
            bytesNoCopy: UnsafeMutablePointer(mutating: strPtr), 
            length: Int(len), 
            encoding: .utf16, 
            freeWhenDone: false)
        guard let str = str else {
            fatalError("Failed to load string \(ix)")
        }
        return str
    }

    func getString(_ ix: Int) -> String {
        let len = string_lens.advanced(by: ix).pointee
        let strPtr = strings.advanced(by: ix).pointee
        
        let str = String(
            bytesNoCopy: UnsafeMutablePointer(mutating: strPtr), 
            length: Int(len), 
            encoding: .utf8, 
            freeWhenDone: false)
        guard let str = str else {
            fatalError("Failed to load string \(ix)")
        }
        return str
    }
}