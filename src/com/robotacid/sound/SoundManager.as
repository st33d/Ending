package com.robotacid.sound {
	import flash.events.Event;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	import flash.media.SoundChannel;
	import flash.utils.getTimer;
	/**
	 * A static class that plays sounds.
	 * 
	 * Must first be initialised to create a library to play from
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class SoundManager{
		
		public static var active:Boolean = true;
		public static var sounds:Object/*Sound*/ = {};
		public static var soundChannels:Object/*SoundChannel*/= {};
		public static var volumes:Object/*Number*/ = {};
		
		public function SoundManager(){
			
		}
		
		/* Reads values for music and sfx toggles from the SharedObject */
		public static function init():void{
			active = UserData.settings.sfx;
			SoundLibrary.init();
		}
		
		/* Adds a sound to the sounds hash. Use this method to add all sounds to a project */
		public static function addSound(sound:Sound, name:String, volume:Number = 1.0):void{
			sounds[name] = sound;
			volumes[name] = volume;
		}
		
		/* Plays a sound once */
		public static function playSound(name:String, volume:Number = 1):void{
			if(!active || !sounds[name]) return;
			var sound:Sound = sounds[name];
			var soundTransform:SoundTransform = new SoundTransform(volumes[name] * volume);
			soundChannels[name] = sound.play(0, 0, soundTransform);
		}
		
		/* Stops a sound, deleting any loop or fading operation */
		public static function stopSound(name:String):void {
			if(soundChannels[name]){
				soundChannels[name].stop();
				delete soundChannels[name];
			}
		}
		
		/* Stops all sounds (except the currentMusic) */
		public static function stopAllSounds():void{
			var key:String;
			for(key in soundChannels){
				stopSound(key);
			}
		}
		
	}

}