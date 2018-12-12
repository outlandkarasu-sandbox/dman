import std.stdio;

import std.algorithm : max, map, joiner;
import std.array : array;
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

import dman.math.mvp :
    dotProduct,
    mat4ed,
    toRotateXYZ,
    toScale,
    toTranslate
;

import bindbc.sdl :
    SDL_GL_CONTEXT_MAJOR_VERSION,
    SDL_GL_CONTEXT_MINOR_VERSION,
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
    SDL_Delay,
    SDL_DestroyWindow,
    SDL_Event,
    SDL_FreeSurface,
    SDL_GetPerformanceCounter,
    SDL_GetPerformanceFrequency,
    SDL_PollEvent,
    SDL_WINDOW_OPENGL,
    SDL_WINDOW_SHOWN
;

import bindbc.opengl :
    GL_ARRAY_BUFFER,
    GL_COLOR_BUFFER_BIT,
    GL_COMPILE_STATUS,
    GL_DEPTH_BUFFER_BIT,
    GL_DEPTH_TEST,
    GL_ELEMENT_ARRAY_BUFFER,
    GL_FALSE,
    GL_FLOAT,
    GL_FRAGMENT_SHADER,
    GL_INFO_LOG_LENGTH,
    GL_LINEAR,
    GL_LINK_STATUS,
    GL_REPEAT,
    GL_RGB,
    GL_STATIC_DRAW,
    GL_TEXTURE_2D,
    GL_TEXTURE_MIN_FILTER,
    GL_TEXTURE_MAG_FILTER,
    GL_TEXTURE_WRAP_S,
    GL_TEXTURE_WRAP_T,
    GL_TEXTURE0,
    GL_TRIANGLES,
    GL_TRUE,
    GL_UNSIGNED_BYTE,
    GL_UNSIGNED_INT,
    GL_UNSIGNED_SHORT,
    GL_VERSION,
    GL_VERTEX_SHADER,
    glAttachShader,
    glActiveTexture,
    glBindBuffer,
    glBindTexture,
    glBindVertexArray,
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
    glDeleteTextures,
    glDeleteVertexArrays,
    glDetachShader,
    glDisableVertexAttribArray,
    glDrawArrays,
    glDrawElements,
    glEnable,
    glEnableVertexAttribArray,
    GLenum,
    GLfloat,
    GLubyte,
    GLushort,
    glFlush,
    glGenBuffers,
    glGenTextures,
    glGenVertexArrays,
    glGetProgramiv,
    glGetProgramInfoLog,
    glGetShaderiv,
    glGetShaderInfoLog,
    glGetString,
    glGetUniformLocation,
    GLint,
    glLinkProgram,
    glShaderSource,
    GLsizei,
    glTexImage2D,
    glTexParameteri,
    glUniform1i,
    glUniformMatrix4fv,
    glUseProgram,
    GLuint,
    glVertexAttribPointer,
    glViewport,
    GLvoid
;

import bindbc.sdl.image :
    IMG_Init,
    IMG_INIT_PNG,
    IMG_Load,
    IMG_Quit,
    loadSDLImage,
    sdlImageSupport
;

import derelict.assimp3.assimp :
    aiAttachLogStream,
    aiDefaultLogStream_STDOUT,
    aiGetPredefinedLogStream,
    aiProcessPreset_TargetRealtime_MaxQuality,
    aiImportFile,
    aiReleaseImport,
    DerelictASSIMP3
;

/// D言語くんモデル
enum DMAN_MODEL_PATH = "./asset/Dman_2013.fbx";
enum DMAN_TEXTURE_PATH = "./asset/Dman_tex.png";

/// ウィンドウタイトル
enum TITLE = "D-man Viewer";

/// ウィンドウ初期表示位置
enum {
    WINDOW_POS_X = 0,
    WINDOW_POS_Y = 0,
    WINDOW_WIDTH = 480,
    WINDOW_HEIGHT = 480, //WINDOW_HEIGHT = 320, 一旦正方形にしておく
}

/// ウィンドウ設定。作成時に表示・OpenGL有効化。
enum WINDOW_FLAGS = SDL_WINDOW_SHOWN | SDL_WINDOW_OPENGL;

