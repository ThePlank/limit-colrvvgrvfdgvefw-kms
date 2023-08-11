
package;

import flixel.system.FlxAssets.FlxShader;

// based on https://ptb.discord.com/channels/922849922175340586/1107166958425739295 :3
class OverlayBlendShader extends FlxShader {
    @:glFragmentSource('
        // https://www.shadertoy.com/view/Md3GzX
        
        #pragma header

        uniform vec3 overlayColor;

        void main() {
            vec4 src = flixel_texture2D(bitmap, openfl_TextureCoordv.xy);
            src.rgb = mix(2.0 * overlayColor * src.rgb, 1.0 - 2.0 * (1.0 - overlayColor) * (1.0-src.rgb), step(0.5, src.rgb));
            gl_FragColor = src;
        }
    ')

    public function new() {
        super();
    }
}