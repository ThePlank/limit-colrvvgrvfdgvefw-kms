import flixel.system.FlxAssets;
import flixel.util.FlxColor;
class CameraShadowFilter extends FlxShader {

	@:glFragmentSource('
		#pragma header

		uniform float uOffsetX;
		uniform float uOffsetY;
		uniform vec4 uShadow;

		void main() {
			float x = 1.0 / openfl_TextureSize.x;
			float y = 1.0 / openfl_TextureSize.y;

			vec4 col = texture2D(bitmap, openfl_TextureCoordv.st);
			vec4 smp = texture2D(bitmap, openfl_TextureCoordv.st + vec2(x * -uOffsetX, y * -uOffsetY));

			if (smp.a > 0.0) {
				gl_FragColor = mix(uShadow, col, col.a);
			}
			else {
				gl_FragColor = col;
			}
		}
	')

	public var offset_x(default, set):Float;
	public var offset_y(default, set):Float;
	public var shadow(default, set):FlxColor;

	function set_offset_x(v:Float) {
		uOffsetX.value = [v];
		return offset_x = v;
	}

	function set_offset_y(v:Float) {
		uOffsetY.value = [v];
		return offset_y = v;
	}

	function set_shadow(v:FlxColor) {
		uShadow.value = [v.redFloat, v.greenFloat, v.blueFloat, v.alphaFloat];
		return shadow = v;
	}

	public function new(offset_x:Float = 4, offset_y:Float = 4, shadow:FlxColor = FlxColor.BLACK) {
		super();
		this.offset_x = offset_x;
		this.offset_y = offset_y;
		this.shadow = shadow;
	}
}