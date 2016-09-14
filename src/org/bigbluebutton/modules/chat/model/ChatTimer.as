package org.bigbluebutton.modules.chat.model
{
	/*****************************************
	 * ChatTimer :
	 * Demonstrates using getTimer to create a timer.
	 * -------------------
	 * See 1_timer.fla
	 ****************************************/
	 
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.display.SimpleButton;
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.utils.getTimer;

import org.bigbluebutton.core.BBB;
import mx.controls.Button;

public class ChatTimer extends MovieClip
	{
		//*************************
		// Properties: 
		
		public var hours:Number = 0;
		public var seconds:Number = 0;
		public var minutes:Number = 0;
		public var milli:Number = 0;
		
		// Time stamps
		public var pauseTime:Number = 0;
		public var pauseLength:Number = 0;
		public var buttonPressTime:Number = 0;
		
		// Flag
		public var timing:Boolean = false;

		public var pause_btn:Button;
		public var reset_btn:Button;
		public var unPause_btn:Button;

		public var seconds_txt:TextField;
		public var minutes_txt:TextField;
		public var hours_txt:TextField;
		public var milli_txt:TextField;

		[Bindable]
		public var position:String = "top-right";
		
		[Bindable]
		public var baseTabIndex:int;

		//*************************
		// Constructor:
		
		public function ChatTimer()
		{
			var cxml:XML = BBB.getConfigForModule("ChatModule");
			if (cxml != null) {
				if (cxml.@position != undefined) {
					position = cxml.@position.toString();
				}
				if (cxml.@baseTabIndex != undefined) {
					baseTabIndex = cxml.@baseTabIndex;
				} else {
					baseTabIndex = 801;
				}
			}

			pause_btn.visible = false;
			
			// Respond to mouse events
			reset_btn.addEventListener(MouseEvent.CLICK,clickHandler,false,0,true);
			pause_btn.addEventListener(MouseEvent.CLICK,clickHandler,false,0,true);
			unPause_btn.addEventListener(MouseEvent.CLICK,clickHandler,false,0,true);
			
			// Update screen every frame
			addEventListener(Event.ENTER_FRAME,enterFrameHandler);
		}

		public function getBaseIndex():int {
			return baseTabIndex;
		}
		
		//*************************
		// Event Handling:
		
		protected function enterFrameHandler(event:Event):void
		{
			var totalTime:Number = (getTimer()/1000)-pauseLength;
			var goTime:Number = totalTime-buttonPressTime;
			
			if( timing ) 
			{
				// Calculate time
				hours = Math.floor(goTime/3600);
				minutes = Math.floor((goTime/3600-hours)*60);
				seconds = Math.floor(((goTime/3600-hours)*60-minutes)*60);
				milli = Math.floor((goTime-(seconds+(minutes*60)+(hours*3600)))*100);
				
				// Display formatted time
				seconds_txt.text = format(seconds);
				minutes_txt.text = format(minutes);
				hours_txt.text = format(hours);
				milli_txt.text = format(milli);
			}
		}
		
		protected function clickHandler(event:MouseEvent):void
		{
			switch( event.target )
			{
				case reset_btn:
					
					restart();
					pause_btn.visible = false;
					unPause_btn.visible = true;
					break;
					
				case pause_btn:
					
					pause(true);
					pause_btn.visible = false;
					unPause_btn.visible = true;
					break;
					
				case unPause_btn:
					
					pause(false);
					pause_btn.visible = true;
					unPause_btn.visible = false;
					break;
			}
		}
		
		//*************************
		// Public methods:
		
		public function restart():void
		{
			hours_txt.text = "00";
			minutes_txt.text = "00";
			seconds_txt.text = "00";
			milli_txt.text = "00";
			buttonPressTime = (getTimer()/1000)-pauseLength;
			pause(true);
		}
		
		public function pause(b:Boolean):void
		{
			if( b ){
				pauseTime = getTimer()/1000;
			}else{
				pauseLength = ((getTimer()/1000)-pauseTime)+pauseLength;
			}
			timing = !b;
		}
		
		//*************************
		// Utils:
		
		protected function format(n:Number):String
		{
			if( n < 10 ){
				return ("0"+n);
			}
			return n.toString();
		}
	}
}