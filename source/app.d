import std.stdio;

import std.exception : assumeUnique;
import std.string : fromStringz;

import dman.sdl :
    enforceSdl,
    loadSdl
;

import dman.opengl :
    loadOpenGl,
    OpenGlException
;

import bindbc.sdl :
    SDL_GL_CONTEXT_PROFILE_CORE,
    SDL_GL_CONTEXT_PROFILE_MASK,
    SDL_GL_CreateContext,
    SDL_GL_DeleteContext,
    SDL_GL_DOUBLEBUFFER,
    SDL_GL_SetAttribute,
    SDL_GL_SwapWindow,
    SDL_INIT_VIDEO,
    SDL_Init,
    SDL_QUIT,
    SDL_Quit,
    SDL_CreateWindow,
    SDL_DestroyWindow,
    SDL_Event,
    SDL_PollEvent,
    SDL_WINDOW_OPENGL,
    SDL_WINDOW_SHOWN
;

import bindbc.opengl :
    GL_ARRAY_BUFFER,
    GL_COLOR_BUFFER_BIT,
    GL_COMPILE_STATUS,
    GL_ELEMENT_ARRAY_BUFFER,
    GL_FALSE,
    GL_FLOAT,
    GL_FRAGMENT_SHADER,
    GL_INFO_LOG_LENGTH,
    GL_LINK_STATUS,
    GL_STATIC_DRAW,
    GL_TRIANGLES,
    GL_UNSIGNED_INT,
    GL_VERSION,
    GL_VERTEX_SHADER,
    glAttachShader,
    glBindBuffer,
    glBufferData,
    GLchar,
    glClearColor,
    glClear,
    glCompileShader,
    glCreateShader,
    glCreateProgram,
    glDeleteBuffers,
    glDeleteProgram,
    glDeleteShader,
    glDetachShader,
    glDisableVertexAttribArray,
    glDrawElements,
    glEnableVertexAttribArray,
    GLenum,
    GLfloat,
    glFlush,
    glGenBuffers,
    glGetProgramiv,
    glGetProgramInfoLog,
    glGetShaderiv,
    glGetShaderInfoLog,
    glGetString,
    GLint,
    glLinkProgram,
    glShaderSource,
    GLsizei,
    GLuint,
    glVertexAttribPointer,
    GLvoid
;

/// ウィンドウタイトル
enum TITLE = "D-man Viewer";

/// ウィンドウ初期表示位置
enum {
    WINDOW_POS_X = 0,
    WINDOW_POS_Y = 0,
    WINDOW_WIDTH = 480,
    WINDOW_HEIGHT = 320,
}

/// ウィンドウ設定。作成時に表示・OpenGL有効化。
enum WINDOW_FLAGS = SDL_WINDOW_SHOWN | SDL_WINDOW_OPENGL;

/// メイン処理
void main() {
    // SDLのロード
    immutable sdlVersion = loadSdl();
    writefln("SDL loaded: %s", sdlVersion);

    // 使用するサブシステムの初期化
    enforceSdl(SDL_Init(SDL_INIT_VIDEO));
    scope(exit) SDL_Quit();

    // OpenGL初期設定
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

    // メインウィンドウ生成
    auto window = enforceSdl(SDL_CreateWindow(
        TITLE,
        WINDOW_POS_X,
        WINDOW_POS_Y,
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        WINDOW_FLAGS));
    scope(exit) SDL_DestroyWindow(window);

    // OpenGLコンテキスト生成
    auto openGlContext = enforceSdl(SDL_GL_CreateContext(window));
    scope(exit) SDL_GL_DeleteContext(openGlContext);

    // OpenGLのロード
    immutable openGlVersion = loadOpenGl();
    writefln("OpenGL loaded: %s(%s)",
            openGlVersion,
            (cast(const(char)*) glGetString(GL_VERSION)).fromStringz);

    // シェーダーの生成
    immutable programId = createShaderProgram(import("dman.vert"), import("dman.frag"));

    // 画面のクリア
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    // 頂点バッファの生成
    GLuint verticesBuffer;
    glGenBuffers(1, &verticesBuffer);
    scope(exit) glDeleteBuffers(1, &verticesBuffer);

    // 頂点データの設定
    glBindBuffer(GL_ARRAY_BUFFER, verticesBuffer);
    immutable(GLfloat)[] triangle = [
        -1.0f, -1.0f, 0.0f,
         1.0f, -1.0f, 0.0f,
         0.0f,  1.0f, 0.0f,
    ];
    glBufferData(GL_ARRAY_BUFFER, triangle.length * GLfloat.sizeof, triangle.ptr, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    // インデックスバッファの生成
    GLuint indiciesBuffer;
    glGenBuffers(1, &indiciesBuffer);
    scope(exit) glDeleteBuffers(1, &indiciesBuffer);

    // インデックスデータの設定
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indiciesBuffer);
    immutable(GLuint)[] indicies = [0, 1, 2];
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indicies.length * GLuint.sizeof, indicies.ptr, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

    // 頂点属性を設定する
    glBindBuffer(GL_ARRAY_BUFFER, verticesBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indiciesBuffer);

    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, cast(const(GLvoid)*) 0);
    glDrawElements(GL_TRIANGLES, cast(GLsizei) indicies.length, GL_UNSIGNED_INT, cast(const(GLvoid)*) 0);
    glDisableVertexAttribArray(0);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glFlush();

    // 描画結果に差し替える。
    SDL_GL_SwapWindow(window);

    // メインループ
    mainLoop: for(;;) {
        // イベントがキューにある限り処理を行う。           
        for(SDL_Event e; SDL_PollEvent(&e);) {
            switch(e.type) {
            case SDL_QUIT:
                break mainLoop;
            default:
                break;
            }
        }
    }
}

