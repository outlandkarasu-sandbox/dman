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
    GL_ARRAY_BUFFER,
    GL_COLOR_BUFFER_BIT,
    GL_ELEMENT_ARRAY_BUFFER,
    GL_FALSE,
    GL_FLOAT,
    GL_STATIC_DRAW,
    GL_TRIANGLES,
    GL_UNSIGNED_INT,
    glBindBuffer,
    glBufferData,
    glClearColor,
    glClear,
    glDeleteBuffers,
    glDisableVertexAttribArray,
    glDrawElements,
    glEnableVertexAttribArray,
    GLfloat,
    glFlush,
    glGenBuffers,
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

