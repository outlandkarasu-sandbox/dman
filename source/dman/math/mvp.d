/**
 *  MVP変換のためのモジュール
 */
module dman.math.mvp;

import mir.ndslice :
    diagonal,
    flattened,
    ndarray,
    Slice,
    slice,
    SliceKind,
    transposed
;

/// 4x4行列を生成する。
auto mat4(T = float)() {
    return slice!T(4, 4);
}

/**
 *  OpenGL行列形式(Column-Major)に変換する。
 */
auto glMat4(Iterator, size_t N, SliceKind kind)(Slice!(Iterator, N, kind) slice)
if(N == 2)
in {
    assert(slice.shape == [4, 4]);
} body {
    return slice.transposed.flattened.ndarray;
}

///
unittest {
    auto id = mat4();
    id[] = 0.0f;
    id.diagonal[] = 1.0f;
    id[0, 2] = 2.0f;
    assert(id.glMat4 == [
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 0.0f,
        2.0f, 0.0f, 1.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 1.0f,
    ]);
}

