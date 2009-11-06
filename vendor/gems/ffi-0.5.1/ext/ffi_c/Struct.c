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

#include <sys/types.h>

#include "Function.h"
#include <sys/param.h>
#include <stdint.h>
#include <stdbool.h>
#include <ruby.h>
#include "rbffi.h"
#include "compat.h"
#include "AbstractMemory.h"
#include "Pointer.h"
#include "MemoryPointer.h"
#include "Function.h"
#include "Types.h"
#include "Struct.h"
#include "StructByValue.h"
#include "ArrayType.h"

#define FFI_ALIGN(v, a)  (((((size_t) (v))-1) | ((a)-1))+1)

typedef struct StructLayoutBuilder {
    VALUE rbFieldNames;
    VALUE rbFieldMap;
    unsigned int size;
    unsigned int alignment;
    bool isUnion;
} StructLayoutBuilder;

typedef struct InlineArray_ {
    VALUE rbMemory;
    VALUE rbField;

    AbstractMemory* memory;
    StructField* field;
    MemoryOp *op;
    Type* componentType;
} InlineArray;


static void struct_mark(Struct *);
static void struct_layout_builder_mark(StructLayoutBuilder *);
static void struct_layout_builder_free(StructLayoutBuilder *);
static void inline_array_mark(InlineArray *);

static inline int align(int offset, int align);

VALUE rbffi_StructClass = Qnil;
static VALUE StructLayoutBuilderClass = Qnil;

VALUE rbffi_StructInlineArrayClass = Qnil;
static ID id_pointer_ivar = 0, id_layout_ivar = 0;
static ID id_get = 0, id_put = 0, id_to_ptr = 0, id_to_s = 0, id_layout = 0;

static inline char*
memory_address(VALUE self)
{
    return ((AbstractMemory *)DATA_PTR((self)))->address;
}

static VALUE
struct_allocate(VALUE klass)
{
    Struct* s;
    VALUE obj = Data_Make_Struct(klass, Struct, struct_mark, -1, s);
    
    s->rbPointer = Qnil;
    s->rbLayout = Qnil;

    return obj;
}

static VALUE
struct_initialize(int argc, VALUE* argv, VALUE self)
{
    Struct* s;
    VALUE rbPointer = Qnil, rest = Qnil, klass = CLASS_OF(self);
    int nargs;

    Data_Get_Struct(self, Struct, s);
    
    nargs = rb_scan_args(argc, argv, "01*", &rbPointer, &rest);

    /* Call up into ruby code to adjust the layout */
    if (nargs > 1) {
        s->rbLayout = rb_funcall2(CLASS_OF(self), id_layout, RARRAY_LEN(rest), RARRAY_PTR(rest));
    } else if (rb_cvar_defined(klass, id_layout_ivar)) {
        s->rbLayout = rb_cvar_get(klass, id_layout_ivar);
    } else {
        rb_raise(rb_eRuntimeError, "No Struct layout configured");
    }

    if (!rb_obj_is_kind_of(s->rbLayout, rbffi_StructLayoutClass)) {
        rb_raise(rb_eRuntimeError, "Invalid Struct layout");
    }

    Data_Get_Struct(s->rbLayout, StructLayout, s->layout);
    
    if (rbPointer != Qnil) {
        s->pointer = MEMORY(rbPointer);
        s->rbPointer = rbPointer;
    } else {
        s->rbPointer = rbffi_MemoryPointer_NewInstance(s->layout->size, 1, true);
        s->pointer = (AbstractMemory *) DATA_PTR(s->rbPointer);
    }

    if (s->pointer->ops == NULL) {
        VALUE name = rb_class_name(CLASS_OF(s->rbPointer));
        rb_raise(rb_eRuntimeError, "No memory ops set for %s", StringValueCStr(name));
    }

    return self;
}

static void
struct_mark(Struct *s)
{
    rb_gc_mark(s->rbPointer);
    rb_gc_mark(s->rbLayout);
}

