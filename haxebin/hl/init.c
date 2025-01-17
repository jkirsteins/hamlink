﻿// Generated by HLC 4.2.5 (HL v4)
#define HLC_BOOT
#include <hlc.h>
#include <hl/Class.h>
#include <hl/CoreType.h>
#include <_std/String.h>
#include <hl/CoreEnum.h>
#include <hl/Enum.h>
#include <haxe/io/Error.h>
#include <hl/types/ArrayBase.h>
#include <hl/types/ArrayDyn.h>
#include <hl/natives.h>
#include <_std/Std.h>
#include <_std/Sys.h>
void Type_init(void);
extern hl_type t$$Date;
extern hl_type t$Date;
hl__Class Type_initClass(hl_type*,hl_type*,vbyte*);
extern hl_type t$$Path;
extern hl_type t$Path;
extern hl_type t$$Path2;
extern hl_type t$Path2;
extern hl_type t$$Main;
extern hl_type t$Main;
extern hl_type t$$Std;
extern hl_type t$Std;
extern hl_type t$hl_CoreType;
extern hl_type t$_f64;
extern String s$Float;
extern hl__CoreType g$_Float;
#include <hl/BaseType.h>
void Type_register(vbyte*,hl__BaseType);
extern hl_type t$_i32;
extern String s$Int;
extern hl__CoreType g$_Int;
extern hl_type t$hl_CoreEnum;
extern hl_type t$_bool;
extern String s$Bool;
extern hl__CoreEnum g$_Bool;
extern hl_type t$_dyn;
extern String s$Dynamic;
extern hl__CoreType g$_Dynamic;
extern hl_type t$$String;
extern hl_type t$String;
extern hl_type t$$StringBuf;
extern hl_type t$StringBuf;
extern hl_type t$$SysError;
extern hl_type t$SysError;
extern hl_type t$hl__Bytes_$Bytes_Impl_;
extern hl_type t$hl__Bytes_Bytes_Impl_;
extern hl_type t$$Sys;
extern hl_type t$Sys;
extern hl_type t$$Type;
extern hl_type t$Type;
extern hl_type t$haxe_$Exception;
extern hl_type t$haxe_Exception;
extern hl_type t$haxe_$Log;
extern hl_type t$haxe_Log;
extern hl_type t$haxe_$NativeStackTrace;
extern hl_type t$haxe_NativeStackTrace;
extern hl_type t$haxe_$ValueException;
extern hl_type t$haxe_ValueException;
extern hl_type t$haxe_ds_$ArraySort;
extern hl_type t$haxe_ds_ArraySort;
extern hl_type t$haxe_exceptions_$PosException;
extern hl_type t$haxe_exceptions_PosException;
extern hl_type t$haxe_exceptions_$NotImplementedException;
extern hl_type t$haxe_exceptions_NotImplementedException;
extern hl_type t$haxe_io_$Error;
extern hl_type t$haxe_io_Error;
hl__Enum Type_initEnum(hl_type*,hl_type*);
extern venum* g$haxe_io_Error_Blocked;
extern venum* g$haxe_io_Error_Overflow;
extern venum* g$haxe_io_Error_OutsideBounds;
extern hl_type t$haxe_iterators_$ArrayIterator;
extern hl_type t$haxe_iterators_ArrayIterator;
extern hl_type t$haxe_iterators_$ArrayKeyValueIterator;
extern hl_type t$haxe_iterators_ArrayKeyValueIterator;
extern hl_type t$hl_$BaseType;
extern hl_type t$hl_BaseType;
extern hl_type t$hl_Class;
extern hl_type t$hl_$Enum;
extern hl_type t$hl_Enum;
extern hl_type t$hl__NativeArray_$NativeArray_Impl_;
extern hl_type t$hl__NativeArray_NativeArray_Impl_;
extern hl_type t$hl_$NativeArrayIterator_Dynamic;
extern hl_type t$hl_NativeArrayIterator_Dynamic;
extern hl_type t$hl_$NativeArrayIterator_Int;
extern hl_type t$hl_NativeArrayIterator_Int;
extern hl_type t$hl__Type_$Type_Impl_;
extern hl_type t$hl__Type_Type_Impl_;
extern hl_type t$hl_types_$ArrayAccess;
extern hl_type t$hl_types_ArrayAccess;
extern hl_type t$hl_types_$ArrayBase;
extern hl__types__$ArrayBase g$_hl_types_ArrayBase;
extern String s$Array;
extern hl_type t$hl_types_$ArrayBytes_hl_F32;
extern hl_type t$hl_types_ArrayBytes_hl_F32;
extern hl_type t$hl_types_$ArrayDynIterator;
extern hl_type t$hl_types_ArrayDynIterator;
extern hl_type t$hl_types_$ArrayDynKeyValueIterator;
extern hl_type t$hl_types_ArrayDynKeyValueIterator;
extern hl_type t$hl_types_$ArrayDyn;
extern hl__types__$ArrayDyn g$_hl_types_ArrayDyn;
extern hl_type t$hl_types_ArrayDyn;
extern String s$hl_types_ArrayDyn;
extern hl_type t$hl_types_$ArrayObjIterator;
extern hl_type t$hl_types_ArrayObjIterator;
extern hl_type t$hl_types_$ArrayObjKeyValueIterator;
extern hl_type t$hl_types_ArrayObjKeyValueIterator;
extern hl_type t$hl_types_$BytesIterator_Float;
extern hl_type t$hl_types_BytesIterator_Float;
extern hl_type t$hl_types_$BytesIterator_Int;
extern hl_type t$hl_types_BytesIterator_Int;
extern hl_type t$hl_types_$BytesIterator_hl_F32;
extern hl_type t$hl_types_BytesIterator_hl_F32;
extern hl_type t$hl_types_$BytesIterator_hl_UI16;
extern hl_type t$hl_types_BytesIterator_hl_UI16;
extern hl_type t$hl_types_$BytesKeyValueIterator_Float;
extern hl_type t$hl_types_BytesKeyValueIterator_Float;
extern hl_type t$hl_types_$BytesKeyValueIterator_Int;
extern hl_type t$hl_types_BytesKeyValueIterator_Int;
extern hl_type t$hl_types_$BytesKeyValueIterator_hl_F32;
extern hl_type t$hl_types_BytesKeyValueIterator_hl_F32;
extern hl_type t$hl_types_$BytesKeyValueIterator_hl_UI16;
extern hl_type t$hl_types_BytesKeyValueIterator_hl_UI16;
extern hl_type t$hl_types__BytesMap_$BytesMap_Impl_;
extern hl_type t$hl_types__BytesMap_BytesMap_Impl_;
extern $Std g$_Std;
extern $Sys g$_Sys;
void Main_main(void);

