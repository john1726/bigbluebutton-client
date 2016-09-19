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
package org.bigbluebutton.main.model.timer
{
	import com.asfusion.mate.events.Dispatcher;
	
	import flash.external.ExternalInterface;
	
	import mx.collections.ArrayCollection;
	
	import org.as3commons.logging.api.ILogger;
	import org.as3commons.logging.api.getClassLogger;
	import org.bigbluebutton.core.BBB;
	import org.bigbluebutton.core.managers.TimerManager;
	import org.bigbluebutton.core.model.Config;
	import org.bigbluebutton.main.events.BBBEvent;
	import org.bigbluebutton.main.events.TimerServicesEvent;
	import org.bigbluebutton.main.model.timer.events.StartTimerEvent;
	import org.bigbluebutton.main.model.timer.events.StopTimerEvent;

        import flash.utils.Timer;
        import flash.events.TimerEvent;

        private const MIN_MASK:String = "00";
        private const SEC_MASK:String = "00";
        private const MS_MASK:String = "000";
        private const TIMER_INTERVAL:int = 10;

        private const TIMER_INTERVAL:int = 10;
        private var baseTimer:int;
        private var t:Timer;

	public class TimerService {
		private static const LOGGER:ILogger = getClassLogger(TimerService);      
    
		private var dispatcher:Dispatcher;
		
		public function TimerService() {
			dispatcher = new Dispatcher();
		}
		
		public function startService():void {
                    t = new Timer(TIMER_INTERVAL);
                    t.addEventListener(TimerEvent.TIMER, updateTimer);
		}
		
		public function startTimer():void{
                    baseTimer = getTimer();
                    t.start();
		}

                private function updateTimer(evt:TimerEvent):void {
                    var d:Date = new Date(getTimer() - baseTimer);
                    counter.text = dateFormatter.format(d);
                }

		public function stopTimer():void{
                    t.stop();
		}
	}
}
