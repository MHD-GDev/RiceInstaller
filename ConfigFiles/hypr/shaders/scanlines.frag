#version 300 es
// SPDX-License-Identifier: GPL-3.0+
// PCSX2 "Scanline Filter" TV shader, ported 1:1 to Hyprland.
//
// Upstream: PCSX2 bin/resources/shaders/*/present.glsl -> ps_filter_scanlines
//   https://github.com/PCSX2/pcsx2/blob/master/bin/resources/shaders/vulkan/present.glsl
//
// Upstream logic: even pixel rows render at full brightness, odd rows are
// clamped to 50% (the `mask[i] + 0.5` trick). Hyprland adaptations are only:
// samp0/sample_c -> tex, o_col0 -> fragColor, and `2` -> `2u` for strict
// GLSL ES 3.00 integer typing.

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

vec4 ps_scanlines(uint i)
{
    vec4 mask[2] = vec4[2](
        vec4(1, 1, 1, 0),
        vec4(0, 0, 0, 0));

    return texture(tex, v_texcoord) * clamp((mask[i] + 0.5), 0.0, 1.0);
}

void main()
{
    uvec4 p = uvec4(gl_FragCoord);

    fragColor = ps_scanlines(p.y % 2u);
}
