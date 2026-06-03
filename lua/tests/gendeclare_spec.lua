package.path = "lua/?.lua;lua/?/init.lua;" .. package.path

local gendeclare = require("configs.gendeclare")
local helpers = gendeclare._test

local function eq(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s\nexpected: %s\nactual:   %s", label, tostring(expected), tostring(actual)), 2)
    end
end

eq(
    helpers.build_declaration({
        "int foo(",
        "    int a,",
        "    const char *name)",
        "{",
    }, "c"),
    "extern int foo(int a, const char *name);",
    "builds a C declaration from a multiline function signature"
)

eq(
    helpers.build_declaration({ "static int hidden(int a) {" }, "c"),
    nil,
    "does not create declarations for static functions"
)

eq(
    helpers.build_declaration({ "inline static int hidden(int a) {" }, "c"),
    nil,
    "does not create declarations for inline static functions"
)

eq(
    helpers.build_declaration({ "static inline int hidden(int a) {" }, "c"),
    nil,
    "does not create declarations for static inline functions"
)

eq(
    helpers.build_declaration({ "int Widget::count() const {" }, "cpp"),
    "int Widget::count() const;",
    "does not add extern for C++ member-style declarations"
)

eq(
    helpers.declaration_exists({
        "extern int foo(",
        "    int a,",
        "    const char *name",
        ");",
    }, "extern int foo(int a, const char *name);"),
    true,
    "detects existing multiline declarations"
)

eq(helpers.find_insert_row({ "#pragma once", "", "int bar(void);" }, "int foo(void);", nil, nil), 2,
    "falls back after header preamble when no anchor exists")

eq(helpers.find_insert_row({ "int prev(void);", "int next(void);" }, "int foo(void);", "next", "up"), 1,
    "inserts before the next function anchor")

print("gendeclare_spec: ok")
