/**
* BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
* 
* Copyright (c) 2012 BigBlueButton Inc. and by respective authors (see below).
*
* This program is free software; you can redistribute it and/or modify it under the
* terms of the GNU Lesser General Public License as published by the Free Software
* Foundation; either version 3.0 of the License, or (at your option) any later
* version.
* 
* BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
* WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
* PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public License along
* with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.
*
*/
package org.bigbluebutton.modules.timer.managers
{
	import com.asfusion.mate.events.Dispatcher;
	
	import org.bigbluebutton.common.events.CloseWindowEvent;
	import org.bigbluebutton.common.events.OpenWindowEvent;
	import org.bigbluebutton.core.BBB;
	import org.bigbluebutton.modules.timer.events.StartTimerModuleEvent;
	import org.bigbluebutton.modules.timer.views.TimerWindow;

	public class TimerManager
	{		
		private var dispatcher:Dispatcher;
		private var timerWindow:TimerWindow;
		
		public function TimerManager(){
			dispatcher = new Dispatcher();
		}
		
		public function moduleStarted(event:StartTimerModuleEvent):void{
			if (timerWindow == null){
				timerWindow = new TimerWindow();
				
				var e:OpenWindowEvent = new OpenWindowEvent(OpenWindowEvent.OPEN_WINDOW_EVENT);
				e.window = timerWindow;
				dispatcher.dispatchEvent(e);
			}
		}
		
		public function moduleEnded():void{
			var event:CloseWindowEvent = new CloseWindowEvent(CloseWindowEvent.CLOSE_WINDOW_EVENT);
			event.window = timerWindow;
			dispatcher.dispatchEvent(event);
		}
	}
}