package;

#if discord_rpc
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import flixel.addons.display.FlxBackdrop;
import sys.io.Process;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxTimer;
import openfl.events.MouseEvent;
import Section.SwagSection;
import Song.SwagSong;
import flixel.FlxBasic;
import flixel.FlxState;
import haxe.Json;

//3d shit
import openfl.geom.Vector3D;
import flx3d.Flx3DView;
import flx3d.Flx3DUtil;
import flx3d.Flx3DCamera;
import flx3d.FlxView3D;
import away3d.entities.Mesh;
import openfl.system.System;
import away3d.events.Asset3DEvent;
import away3d.library.assets.Asset3DType;
import away3d.lights.DirectionalLight;
import away3d.loaders.Loader3D;
import away3d.loaders.misc.AssetLoaderContext;
import away3d.loaders.parsers.OBJParser;
import away3d.materials.TextureMaterial;
import away3d.materials.lightpickers.StaticLightPicker;
import away3d.utils.Cast;
import openfl.utils.Assets;

#if !flash 
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.6.3 (i did not have enough time to port to 0.7.1h :sob:)'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camOther:FlxCamera;
	private var camGame:FlxCamera;
	
	var optionShit:Array<{x:Int, y:Int, scale:Float, ?die:Array<Int>, name:String}> = [
		{x: 0,  y: -50, scale: 1,    die: [0, 0],     name:    'play'},
		{x: 0,  y: -20, scale: 0.75, die: [-40, -30], name: 'credits'},
		{x: 0,  y: -20, scale: 1,    die: [-10, -27], name: 'options'},
	];

	var magenta:FlxSprite;
	var debugKeys:Array<FlxKey>;
	var barrelDistortion = new BarrelDistortionShader();

	public var cam3D:Flx3DView;
	public var ground:Mesh;
	public var popups:Array<Mesh> = [];

	override function create()
	{
		if (ClientPrefs.completedSublime) {
			optionShit.insert(3, {x: 500, y: -500, scale: 1, name:'98'}); 
		}

		#if discord_rpc
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		camGame = new FlxCamera();
		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camOther, false);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1); //do we even use this?

		var bg:FlxBackdrop = new FlxBackdrop(Paths.image('dots'), XY);
		bg.scale.set(1.4, 1.4);
		bg.velocity.set(40, 40);
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		if(ClientPrefs.shaders) {
			barrelDistortion.barrelDistortion1 = -0.15;
			barrelDistortion.barrelDistortion2 = -0.15;
			camGame.setFilters([new ShaderFilter(barrelDistortion)]);
		}

		cam3D = new Flx3DView(0, 0, 1280, 720); //make sure to keep width and height as 1600 and 900
		// cam3D.view.camera = new FunnyCamera();
		cam3D.scrollFactor.set();
		cam3D.screenCenter();
		cam3D.antialiasing = false;
		add(cam3D);
		cam3D.view.camera.rotationY = 5;

		cam3D.addModel(Paths.obj("ground"), function(event) { if (Std.string(event.asset.assetType) != "mesh") return;
			ground = cast(event.asset, Mesh);
			ground.scale(115);
			ground.x = 50;
			ground.y = -410;
			ground.z = -750;
			ground.rotationY = 90;
			System.gc();
			cam3D.view.scene.addChild(ground); }, "assets/models/nicecock.png", true);


		cam3D.addModel(Paths.obj("popup"), function(event) { 
			if (Std.string(event.asset.assetType) != "mesh") return;
			var basePopup:Mesh = cast(event.asset, Mesh);
			basePopup.scale(110);
			basePopup.y = 10;

			for (i in 0...3) {
				var popup = basePopup.clone();
				popup.rotationY = 90;
				popups.push(popup);
				cam3D.view.scene.addChild(popup);
			}
			System.gc(); }, "assets/models/terrible.png", true);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;

		for (i in 0...optionShit.length) {
			var option = optionShit[i];
			var menuItem:FlxSprite = new FlxSprite(option.x, option.y);
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + option.name);
			menuItem.animation.addByPrefix('idle', option.name + " basic", 24);
			menuItem.animation.addByPrefix('selected', option.name + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.cameras = [camOther];
			menuItem.antialiasing = false;
			menuItem.scale.set(option.scale, option.scale);
			menuItem.updateHitbox();
			menuItems.add(menuItem);
		}

		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.BLACK, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.WHITE);
		versionShit.cameras = [camOther];
		add(versionShit);

		changeItem();

		super.create();
		FlxG.fixedTimestep = false; // fix lagging with 3d main menu
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float) {
		if (FlxG.sound.music.volume < 0.8) {
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			if(FreeplayState.vocals != null) FreeplayState.vocals.volume += 0.5 * elapsed;
		}
		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);

		for (popup in popups) {
			popup.x = FlxMath.lerp(popup.x, (popups.indexOf(popup) - curSelected) * 190, lerpVal);
			popup.z = FlxMath.lerp(popup.z, ((popups.indexOf(popup) - curSelected) * 110) + -780, lerpVal);

			var anal:Vector3D = cam3D.view.camera.project(popup.scenePosition);
			var item:FlxSprite = menuItems.members[popups.indexOf(popup)];
			var bitem = optionShit[popups.indexOf(popup)];

			item.setPosition((anal.x * FlxG.width / 1.9) + FlxG.width / 2, (anal.y * FlxG.height) + FlxG.height / 2);
			item.offset.set(item.frameWidth / 2, (item.frameHeight / 2) + bitem.y);
			if (item.animation.curAnim.name == 'selected') item.offset.add(bitem.die[0], bitem.die[1]);

			var scale:Float = FlxMath.remapToRange(popup.scenePosition.z, -780, -560, 0.65, 0.4);
			scale *= bitem.scale;
			item.scale.set(scale, scale); //make 98 unselectable with keyboard pls
		}


		if (!selectedSomethin) {
			if (controls.UI_LEFT_P) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_RIGHT_P) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (FlxG.keys.pressed.SPACE) {
				ClientPrefs.completedSublime = false;
			}

			if (FlxG.keys.pressed.SHIFT) {
				ClientPrefs.completedSublime = true; //hee hee
			}

			if (controls.BACK) {
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT) {
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));

				menuItems.forEach(function(spr:FlxSprite) {
					if (curSelected != spr.ID) {
						FlxTween.tween(spr, {alpha: 0}, 0.4, {
							ease: FlxEase.quadOut,
							onComplete: function(twn:FlxTween)
							{
								spr.kill();
							}
						});
					} else {
						new FlxTimer().start(1, function(tmr:FlxTimer) {
							var daChoice:String = optionShit[curSelected].name;
							switch (daChoice) {
								case 'play':
									MusicBeatState.switchState(new DemoLoadState());
								case 'credits':
									MusicBeatState.switchState(new CreditsState());
								case 'options':
									LoadingState.loadAndSwitchState(new options.OptionsState());
								case '98':
									PlayState.SONG = Song.loadFromJson('sublime', 'sublime');
									LoadingState.loadAndSwitchState(new PlayState());
							}
							new FlxTimer().start(1, function(tmr:FlxTimer) {
								FlxG.fixedTimestep = true;
							});
						});
					}
				});	
			}
			// #if desktop
			// else if (FlxG.keys.anyJustPressed(debugKeys)) {
			// 	selectedSomethin = true;
			// 	MusicBeatState.switchState(new MasterEditorMenu());
			// }
			// #end
		}

		super.update(elapsed);
	}

	function changeItem(huh:Int = 0) {
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite) {
			spr.animation.play('idle');
			spr.updateHitbox();

			if (spr.ID == curSelected) {
				spr.animation.play('selected');
				var add:Float = 0;
				if(menuItems.length > 4) {
					add = menuItems.length * 8;
				}
				spr.centerOffsets();
			}
		});
	}
}

