module dman.opengl.initialize;

import dman.opengl.error : OpenGlException;

import bindbc.opengl :
    loadOpenGL,
    GLSupport
;

/**
 *  OpenGLのロードを行う。
 *
 *  Throws:
 *      OpenGlException ロードエラー時にスロー
 */
GLSupport loadOpenGl() {
    immutable loadedVersion = loadOpenGL();
        // OpenGL無しか未対応バージョンだった場合はエラー。
    if(loadedVersion == GLSupport.noLibrary) {
        throw new OpenGlException("OpenGL not found.");
    } else if(loadedVersion == GLSupport.badLibrary) {
        throw new OpenGlException("OpenGL bad library.");
    } else if(loadedVersion == GLSupport.noContext) {
        throw new OpenGlException("OpenGL context not yet created.");
    }
    return loadedVersion;
}

