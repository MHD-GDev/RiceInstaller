#version 300 es
// SPDX-License-Identifier: GPL-3.0+
// PCSX2 "Lottes CRT" TV shader, ported 1:1 to Hyprland.
//
// Upstream: PCSX2 bin/resources/shaders/*/present.glsl -> ps_filter_lottes
//   https://github.com/PCSX2/pcsx2/blob/master/bin/resources/shaders/vulkan/present.glsl
//
// PCSX2's variant of Timothy Lottes' public-domain CRT shader differs from
// the RetroArch/libretro one: scanline geometry is hardcoded to 640x480
// (see Dist below), there is no brightness boost, and curvature warping
// defaults to 0. All knobs below are PCSX2's defaults.
//
// Hyprland adaptations (visual output unchanged):
//   - samp0/sample_c -> tex, o_col0 -> fragColor
//   - u_target_size (output resolution) -> const vec2, set it to your
//     monitor resolution
//   - fragcoord/u_target_size -> v_texcoord (identical on a fullscreen pass)
//   - alpha forced to 1.0 (upstream leaves it undefined)

precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

#define MaskingType 4                      //[1|2|3|4] The type of CRT shadow masking used. 1: compressed TV style, 2: Aperture-grille, 3: Stretched VGA style, 4: VGA style.
#define ScanBrightness -8.00               //[-16.0 to 1.0] The overall brightness of the scanline effect. Lower for darker, higher for brighter.
#define FilterCRTAmount -3.00              //[-4.0 to 1.0] The amount of filtering used, to replicate the TV CRT look. Lower for less, higher for more.
#define HorizontalWarp 0.00                //[0.0 to 0.1] The distortion warping effect for the horizontal (x) axis of the screen. Use small increments.
#define VerticalWarp 0.00                  //[0.0 to 0.1] The distortion warping effect for the verticle (y) axis of the screen. Use small increments.
#define MaskAmountDark 0.50                //[0.0 to 1.0] The value of the dark masking line effect used. Lower for darker lower end masking, higher for brighter.
#define MaskAmountLight 1.50               //[0.0 to 2.0] The value of the light masking line effect used. Lower for darker higher end masking, higher for brighter.
#define BloomPixel -1.50                   //[-2.0 -0.5] Pixel bloom radius. Higher for increased softness of bloom.
#define BloomScanLine -2.0                 //[-4.0 -1.0] Scanline bloom radius. Higher for increased softness of bloom.
#define BloomAmount 0.15                   //[0.0 1.0] Bloom intensity. Higher for brighter.
#define Shape 2.0                          //[0.0 10.0] Kernal filter shape. Lower values will darken image and introduce moire patterns if used with curvature.
#define UseShadowMask 1                    //[0 or 1] Enables, or disables the use of the CRT shadow mask. 0 is disabled, 1 is enabled.

// PCSX2's u_target_size: the output (window) resolution in pixels.
const vec2 u_target_size = vec2(2722.5, 2722.5);

float ToLinear1(float c)
{
    return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4);
}

vec3 ToLinear(vec3 c)
{
    return vec3(ToLinear1(c.r), ToLinear1(c.g), ToLinear1(c.b));
}

float ToSrgb1(float c)
{
    return c < 0.0031308 ? c * 12.92 : 1.055 * pow(c, 0.41666) - 0.055;
}

vec3 ToSrgb(vec3 c)
{
    return vec3(ToSrgb1(c.r), ToSrgb1(c.g), ToSrgb1(c.b));
}

vec3 Fetch(vec2 pos, vec2 off)
{
    pos = (floor(pos * u_target_size + off) + vec2(0.5, 0.5)) / u_target_size;
    if (max(abs(pos.x - 0.5), abs(pos.y - 0.5)) > 0.5)
    {
        return vec3(0.0, 0.0, 0.0);
    }
    else
    {
        return ToLinear(texture(tex, pos.xy).rgb);
    }
}

vec2 Dist(vec2 pos)
{
    // PCSX2 hardcodes the emulated PS2 resolution here.
    pos = pos * vec2(640, 480);

    return -((pos - floor(pos)) - vec2(0.5, 0.5));
}

float Gaus(float pos, float scale)
{
    return exp2(scale * pow(abs(pos), Shape));
}

vec3 Horz3(vec2 pos, float off)
{
    vec3 b = Fetch(pos, vec2(-1.0, off));
    vec3 c = Fetch(pos, vec2(0.0, off));
    vec3 d = Fetch(pos, vec2(1.0, off));
    float dst = Dist(pos).x;

    // Convert distance to weight.
    float scale = FilterCRTAmount;
    float wb = Gaus(dst - 1.0, scale);
    float wc = Gaus(dst + 0.0, scale);
    float wd = Gaus(dst + 1.0, scale);

    return (b * wb + c * wc + d * wd) / (wb + wc + wd);
}

vec3 Horz5(vec2 pos, float off)
{
    vec3 a = Fetch(pos, vec2(-2.0, off));
    vec3 b = Fetch(pos, vec2(-1.0, off));
    vec3 c = Fetch(pos, vec2(0.0, off));
    vec3 d = Fetch(pos, vec2(1.0, off));
    vec3 e = Fetch(pos, vec2(2.0, off));
    float dst = Dist(pos).x;

    // Convert distance to weight.
    float scale = FilterCRTAmount;

    float wa = Gaus(dst - 2.0, scale);
    float wb = Gaus(dst - 1.0, scale);
    float wc = Gaus(dst + 0.0, scale);
    float wd = Gaus(dst + 1.0, scale);
    float we = Gaus(dst + 2.0, scale);

    return (a * wa + b * wb + c * wc + d * wd + e * we) / (wa + wb + wc + wd + we);
}

