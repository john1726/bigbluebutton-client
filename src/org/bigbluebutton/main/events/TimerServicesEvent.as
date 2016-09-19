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
package org.bigbluebutton.main.events
{
	import flash.events.Event;

	public class TimerServicesEvent extends Event
	{
		public static const START_TIMER_SERVICES:String = "START_TIMER_SERVICES";
		public static const TIMER_SERVICES_STARTED:String = "TIMER_SERVICES_STARTED";
		
		public var applicationURI:String;
		public var hostURI:String;
		public var isTunnelling:Boolean = false;
    
		public var user:Object;
		
		public function TimerServicesEvent(type:String)
		{
			super(type, true, false);
		}
	}
}