static VALUE
struct_field(Struct* s, VALUE fieldName)
{
    StructLayout* layout = s->layout;
    VALUE rbField;
    if (layout == NULL) {
        rb_raise(rb_eRuntimeError, "layout not set for Struct");
    }

    rbField = rb_hash_aref(layout->rbFieldMap, fieldName);
    if (rbField == Qnil) {
        VALUE str = rb_funcall2(fieldName, id_to_s, 0, NULL);
        rb_raise(rb_eArgError, "No such field '%s'", StringValuePtr(str));
    }

    return rbField;
}

static VALUE
struct_aref(VALUE self, VALUE fieldName)
{
    Struct* s;
    VALUE rbField;
    StructField* f;
    MemoryOp* op;

    Data_Get_Struct(self, Struct, s);
    rbField = struct_field(s, fieldName);
    f = (StructField *) DATA_PTR(rbField);

    op = memory_get_op(s->pointer, f->type);
    if (op != NULL) {
        return (*op->get)(s->pointer, f->offset);
    }
    
    /* call up to the ruby code to fetch the value */
    return rb_funcall2(rbField, id_get, 1, &s->rbPointer);
}

static VALUE
struct_aset(VALUE self, VALUE fieldName, VALUE value)
{
    Struct* s;
    VALUE rbField;
    StructField* f;
    MemoryOp* op;
    VALUE argv[2];

    Data_Get_Struct(self, Struct, s);
    rbField = struct_field(s, fieldName);
    f = (StructField *) DATA_PTR(rbField);

    op = memory_get_op(s->pointer, f->type);
    if (op != NULL) {
        (*op->put)(s->pointer, f->offset, value);
        return self;
    }
    
    /* call up to the ruby code to set the value */
    argv[0] = s->rbPointer;
    argv[1] = value;
    rb_funcall2(rbField, id_put, 2, argv);
    
    return self;
}

static VALUE
struct_set_pointer(VALUE self, VALUE pointer)
{
    Struct* s;

    if (!rb_obj_is_kind_of(pointer, rbffi_AbstractMemoryClass)) {
        rb_raise(rb_eArgError, "Invalid pointer");
    }

    Data_Get_Struct(self, Struct, s);
    s->pointer = MEMORY(pointer);
    s->rbPointer = pointer;
    rb_ivar_set(self, id_pointer_ivar, pointer);

    return self;
}

static VALUE
struct_get_pointer(VALUE self)
{
    Struct* s;

    Data_Get_Struct(self, Struct, s);

    return s->rbPointer;
}

static VALUE
struct_set_layout(VALUE self, VALUE layout)
{
    Struct* s;
    Data_Get_Struct(self, Struct, s);

    if (!rb_obj_is_kind_of(layout, rbffi_StructLayoutClass)) {
        rb_raise(rb_eArgError, "Invalid Struct layout");
    }

    Data_Get_Struct(layout, StructLayout, s->layout);
    rb_ivar_set(self, id_layout_ivar, layout);

    return self;
}

static VALUE
struct_get_layout(VALUE self)
{
    Struct* s;

    Data_Get_Struct(self, Struct, s);

    return s->rbLayout;
}

static VALUE
struct_layout_builder_allocate(VALUE klass)
{
    StructLayoutBuilder* builder;
    VALUE obj;

    obj = Data_Make_Struct(klass, StructLayoutBuilder, struct_layout_builder_mark, struct_layout_builder_free, builder);

    builder->size = 0;
    builder->alignment = 1;
    builder->isUnion = false;
    builder->rbFieldNames = rb_ary_new();
    builder->rbFieldMap = rb_hash_new();

    return obj;
}

static void
struct_layout_builder_mark(StructLayoutBuilder* builder)
{
    rb_gc_mark(builder->rbFieldNames);
    rb_gc_mark(builder->rbFieldMap);
}

static void
struct_layout_builder_free(StructLayoutBuilder* builder)
{
    xfree(builder);
}

static VALUE
struct_layout_builder_initialize(VALUE self)
{
    StructLayoutBuilder* builder;

    Data_Get_Struct(self, StructLayoutBuilder, builder);

    return self;
}

static VALUE
struct_layout_builder_get_size(VALUE self)
{
    StructLayoutBuilder* builder;

    Data_Get_Struct(self, StructLayoutBuilder, builder);

    return UINT2NUM(builder->size);
}

