import std.stdio;

import dman.sdl :
    enforceSdl,
    loadSdl
;

import dman.opengl :
    loadOpenGl
;

import bindbc.sdl :
    SDL_GL_CreateContext,
    SDL_GL_DeleteContext,
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
    GL_COLOR_BUFFER_BIT,
    glBindBuffer,
    glClearColor,
    glClear,
    glDeleteBuffers,
    glGenBuffers,
    GLuint
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
    writefln("OpenGL loaded: %s", openGlVersion);

    // 画面のクリア
    glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    // 頂点バッファの生成
    GLuint verticesBuffer;
    glGenBuffers(1, &verticesBuffer);
    scope(exit) glDeleteBuffers(1, &verticesBuffer);

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

