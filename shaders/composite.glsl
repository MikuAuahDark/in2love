/*
    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
	Modified to be compatible with LOVE
    Authors: Luna Nielsen, Miku AuahDark
*/

// uniform sampler2D MainTex;
// varying LOVE_HIGHP_OR_MEDIUMP vec4 VaryingTexCoord;
// varying mediump vec4 VaryingColor;

#define albedo MainTex
uniform Image emissive;
uniform Image bumpmap;

#define opacity VaryingColor.a
#define multColor VaryingColor.rgb
uniform vec3 screenColor;

// Needs MRT with at least 3 canvases.
#define outAlbedo love_Canvases[0]
#define outEmissive love_Canvases[1]
#define outBump love_Canvases[2]

void effect()
{
	vec2 texUVs = VaryingTexCoord.st;

	// Sample texture
	vec4 texColor = Texel(albedo, texUVs);

	// Screen color math
	vec3 screenOut = vec3(1.0) - ((vec3(1.0) - (texColor.xyz)) * (vec3(1.0) - (screenColor * texColor.a)));

    // Multiply color math + opacity application.
    outAlbedo = vec4(screenOut.xyz, texColor.a) * vec4(multColor.xyz, 1) * opacity;

    // Emissive
    outEmissive = texture(emissive, texUVs) * outAlbedo.a;

    // Bumpmap
    outBump = texture(bumpmap, texUVs) * outAlbedo.a;
}
