# comparaison behaviours

// bad type
_BADTYPE: Fact_BADTYPE, 
    true if compared against _BADTYPE
    false in all other cases

// pod types
boolean: FactBoolean,
    nonzero integer, float, typeRef, ref all convert to .boolean = true
    zeros  convert to .boolean = false
integer: FactInteger,
    enums convert into integer
    float truncates to i64, boolean is 0 or 1
float: FactFloat,
    float integers convert to x.0 floats, and booleans convert to 1.0 or 0.0

typeRef: FactTypeRef,
    can only compare against other typeRefs
ref: FactRef,
    ..... should dereference then compare

// array types
array: FactArray,
    can only compare against another array of the same type and length
string: FactString,
    can compare against string representations of anything.
    returns true if slices are equal

// user type system
typeInfo: FactTypeInfo,
    typeRef can convert into typeInfo by derference
    
userEnum: FactUserEnum,
    can convert integer into enum

userStruct: FactUserStruct,
    does not convert into anything