static VALUE
struct_layout_builder_set_size(VALUE self, VALUE rbSize)
{
    StructLayoutBuilder* builder;
    unsigned int size = NUM2UINT(rbSize);

    Data_Get_Struct(self, StructLayoutBuilder, builder);
    builder->size = MAX(size, builder->size);

    return UINT2NUM(builder->size);
}

static VALUE
struct_layout_builder_get_alignment(VALUE self)
{
    StructLayoutBuilder* builder;

    Data_Get_Struct(self, StructLayoutBuilder, builder);

    return UINT2NUM(builder->alignment);
}

static VALUE
struct_layout_builder_set_alignment(VALUE self, VALUE rbAlign)
{
    StructLayoutBuilder* builder;
    unsigned int align = NUM2UINT(rbAlign);

    Data_Get_Struct(self, StructLayoutBuilder, builder);
    builder->size = MAX(align, builder->alignment);

    return UINT2NUM(builder->alignment);
}

static VALUE
struct_layout_builder_set_union(VALUE self, VALUE rbUnion)
{
    StructLayoutBuilder* builder;


    Data_Get_Struct(self, StructLayoutBuilder, builder);
    builder->isUnion = RTEST(rbUnion);

    return rbUnion;
}

static VALUE
struct_layout_builder_union_p(VALUE self)
{
    StructLayoutBuilder* builder;


    Data_Get_Struct(self, StructLayoutBuilder, builder);


    return builder->isUnion ? Qtrue : Qfalse;
}

static void
store_field(StructLayoutBuilder* builder, VALUE rbName, VALUE rbField, 
    unsigned int offset, unsigned int size, unsigned int alignment)
{
    rb_ary_push(builder->rbFieldNames, rbName);
    rb_hash_aset(builder->rbFieldMap, rbName, rbField);

    builder->alignment = MAX(builder->alignment, alignment);

    if (builder->isUnion) {
        builder->size = MAX(builder->size, size);
    } else {
        builder->size = MAX(builder->size, offset + size);
    }
}

static int
calculate_offset(StructLayoutBuilder* builder, int alignment, VALUE rbOffset)
{
    if (rbOffset != Qnil) {
        return NUM2UINT(rbOffset);
    } else {
        return builder->isUnion ? 0 : align(builder->size, alignment);
    }
}

static VALUE
struct_layout_builder_add_field(int argc, VALUE* argv, VALUE self)
{
    StructLayoutBuilder* builder;
    VALUE rbName = Qnil, rbType = Qnil, rbOffset = Qnil, rbField = Qnil;
    unsigned int size, alignment, offset;
    int nargs;

    nargs = rb_scan_args(argc, argv, "21", &rbName, &rbType, &rbOffset);
    
    Data_Get_Struct(self, StructLayoutBuilder, builder);

    alignment = NUM2UINT(rb_funcall2(rbType, rb_intern("alignment"), 0, NULL));
    size = NUM2UINT(rb_funcall2(rbType, rb_intern("size"), 0, NULL));

    offset = calculate_offset(builder, alignment, rbOffset);

    //
    // If a primitive type was passed in as the type arg, try and convert
    //
    if (!rb_obj_is_kind_of(rbType, rbffi_StructLayoutFieldClass)) {
        VALUE fargv[3], rbFieldClass;
        fargv[0] = rbName;
        fargv[1] = UINT2NUM(offset);
        fargv[2] = rbType;
        if (rb_obj_is_kind_of(rbType, rbffi_FunctionTypeClass)) {
            rbFieldClass = rbffi_StructLayoutFunctionFieldClass;
        } else if (rb_obj_is_kind_of(rbType, rbffi_StructByValueClass)) {
            rbFieldClass = rbffi_StructLayoutStructFieldClass;
        } else if (rb_obj_is_kind_of(rbType, rbffi_ArrayTypeClass)) {
            rbFieldClass = rbffi_StructLayoutArrayFieldClass;
        } else {
            rbFieldClass = rbffi_StructLayoutFieldClass;
        }

        rbField = rb_class_new_instance(3, fargv, rbFieldClass);
    } else {
        rbField = rbType;
    }

    store_field(builder, rbName, rbField, offset, size, alignment);
    
    return self;
}

