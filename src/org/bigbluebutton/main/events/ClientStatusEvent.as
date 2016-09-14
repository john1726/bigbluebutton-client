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
	
	public class ClientStatusEvent extends Event
	{
		public static const SUCCESS_MESSAGE_EVENT:String = "SUCCESS_MESSAGE_EVENT";
		public static const WARNING_MESSAGE_EVENT:String = "WARNING_MESSAGE_EVENT";
		public static const FAIL_MESSAGE_EVENT:String = "FAIL_MESSAGE_EVENT";
		
		public var title:String;
		public var message:String;
		
		public function ClientStatusEvent(type:String, title:String, message:String)
		{
			super(type);
			this.title = title;
			this.message = message;
		}
	}
}