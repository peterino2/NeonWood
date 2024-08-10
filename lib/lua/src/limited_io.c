#include "lprefix.h"
#include <stddef.h>
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

static const luaL_Reg limitedio_libs[] = {
  {LUA_GNAME, luaopen_base},
  {LUA_LOADLIBNAME, luaopen_package},
  {LUA_COLIBNAME, luaopen_coroutine},
  {LUA_TABLIBNAME, luaopen_table},

  // thhese will be provided by engine
  // {LUA_IOLIBNAME, luaopen_io}, no access to IOstream
  // {LUA_OSLIBNAME, luaopen_os}, no access to file system

  {LUA_STRLIBNAME, luaopen_string},
  {LUA_MATHLIBNAME, luaopen_math},
  {LUA_UTF8LIBNAME, luaopen_utf8},
  {LUA_DBLIBNAME, luaopen_debug},
  {NULL, NULL}
};

void open_limitedio_libs (lua_State *L) {
  const luaL_Reg *lib;
  /* "require" functions from 'loadedlibs' and set results to global table */
  for (lib = limitedio_libs; lib->func; lib++) {
    luaL_requiref(L, lib->name, lib->func, 1);
    lua_pop(L, 1);  /* remove lib */
  }
}