static VALUE
struct_layout_builder_add_struct(int argc, VALUE* argv, VALUE self)
{
    StructLayoutBuilder* builder;
    VALUE rbName = Qnil, rbType = Qnil, rbOffset = Qnil, rbField = Qnil, rbStructClass = Qnil;
    VALUE fargv[3];
    unsigned int size, alignment, offset;
    int nargs;

    nargs = rb_scan_args(argc, argv, "21", &rbName, &rbStructClass, &rbOffset);

    if (!rb_obj_is_instance_of(rbStructClass, rb_cClass) || !rb_class_inherited(rbStructClass, rbffi_StructClass)) {
        rb_raise(rb_eTypeError, "wrong argument type.  Expected subclass of FFI::Struct");
    }

    rbType = rb_class_new_instance(1, &rbStructClass, rbffi_StructByValueClass);

    alignment = NUM2UINT(rb_funcall2(rbType, rb_intern("alignment"), 0, NULL));
    size = NUM2UINT(rb_funcall2(rbType, rb_intern("size"), 0, NULL));

    Data_Get_Struct(self, StructLayoutBuilder, builder);

    offset = calculate_offset(builder, alignment, rbOffset);

    fargv[0] = rbName;
    fargv[1] = UINT2NUM(offset);
    fargv[2] = rbType;
    rbField = rb_class_new_instance(3, fargv, rbffi_StructLayoutStructFieldClass);
    store_field(builder, rbName, rbField, offset, size, alignment);

    return self;
}

static VALUE
struct_layout_builder_add_array(int argc, VALUE* argv, VALUE self)
{
    StructLayoutBuilder* builder;
    VALUE rbName = Qnil, rbType = Qnil, rbLength = Qnil, rbOffset = Qnil, rbField;
    VALUE fargv[3], aargv[2];
    unsigned int size, alignment, offset;
    int nargs;

    nargs = rb_scan_args(argc, argv, "31", &rbName, &rbType, &rbLength, &rbOffset);

    Data_Get_Struct(self, StructLayoutBuilder, builder);

    alignment = NUM2UINT(rb_funcall2(rbType, rb_intern("alignment"), 0, NULL));
    size = NUM2UINT(rb_funcall2(rbType, rb_intern("size"), 0, NULL)) * NUM2UINT(rbLength);

    offset = calculate_offset(builder, alignment, rbOffset);

    aargv[0] = rbType;
    aargv[1] = rbLength;
    fargv[0] = rbName;
    fargv[1] = UINT2NUM(offset);
    fargv[2] = rb_class_new_instance(2, aargv, rbffi_ArrayTypeClass);
    rbField = rb_class_new_instance(3, fargv, rbffi_StructLayoutArrayFieldClass);

    store_field(builder, rbName, rbField, offset, size, alignment);

    return self;
}

static inline int
align(int offset, int align)
{
    return align + ((offset - 1) & ~(align - 1));
}

static VALUE
struct_layout_builder_build(VALUE self)
{
    StructLayoutBuilder* builder;
    VALUE argv[4];

    Data_Get_Struct(self, StructLayoutBuilder, builder);

    argv[0] = builder->rbFieldNames;
    argv[1] = builder->rbFieldMap;
    argv[2] = UINT2NUM(align(builder->size, builder->alignment)); // tail padding
    argv[3] = UINT2NUM(builder->alignment);

    return rb_class_new_instance(4, argv, rbffi_StructLayoutClass);
}

static VALUE
inline_array_allocate(VALUE klass)
{
    InlineArray* array;
    VALUE obj;

    obj = Data_Make_Struct(klass, InlineArray, inline_array_mark, -1, array);
    array->rbField = Qnil;
    array->rbMemory = Qnil;

    return obj;
}

static void
inline_array_mark(InlineArray* array)
{
    rb_gc_mark(array->rbField);
    rb_gc_mark(array->rbMemory);
}

