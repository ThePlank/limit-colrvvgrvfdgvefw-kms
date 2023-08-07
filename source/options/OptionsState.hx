package options;

#if discord_rpc
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;
import flixel.addons.display.FlxBackdrop;

#if !flash 
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

using StringTools;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = ['Controls', 'Adjust Delay and Combo', 'Graphics', 'Visuals and UI', 'Gameplay'];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	private var camOther:FlxCamera;
	private var camGame:FlxCamera;

	var barrelDistortion = new BarrelDistortionShader();
	public static var canClick:Bool = true;
	function openSelectedSubstate(label:String) {
		switch(label) {
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals and UI':
				openSubState(new options.VisualsUISubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				LoadingState.loadAndSwitchState(new options.NoteOffsetState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create() {
		#if discord_rpc
		DiscordClient.changePresence("Options Menu", null);
		#end

		camGame = new FlxCamera();
		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camOther, false);

		persistentUpdate = true;
		var bg:FlxBackdrop = new FlxBackdrop(Paths.image('whitecubes'), XY);
		bg.scale.set(1.4, 1.4);
		bg.velocity.set(30, 30);
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		if(ClientPrefs.shaders){
			barrelDistortion.barrelDistortion1 = -0.15;
			barrelDistortion.barrelDistortion2 = -0.15;
			camGame.setFilters([new ShaderFilter(barrelDistortion)]);
		}

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		selectorLeft.cameras = [camOther];
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		selectorRight.cameras = [camOther];
		add(selectorRight);

		changeSelection();
		ClientPrefs.saveSettings();

		var eventThing:FlxSprite = new FlxSprite(0, 610).loadGraphic(Paths.image('eventThing'));
		eventThing.updateHitbox();
		eventThing.color = 0xFF000000;
		eventThing.cameras = [camOther];
		eventThing.antialiasing = ClientPrefs.globalAntialiasing;
		add(eventThing);

		var eventThing2:FlxSprite = new FlxSprite().loadGraphic(Paths.image('eventThing'));
		eventThing2.updateHitbox();
		eventThing2.flipY = true;
		eventThing2.color = 0xFF000000;
		eventThing2.cameras = [camOther];
		eventThing2.antialiasing = ClientPrefs.globalAntialiasing;
		add(eventThing2);

		super.create();
	}

	override function closeSubState() {
		super.closeSubState();
		ClientPrefs.saveSettings();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, 0.95);

	if(canClick)
	{
		if (controls.UI_UP_P) {
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P) {
			changeSelection(1);
		}

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}


		if (controls.ACCEPT) {
			canClick = false;
			openSelectedSubstate(options[curSelected]);
			for (item in grpOptions.members) {
				item.visible = false;
				selectorLeft.visible = false;
				selectorRight.visible = false;
			}
		} else {
			canClick = true;
			for (item in grpOptions.members) {
				item.visible = true;
				selectorLeft.visible = true;
				selectorRight.visible = true;

		    	item.alpha = 0.6;
		    	if (item.targetY == 0) {
		    		item.alpha = 1;
			    }
		    }
		}
	}
	}
	
	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			if (item.targetY == 0) {
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}