package;

import flixel.system.FlxAssets.FlxShader;

// https://ptb.discord.com/channels/922849922175340586/922851578996744252/1022375142896185354 :3
class BloomShader extends FlxShader {
    @:glFragmentSource('
	#pragma header

	uniform float uSize;
	uniform float uAlpha;

	void main(void) {
	    vec2 uv = openfl_TextureCoordv.xy;
	    vec4 blur = vec4(0.0, 0.0, 0.0, 0.0);
	    float a_size = uSize * 0.05 * openfl_TextureCoordv.y;
	    for (float i = -a_size; i < a_size; i += 0.001) {blur.rgb += flixel_texture2D(bitmap, uv + vec2(0.0, i)).rgb / (1600.0 * a_size);}
	    vec4 color = flixel_texture2D(bitmap, uv);
	    gl_FragColor = color + uAlpha * (color * (color + blur * 1.5 - 1.0));
	}
	')

    public function new() {
        super();
		uSize.value = [0];
		uAlpha.value = [1];
    }

    @:isVar
    public var size(get,set):Float;

    function get_size()
		return uSize.value[0];

	function set_size(val:Float)
		return uSize.value[0] = val;

	@:isVar
    public var shaderAlpha(get,set):Float; // alpha is already a property of FlxGraphicsShader :spcunchbronk:

    function get_shaderAlpha()
		return uAlpha.value[0];

	function set_shaderAlpha(val:Float)
		return uAlpha.value[0] = val;
}