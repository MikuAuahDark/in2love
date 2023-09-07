/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

	Modified to be compatible with LOVE
    Authors: Luna Nielsen, Miku AuahDark
*/

uniform number threshold;

vec4 effect(vec4 multColor, Image tex, vec2 texUVs, vec2 pc)
{
    vec4 color = Texel(tex, texUVs) * vec4(1.0, 1.0, 1.0, multColor.a);

    if (color.a <= threshold)
		discard;

    outColor = vec4(1.0, 1.0, 1.0);
}
