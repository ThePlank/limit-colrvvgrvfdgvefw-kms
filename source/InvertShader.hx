package;

import flixel.system.FlxAssets.FlxShader;

class InvertShader extends FlxShader {
	@:glFragmentSource('
		#pragma header
		void main() {
		    vec4 tex = flixel_texture2D(bitmap, openfl_TextureCoordv.xy);
		    gl_FragColor = vec4((1.0 - tex.r) * tex.a, (1.0 - tex.g) * tex.a, (1.0 - tex.b) * tex.a, tex.a);
		}
	')

	public function new() { super(); }
}