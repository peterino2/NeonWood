// this folder contains
const std = @import("std");
const root = @import("root");
const nw = root.neonwood;

const core = nw.core;

pub fn testFunc() void {
    core.engine_logs("tested");
}
