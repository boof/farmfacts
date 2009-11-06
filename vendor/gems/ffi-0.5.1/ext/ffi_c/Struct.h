/*
 * Copyright (c) 2008, 2009, Wayne Meissner
 * Copyright (c) 2009, Luc Heinrich <luc@honk-honk.com>
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * * Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 * * Redistributions in binary form must reproduce the above copyright notice
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 * * The name of the author or authors may not be used to endorse or promote
 *   products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef RBFFI_STRUCT_H
#define	RBFFI_STRUCT_H

#include "AbstractMemory.h"
#include "Type.h"

#ifdef	__cplusplus
extern "C" {
#endif

    extern void rbffi_Struct_Init(VALUE ffiModule);
    extern void rbffi_StructLayout_Init(VALUE ffiModule);

    typedef struct StructField_ {
        Type* type;
        unsigned int offset;

        VALUE rbType;
        VALUE rbName;
    } StructField;

    typedef struct StructLayout_ {
        Type base;
        StructField** fields;
        unsigned int fieldCount;
        int size;
        int align;
        ffi_type** ffiTypes;
        VALUE rbFieldNames;
        VALUE rbFieldMap;
        VALUE rbFields;
    } StructLayout;

    typedef struct Struct {
        StructLayout* layout;
        AbstractMemory* pointer;
        VALUE rbLayout;
        VALUE rbPointer;
    } Struct;

    extern VALUE rbffi_StructClass, rbffi_StructLayoutClass;
    extern VALUE rbffi_StructLayoutFieldClass, rbffi_StructLayoutFunctionFieldClass;
    extern VALUE rbffi_StructLayoutArrayFieldClass, rbffi_StructLayoutStructFieldClass;
    extern VALUE rbffi_StructInlineArrayClass;

#ifdef	__cplusplus
}
#endif

#endif	/* RBFFI_STRUCT_H */

