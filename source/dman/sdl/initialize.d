module dman.sdl.initialize;

import dman.sdl.error : SdlException;

import bindbc.sdl :
    loadSDL,
    sdlSupport,
    SDLSupport
;

/**
 *  SDLのロードを行う。
 *
 *  Throws:
 *      SdlException ロードエラー時にスロー
 */
SDLSupport loadSdl() {
    immutable loadedVersion = loadSDL();
    if(loadedVersion != sdlSupport) {
        // SDL無しか未対応バージョンだった場合はエラー。
        if(loadedVersion == SDLSupport.noLibrary) {
            throw new SdlException("SDL2 not found.");
        } else if(loadedVersion == SDLSupport.badLibrary) {
            throw new SdlException("SDL2 bad library.");
        }
    }
    return loadedVersion;
}

