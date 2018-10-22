require("libraries.packagePath")
require("tweaks")
require("Cache")
json = require("json")
sqlite = require("ljsqlite3")
ffi = require("ffi")
require("iconv_ffi")

require("byte")
require("soul")
require("ncdk")
require("bms")
require("o2jam")
require("osu")
require("ucs")
require("jnc")

cache = Cache:new()
cache:init()
cache:lookup(args[1], args[2])
cache:clean(args[1])
