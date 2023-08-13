package;

#if sys
import sys.thread.Thread;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileCircle;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import haxe.Json;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import flixel.FlxCamera;
import options.GraphicsSettingsSubState;
//import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import openfl.display.BlendMode;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.Assets;
import flxgif.FlxGifSprite;
import flixel.addons.display.FlxBackdrop;
import openfl.utils.ByteArray;
import flixel.graphics.FlxGraphic;

#if !flash 
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

using StringTools;

typedef TitleData = {

	titlex:Float,
	titley:Float,
	startx:Float,
	starty:Float,
	backgroundSprite:String,
	bpm:Int
}
class TitleState extends MusicBeatState {
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var initialized:Bool = false;

	private var camOther:FlxCamera;
	private var camGame:FlxCamera;

	var blackScreen:FlxSprite;
	var blackScreenO:FlxGifSprite;
	var credGroup:FlxGroup;
	var credTextShit:Alphabet;
	var textGroup:FlxGroup;
	var ngSpr:FlxGifSprite;

	var libingLovesMen:FlxGifSprite;

	var curWacky:Array<String> = [];
	var loadingGifs:Array<openfl.utils.Future<ByteArray>> = [];
	var canStartIntro:Bool = false;

	var wackyImage:FlxSprite;
	var barrelDistortion = new BarrelDistortionShader();
	var mustUpdate:Bool = false;

	public static var diamond:FlxGraphic;

	var titleJSON:TitleData;

	public static var updateVersion:String = '';

	override public function create():Void {
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		#if LUA_ALLOWED
		Paths.pushGlobalMods();
		#end
		// Just to load a mod on start up if ya got one. For mods that change the menu music and bg
		WeekData.loadTheFirstEnabledMod();

		//trace(path, FileSystem.exists(path));

		/*#if (polymod && !html5)
		if (sys.FileSystem.exists('mods/')) {
			var folders:Array<String> = [];
			for (file in sys.FileSystem.readDirectory('mods/')) {
				var path = haxe.io.Path.join(['mods/', file]);
				if (sys.FileSystem.isDirectory(path)) {
					folders.push(file);
				}
			}
			if(folders.length > 0) {
				polymod.Polymod.init({modRoot: "mods", dirs: folders});
			}
		}
		#end*/

		camGame = new FlxCamera();
		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camOther, false);

