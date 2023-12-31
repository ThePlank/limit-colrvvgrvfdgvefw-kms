package;

#if discord_rpc
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import lime.utils.Assets;

#if !flash 
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

using StringTools;

class CreditsState extends MusicBeatState
{
	var curSelected:Int = -1;

	private var camOther:FlxCamera;
	private var camGame:FlxCamera;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<AttachedSprite> = [];
	private var creditsStuff:Array<Array<String>> = [];

	public static var discord:Bool = false;

	var descText:FlxText;
	var descBox:AttachedSprite;

	var offsetThing:Float = -75;
	var bgn:FlxBackdrop;
	var bgk:FlxBackdrop;
	var barrelDistortion = new BarrelDistortionShader();

	var iconShit:Array<(AttachedSprite, Float)->Void> = [
		(icon, totalDelta) -> { icon.offset.y = Math.abs(Math.sin(totalDelta * 4)) * 50; }, // libing
		(icon, totalDelta) -> { icon.angleAdd += FlxG.elapsed * 15; }, // plank
		(icon, totalDelta) -> {
				icon.offset.x = FlxG.random.int(-5, 5);
				icon.offset.y = FlxG.random.int(-3, 3);
				icon.angleAdd = FlxG.random.int(-2, 2);
		}, //nick
		(icon, totalDelta) -> {
			icon.offset.y = Math.abs(Math.sin(totalDelta * 4)) * 50;
			icon.offset.x = Math.cos(totalDelta * 4) * 25;
		} // ffb
	];

	override function create()
	{
		camGame = new FlxCamera();
		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camOther, false);

		#if discord_rpc
		DiscordClient.changePresence("In the Menus", null);
		#end

		FlxG.camera.zoom = 0.75;

		persistentUpdate = true;

		var bg:FlxBackdrop = new FlxBackdrop(Paths.image('whitecubes'), XY);
		bg.scale.set(1.4, 1.4);
		bg.scale.add(0.65, 0.65);
		bg.velocity.set(30, 30);
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = false;
		add(bg);

		bgn = new FlxBackdrop(Paths.image('nickcubes'), XY);
		bgn.scale.set(1.4, 1.4);
		bgn.scale.add(0.65, 0.65);
		bgn.velocity.set(30, 30);
		bgn.updateHitbox();
		bgn.screenCenter();
		bgn.alpha = 0;
		bgn.antialiasing = false;
		add(bgn);

		bgk = new FlxBackdrop(Paths.image('keoikicubes'), XY);
		bgk.scale.set(1.4, 1.4);
		bgk.scale.add(0.65, 0.65);
		bgk.velocity.set(30, 30);
		bgk.updateHitbox();
		bgk.screenCenter();
		bgk.alpha = 0;
		bgk.antialiasing = ClientPrefs.globalAntialiasing;
		add(bgk);
		
		if(ClientPrefs.shaders){
			barrelDistortion.barrelDistortion1 = -0.15;
			barrelDistortion.barrelDistortion2 = -0.15;
			camGame.setFilters([new ShaderFilter(barrelDistortion)]);
		}

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		var saygex:Array<Array<String>> = [ //Name - Icon name - Description - Link - Antialias - icon shit
			['Skech Team'],
			['libing',		        'theyarelimitedcolors','director, charter',            'https://www.youtube.com/channel/UCwH4gcjdN-gWPGunlBxAnQQ', 'true'],
			['plankdev',	    	'plank icon real',	   'main programmer and 3d modeler.\nmain programmer of hashlinked','https://twitter.com/_PlankDev', 'true'],
			['Nick',		        'nilk',		 		   'Programmer, Artist, slave',                'discord://-/users/749249635968745502', 'false'],
			['Flying Felt Boot',    'fefefbee',			   'Artist',								           'discord://-/users/590206534076727307', 'true'],
			['ItsWalker412',        'gwagwalker',		   'Composer',								               'https://twitter.com/ItsWalker412', 'true'],
			[''],
			['Psych Engine Team'],
			['Shadow Mario',		'shadowmario',		'Main Programmer of Psych Engine',				          'https://twitter.com/Shadow_Mario_', 'true'],
			['RiverOaken',			'river',			'Main Artist/Animator of Psych Engine',						 'https://twitter.com/RiverOaken', 'true'],
			['shubs',				'shubs',			'Additional Programmer of Psych Engine',					    'https://twitter.com/yoshubs', 'true'],
			[''],
			['Former Engine Members'],
			['bb-panzu',			'bb',				'Ex-Programmer of Psych Engine',								 'https://twitter.com/bbsub3', 'true'],
			[''],
			['Engine Contributors'],
			['iFlicky',				'flicky',			'Composer of Psync and Tea Time\nMade the Dialogue Sounds',    'https://twitter.com/flicky_i', 'true'],
			['SqirraRNG',			'sqirra',			'Crash Handler and Base code for\nChart Editor\'s Waveform',   'https://twitter.com/gedehari', 'true'],
			['EliteMasterEric',		'mastereric',		'Runtime Shaders support',							    'https://twitter.com/EliteMasterEric', 'true'],
			['PolybiusProxy',		'proxy',			'.MP4 Video Loader Library (hxCodec)',			          'https://twitter.com/polybiusproxy', 'true'],
			['KadeDev',				'kade',				'Fixed some cool stuff on Chart Editor\nand other PRs',		   'https://twitter.com/kade0912', 'true'],
			['Keoiki',				'keoiki',			'Note Splash Animations :keoiki:',								        'https://twitter.com/Keoiki_', 'true'],
			['Nebula the Zorua',	'nebula',			'LUA JIT Fork and some Lua reworks',					   'https://twitter.com/Nebula_Zorua', 'true'],
			['Smokey',				'smokey',			'Sprite Atlas Support',									      'https://twitter.com/Smokey_5_', 'true']
		];
		
