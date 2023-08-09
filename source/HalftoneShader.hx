package;

import flixel.system.FlxAssets.FlxShader;

// based on https://www.shadertoy.com/view/4sBBDK :3
class HalftoneShader extends FlxShader {
	@:glFragmentSource('
		#pragma header
		#define rotate2d(a) mat2(cos(angle), -sin(angle), sin(angle),cos(angle))

		uniform float angle;
		uniform float scale;

		float dotScreen(vec2 uv, float angle, float scale) {
			float s = sin( angle ), c = cos( angle );
			vec2 p = (uv - vec2(0.5)) * openfl_TextureSize.xy;
			vec2 q = rotate2d(angle) * p * scale;
			return ( sin( q.x ) * sin( q.y ) ) * 4.0;
		}

		void main() {
			vec2 uv = openfl_TextureCoordv.xy;
			vec4 col = flixel_texture2D(bitmap, uv);
			col.rgb = vec3(col.rgb * 10.0 - 5.0 + dotScreen(uv, angle, scale));
			gl_FragColor = col;
		}
	')
}