/**
 *  シェーダーをコンパイルする。
 *
 *  Params:
 *      source = シェーダーのソースコード
 *      shaderType = シェーダーの種類
 *  Returns:
 *      コンパイルされたシェーダーのID
 *  Throws:
 *      OpenGlException エラー発生時にスロー
 */
GLuint compileShader(string source, GLenum shaderType) {
    // シェーダー生成。エラー時は破棄する。
    immutable shaderId = glCreateShader(shaderType);
    scope(failure) glDeleteShader(shaderId);

    // シェーダーのコンパイル
    immutable length = cast(GLint) source.length;
    const sourcePointer = source.ptr;
    glShaderSource(shaderId, 1, &sourcePointer, &length);
    glCompileShader(shaderId);

    // コンパイル結果取得
    GLint status;
    glGetShaderiv(shaderId, GL_COMPILE_STATUS, &status);
    if(status == GL_FALSE) {
        // コンパイルエラー発生。ログを取得して例外を投げる。
        GLint logLength;
        glGetShaderiv(shaderId, GL_INFO_LOG_LENGTH, &logLength);
        auto log = new GLchar[logLength];
        glGetShaderInfoLog(shaderId, logLength, null, log.ptr);
        throw new OpenGlException(assumeUnique(log));
    }
    return shaderId;
}

/**
 *  シェーダープログラムを生成する。
 *
 *  Params:
 *      vertexShaderSource = 頂点シェーダーのソースコード
 *      fragmentShaderSource = フラグメントシェーダーのソースコード
 *  Returns:
 *      生成されたシェーダープログラム
 *  Throws:
 *      OpenGlException コンパイルエラー等発生時にスロー
 */
GLuint createShaderProgram(string vertexShaderSource, string fragmentShaderSource) {
    // 頂点シェーダーコンパイル
    immutable vertexShaderId = compileShader(vertexShaderSource, GL_VERTEX_SHADER);
    scope(exit) glDeleteShader(vertexShaderId);

    // フラグメントシェーダーコンパイル
    immutable fragmentShaderId = compileShader(fragmentShaderSource, GL_FRAGMENT_SHADER);
    scope(exit) glDeleteShader(fragmentShaderId);

    // プログラム生成
    auto programId = glCreateProgram();
    scope(failure) glDeleteProgram(programId);
    glAttachShader(programId, vertexShaderId);
    scope(exit) glDetachShader(programId, vertexShaderId);
    glAttachShader(programId, fragmentShaderId);
    scope(exit) glDetachShader(programId, fragmentShaderId);

    // プログラムのリンク
    glLinkProgram(programId);
    GLint status;
    glGetProgramiv(programId, GL_LINK_STATUS, &status);
    if(status == GL_FALSE) {
        // エラー発生時はメッセージを取得して例外を投げる
        GLint logLength;
        glGetProgramiv(programId, GL_INFO_LOG_LENGTH, &logLength);
        auto log = new GLchar[logLength];
        glGetProgramInfoLog(programId, logLength, null, log.ptr);
        throw new OpenGlException(assumeUnique(log));
    }

    return programId;
}