static VALUE
inline_array_initialize(VALUE self, VALUE rbMemory, VALUE rbField)
{
    InlineArray* array;
    ArrayType* arrayType;

    Data_Get_Struct(self, InlineArray, array);
    array->rbMemory = rbMemory;
    array->rbField = rbField;

    Data_Get_Struct(rbMemory, AbstractMemory, array->memory);
    Data_Get_Struct(rbField, StructField, array->field);
    Data_Get_Struct(array->field->rbType, ArrayType, arrayType);
    Data_Get_Struct(arrayType->rbComponentType, Type, array->componentType);
    
    array->op = memory_get_op(array->memory, array->componentType);
    if (array->op == NULL) {
        rb_raise(rb_eRuntimeError, "invalid memory ops");
    }

    return self;
}

static VALUE
inline_array_size(VALUE self)
{
    InlineArray* array;

    Data_Get_Struct(self, InlineArray, array);

    return UINT2NUM(array->field->type->ffiType->size);
}

static int
inline_array_offset(InlineArray* array, unsigned int index)
{
    return array->field->offset + (index * array->componentType->ffiType->size);
}

static VALUE
inline_array_aref(VALUE self, VALUE rbIndex)
{
    InlineArray* array;

    Data_Get_Struct(self, InlineArray, array);

    return array->op->get(array->memory, inline_array_offset(array, NUM2UINT(rbIndex)));
}

static VALUE
inline_array_aset(VALUE self, VALUE rbIndex, VALUE rbValue)
{
    InlineArray* array;

    Data_Get_Struct(self, InlineArray, array);

    array->op->put(array->memory, inline_array_offset(array, NUM2UINT(rbIndex)),
        rbValue);

    return rbValue;
}

static VALUE
inline_array_each(VALUE self)
{
    InlineArray* array;
    ArrayType* arrayType;
    
    int i;

    Data_Get_Struct(self, InlineArray, array);
    Data_Get_Struct(array->field->rbType, ArrayType, arrayType);

    for (i = 0; i < arrayType->length; ++i) {
    int offset = inline_array_offset(array, i);
        rb_yield(array->op->get(array->memory, offset));
    }

    return self;
}

static VALUE
inline_array_to_a(VALUE self)
{
    InlineArray* array;
    ArrayType* arrayType;
    VALUE obj;
    int i;

    Data_Get_Struct(self, InlineArray, array);
    Data_Get_Struct(array->field->rbType, ArrayType, arrayType);
    obj = rb_ary_new2(arrayType->length);

    
    for (i = 0; i < arrayType->length; ++i) {
        int offset = inline_array_offset(array, i);
        rb_ary_push(obj, array->op->get(array->memory, offset));
    }

    return obj;
}

static VALUE
inline_array_to_s(VALUE self)
{
    InlineArray* array;
    ArrayType* arrayType;
    VALUE argv[2];

    Data_Get_Struct(self, InlineArray, array);
    Data_Get_Struct(array->field->rbType, ArrayType, arrayType);

    if (arrayType->componentType->nativeType != NATIVE_INT8 && arrayType->componentType->nativeType != NATIVE_UINT8) {
        rb_raise(rb_eNoMethodError, "to_s not defined for this array type");
        return Qnil;
    }

    argv[0] = UINT2NUM(array->field->offset);
    argv[1] = UINT2NUM(arrayType->length);

    return rb_funcall2(array->rbMemory, rb_intern("get_string"), 2, argv);
}


static VALUE
inline_array_to_ptr(VALUE self)
{
    InlineArray* array;
    AbstractMemory* ptr;
    VALUE rbOffset, rbPointer;

    Data_Get_Struct(self, InlineArray, array);

    rbOffset = UINT2NUM(array->field->offset);
    rbPointer = rb_funcall2(array->rbMemory, rb_intern("+"), 1, &rbOffset);
    Data_Get_Struct(rbPointer, AbstractMemory, ptr);
    
    // Restrict the size of the pointer so ops like ptr.get_string(0) are bounds checked
    ptr->size = MIN(ptr->size, array->field->type->ffiType->size);

    return rbPointer;
}


