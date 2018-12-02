/**
 *  MVP変換のためのモジュール
 */
module dman.math.mvp;

import mir.ndslice :
    blocks,
    diagonal,
    flattened,
    isMatrix,
    ndarray,
    slice,
    transposed,
    zip
;

/// 4x4行列を生成する。
auto mat4(T = float)() {
    return slice!T(4, 4);
}

/// 単位行列を生成する。
auto identitied(S)(S slice) if(isMatrix!S)
in {
    assert(slice.shape[0] == slice.shape[1]);
} body {
    alias T = S.DeepElement;
    slice[] = cast(T) 0.0;
    slice.diagonal[] = cast(T) 1.0;
    return slice;
}

/// ditto
auto identity4(T = float)() {
    return mat4!T.identitied;
}

/// OpenGL行列形式(Column-Major)に変換する。
auto glMat4(S)(S slice) if(isMatrix!S)
in {
    assert(slice.shape == [4, 4]);
} body {
    return slice.transposed.flattened.ndarray;
}

///
unittest {
    auto m = identity4();
    m[0, 2] = 2.0f;
    assert(m.glMat4 == [
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 0.0f,
        2.0f, 0.0f, 1.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 1.0f,
    ]);
}

/// 平行移動を行う行列の生成。
auto translated(S, T)(S slice, T x, T y, T z) if(isMatrix!S) {
    auto m = slice.identitied;
    m[0, 3] = x;
    m[1, 3] = y;
    m[2, 3] = z;
    return m;
}

///
unittest {
    auto m = identity4.translated(1.0f, 2.0f, 3.0f);
    assert(m.glMat4 == [
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
        1.0f, 2.0f, 3.0f, 1.0f,
    ]);
}

