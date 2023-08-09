
package;

import flixel.system.FlxAssets.FlxShader;

// based on https://ptb.discord.com/channels/922849922175340586/1107166958425739295 :3
class OverlayBlendShader extends FlxShader {
    @:glFragmentSource('
        #pragma header

        // https://www.shadertoy.com/view/Md3GzX
        uniform vec4 overlayColor;

        void main() {
            vec4 src = flixel_texture2D(bitmap, openfl_TextureCoordv.xy);
            src.rgb = mix(2.0 * src.rgb * overlayColor, 1.0 - 2.0 * (1.0 - src.rgb) * (1.0-overlayColor), step(0.5, overlayColor));
            gl_FragColor = src; 
        }
    ')
}