void
rbffi_Struct_Init(VALUE moduleFFI)
{
    VALUE StructClass;

    rbffi_StructLayout_Init(moduleFFI);

    rbffi_StructClass = StructClass = rb_define_class_under(moduleFFI, "Struct", rb_cObject);
    rb_global_variable(&rbffi_StructClass);


    StructLayoutBuilderClass = rb_define_class_under(moduleFFI, "StructLayoutBuilder", rb_cObject);
    rb_global_variable(&StructLayoutBuilderClass);

    rbffi_StructInlineArrayClass = rb_define_class_under(rbffi_StructClass, "InlineArray", rb_cObject);
    rb_global_variable(&rbffi_StructInlineArrayClass);



    rb_define_alloc_func(StructClass, struct_allocate);
    rb_define_method(StructClass, "initialize", struct_initialize, -1);
    
    rb_define_alias(rb_singleton_class(StructClass), "alloc_in", "new");
    rb_define_alias(rb_singleton_class(StructClass), "alloc_out", "new");
    rb_define_alias(rb_singleton_class(StructClass), "alloc_inout", "new");
    rb_define_alias(rb_singleton_class(StructClass), "new_in", "new");
    rb_define_alias(rb_singleton_class(StructClass), "new_out", "new");
    rb_define_alias(rb_singleton_class(StructClass), "new_inout", "new");

    rb_define_method(StructClass, "pointer", struct_get_pointer, 0);
    rb_define_private_method(StructClass, "pointer=", struct_set_pointer, 1);

    rb_define_method(StructClass, "layout", struct_get_layout, 0);
    rb_define_private_method(StructClass, "layout=", struct_set_layout, 1);

    rb_define_method(StructClass, "[]", struct_aref, 1);
    rb_define_method(StructClass, "[]=", struct_aset, 2);
    
    

    rb_define_alloc_func(StructLayoutBuilderClass, struct_layout_builder_allocate);
    rb_define_method(StructLayoutBuilderClass, "initialize", struct_layout_builder_initialize, 0);
    rb_define_method(StructLayoutBuilderClass, "build", struct_layout_builder_build, 0);

    rb_define_method(StructLayoutBuilderClass, "alignment", struct_layout_builder_get_alignment, 0);
    rb_define_method(StructLayoutBuilderClass, "alignment=", struct_layout_builder_set_alignment, 1);
    rb_define_method(StructLayoutBuilderClass, "size", struct_layout_builder_get_size, 0);
    rb_define_method(StructLayoutBuilderClass, "size=", struct_layout_builder_set_size, 1);
    rb_define_method(StructLayoutBuilderClass, "union=", struct_layout_builder_set_union, 1);
    rb_define_method(StructLayoutBuilderClass, "union?", struct_layout_builder_union_p, 0);
    rb_define_method(StructLayoutBuilderClass, "add_field", struct_layout_builder_add_field, -1);
    rb_define_method(StructLayoutBuilderClass, "add_array", struct_layout_builder_add_array, -1);
    rb_define_method(StructLayoutBuilderClass, "add_struct", struct_layout_builder_add_struct, -1);

    rb_include_module(rbffi_StructInlineArrayClass, rb_mEnumerable);
    rb_define_alloc_func(rbffi_StructInlineArrayClass, inline_array_allocate);
    rb_define_method(rbffi_StructInlineArrayClass, "initialize", inline_array_initialize, 2);
    rb_define_method(rbffi_StructInlineArrayClass, "[]", inline_array_aref, 1);
    rb_define_method(rbffi_StructInlineArrayClass, "[]=", inline_array_aset, 2);
    rb_define_method(rbffi_StructInlineArrayClass, "each", inline_array_each, 0);
    rb_define_method(rbffi_StructInlineArrayClass, "size", inline_array_size, 0);
    rb_define_method(rbffi_StructInlineArrayClass, "to_a", inline_array_to_a, 0);
    rb_define_method(rbffi_StructInlineArrayClass, "to_s", inline_array_to_s, 0);
    rb_define_alias(rbffi_StructInlineArrayClass, "to_str", "to_s");
    rb_define_method(rbffi_StructInlineArrayClass, "to_ptr", inline_array_to_ptr, 0);

    id_pointer_ivar = rb_intern("@pointer");
    id_layout_ivar = rb_intern("@layout");
    id_layout = rb_intern("layout");
    id_get = rb_intern("get");
    id_put = rb_intern("put");
    id_to_ptr = rb_intern("to_ptr");
    id_to_s = rb_intern("to_s");
}
