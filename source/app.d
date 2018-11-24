import std.stdio;

import dman.sdl :
    enforceSdl,
    loadSdl
;

import bindbc.sdl :
    SDL_Init,
    SDL_INIT_VIDEO,
    SDL_Quit
;

/// メイン処理
void main() {
    immutable loadedVersion = loadSdl();
    writefln("SDL loaded: %s", loadedVersion);

    enforceSdl(SDL_Init(SDL_INIT_VIDEO));
    scope(exit) SDL_Quit();
}

