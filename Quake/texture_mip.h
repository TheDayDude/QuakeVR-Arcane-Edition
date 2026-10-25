/* GPL-2.0-or-later. Area-filter an odd-sized RGBA mip axis in place.
 * Unlike the paired SSE path, this retains row/layer boundaries and includes
 * the final texel. Non-power-of-two HD skins reach odd sizes at multiple levels.
 */
#ifndef QUAKE_TEXTURE_MIP_H
#define QUAKE_TEXTURE_MIP_H
static unsigned *TexMip_OddAxis(unsigned *data, int width, int height, int depth, int vertical)
{
    unsigned char *pixels = (unsigned char *)data;
    const int source = vertical ? height : width;
    const int dest = source / 2;
    const int outwidth = vertical ? width : dest;
    const int outheight = vertical ? dest : height;
    int z, y, x, channel, k;
    if (!data || dest < 1) return data;
    for (z = 0; z < depth; ++z)
        for (y = 0; y < outheight; ++y)
            for (x = 0; x < outwidth; ++x)
            {
                /* Integer interval weights avoid rounding drift along the row. */
                const int start = (vertical ? y : x) * source;
                const int end = start + source;
                const int first = start / dest;
                const int last = (end - 1) / dest;
                for (channel = 0; channel < 4; ++channel)
                {
                    unsigned sum = 0;
                    for (k = first; k <= last; ++k)
                    {
                        const int lo = start > k * dest ? start : k * dest;
                        const int hi = end < (k + 1) * dest ? end : (k + 1) * dest;
                        const int sx = vertical ? x : k;
                        const int sy = vertical ? k : y;
                        sum += pixels[((z * height + sy) * width + sx) * 4 + channel] * (hi - lo);
                    }
                    pixels[((z * outheight + y) * outwidth + x) * 4 + channel] =
                        (unsigned char)((sum + source / 2) / source);
                }
            }
    return data;
}
#endif
