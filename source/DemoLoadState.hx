package;

import Section.SwagSection;
import Song.SwagSong;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxState;
import haxe.Json;

class DemoLoadState extends MusicBeatState {
	override function update(elapsed:Float) {
        PlayState.isStoryMode = true;
        PlayState.SONG = Song.loadFromJson('test', 'test');
        LoadingState.loadAndSwitchState(new PlayState());
    }
}