		if(ClientPrefs.shaders) {
			barrelDistortion.barrelDistortion1 = -0.15;
			barrelDistortion.barrelDistortion2 = -0.15;
			camGame.setFilters([new ShaderFilter(barrelDistortion)]);
		}

		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];

		PlayerSettings.init();

		curWacky = FlxG.random.getObject(getIntroTextShit());

		// DEBUG BULLSHIT

		swagShader = new ColorSwap();
		super.create();

		FlxG.save.bind('funkin', CoolUtil.getSavePath());

		ClientPrefs.loadPrefs();

		Highscore.load();

		// IGNORE THIS!!!
		titleJSON = Json.parse(Paths.getTextFromFile('images/gfDanceTitle.json'));

		if(!initialized) {
			if(FlxG.save.data != null && FlxG.save.data.fullscreen) {
				FlxG.fullscreen = FlxG.save.data.fullscreen;
				//trace('LOADED FULLSCREEN SETTING!!');
			}
			persistentUpdate = true;
			persistentDraw = true;
		}

		if (FlxG.save.data.weekCompleted != null) {
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		FlxG.mouse.visible = false;
		if(FlxG.save.data.flashing == null && !FlashingState.leftState) {
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		} else {
			if (initialized)
				startIntro();
			else {
				new FlxTimer().start(1, function(tmr:FlxTimer) {
					canStartIntro = true;
				});
			}
		}
	}

	var logoBl:FlxSprite;
	var titleText:FlxSprite;
	var him:FlxSprite;
	var zovtonMissing:Bool = false;
	var swagShader:ColorSwap = null;

	function startIntro() {
		if (!initialized) {
			diamond = FlxGraphic.fromClass(GraphicTransTileCircle);
			diamond.persist = true;
			diamond.destroyOnNoUse = false;

			if(FlxG.sound.music == null) {
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			}
		}

		zovtonMissing = !sys.FileSystem.exists('${Sys.getCwd()}assets/images/Zovtan.png');

		if (zovtonMissing)
			trace('imagine the game exploding');

		Conductor.changeBPM(titleJSON.bpm);
		persistentUpdate = true;

		var bg:FlxBackdrop = new FlxBackdrop(Paths.image('cubes'), XY);
		bg.scale.set(1.4, 1.4);
		bg.velocity.set(10, 10);
		bg.updateHitbox();
		bg.screenCenter();
		bg.useFramePixels = true;
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.cameras = [camGame];
		add(bg);
	
		logoBl = new FlxSprite(700, 75).loadGraphic(Paths.image('logoBump'));
		logoBl.scale.set(2, 2);
		logoBl.antialiasing = false;
		logoBl.updateHitbox();
		logoBl.cameras = [camOther];
		swagShader = new ColorSwap();
		add(logoBl);

		him = new FlxSprite(60,  200).loadGraphic(Paths.image('himTitle'));
		him.cameras = [camOther];
		add(him);

		titleText = new FlxSprite(1075, 500);
		titleText.frames = Paths.getSparrowAtlas('enter');	
		titleText.animation.addByPrefix('idle', "enter idle", 24);
		titleText.animation.addByPrefix('press', "enter press", 24);
		titleText.antialiasing = false;
		titleText.scale.set(2, 2);
		titleText.cameras = [camOther];
		titleText.animation.play('idle');
		titleText.updateHitbox();
		add(titleText);

		logoBl.shader = swagShader.shader;
		him.shader = swagShader.shader;
		titleText.shader = swagShader.shader;
		bg.shader = swagShader.shader;

		var eventThing:FlxBackdrop = new FlxBackdrop(Paths.image('eventThing'), X);
		eventThing.velocity.set(30, 0);
		eventThing.offset.set(0, 0);
		eventThing.flipY = true;
		eventThing.updateHitbox();
		eventThing.color = 0xFF000000;
		eventThing.antialiasing = ClientPrefs.globalAntialiasing;
		eventThing.cameras = [camGame];
		add(eventThing);

		var eventThing2:FlxBackdrop = new FlxBackdrop(Paths.image('eventThing'), X);
		eventThing2.velocity.set(-30, 0);
		eventThing2.y = 610;
		eventThing2.updateHitbox();
		eventThing2.color = 0xFF000000;
		eventThing2.antialiasing = ClientPrefs.globalAntialiasing;
		eventThing2.cameras = [camGame];
		add(eventThing2);

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		blackScreen.cameras = [camOther];
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.cameras = [camOther];
		credTextShit.screenCenter();

		credTextShit.visible = false;
		libingLovesMen = new FlxGifSprite(0, 0);
		loadingGifs.push(ByteArray.loadFromFile('assets/images/deltarune.gif').onComplete((arr:ByteArray) -> {
			libingLovesMen.loadGif(arr); // prevent the game from shidding itself while loading
			loadingGifs.shift();
		}));
		libingLovesMen.cameras = [camOther];
		libingLovesMen.scale.x = 4;
		libingLovesMen.scale.y = 2;
		libingLovesMen.updateHitbox();
		libingLovesMen.screenCenter();

		ngSpr = new FlxGifSprite(0, FlxG.height * 0.52);
		loadingGifs.push(ByteArray.loadFromFile('assets/images/newgrounds.gif').onComplete((arr:ByteArray) -> {
			ngSpr.loadGif(arr); // prevent the game from shidding itself while loading
			loadingGifs.shift();
		}));
		ngSpr.visible = false;
		ngSpr.y += 750;
		ngSpr.cameras = [camOther];
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = ClientPrefs.globalAntialiasing;
		add(ngSpr);

		FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

		if (initialized)
			skipIntro();
		else
			initialized = true;

		blackScreenO = new FlxGifSprite(320, 180);
		loadingGifs.push(ByteArray.loadFromFile('assets/images/titleshit.gif').onComplete((arr:ByteArray) -> {
			blackScreenO.loadGif(arr); // prevent the game from shidding itself while loading
			loadingGifs.shift();
		}));
		blackScreenO.cameras = [camOther];
		blackScreenO.blend = ADD;
		blackScreenO.antialiasing = ClientPrefs.globalAntialiasing;
		blackScreenO.setGraphicSize(FlxG.width, FlxG.height);
		blackScreenO.visible = (ClientPrefs.flashing && !skippedIntro);
		add(blackScreenO);
	}

	function getIntroTextShit():Array<Array<String>> {
		var fullText:String = Assets.getText(Paths.txt('introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray) {
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;
	private static var playJingle:Bool = false;

	override function update(elapsed:Float) {
		if (canStartIntro && loadingGifs.length >= 0 && !initialized)
				startIntro();

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		// FlxG.watch.addQuick('amp', FlxG.sound.music.amplitude);

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null) {
			if (gamepad.justPressed.START)
				pressedEnter = true;

			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}

		if (initialized && !transitioning && skippedIntro) {
			if(pressedEnter) {
				if (zovtonMissing) {
					add(libingLovesMen);
					libingLovesMen.player.reset(true);
					FlxG.sound.play(Paths.sound('snd_badexplosion'), 1);
					new FlxTimer().start(0.5, function(tmr:FlxTimer) {
						Sys.exit(0);
					});
				} else {
					titleText.animation.play('press');

					new FlxTimer().start(0.2, function(tmr:FlxTimer) {  
						titleText.animation.play('idle');
					});

					FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

					transitioning = true;
					// FlxG.sound.music.stop();

					new FlxTimer().start(1, function(tmr:FlxTimer) {  
						MusicBeatState.switchState(new MainMenuState());
						closedState = true;
					});
				}
			}
		}

		if (initialized && pressedEnter && !skippedIntro) {
			skipIntro();
		}

		if(swagShader != null) {
			if(controls.UI_LEFT) swagShader.hue -= elapsed * 0.1;
			if(controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
		}

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0) {
		for (i in 0...textArray.length) {
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true);
			money.screenCenter(X);
			money.cameras = [camOther];
			money.y += (i * 60) + 200 + offset;
			if(credGroup != null && textGroup != null) {
				credGroup.add(money);
				textGroup.add(money);
			}
			money.y -= 350;
			FlxTween.tween(money, {y: money.y + 350}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.0});
		}
	}

	function createUncoolText(textArray:Array<String>, ?offset:Float = 0) {
		for (i in 0...textArray.length) {
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true);
			money.screenCenter(XY);
			money.cameras = [camOther];
			if(credGroup != null && textGroup != null) {
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0) {
		if(textGroup != null && credGroup != null) {
			var coolText:Alphabet = new Alphabet(0, 0, text, true);
			coolText.screenCenter(X);
			coolText.cameras = [camOther];
			coolText.y += (textGroup.length * 60) + 200 + offset;
			credGroup.add(coolText);
			textGroup.add(coolText);
			coolText.y += 750;
		    FlxTween.tween(coolText, {y: coolText.y - 750}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.0});
		}
	}

	function deleteCoolText() {
		while (textGroup.members.length > 0) {
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	private var sickBeats:Int = 0; //Basically curBeat but won't be skipped if you hold the tab or resize the screen
	public static var closedState:Bool = false;
	override function beatHit() {
		super.beatHit();

		FlxTween.cancelTweensOf(logoBl);
		logoBl.scale.set(2.2, 2.2);
		FlxTween.tween(logoBl.scale, {x: 2, y: 2}, (Conductor.crochet / 1000) * 0.75, {ease: FlxEase.expoOut}); // fyu the duration of this tween is 2 steps :3
		
		if(!closedState) {
			sickBeats++;
			switch (sickBeats) {
				case 1:
					//FlxG.sound.music.stop();
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
					FlxG.sound.music.fadeIn(4, 0, 0.7);
				case 2:
					createCoolText(['Libing', 'Plank', 'Nick', 'Flying Felt Boot', 'Walker']);
				// credTextShit.visible = true;
				case 4:
					addMoreText('Present');
				// credTextShit.text += '\npresent...';
				// credTextShit.addText();
				case 5:
					deleteCoolText();
				// credTextShit.visible = false;
				// credTextShit.text = 'In association \nwith';
				// credTextShit.screenCenter();
				case 6:
					createCoolText(['Not associated', 'with'], -40);
				case 8:
					addMoreText('newgrounds', -40);
					ngSpr.visible = true;
					FlxTween.tween(ngSpr, {y: ngSpr.y - 750}, 0.5, {ease: FlxEase.expoOut, startDelay: 0.0});
				// credTextShit.text += '\nNewgrounds';
				case 9:
					deleteCoolText();
					ngSpr.visible = false;
				// credTextShit.visible = false;

				// credTextShit.text = 'Shoutouts Tom Fulp';
				// credTextShit.screenCenter();
				case 10:
					createCoolText([curWacky[0]]);
				// credTextShit.visible = true;
				case 12:
					addMoreText(curWacky[1]);
				// credTextShit.text += '\nlmao';
				case 13:
					deleteCoolText();
				// credTextShit.visible = false;
				// credTextShit.text = "Friday";
				// credTextShit.screenCenter();
				case 14:
					createUncoolText(['choice']);
				// credTextShit.visible = true;
				case 15:
					deleteCoolText();
					createUncoolText(['.']);
				// credTextShit.text += '\nNight';
				case 16:
					deleteCoolText();
					createUncoolText(['fla']);

				case 17:
					skipIntro();
			}
		}
	}

	var skippedIntro:Bool = false;
	var increaseVolume:Bool = false;
	function skipIntro():Void {
		if (!skippedIntro) { {
				remove(ngSpr);
				remove(credGroup);
				if(ClientPrefs.flashing)
				    remove(blackScreenO);
				camOther.flash(FlxColor.WHITE, 4);
			}
			skippedIntro = true;
		}
	}
}