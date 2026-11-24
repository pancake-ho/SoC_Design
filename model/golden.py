"""Independent integer/float CNN reference. Python 3.6+, no numpy overflow."""
import math
from workload import X_COUNT, W_COUNT, BIAS_COUNT, FILTERS, OUT_H, OUT_W

INT32_MIN=-(1<<31)
INT32_MAX=(1<<31)-1


def round_away(value):
    if not math.isfinite(value):
        raise ValueError('non-finite input')
    return math.floor(value + 0.5) if value >= 0 else -math.floor(-value + 0.5)


def quantize(value, scale):
    if not math.isfinite(scale) or scale <= 0:
        raise ValueError('scale must be finite and positive')
    return max(-128, min(127, round_away(value / scale)))


def requant(acc, shift, relu):
    if type(shift) is not int or not 0 <= shift <= 15:
        raise ValueError('shift out of range')
    a = max(acc, 0) if relu else acc
    mag = abs(a) if shift == 0 else (abs(a) + (1 << (shift - 1))) >> shift
    return max(-128, min(127, -mag if a < 0 else mag))


def dot_products(x, w):
    if len(x) != X_COUNT or len(w) != W_COUNT:
        raise ValueError('v9 requires X[16][16] and W[4][3][3]')
    if any(type(v) is not int or not -128 <= v <= 127 for v in list(x) + list(w)):
        raise ValueError('signed int8 required')
    return [sum(x[(r+i)*16+c+j]*w[f*9+i*3+j] for i in range(3) for j in range(3))
            for f in range(FILTERS) for r in range(OUT_H) for c in range(OUT_W)]


def raw_sums(x, w, bias):
    if (not isinstance(bias, (list, tuple)) or len(bias) != BIAS_COUNT or
            any(type(v) is not int or not INT32_MIN <= v <= INT32_MAX for v in bias)):
        raise ValueError('four signed int32 bias values required')
    return [bias[k//(OUT_H*OUT_W)]+d for k,d in enumerate(dot_products(x,w))]


def narrow_int32(value, satfinite):
    if satfinite:
        return max(INT32_MIN,min(INT32_MAX,value))
    return (value-INT32_MIN)%(1<<32)+INT32_MIN


def conv16x16(x, w, bias, shift=2, relu=True, satfinite=True):
    raw = [narrow_int32(a,satfinite) for a in raw_sums(x,w,bias)]
    return raw, [requant(a, shift, relu) for a in raw]


def float_experiment(x, w, bias, sx, sw, shift, relu):
    xq, wq = [quantize(v, sx) for v in x], [quantize(v, sw) for v in w]
    bq = [round_away(v / (sx*sw)) for v in bias]
    raw, y = conv16x16(xq, wq, bq, shift, relu)
    sy = sx*sw*2**shift
    expected = [bias[f] + sum(x[(r+i)*16+c+j]*w[f*9+i*3+j] for i in range(3) for j in range(3))
                for f in range(FILTERS) for r in range(OUT_H) for c in range(OUT_W)]
    if relu:
        expected = [max(0, v) for v in expected]
    error = [abs(a-b*sy) for a, b in zip(expected, y)]
    return dict(raw=raw, yq=y, sy=sy, max_abs_error=max(error), mae=sum(error)/len(error),
                clipping_count=sum(not -128 <= round_away((max(v, 0) if relu else v)/2**shift) <= 127
                                   for v in raw), classification_accuracy=None)
