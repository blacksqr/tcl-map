/* ----------------------------------------------------------------------------
 * This file was automatically generated by SWIG (http://www.swig.org).
 * Version 1.3.36
 * 
 * This file is not intended to be easily readable and contains a number of 
 * coding conventions designed to improve portability and efficiency. Do not make
 * changes to this file unless you know what you are doing--modify the SWIG 
 * interface file instead. 
 * ----------------------------------------------------------------------------- */



#ifndef PHP_GDALCONST_H
#define PHP_GDALCONST_H

extern zend_module_entry gdalconst_module_entry;
#define phpext_gdalconst_ptr &gdalconst_module_entry

#ifdef PHP_WIN32
# define PHP_GDALCONST_API __declspec(dllexport)
#else
# define PHP_GDALCONST_API
#endif

#ifdef ZTS
#include "TSRM.h"
#endif

PHP_MINIT_FUNCTION(gdalconst);
PHP_MSHUTDOWN_FUNCTION(gdalconst);
PHP_RINIT_FUNCTION(gdalconst);
PHP_RSHUTDOWN_FUNCTION(gdalconst);
PHP_MINFO_FUNCTION(gdalconst);

#endif /* PHP_GDALCONST_H */