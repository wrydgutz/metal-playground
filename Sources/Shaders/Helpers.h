//
//  Helpers.h
//  metal-playground
//
//  Created by Wrydrick Gutierrez on 18/5/26.
//

#include <metal_stdlib>
using namespace metal;

// Guard against out-of-bounds.
template <class T, access A>
inline bool isOutOfBounds(thread const texture2d<T, A>& texture, uint2 gid) {
    return gid.x >= texture.get_width() ||
           gid.y >= texture.get_height();
}

template <class T, class T3>
inline T luminanceRec601(T3 colorRGB) {
    return dot(colorRGB, T3(0.299f, 0.587f, 0.114f));
}
