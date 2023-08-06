package openfl.display;

import flixel.util.FlxStringUtil;
import openfl.Lib;
import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import openfl.Memory;
import lime.system.System;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.display.Sprite;

class FPS extends Sprite {
	//The current frame rate, expressed using frames-per-second

	public var currentFPS(default, null):Int;

	private var currentMemory:Float;
	private var maxMemory:Float;

	private var outlineColor:FlxColor = 0xFFFFFFFF;

	public var baseText:TextField;
	public var outlineTexts:Array<TextField> = [];
	private var outlineWidth:Int = 2;
	private var outlineQuality:Int = 8;
	var defaultTextFormat:TextFormat;

	@:noCompletion private var cacheCount:Int = 0;
	@:noCompletion private var currentTime:Float = 0;
	@:noCompletion private var times:Array<Float> = [];

	public var text(default, set):String; 

	public function new(x:Float = 10, y:Float = 10) {
		super();

		this.x = x;
		this.y = y;

		this.defaultTextFormat = new TextFormat("VCR OSD Mono", 18, 0xFF000000);

		baseText = new TextField();
		baseText.defaultTextFormat = this.defaultTextFormat;
		baseText.selectable = false;
		baseText.mouseEnabled = false;
		baseText.width = FlxG.width;

		currentFPS = 0;
		currentMemory = 0;
		maxMemory = 0;


		for (i in 0...outlineQuality) {
			var otext:TextField = new TextField();
			otext.x = Math.sin(i) *outlineWidth;
			otext.y = Math.cos(i) *outlineWidth;
			otext.defaultTextFormat = this.defaultTextFormat;
			otext.textColor = outlineColor;
			otext.width = baseText.width;
			outlineTexts.push(otext);
			addChild(otext);
		}

		addChild(baseText);

		text = "FPS: ";

	}

	// Event Handlers
	private override function __enterFrame(deltaTime:Float):Void {
		currentTime += deltaTime;
		times.push(currentTime);

		while (times[0] < currentTime - 1000)
		{
			times.shift();
		}

		var currentCount = times.length;
		currentFPS = Math.round((currentCount + cacheCount) / 2);
		if (currentFPS > ClientPrefs.framerate) currentFPS = ClientPrefs.framerate;

		if (currentCount != cacheCount /*&& visible*/) {
			#if (gl_stats && !disable_cffi && (!html5 || !canvas))
			text += "\ntotalDC: " + Context3DStats.totalDrawCalls();
			text += "\nstageDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE);
			text += "\nstage3DDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE3D);
			#end

			var stats:{currentMemory:Float, totalAllocated:Float, allocationCount:Float} = hl.Gc.stats();
			currentMemory = stats.currentMemory;
			if (currentMemory > maxMemory)
				maxMemory = currentMemory;

			baseText.textColor = 0xFF000000;
			if (currentMemory > 3221225472 || currentFPS <= ClientPrefs.framerate / 2) // why 3221225472? idk.
				baseText.textColor = 0xFFFF0000;

			text = 'FPS: ${currentFPS}\nMEM: ${FlxStringUtil.formatBytes(currentMemory)} / ${FlxStringUtil.formatBytes(maxMemory)}';
		}
		cacheCount = currentCount;
	}

	private function set_text(value:String):String {
		baseText.text = value;
		for (text in outlineTexts) {
			text.text = value;
		}
		return value;
	}
}
