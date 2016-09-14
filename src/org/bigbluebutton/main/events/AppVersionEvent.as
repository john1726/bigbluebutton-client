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

	public class AppVersionEvent extends Event {		
		public static const APP_VERSION_EVENT:String = "APP VERSION EVENT";
		public var appVersion:String;
		public var localeVersion:String;
		public var suppressLocaleWarning:Boolean = false;
		// If this version is from config.xml (true) or from locale.swf (false)
		public var configLocaleVersion:Boolean = false;
		
		public function AppVersionEvent()
		{
			super(APP_VERSION_EVENT, true, false);
		}
		
	}
}