vec3 Horz7(vec2 pos, float off)
{
    vec3 a = Fetch(pos, vec2(-3.0, off));
    vec3 b = Fetch(pos, vec2(-2.0, off));
    vec3 c = Fetch(pos, vec2(-1.0, off));
    vec3 d = Fetch(pos, vec2( 0.0, off));
    vec3 e = Fetch(pos, vec2( 1.0, off));
    vec3 f = Fetch(pos, vec2( 2.0, off));
    vec3 g = Fetch(pos, vec2( 3.0, off));

    float dst = Dist(pos).x;
    // Convert distance to weight.
    float scale = BloomPixel;
    float wa = Gaus(dst - 3.0, scale);
    float wb = Gaus(dst - 2.0, scale);
    float wc = Gaus(dst - 1.0, scale);
    float wd = Gaus(dst + 0.0, scale);
    float we = Gaus(dst + 1.0, scale);
    float wf = Gaus(dst + 2.0, scale);
    float wg = Gaus(dst + 3.0, scale);

    // Return filtered sample.
    return (a * wa + b * wb + c * wc + d * wd + e * we + f * wf + g * wg) / (wa + wb + wc + wd + we + wf + wg);
}

// Return scanline weight.
float Scan(vec2 pos, float off)
{
    float dst = Dist(pos).y;
    return Gaus(dst + off, ScanBrightness);
}

float BloomScan(vec2 pos, float off)
{
    float dst = Dist(pos).y;

    return Gaus(dst + off, BloomScanLine);
}

vec3 Tri(vec2 pos)
{
    vec3 a = Horz3(pos, -1.0);
    vec3 b = Horz5(pos, 0.0);
    vec3 c = Horz3(pos, 1.0);

    float wa = Scan(pos, -1.0);
    float wb = Scan(pos, 0.0);
    float wc = Scan(pos, 1.0);

    return (a * wa) + (b * wb) + (c * wc);
}

vec3 Bloom(vec2 pos)
{
    vec3 a = Horz5(pos, -2.0);
    vec3 b = Horz7(pos, -1.0);
    vec3 c = Horz7(pos, 0.0);
    vec3 d = Horz7(pos, 1.0);
    vec3 e = Horz5(pos, 2.0);

    float wa = BloomScan(pos, -2.0);
    float wb = BloomScan(pos, -1.0);
    float wc = BloomScan(pos, 0.0);
    float wd = BloomScan(pos, 1.0);
    float we = BloomScan(pos, 2.0);

    return a * wa + b * wb + c * wc + d * wd + e * we;
}

vec2 Warp(vec2 pos)
{
    pos = pos * 2.0 - 1.0;
    pos *= vec2(1.0 + (pos.y * pos.y) * HorizontalWarp, 1.0 + (pos.x * pos.x) * VerticalWarp);
    return pos * 0.5 + 0.5;
}

vec3 Mask(vec2 pos)
{
#if MaskingType == 1
    // Very compressed TV style shadow mask.
    float lines = MaskAmountLight;
    float odd = 0.0;

    if (fract(pos.x / 6.0) < 0.5)
    {
        odd = 1.0;
    }
    if (fract((pos.y + odd) / 2.0) < 0.5)
    {
        lines = MaskAmountDark;
    }
    pos.x = fract(pos.x / 3.0);
    vec3 mask = vec3(MaskAmountDark, MaskAmountDark, MaskAmountDark);

    if (pos.x < 0.333)
    {
        mask.r = MaskAmountLight;
    }
    else if (pos.x < 0.666)
    {
        mask.g = MaskAmountLight;
    }
    else
    {
        mask.b = MaskAmountLight;
    }

    mask *= lines;

    return mask;

#elif MaskingType == 2
    // Aperture-grille.
    pos.x = fract(pos.x / 3.0);
    vec3 mask = vec3(MaskAmountDark, MaskAmountDark, MaskAmountDark);

    if (pos.x < 0.333)
    {
        mask.r = MaskAmountLight;
    }
    else if (pos.x < 0.666)
    {
        mask.g = MaskAmountLight;
    }
    else
    {
        mask.b = MaskAmountLight;
    }

    return mask;

#elif MaskingType == 3
    // Stretched VGA style shadow mask (same as prior shaders).
    pos.x += pos.y * 3.0;
    vec3 mask = vec3(MaskAmountDark, MaskAmountDark, MaskAmountDark);
    pos.x = fract(pos.x / 6.0);

    if (pos.x < 0.333)
    {
        mask.r = MaskAmountLight;
    }
    else if (pos.x < 0.666)
    {
        mask.g = MaskAmountLight;
    }
    else
    {
        mask.b = MaskAmountLight;
    }

    return mask;

#else
    // VGA style shadow mask.
    pos.xy = floor(pos.xy * vec2(1.0, 0.5));
    pos.x += pos.y * 3.0;

    vec3 mask = vec3(MaskAmountDark, MaskAmountDark, MaskAmountDark);
    pos.x = fract(pos.x / 6.0);

    if (pos.x < 0.333)
    {
        mask.r = MaskAmountLight;
    }
    else if (pos.x < 0.666)
    {
        mask.g = MaskAmountLight;
    }
    else
    {
        mask.b = MaskAmountLight;
    }
    return mask;
#endif
}

vec4 LottesCRTPass()
{
    vec4 color = vec4(0.0, 0.0, 0.0, 1.0);

    vec2 pos = Warp(v_texcoord);
    color.rgb = Tri(pos);
    color.rgb += Bloom(pos) * BloomAmount;
#if UseShadowMask
    color.rgb *= Mask(gl_FragCoord.xy);
#endif
    color.rgb = ToSrgb(color.rgb);

    return color;
}

void main()
{
    fragColor = LottesCRTPass();
}