		for(i in saygex)
			creditsStuff.push(i);
	
		for (i in 0...creditsStuff.length)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(FlxG.width / 2, 300, creditsStuff[i][0], !isSelectable);
			optionText.isMenuItem = true;
			optionText.targetY = i;
			optionText.changeX = false;
			optionText.cameras = [camGame];
			optionText.snapToPosition();
			grpOptions.add(optionText);

			if(isSelectable) {
				if(creditsStuff[i][5] != null)
				{
					Paths.currentModDirectory = creditsStuff[i][5];
				}

				var icon:AttachedSprite = new AttachedSprite('credits/' + creditsStuff[i][1]);
				icon.xAdd = optionText.width + 10;
				icon.sprTracker = optionText;
				icon.antialiasing = (creditsStuff[i][4] == 'true');
	
				// using a FlxGroup is too much fuss!
				iconArray.push(icon);
				add(icon);

				if(curSelected == -1) curSelected = i;
			}
			else optionText.alignment = CENTERED;
		}
		
		descBox = new AttachedSprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.xAdd = -10;
		descBox.yAdd = -10;
		descBox.cameras = [camOther];
		descBox.alphaMult = 0.6;
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, FlxG.height + 75 - 25, 1180, "", 32);
		descText.cameras = [camOther];
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER/*, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK*/);
		descText.scrollFactor.set();
		//descText.borderSize = 2.4;
		descBox.sprTracker = descText;
		add(descText);

		changeSelection();

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

	var quitting:Bool = false;
	var holdTime:Float = 0;
	var totalDelta:Float = 0;
	override function update(elapsed:Float)
	{
		totalDelta += elapsed;
		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		for (i in 0...iconArray.length)
			if (iconShit[i] != null) iconShit[i](iconArray[i], totalDelta);

		//pwease make dis code gud pwank :3
		// oki :3
		//dis whowe time it was that shwimpwe?? owo thankies tho <3
		bgn.alpha = FlxMath.lerp(bgn.alpha, ((curSelected == 3) ? 1 : 0), 0.01);
		bgk.alpha = FlxMath.lerp(bgk.alpha, ((curSelected == 21) ? 1 : 0), 0.01);

		if(!quitting)
		{
			if(creditsStuff.length > 1)
			{
				var shiftMult:Int = 1;
				if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

				var upP = controls.UI_UP_P;
				var downP = controls.UI_DOWN_P;

				if (upP)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (downP)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}

				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					}
				}
			}

			if(controls.ACCEPT && (creditsStuff[curSelected][3] == null || creditsStuff[curSelected][3].length > 4)) {
				CoolUtil.browserLoad(creditsStuff[curSelected][3]);
			}
			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
				quitting = true;
			}
		}
		
		for (item in grpOptions.members)
		{
			if(!item.bold)
			{
				var lerpVal:Float = CoolUtil.boundTo(elapsed * 12, 0, 1);
				if(item.targetY == 0)
				{
					var lastX:Float = item.x;
					item.screenCenter(X);
					item.x = FlxMath.lerp(lastX, item.x - 70, lerpVal);
				}
				else
				{
					item.x = FlxMath.lerp(item.x, 200 + -40 * Math.abs(item.targetY), lerpVal);
				}
			}
		}
		super.update(elapsed);
	}

	var moveTween:FlxTween = null;
	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		do {
			curSelected += change;
			if (curSelected < 0)
				curSelected = creditsStuff.length - 1;
			if (curSelected >= creditsStuff.length)
				curSelected = 0;
		} while(unselectableCheck(curSelected));

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if(!unselectableCheck(bullShit-1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
				}
			}
		}

		descText.text = creditsStuff[curSelected][2];
		descText.y = FlxG.height - descText.height + offsetThing - 60;

		if(moveTween != null) moveTween.cancel();
		moveTween = FlxTween.tween(descText, {y : descText.y + 15}, 0.25, {ease: FlxEase.sineOut});

		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();
	}

	private function unselectableCheck(num:Int):Bool {
		return creditsStuff[num].length <= 1;
	}
}