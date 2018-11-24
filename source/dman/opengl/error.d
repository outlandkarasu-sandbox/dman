module dman.opengl.error;

/**
 *  OpenGL関連エラー例外
 */
class OpenGlException : Exception {

    /**
     *  Params:
     *      msg = エラーメッセージ
     *      file = ファイル名
     *      line = 行番号
     */
    pure nothrow @nogc @safe this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