/*
class FunnyCamera extends away3d.cameras.Camera3D {
    var oldX:Float = 0;
    var oldY:Float = 0;
    var sensitivity:Float = 0.51;
    public function new() {
        super();
        FlxG.stage.addEventListener(MouseEvent.MOUSE_MOVE, (ae:MouseEvent) -> {
            var x:Float = ae.stageY * sensitivity;
            var y:Float = FlxMath.wrap(Std.int(ae.stageX * sensitivity), -180, 180);
            var deltaX:Float = oldX - x;
            var deltaY:Float = oldY - y;
            rotationX -= deltaX;
            rotationY -= deltaY;
            oldX = x;
            oldY = y;
        });
        FlxG.stage.addEventListener(openfl.events.Event.ENTER_FRAME, (ev:openfl.events.Event) -> {
            if (FlxG.keys.pressed.A)
                translateLocal(Vector3D.X_AXIS, -5);
            if (FlxG.keys.pressed.D)
                translateLocal(Vector3D.X_AXIS, 5);
            if (FlxG.keys.pressed.W)
                translateLocal(Vector3D.Z_AXIS, 5);
            if (FlxG.keys.pressed.S)
                translateLocal(Vector3D.Z_AXIS, -5);
            if (FlxG.keys.pressed.E)
                translateLocal(Vector3D.Y_AXIS, 5);
            if (FlxG.keys.pressed.Q)
                translateLocal(Vector3D.Y_AXIS, -5);
        });
    }
}
*/