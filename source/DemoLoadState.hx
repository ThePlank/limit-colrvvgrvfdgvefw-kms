package;

import Section.SwagSection;
import Song.SwagSong;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxState;
import haxe.Json;

class DemoLoadState extends MusicBeatState {
	override function create() {
        PlayState.SONG = Song.loadFromJson('sublime', 'sublime');
        LoadingState.loadAndSwitchState(new PlayState());
    }
}