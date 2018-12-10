/**
 *  MVP変換のためのモジュール
 */
module dman.math.mvp;

import std.math :
  sin,
  cos
;

import mir.math.sum :
    sum
;

import mir.ndslice :
    blocks,
    byDim,
    canonical,
    diagonal,
    flattened,
    isMatrix,
    isVector,
    map,
    ndarray,
    slice,
    sliced,
    transposed,
    Universal,
    universal,
    zip
;

@safe:

/// 4x4行列を生成する。
auto mat4(T = float)()
out(r) {
    static assert(isMatrix!(typeof(r)));
    assert(r.shape == [4, 4]);
    assert(r.kind == Universal);
} body {
    return slice!T(4, 4).universal;
}

/// 4x4行列を生成する。
auto mat4ed(T = float)(T[] array) @nogc nothrow
out(r) {
    static assert(isMatrix!(typeof(r)));
    immutable float[2] expected = [4, 4];
    assert(r.shape == expected);
    assert(r.kind == Universal);
} body {
    return array.sliced!2(4, 4).universal;
}

///
@nogc nothrow unittest {
    float[16] array = [
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 1.0f
    ];
    auto m = array.mat4ed;
    immutable float[4][4] expected = [
        [1.0f, 0.0f, 0.0f, 0.0f],
        [0.0f, 1.0f, 0.0f, 0.0f],
        [0.0f, 0.0f, 1.0f, 0.0f],
        [0.0f, 0.0f, 0.0f, 1.0f],
    ];
    assert(m[] == expected);
}

/// 4次元ベクトルを生成する。
auto vec4(T = float)()
out(r) {
    static assert(isVector!(typeof(r)));
    assert(r.shape == [4]);
    assert(r.kind == Universal);
} body {
    return slice!T(4).universal;
}

/// 4次元ベクトルを生成する。
auto vec4ed(T = float)(T[] array) @nogc nothrow
in {
    assert(array.length >= 4);
} out(r) {
    static assert(isVector!(typeof(r)));
    immutable float[1] expected = [4];
    assert(r.shape == expected);
    assert(r.kind == Universal);
} body {
    return array.sliced!(1)(4).universal;
}

///
@nogc nothrow unittest {
    float[4] array = [0.0f, 1.0f, 2.0f, 3.0f];
    auto v = array.vec4ed;
    immutable float[4] expected = [0.0f, 1.0f, 2.0f, 3.0f];
    assert(v[] == expected);
}
/// 単位行列にする。
auto toIdentity(S)(S slice) if(isMatrix!S)
in {
    assert(slice.shape[0] == slice.shape[1]);
} body {
    alias T = S.DeepElement;
    slice[] = cast(T) 0.0;
    slice.diagonal[] = cast(T) 1.0;
    return slice;
}

///
unittest {
    auto m = mat4();
    assert(m.toIdentity.glMat4 == [
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 1.0f,
    ]);
}

/// ditto
auto identity4(T = float)() {
    return mat4!T.toIdentity;
}

