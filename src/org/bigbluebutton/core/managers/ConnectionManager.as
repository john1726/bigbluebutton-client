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
package org.bigbluebutton.core.managers
{
    import flash.net.NetConnection;
    
    import org.bigbluebutton.main.model.ConferenceParameters;
    import org.bigbluebutton.main.model.users.IMessageListener;
    import org.bigbluebutton.main.model.users.NetConnectionDelegate;

	public class ConnectionManager
	{
    private var connDelegate:NetConnectionDelegate;
        
    [Bindable]
    public var isTunnelling:Boolean = false;
        
		public function ConnectionManager() {
      connDelegate = new NetConnectionDelegate();
		}
   
       
    public function setUri(uri:String):void {
      connDelegate.setUri(uri);
    }

    public function get connection():NetConnection {
      return connDelegate.connection;
    }
        
    public function connect(params:ConferenceParameters):void {
        connDelegate.connect(params);
    }
        
    public function disconnect(onUserAction:Boolean):void {
        connDelegate.disconnect(onUserAction);
    }
        
        public function addMessageListener(listener:IMessageListener):void {
            connDelegate.addMessageListener(listener);
        }
        
        public function removeMessageListener(listener:IMessageListener):void {
            connDelegate.removeMessageListener(listener);
        }
		
		public function sendMessage(service:String, onSuccess:Function, onFailure:Function, message:Object=null):void {
			connDelegate.sendMessage(service, onSuccess, onFailure, message);
		}
    
    public function forceClose():void {
      connDelegate.forceClose(); 
    }
            
	}
}