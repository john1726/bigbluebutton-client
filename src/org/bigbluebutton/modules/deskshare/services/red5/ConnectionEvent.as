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
package org.bigbluebutton.modules.deskshare.services.red5
{
	import flash.events.Event;
	
	public class ConnectionEvent extends Event {
    
    public static const DESKSHARE_CONNECTION_EVENT:String = "deskshare connection event";
    
    public static const SUCCESS:String = "connection success";
    public static const FAILED:String = "connection failed";
    public static const CLOSED:String = "connection closed";
    public static const REJECTED:String = "connection rejected";
    public static const INVALIDAPP:String = "connection invalidApp";
    public static const APPSHUTDOWN:String = "connection appShutdown";
    public static const SECURITYERROR:String = "connection securityError";
    public static const DISCONNECTED:String = "connection disconnected";
    public static const CONNECTING:String = "connection connecting";
    public static const CONNECTING_RETRY:String = "connection retry";
    public static const CONNECTING_MAX_RETRY:String = "connection max retry";
    public static const CHECK_FOR_DESKSHARE_STREAM:String = "connection check deskshare publishing";
    public static const NO_DESKSHARE_STREAM:String = "connection deskshare publishing";
    public static const FAIL_CHECK_FOR_DESKSHARE_STREAM:String = "connection failed check deskshare publishing";
    
		public var status:String = "";
    
    public var retryAttempts:int = 0;
    
		public function ConnectionEvent():void {
			super(DESKSHARE_CONNECTION_EVENT, true, false);
		}	
	}
}