/// OpenGL行列形式(Column-Major)に変換する。
auto glMat4(S)(S slice) if(isMatrix!S)
in {
    assert(slice.shape == [4, 4]);
} out(r) {
    assert(r.length == 4 * 4);
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

/// OpenGLベクトル形式に変換する。
auto glVec4(S)(S slice) if(isVector!S)
in {
    assert(slice.shape == [4]);
} out(r) {
    assert(r.length == 4);
} body {
    return slice.ndarray;
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

/// ベクトルの内積を計算する。
auto dotProduct(S1, S2)(S1 a, S2 b) @nogc nothrow if(isVector!S1 && isVector!S2)
in {
    assert(a.shape == b.shape);
} body {
    return zip(a, b).map!"a * b".sum!"fast";
}

///
unittest {
    auto a = vec4();
    auto b = vec4();
    a[] = [1, 2, 3, 4];
    b[] = [5, 6, 7, 8];
    assert(a.dotProduct(b) == 1 * 5 + 2 * 6 + 3 * 7 + 4 * 8);
}

/// 行列積を計算する。
void dotProduct(S, T)(S a, S b, T result) @nogc nothrow if(isMatrix!S && isMatrix!T)
in {
    assert(a.shape[1] == b.shape[0]);
    assert(result.shape[0] == a.shape[0]);
    assert(result.shape[1] == b.shape[1]);
} body {
    // aのi行目・bのj列目の内積を計算して代入
    foreach(i; 0 .. a.shape[0]) {
        foreach(j; 0 .. b.shape[1]) {
            result[i, j] = dotProduct(a[i], b[0 .. $, j]);
        }
    }
}

///
unittest {
    auto a = identity4;
    auto b = identity4.toTranslate(1.0f, 2.0f, 3.0f);
    auto result = identity4;
    dotProduct(a, b, result);
    assert(result.glMat4 == [
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
        1.0f, 2.0f, 3.0f, 1.0f,
    ]);
}

/// 行列とベクトルの積を計算する。
void dotProduct(S, T)(S a, T b, T result) @nogc nothrow if(isMatrix!S && isVector!T)
in {
    assert(a.shape[1] == b.shape[0]);
    assert(result.shape[0] == a.shape[0]);
} body {
    // aのi行目・bのj列目の内積を計算して代入
    foreach(i; 0 .. a.shape[0]) {
        result[i] = dotProduct(a[i, 0 .. $], b);
    }
}

///
unittest {
    auto a = identity4.toTranslate(1.0f, 2.0f, 3.0f);
    auto b = vec4();
    b[] = [0.0f, 0.0f, 0.0f, 1.0f];
    auto result = vec4();
    dotProduct(a, b, result);
    assert(result.glVec4 == [1.0f, 2.0f, 3.0f, 1.0f]);
}

/// 行列とベクトルの積を計算する。
void dotProduct(S, T, U)(S a, T b, U result) @nogc nothrow if(isVector!S && isMatrix!T && isVector!U)
in {
    assert(a.shape[0] == b.shape[0]);
    assert(result.shape[0] == b.shape[1]);
} body {
    // aのi行目・bのj列目の内積を計算して代入
    foreach(j; 0 .. b.shape[1]) {
        result[j] = dotProduct(a, b[0 .. $, j]);
    }
}

///
unittest {
    auto a = vec4();
    a[] = [0.0f, 0.0f, 0.0f, 1.0f];
    auto b = identity4.toTranslate(1.0f, 2.0f, 3.0f).transposed;
    auto result = vec4();
    dotProduct(a, b, result);
    assert(result.glVec4 == [1.0f, 2.0f, 3.0f, 1.0f]);
}

/// 平行移動を行う行列の生成。
auto toTranslate(S, T)(S slice, T x, T y, T z) @nogc nothrow if(isMatrix!S) {
    auto m = slice.toIdentity;
    m[0, 3] = x;
    m[1, 3] = y;
    m[2, 3] = z;
    return m;
}

///
unittest {
    auto m = identity4.toTranslate(1.0f, 2.0f, 3.0f);
    assert(m.glMat4 == [
        1.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 1.0f, 0.0f,
        1.0f, 2.0f, 3.0f, 1.0f,
    ]);
}

/// 拡大縮小を行う行列の生成。
auto toScale(S, T)(S slice, T x, T y, T z) @nogc nothrow if(isMatrix!S) {
    auto m = slice.toIdentity;
    m[0, 0] = x;
    m[1, 1] = y;
    m[2, 2] = z;
    return m;
}

///
unittest {
    auto m = identity4.toScale(0.5f, 2.0f, 3.0f);
    assert(m.glMat4 == [
        0.5f, 0.0f, 0.0f, 0.0f,
        0.0f, 2.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 3.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 1.0f,
    ]);
}

/// X軸回転を行う行列の生成
auto toRotateX(S, T)(S slice, T rad) @nogc nothrow if(isMatrix!S) {
    auto m = slice.toIdentity;
    auto sinRad = sin(rad);
    auto cosRad = cos(rad);
    m[1, 1] = cosRad;
    m[1, 2] = sinRad;
    m[2, 1] = -sinRad;
    m[2, 2] = cosRad;
    return m;
}

///
unittest {
    import std.math : PI, sqrt;

    // 60度回転
    auto m = identity4.toRotateX(PI / 3.0f);
    auto v = vec4();
    v[] = [1.0f, 0.0f, 1.0f, 1.0f];
    auto result = vec4();
    m.dotProduct(v, result);
    assert(result[] == [1.0f, sqrt(3.0f) / 2.0f, 1.0f / 2.0f, 1.0f]);
}

/// Y軸回転を行う行列の生成
auto toRotateY(S, T)(S slice, T rad) @nogc nothrow if(isMatrix!S) {
    auto m = slice.toIdentity;
    auto sinRad = sin(rad);
    auto cosRad = cos(rad);
    m[0, 0] = cosRad;
    m[0, 2] = -sinRad;
    m[2, 0] = sinRad;
    m[2, 2] = cosRad;
    return m;
}

///
unittest {
    import std.math : PI, sqrt;

    // 60度回転
    auto m = identity4.toRotateY(PI / 3.0f);
    auto v = vec4();
    v[] = [1.0f, 1.0f, 0.0f, 1.0f];
    auto result = vec4();
    m.dotProduct(v, result);
    assert(result[] == [1.0f / 2.0f, 1.0f, sqrt(3.0f) / 2.0f, 1.0f]);
}

/// Z軸回転を行う行列の生成
auto toRotateZ(S, T)(S slice, T rad) @nogc nothrow if(isMatrix!S) {
    auto m = slice.toIdentity;
    auto sinRad = sin(rad);
    auto cosRad = cos(rad);
    m[0, 0] = cosRad;
    m[0, 1] = sinRad;
    m[1, 0] = -sinRad;
    m[1, 1] = cosRad;
    return m;
}

///
unittest {
    import std.math : PI, sqrt;

    // 60度回転
    auto m = identity4.toRotateZ(PI / 3.0f);
    auto v = vec4();
    v[] = [0.0f, 1.0f, 1.0f, 1.0f];
    auto result = vec4();
    m.dotProduct(v, result);
    assert(result[] == [sqrt(3.0f) / 2.0f, 1.0f / 2.0f, 1.0f, 1.0f]);
}

/// 回転行列の生成
private auto toRotate(alias R1, alias R2, alias R3, S, T)(S slice, T r1, T r2, T r3) @nogc nothrow if(isMatrix!S) {
    T[4 * 4] m = void;
    auto rotateMatrix = m.mat4ed;

    T[4 * 4] t = void;
    auto temp = t.mat4ed;

    auto s = slice.toIdentity;
    R1(rotateMatrix, r1); 
    dotProduct(rotateMatrix, s, temp);
    s[0 .. $, 0 .. $] = temp;

    R2(rotateMatrix, r2); 
    dotProduct(rotateMatrix, s, temp);
    s[0 .. $, 0 .. $] = temp;

    R3(rotateMatrix, r3); 
    dotProduct(rotateMatrix, s, temp);
    s[0 .. $, 0 .. $] = temp;
    return s;
}

/// XYZ回転行列を返す。
auto toRotateXYZ(S, T)(S slice, T x, T y, T z) @nogc nothrow if(isMatrix!S) {
    return toRotate!(toRotateX, toRotateY, toRotateZ)(slice, x, y, z);
}

/// XZY回転行列を返す。
auto toRotateXZY(S, T)(S slice, T x, T y, T z) @nogc nothrow if(isMatrix!S) {
    return toRotate!(toRotateX, toRotateZ, toRotateY)(slice, x, z, y);
}

/// YXZ回転行列を返す。
auto toRotateYXZ(S, T)(S slice, T x, T y, T z) @nogc nothrow if(isMatrix!S) {
    return toRotate!(toRotateY, toRotateX, toRotateZ)(slice, y, x, z);
}

/// YZX回転行列を返す。
auto toRotateYZX(S, T)(S slice, T x, T y, T z) @nogc nothrow if(isMatrix!S) {
    return toRotate!(toRotateY, toRotateZ, toRotateX)(slice, y, z, x);
}

/// ZXY回転行列を返す。
auto toRotateZXY(S, T)(S slice, T x, T y, T z) @nogc nothrow if(isMatrix!S) {
    return toRotate!(toRotateZ, toRotateX, toRotateY)(slice, z, x, y);
}

/// ZYX回転行列を返す。
auto toRotateZYX(S, T)(S slice, T x, T y, T z) @nogc nothrow if(isMatrix!S) {
    return toRotate!(toRotateZ, toRotateY, toRotateX)(slice, z, y, x);
}