/// OpenGLバージョン
enum {
    OPEN_GL_MAJOR_VERSION = 3,
    OPEN_GL_MINOR_VERSION = 3,
}

/// FPS設定
enum FPS = 90;

/// 位置の型
struct Position {
    GLfloat x;
    GLfloat y;
    GLfloat z;
}

/// テクスチャ座標の型
struct TextureCoord {
    GLfloat u;
    GLfloat v;
}

/// 色の型
struct Color {
    GLubyte r;
    GLubyte g;
    GLubyte b;
    GLubyte a;
}

/// 頂点データ型
struct Vertex {
    Position position;
    Color color;
    TextureCoord textureCoord;
}

/// メイン処理
void main() {
    // ASSIMPのロード
    DerelictASSIMP3.load();

    // 標準出力にログを出すよう設定
    auto logStream = aiGetPredefinedLogStream(aiDefaultLogStream_STDOUT, null);
    aiAttachLogStream(&logStream);

    // D言語くん読み込み
    auto scene = aiImportFile(DMAN_MODEL_PATH, aiProcessPreset_TargetRealtime_MaxQuality);
    scope(exit) aiReleaseImport(scene);

    // メッシュ等取得
    auto meshes = scene.mMeshes[0 .. scene.mNumMeshes];
    auto materials = scene.mMaterials[0 .. scene.mNumMaterials];
    auto materialProperties = materials[0].mProperties[0 .. materials[0].mNumProperties];
    foreach(m; materialProperties) {
        writefln("%s", m.mKey.data[0 .. m.mKey.length]);
    }

    // メッシュから頂点情報を取得
    auto mesh = meshes[0];
    auto vertices = mesh.mVertices[0 .. mesh.mNumVertices]
        .map!(v => Vertex(Position(-v.x, v.y, v.z), Color(255, 0, 0, 255)))
        .array;

    // テクスチャ座標の設定
    if(mesh.mTextureCoords[0]) {
        foreach(i, uv; mesh.mTextureCoords[0][0 .. vertices.length]) {
            vertices[i].textureCoord = TextureCoord(uv.x, 1.0f - uv.y);
        }
    }

    // 面情報の取得
    auto indices = mesh.mFaces[0 .. mesh.mNumFaces]
        .map!(f => f.mIndices[0 .. f.mNumIndices])
        .joiner
        .map!(i => cast(GLushort) i)
        .array;

    // SDLのロード
    immutable sdlVersion = loadSdl();
    writefln("SDL loaded: %s", sdlVersion);

    // SDL_imageのロード
    immutable sdlImageVersion = loadSDLImage();
    writefln("SDL_image loaded: %s", sdlImageVersion);

    // 使用するサブシステムの初期化
    enforceSdl(SDL_Init(SDL_INIT_VIDEO));
    scope(exit) SDL_Quit();

    enforceSdl(IMG_Init(IMG_INIT_PNG) == IMG_INIT_PNG);
    scope(exit) IMG_Quit();

    // OpenGLバージョン等設定
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, OPEN_GL_MAJOR_VERSION);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, OPEN_GL_MINOR_VERSION);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

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

    // ビューポートの設定
    glViewport(0, 0, WINDOW_HEIGHT, WINDOW_WIDTH);
    glEnable(GL_DEPTH_TEST);

    // シェーダーの生成
    immutable programId = createShaderProgram(import("dman.vert"), import("dman.frag"));
    scope(exit) glDeleteProgram(programId);

    // 頂点データの生成
    GLuint verticesBuffer;
    glGenBuffers(1, &verticesBuffer);
    scope(exit) glDeleteBuffers(1, &verticesBuffer);

    glBindBuffer(GL_ARRAY_BUFFER, verticesBuffer);
    glBufferData(GL_ARRAY_BUFFER, vertices.length * Vertex.sizeof, vertices.ptr, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    // VBOの生成
    GLuint elementBuffer;
    glGenBuffers(1, &elementBuffer);
    scope(exit) glDeleteBuffers(1, &elementBuffer);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.length * GLushort.sizeof, indices.ptr, GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

    // テクスチャの生成
    GLuint texture;
    glGenTextures(1, &texture);
    scope(exit) glDeleteTextures(1, &texture);

    // テクスチャ読み込み
    auto textureSurface = enforceSdl(IMG_Load(DMAN_TEXTURE_PATH));
    scope(exit) SDL_FreeSurface(textureSurface);

    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, textureSurface.w, textureSurface.h, 0, GL_RGB, GL_UNSIGNED_BYTE, textureSurface.pixels);
    glBindTexture(GL_TEXTURE_2D, 0);

    // VAOの生成
    GLuint vao;
    glGenVertexArrays(1, &vao);
    scope(exit) glDeleteVertexArrays(1, &vao);

    // VAOの内容設定
    glBindVertexArray(vao);
    glBindBuffer(GL_ARRAY_BUFFER, verticesBuffer);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(const(GLvoid)*) 0);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 4, GL_UNSIGNED_BYTE, GL_TRUE, Vertex.sizeof, cast(const(GLvoid)*) Vertex.color.offsetof);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(const(GLvoid)*) Vertex.textureCoord.offsetof);
    glEnableVertexAttribArray(2);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBuffer);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    glBindVertexArray(0);

    // 設定済みのバッファを選択解除する。
    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    glBindTexture(GL_TEXTURE_2D, 0);

    // uniform変数のlocationを取得しておく。
    immutable transformLocation = glGetUniformLocation(programId, "transform");

    float[4 * 4] rotateArray = void;
    float[4 * 4] scaleArray = void;
    float[4 * 4] translateArray = void;
    float[4 * 4] transformArray = void;
    float[4 * 4] tempArray = void;
    auto rotateMat = rotateArray.mat4ed;
    auto scaleMat = scaleArray.mat4ed;
    auto translateMat = translateArray.mat4ed;
    auto transformMat = transformArray.mat4ed;
    auto tempMat = tempArray.mat4ed;
    scaleMat.toScale(0.005f, 0.005f, 0.005f);
    translateMat.toTranslate(0.0f, -1.0f, 0.0f);
    float rotate = 0.0f;

    // テクスチャのuniform変数のlocationを取得しておく。
    auto textureLocation = glGetUniformLocation(programId, "textureSampler");

    /// 描画処理
    void draw() {
        // 画面のクリア
        glClearColor(0.0f, 0.0f, 1.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        // VAO・シェーダーを使用して描画する。
        glUseProgram(programId);
        glBindVertexArray(vao);

        // 座標変換行列をuniform変数に設定する。
        rotate += 0.01f;
        translateMat.dotProduct(scaleMat, tempMat);
        rotateMat.toRotateXYZ(0.0f, rotate, 0.0f).dotProduct(tempMat, transformMat);
        glUniformMatrix4fv(transformLocation, 1, true, transformArray.ptr);
    
        // テクスチャ選択
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, texture);
        glUniform1i(textureLocation, 0);
        glDrawElements(GL_TRIANGLES, cast(GLsizei) indices.length, GL_UNSIGNED_SHORT, cast(const(GLvoid)*) 0);
    
        glBindVertexArray(0);
        glUseProgram(0);
        glFlush();
    
        // 描画結果に差し替える。
        SDL_GL_SwapWindow(window);
    }

    // 1フレーム当たりのパフォーマンスカウンタ値計算。FPS制御のために使用する。
    immutable performanceFrequency = SDL_GetPerformanceFrequency();
    immutable countPerFrame = performanceFrequency / FPS;

    // メインループ
    mainLoop: for(;;) {
        immutable frameStart = SDL_GetPerformanceCounter();

        // イベントがキューにある限り処理を行う。           
        for(SDL_Event e; SDL_PollEvent(&e);) {
            switch(e.type) {
            case SDL_QUIT:
                break mainLoop;
            default:
                break;
            }
        }

        // 描画実行
        draw();

        // 次フレームまで待機
        immutable drawDelay = SDL_GetPerformanceCounter() - frameStart;
        if(countPerFrame < drawDelay) {
            SDL_Delay(0);
        } else {
            SDL_Delay(cast(uint)((countPerFrame - drawDelay) * 1000 / performanceFrequency));
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

