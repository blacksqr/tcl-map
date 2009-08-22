dnl  include.m4 --
dnl  Define various m4 macros
dnl  Copyright (c) 1997, CSIRO Australia
dnl  Author: Harvey Davies, CSIRO Mathematical and Information Sciences
dnl  $Id: include.m4,v 1.27 2002/05/15 05:27:36 dav480 Exp $

divert(-1)
    define(`m4define', defn(`define'))
    define(`m4undefine', defn(`undefine'))
    define(`m4defn', defn(`defn'))
    m4undefine(`define')
    m4undefine(`undefine')
    m4undefine(`defn')
    m4define(`m4prefixm4', `m4define(`m4$1',m4defn(`$1'))m4undefine(`$1')')
    m4prefixm4(`changecom')
    m4prefixm4(`changequote')
    m4prefixm4(`decr')
    m4prefixm4(`divert')
    m4prefixm4(`divnum')
    m4prefixm4(`dnl')
    m4prefixm4(`dumpdef')
    m4prefixm4(`errprint')
    m4prefixm4(`eval')
    m4prefixm4(`format')
    m4prefixm4(`ifdef')
    m4prefixm4(`ifelse')
    m4prefixm4(`include')
    m4prefixm4(`incr')
    m4prefixm4(`index')
    m4prefixm4(`len')
    m4prefixm4(`m4exit')
    m4prefixm4(`m4wrap')
    m4prefixm4(`maketemp')
    m4prefixm4(`popdef')
    m4prefixm4(`pushdef')
    m4prefixm4(`shift')
    m4prefixm4(`sinclude')
    m4prefixm4(`substr')
    m4prefixm4(`syscmd')
    m4prefixm4(`sysval')
    m4prefixm4(`traceoff')
    m4prefixm4(`traceon')
    m4prefixm4(`translit')
    m4prefixm4(`undivert')
    m4prefixm4(`unix')
    m4changecom()
    m4define(`m4LowerCase', `m4translit($1, `ABCDEFGHIJKLMNOPQRSTUVWXYZ',
	`abcdefghijklmnopqrstuvwxyz')')
    m4define(`m4UpperCase', `m4translit($1, `abcdefghijklmnopqrstuvwxyz',
	`ABCDEFGHIJKLMNOPQRSTUVWXYZ')')
    m4define(`m4UpperCase0', `m4UpperCase(m4substr($1,0,1))`'m4substr($1,1)')
    m4define(`m4shift2', `m4shift(m4shift($*))')
    m4define(`m4shift3', `m4shift(m4shift(m4shift($*)))')
    m4define(`m4begin', `m4divert(-1)')
    m4define(`m4end', `m4divert(0)m4dnl')
    m4define(`m4DataTypeEnum', `NAP_`'m4UpperCase($1)')
    m4define(`m4DataTypeName', `Nap_`'m4LowerCase($1)')
    m4define(`m4DataTypeMissingValue', `NAP_`'m4UpperCase($1)_NULL')
    m4define(`m4DataTypeMin',  `NAP_`'m4UpperCase($1)_MIN')
    m4define(`m4DataTypeMax',  `NAP_`'m4UpperCase($1)_MAX')
    m4define(`m4MissingValue', `nap_cd->$1`'MissingValueNao->data.$1[0]')

m4define(`m4MinBoxedDataType', `Boxed')
m4define(`m4MaxBoxedDataType', `Ragged')
m4define(`m4ForAllBoxedDataType', `
$1`'m4MinBoxedDataType$2
$1`'m4MaxBoxedDataType$2
')

m4define(`m4MinCharacterDataType', `C8')
m4define(`m4MaxCharacterDataType', `C8')
m4define(`m4ForAllCharacterDataType', `
$1`'m4MinCharacterDataType$2
')

m4define(`m4MinUnsignedIntegerDataType', `U8')
m4define(`m4MaxUnsignedIntegerDataType', `U32')
m4define(`m4ForAllUnsignedIntegerDataType', `
$1`'m4MinUnsignedIntegerDataType$2
$1`'U16$2
$1`'m4MaxUnsignedIntegerDataType$2
')

m4define(`m4MinSignedIntegerDataType', `I8')
m4define(`m4MaxSignedIntegerDataType', `I32')
m4define(`m4ForAllSignedIntegerDataType', `
$1`'m4MinSignedIntegerDataType$2
$1`'I16$2
$1`'m4MaxSignedIntegerDataType$2
')

m4define(`m4MinIntegerDataType', m4MinSignedIntegerDataType)
m4define(`m4MaxIntegerDataType', m4MaxUnsignedIntegerDataType)
m4define(`m4ForAllIntegerDataType', `
m4ForAllUnsignedIntegerDataType(`$1',`$2')
m4ForAllSignedIntegerDataType(`$1',`$2')
')

m4define(`m4MinRealDataType', `F32')
m4define(`m4MaxRealDataType', `F64')
m4define(`m4ForAllRealDataType', `
$1`'m4MinRealDataType$2
$1`'m4MaxRealDataType$2
')

m4define(`m4MinSignedDataType', m4MinSignedIntegerDataType)
m4define(`m4MaxSignedDataType', m4MaxRealDataType)
m4define(`m4ForAllSignedDataType', `
m4ForAllSignedIntegerDataType(`$1',`$2')
m4ForAllRealDataType(`$1',`$2')
')

m4define(`m4MinNumericDataType', m4MinIntegerDataType)
m4define(`m4MaxNumericDataType', m4MaxRealDataType)
m4define(`m4ForAllNumericDataType', `
m4ForAllIntegerDataType(`$1',`$2')
m4ForAllRealDataType(`$1',`$2')
')

m4define(`m4MinUnboxedDataType', m4MinCharacterDataType)
m4define(`m4MaxUnboxedDataType', m4MaxNumericDataType)
m4define(`m4ForAllUnboxedDataType', `
m4ForAllCharacterDataType(`$1',`$2')
m4ForAllNumericDataType(`$1',`$2')
')

m4define(`m4MinDataType', Boxed)
m4define(`m4MaxDataType', m4MaxNumericDataType)
m4define(`m4ForAllDataType', `
$1`'C8$2
$1`'I8$2
$1`'U8$2
$1`'I16$2
$1`'U16$2
$1`'I32$2
$1`'U32$2
$1`'F32$2
$1`'F64$2
$1`'Ragged$2
$1`'Boxed$2
')

m4define(`m4DataTypeValue', `m4DataTypeEnum($1)_VALUE')

m4define(`m4isIntegerDataType',
`(m4DataTypeValue($1) >= m4DataTypeValue(m4MinIntegerDataType) && m4DataTypeValue($1) <= m4DataTypeValue(m4MaxIntegerDataType))')

m4define(`m4isRealDataType',
`(m4DataTypeValue($1) >= m4DataTypeValue(m4MinRealDataType) && m4DataTypeValue($1) <= m4DataTypeValue(m4MaxRealDataType))')

m4define(`m4isNaN', `IsNaN`'m4substr($1, 1)')

m4divert(0)m4dnl
