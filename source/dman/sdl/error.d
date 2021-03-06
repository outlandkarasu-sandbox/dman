module dman.sdl.error;

import std.traits : isIntegral, isPointer;
import std.string : fromStringz;

import bindbc.sdl : SDL_GetError;

/**
 *  SDL関連エラー例外
 */
class SdlException : Exception {

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

/**
 *  SDL関数のエラーチェックを行う。
 *
 *  Params:
 *      T = 戻り値の型。整数型限定。
 *      file = ファイル名
 *      line = 行番号
 *      value = チェック対象の戻り値
 *  Returns:
 *      戻り値がそのまま返る。
 *  Throws: SdlException 戻り値が0でない場合にスロー
 */
T enforceSdl(T, string file = __FILE__, ulong line = __LINE__)(T value) {
    static if(is(T == bool)) {
        immutable hasError = !value;
    } else static if(isIntegral!T) {
        immutable hasError = (value != 0);
    } else static if(isPointer!T) {
        immutable hasError = (value is null);
    } else {
        static assert(false, "unsupported type. " ~ T.stringof);
    }

    if(hasError) {
        throw new SdlException(fromStringz(SDL_GetError()).idup, file, line);
    }
    return value;
}

