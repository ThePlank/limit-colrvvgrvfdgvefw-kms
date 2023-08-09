
package;

import flixel.system.FlxAssets.FlxShader;

// based on https://ptb.discord.com/channels/922849922175340586/1107166958425739295 :3
class OverlayBlendShader extends FlxShader {
    @:glFragmentSource('
        #pragma header

        // https://www.shadertoy.com/view/Md3GzX
        uniform vec3 overlayColor;

        vec3 overlay(vec3 src, vec3 dst) {
            return mix(2.0 * src * dst, 1.0 - 2.0 * (1.0 - src) * (1.0-dst), step(0.5, dst));
        }

        void main() {
            vec4 src = flixel_texture2D(bitmap, openfl_TextureCoordv.xy);
            src.rgb = overlay(overlayColor, src.rgb);
            gl_FragColor = src;
        }
    ')

    public function new() {
        super();
    }
}