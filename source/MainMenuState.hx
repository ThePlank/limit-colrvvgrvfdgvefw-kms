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
import Achievements;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxTimer;
import openfl.events.MouseEvent;
import openfl.geom.Vector3D;
//3d shit
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
	private var camAchievement:FlxCamera;
	
	var optionShit:Array<MainMenuButton> = [
		{x: 50,  y: 250, scale: 0.75,    name:    'play'},
		{x: 450,  y: 250, scale: 0.75,   name: 'credits'},
		{x: 1000,   y: 250, scale: 0.75, name: 'options'}
	];

	var magenta:FlxSprite;
	var debugKeys:Array<FlxKey>;
	var barrelDistortion = new BarrelDistortionShader();

	public var cam3D:Flx3DView;
	public var ground:Mesh;
	public var popups:Array<Mesh> = [];

	override function create()
	{
		#if MODS_ALLOWED
		Paths.pushGlobalMods();
		#end
		WeekData.loadTheFirstEnabledMod();

		#if discord_rpc
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;
		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement, false);
		FlxG.cameras.add(camOther, false);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);

		var bg:FlxBackdrop = new FlxBackdrop(Paths.image('dots'), XY);
		bg.scale.set(1.4, 1.4);
		bg.velocity.set(40, 40);
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		if(ClientPrefs.shaders){
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
			cam3D.view.scene.addChild(ground);
			// FlxTween.tween(ground, {rotationY: 360}, 1, {type: LOOPING});
			
		}, "assets/models/nicecock.png", false);


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

			System.gc();
		}, "assets/models/terrible.png", false);

		// magenta.scrollFactor.set();

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;

		for (i in 0...optionShit.length) {
			var option:MainMenuButton = optionShit[i];
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

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

		super.create();
		FlxG.fixedTimestep = false; // fix lagging with 3d main menu
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement() {
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float) {
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			if(FreeplayState.vocals != null) FreeplayState.vocals.volume += 0.5 * elapsed;
		}
		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);

		for (popup in popups) {
			popup.x = FlxMath.lerp(popup.x, (popups.indexOf(popup) - curSelected) * 150, lerpVal);
			popup.z = FlxMath.lerp(popup.z, ((popups.indexOf(popup) - curSelected) * 110) + -780, lerpVal);
		}


		if (!selectedSomethin)
		{
			if (controls.UI_LEFT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_RIGHT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));

				menuItems.forEach(function(spr:FlxSprite)
				{
					if (curSelected != spr.ID)
					{
						FlxTween.tween(spr, {alpha: 0}, 0.4, {
							ease: FlxEase.quadOut,
							onComplete: function(twn:FlxTween)
							{
								spr.kill();
							}
						});
					}
					else
					{
						FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
						{
							var daChoice:String = optionShit[curSelected].name;
							switch (daChoice)
							{
								case 'play':
									MusicBeatState.switchState(new DemoLoadState());
								case 'credits':
									MusicBeatState.switchState(new CreditsState());
								case 'options':
									LoadingState.loadAndSwitchState(new options.OptionsState());
							}
							FlxG.fixedTimestep = true; // fix lagging with 3d main menu
						});
					}
				});	
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.updateHitbox();

			if (spr.ID == curSelected)
			{
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

typedef MainMenuButton = {
	var x:Int;
	var y:Int;
	var scale:Float;
	var name:String;
}


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