void fun$init() {
	String r6;
	hl__Class r4;
	venum *r10;
	hl_type *r1, *r2;
	$Sys r18;
	bool r17;
	hl_random *r15;
	$Std r16;
	hl__Enum r8;
	hl__types__$ArrayDyn r14;
	hl__CoreType r5;
	hl__CoreEnum r7;
	hl__types__$ArrayBase r13;
	vdynamic *r11;
	int r12;
	varray *r9;
	vbyte *r3;
	Type_init();
	r1 = &t$$Date;
	r2 = &t$Date;
	r3 = (vbyte*)USTR("Date");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$$Path;
	r2 = &t$Path;
	r3 = (vbyte*)USTR("Path");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$$Path2;
	r2 = &t$Path2;
	r3 = (vbyte*)USTR("Path2");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$$Main;
	r2 = &t$Main;
	r3 = (vbyte*)USTR("Main");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$$Std;
	r2 = &t$Std;
	r3 = (vbyte*)USTR("Std");
	r4 = Type_initClass(r1,r2,r3);
	r5 = (hl__CoreType)hl_alloc_obj(&t$hl_CoreType);
	r1 = &t$_f64;
	r5->__type__ = r1;
	r6 = (String)s$Float;
	r5->__name__ = r6;
	g$_Float = (hl__CoreType)r5;
	r3 = (vbyte*)USTR("Float");
	Type_register(r3,((hl__BaseType)r5));
	r5 = (hl__CoreType)hl_alloc_obj(&t$hl_CoreType);
	r1 = &t$_i32;
	r5->__type__ = r1;
	r6 = (String)s$Int;
	r5->__name__ = r6;
	g$_Int = (hl__CoreType)r5;
	r3 = (vbyte*)USTR("Int");
	Type_register(r3,((hl__BaseType)r5));
	r7 = (hl__CoreEnum)hl_alloc_obj(&t$hl_CoreEnum);
	r1 = &t$_bool;
	r7->__type__ = r1;
	r6 = (String)s$Bool;
	r7->__ename__ = r6;
	g$_Bool = (hl__CoreEnum)r7;
	r3 = (vbyte*)USTR("Bool");
	Type_register(r3,((hl__BaseType)r7));
	r5 = (hl__CoreType)hl_alloc_obj(&t$hl_CoreType);
	r1 = &t$_dyn;
	r5->__type__ = r1;
	r6 = (String)s$Dynamic;
	r5->__name__ = r6;
	g$_Dynamic = (hl__CoreType)r5;
	r3 = (vbyte*)USTR("Dynamic");
	Type_register(r3,((hl__BaseType)r5));
	r1 = &t$$String;
	r2 = &t$String;
	r3 = (vbyte*)USTR("String");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$$StringBuf;
	r2 = &t$StringBuf;
	r3 = (vbyte*)USTR("StringBuf");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$$SysError;
	r2 = &t$SysError;
	r3 = (vbyte*)USTR("SysError");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$hl__Bytes_$Bytes_Impl_;
	r2 = &t$hl__Bytes_Bytes_Impl_;
	r3 = (vbyte*)USTR("hl._Bytes.Bytes_Impl_");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$$Sys;
	r2 = &t$Sys;
	r3 = (vbyte*)USTR("Sys");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$$Type;
	r2 = &t$Type;
	r3 = (vbyte*)USTR("Type");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$haxe_$Exception;
	r2 = &t$haxe_Exception;
	r3 = (vbyte*)USTR("haxe.Exception");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$haxe_$Log;
	r2 = &t$haxe_Log;
	r3 = (vbyte*)USTR("haxe.Log");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$haxe_$NativeStackTrace;
	r2 = &t$haxe_NativeStackTrace;
	r3 = (vbyte*)USTR("haxe.NativeStackTrace");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$haxe_$ValueException;
	r2 = &t$haxe_ValueException;
	r3 = (vbyte*)USTR("haxe.ValueException");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$haxe_ds_$ArraySort;
	r2 = &t$haxe_ds_ArraySort;
	r3 = (vbyte*)USTR("haxe.ds.ArraySort");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$haxe_exceptions_$PosException;
	r2 = &t$haxe_exceptions_PosException;
	r3 = (vbyte*)USTR("haxe.exceptions.PosException");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$haxe_exceptions_$NotImplementedException;
	r2 = &t$haxe_exceptions_NotImplementedException;
	r3 = (vbyte*)USTR("haxe.exceptions.NotImplementedException");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$haxe_io_$Error;
	r2 = &t$haxe_io_Error;
	r8 = Type_initEnum(r1,r2);
	r9 = r8->__evalues__;
	r12 = 0;
	r11 = ((vdynamic**)(r9 + 1))[r12];
	r10 = (venum*)hl_dyn_castp(&r11,&t$_dyn,&t$haxe_io_Error);
	g$haxe_io_Error_Blocked = (venum*)r10;
	r12 = 1;
	r11 = ((vdynamic**)(r9 + 1))[r12];
	r10 = (venum*)hl_dyn_castp(&r11,&t$_dyn,&t$haxe_io_Error);
	g$haxe_io_Error_Overflow = (venum*)r10;
	r12 = 2;
	r11 = ((vdynamic**)(r9 + 1))[r12];
	r10 = (venum*)hl_dyn_castp(&r11,&t$_dyn,&t$haxe_io_Error);
	g$haxe_io_Error_OutsideBounds = (venum*)r10;
	r1 = &t$haxe_iterators_$ArrayIterator;
	r2 = &t$haxe_iterators_ArrayIterator;
	r3 = (vbyte*)USTR("haxe.iterators.ArrayIterator");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$haxe_iterators_$ArrayKeyValueIterator;
	r2 = &t$haxe_iterators_ArrayKeyValueIterator;
	r3 = (vbyte*)USTR("haxe.iterators.ArrayKeyValueIterator");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$hl_$BaseType;
	r2 = &t$hl_BaseType;
	r3 = (vbyte*)USTR("hl.BaseType");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$hl_Class;
	r2 = &t$hl_Class;
	r3 = (vbyte*)USTR("Class");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$hl_$Enum;
	r2 = &t$hl_Enum;
	r3 = (vbyte*)USTR("hl.Enum");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$hl__NativeArray_$NativeArray_Impl_;
	r2 = &t$hl__NativeArray_NativeArray_Impl_;
	r3 = (vbyte*)USTR("hl._NativeArray.NativeArray_Impl_");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$hl_$NativeArrayIterator_Dynamic;
	r2 = &t$hl_NativeArrayIterator_Dynamic;
	r3 = (vbyte*)USTR("hl.NativeArrayIterator_Dynamic");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$hl_$NativeArrayIterator_Int;
	r2 = &t$hl_NativeArrayIterator_Int;
	r3 = (vbyte*)USTR("hl.NativeArrayIterator_Int");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$hl__Type_$Type_Impl_;
	r2 = &t$hl__Type_Type_Impl_;
	r3 = (vbyte*)USTR("hl._Type.Type_Impl_");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$hl_types_$ArrayAccess;
	r2 = &t$hl_types_ArrayAccess;
	r3 = (vbyte*)USTR("hl.types.ArrayAccess");
	r4 = Type_initClass(r1,r2,r3);
	r13 = (hl__types__$ArrayBase)hl_alloc_obj(&t$hl_types_$ArrayBase);
	g$_hl_types_ArrayBase = (hl__types__$ArrayBase)r13;
	r1 = &t$hl_types_ArrayAccess;
	r13->__type__ = r1;
	r6 = (String)s$Array;
	r13->__name__ = r6;
	r3 = (vbyte*)USTR("Array");
	Type_register(r3,((hl__BaseType)r13));
	r1 = &t$hl_types_$ArrayBytes_hl_F32;
	r2 = &t$hl_types_ArrayBytes_hl_F32;
	r3 = (vbyte*)USTR("hl.types.ArrayBytes_hl_F32");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$hl_types_$ArrayDynIterator;
	r2 = &t$hl_types_ArrayDynIterator;
	r3 = (vbyte*)USTR("hl.types.ArrayDynIterator");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$hl_types_$ArrayDynKeyValueIterator;
	r2 = &t$hl_types_ArrayDynKeyValueIterator;
	r3 = (vbyte*)USTR("hl.types.ArrayDynKeyValueIterator");
	r4 = Type_initClass(r1,r2,r3);
	r14 = (hl__types__$ArrayDyn)hl_alloc_obj(&t$hl_types_$ArrayDyn);
	g$_hl_types_ArrayDyn = (hl__types__$ArrayDyn)r14;
	r1 = &t$hl_types_ArrayDyn;
	r14->__type__ = r1;
	r6 = (String)s$hl_types_ArrayDyn;
	r14->__name__ = r6;
	r3 = (vbyte*)USTR("hl.types.ArrayDyn");
	Type_register(r3,((hl__BaseType)r14));
	r1 = &t$hl_types_$ArrayObjIterator;
	r2 = &t$hl_types_ArrayObjIterator;
	r3 = (vbyte*)USTR("hl.types.ArrayObjIterator");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$hl_types_$ArrayObjKeyValueIterator;
	r2 = &t$hl_types_ArrayObjKeyValueIterator;
	r3 = (vbyte*)USTR("hl.types.ArrayObjKeyValueIterator");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$hl_types_$BytesIterator_Float;
	r2 = &t$hl_types_BytesIterator_Float;
	r3 = (vbyte*)USTR("hl.types.BytesIterator_Float");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$hl_types_$BytesIterator_Int;
	r2 = &t$hl_types_BytesIterator_Int;
	r3 = (vbyte*)USTR("hl.types.BytesIterator_Int");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$hl_types_$BytesIterator_hl_F32;
	r2 = &t$hl_types_BytesIterator_hl_F32;
	r3 = (vbyte*)USTR("hl.types.BytesIterator_hl_F32");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$hl_types_$BytesIterator_hl_UI16;
	r2 = &t$hl_types_BytesIterator_hl_UI16;
	r3 = (vbyte*)USTR("hl.types.BytesIterator_hl_UI16");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$hl_types_$BytesKeyValueIterator_Float;
	r2 = &t$hl_types_BytesKeyValueIterator_Float;
	r3 = (vbyte*)USTR("hl.types.BytesKeyValueIterator_Float");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$hl_types_$BytesKeyValueIterator_Int;
	r2 = &t$hl_types_BytesKeyValueIterator_Int;
	r3 = (vbyte*)USTR("hl.types.BytesKeyValueIterator_Int");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$hl_types_$BytesKeyValueIterator_hl_F32;
	r2 = &t$hl_types_BytesKeyValueIterator_hl_F32;
	r3 = (vbyte*)USTR("hl.types.BytesKeyValueIterator_hl_F32");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$hl_types_$BytesKeyValueIterator_hl_UI16;
	r2 = &t$hl_types_BytesKeyValueIterator_hl_UI16;
	r3 = (vbyte*)USTR("hl.types.BytesKeyValueIterator_hl_UI16");
	r4 = Type_initClass(r1,r2,r3);
	r1 = &t$hl_types__BytesMap_$BytesMap_Impl_;
	r2 = &t$hl_types__BytesMap_BytesMap_Impl_;
	r3 = (vbyte*)USTR("hl.types._BytesMap.BytesMap_Impl_");
	r4 = Type_initClass(r1,r2,r3);
	r15 = hl_rnd_init_system();
	r16 = ($Std)g$_Std;
	r16->rnd = r15;
	r17 = hl_sys_utf8_path();
	r18 = ($Sys)g$_Sys;
	r18->utf8Path = r17;
	r12 = 0;
	r16 = ($Std)g$_Std;
	r16->toStringDepth = r12;
	Main_main();
	return;
}

