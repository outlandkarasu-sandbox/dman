import std.stdio;

import dman.sdl :
    loadSdl
;

/// メイン処理
void main() {
    writefln("loaded SDL2: %s", loadSdl());
}

