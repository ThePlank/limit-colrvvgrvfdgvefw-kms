package;

import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.FlxCamera;

class CustomFadeTransition extends MusicBeatSubstate {
	public static var finishCallback:Void->Void;
	private var leTween:FlxTween = null;
	public static var nextCamera:FlxCamera;
	var isTransIn:Bool = false;
	var cisBlack:FlxSprite;
	var transGradient:FlxSprite;

	public function new(duration:Float, isTransIn:Bool) {
		super();

		this.isTransIn = isTransIn;
		var zoom:Float = CoolUtil.boundTo(FlxG.camera.zoom, 0.05, 1);
		var width:Int = Std.int(FlxG.width / zoom);
		var height:Int = Std.int(FlxG.height / zoom);
		transGradient = new FlxSprite(0, 0, Paths.image('enbyition'));
		transGradient.setGraphicSize(0, height);
		transGradient.updateHitbox();
		transGradient.scrollFactor.set();
		transGradient.color = 0xFF000000;
		add(transGradient);

		cisBlack = new FlxSprite().makeGraphic(width + 400, height, FlxColor.BLACK);
		cisBlack.scrollFactor.set();
		add(cisBlack);

		transGradient.x = width;

		if(isTransIn) {
			transGradient.flipY = true;
			FlxTween.tween(transGradient, {x: -width}, duration, {
				onComplete: function(twn:FlxTween) {
					close();
				},
			ease: FlxEase.expoOut});
		} else {
			transGradient.flipX = true;
			leTween = FlxTween.tween(transGradient, {x: -width}, duration, {
				onComplete: function(twn:FlxTween) {
					if(finishCallback != null) {
						finishCallback();
					}
				},
			ease: FlxEase.expoOut});
		}

		cisBlack.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		transGradient.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if(isTransIn)
			cisBlack.x = transGradient.x - transGradient.width;
		else
			cisBlack.x = transGradient.x + transGradient.width;
	}

	override function destroy() {
		if(leTween != null) {
			finishCallback();
			leTween.cancel();
		}
		super.destroy();
	}
}