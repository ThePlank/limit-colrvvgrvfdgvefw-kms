package;

import flixel.system.FlxAssets.FlxShader;

class InvertShader extends FlxShader {
	@:glFragmentSource('
		#pragma header
		void main() {
		    vec4 tex = flixel_texture2D(bitmap, openfl_TextureCoordv.xy);
		    tex.rgb = tex.a * (1.0 - tex.rgb);
		    gl_FragColor = tex;
		}
	')

	public function new() { super(); }
}