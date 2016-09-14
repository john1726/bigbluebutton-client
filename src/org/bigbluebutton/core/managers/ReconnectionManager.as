/**
* BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
*
* Copyright (c) 2015 BigBlueButton Inc. and by respective authors (see below).
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
  import com.asfusion.mate.events.Dispatcher;
  
  import flash.display.DisplayObject;
  import flash.events.TimerEvent;
  import flash.utils.Dictionary;
  import flash.utils.Timer;
  
  import mx.collections.ArrayCollection;
  import mx.core.FlexGlobals;
  import mx.core.IFlexDisplayObject;
  import mx.managers.PopUpManager;
  
  import org.as3commons.logging.api.ILogger;
  import org.as3commons.logging.api.getClassLogger;
  import org.bigbluebutton.core.UsersUtil;
  import org.bigbluebutton.main.api.JSLog;
  import org.bigbluebutton.main.events.BBBEvent;
  import org.bigbluebutton.main.events.ClientStatusEvent;
  import org.bigbluebutton.main.events.LogoutEvent;
  import org.bigbluebutton.main.model.users.AutoReconnect;
  import org.bigbluebutton.main.views.ReconnectionPopup;
  import org.bigbluebutton.util.i18n.ResourceUtil;

  public class ReconnectionManager
  {
	private static const LOGGER:ILogger = getClassLogger(ReconnectionManager);      

    public static const BIGBLUEBUTTON_CONNECTION:String = "BIGBLUEBUTTON_CONNECTION";
    public static const SIP_CONNECTION:String = "SIP_CONNECTION";
    public static const VIDEO_CONNECTION:String = "VIDEO_CONNECTION";
    public static const DESKSHARE_CONNECTION:String = "DESKSHARE_CONNECTION";

    private var _connections:Dictionary = new Dictionary();
    private var _reestablished:ArrayCollection = new ArrayCollection();
    private var _reconnectTimer:Timer = new Timer(10000, 1);
    private var _reconnectTimeout:Timer = new Timer(15000, 1);
    private var _dispatcher:Dispatcher = new Dispatcher();
    private var _popup:IFlexDisplayObject = null;
    private var _canceled:Boolean = false;

    public function ReconnectionManager() {
      _reconnectTimer.addEventListener(TimerEvent.TIMER_COMPLETE, reconnect);
      _reconnectTimeout.addEventListener(TimerEvent.TIMER_COMPLETE, timeout);
    }
    
    private function reconnect(e:TimerEvent = null):void {
      if (_connections.hasOwnProperty(BIGBLUEBUTTON_CONNECTION)) {
        reconnectHelper(BIGBLUEBUTTON_CONNECTION);
      } else {
        for (var type:String in _connections) {
          reconnectHelper(type);
        }
      }
      if (!_reconnectTimeout.running)
        _reconnectTimeout.start();
    }

    private function timeout(e:TimerEvent = null):void {
      LOGGER.debug("timeout");
      _dispatcher.dispatchEvent(new BBBEvent(BBBEvent.CANCEL_RECONNECTION_EVENT));
      _dispatcher.dispatchEvent(new LogoutEvent(LogoutEvent.USER_LOGGED_OUT));
    }

    private function reconnectHelper(type:String):void {
      var obj:Object = _connections[type];
      obj.reconnect = new AutoReconnect();
      obj.reconnect.onDisconnect(obj.callback, obj.callbackParameters);
    }

    public function onDisconnected(type:String, callback:Function, parameters:Array):void {
      if (!_canceled) {
		var logData:Object = new Object();
		logData.user = UsersUtil.getUserData();
		logData.user.connection = type;
		
		JSLog.warn("Connection disconnected", logData);
		
		logData.message = "Connection disconnected";
		LOGGER.info(JSON.stringify(logData));
		
        var obj:Object = new Object();
        obj.callback = callback;
        obj.callbackParameters = parameters;
        _connections[type] = obj;

        if (!_reconnectTimer.running) {
          _popup = PopUpManager.createPopUp(FlexGlobals.topLevelApplication as DisplayObject, ReconnectionPopup, true);
          PopUpManager.centerPopUp(_popup);

          _reconnectTimer.reset();
          _reconnectTimer.start();
        }
      }
    }

    public function onConnectionAttemptFailed(type:String):void {
      LOGGER.warn("onConnectionAttemptFailed, type={0}", [type]);
	  
	  var logData:Object = new Object();
	  logData.user = UsersUtil.getUserData();
	  logData.user.connection = type;
	  
	  JSLog.warn("Reconnect attempt on connection failed.", logData);
	  
	  logData.message = "Reconnect attempt on connection failed.";
	  LOGGER.info(JSON.stringify(logData));
	  
      if (_connections.hasOwnProperty(type)) {
        _connections[type].reconnect.onConnectionAttemptFailed();
      }
    }

    private function get connectionDictEmpty():Boolean {
      for (var key:Object in _connections) {
        return false;
      }
      return true;
    }
    
    private function dispatchReconnectionSucceededEvent(type:String):void {
      var map:Object = {
        BIGBLUEBUTTON_CONNECTION: BBBEvent.RECONNECT_BIGBLUEBUTTON_SUCCEEDED_EVENT,
        SIP_CONNECTION: BBBEvent.RECONNECT_SIP_SUCCEEDED_EVENT,
        VIDEO_CONNECTION: BBBEvent.RECONNECT_VIDEO_SUCCEEDED_EVENT,
        DESKSHARE_CONNECTION: BBBEvent.RECONNECT_DESKSHARE_SUCCEEDED_EVENT
      };
      
      if (map.hasOwnProperty(type)) {
        LOGGER.debug("dispatchReconnectionSucceededEvent, type={0}", [type]);
        _dispatcher.dispatchEvent(new BBBEvent(map[type]));
      } else {
		LOGGER.debug("dispatchReconnectionSucceededEvent, couldn't find a map value for type {0}", [type]);
      }
    }

    public function onConnectionAttemptSucceeded(type:String):void {
	  LOGGER.debug("onConnectionAttemptSucceeded, type={0}", [type]);
	  var logData:Object = new Object();
	  logData.user = UsersUtil.getUserData();
	  logData.user.connection = type;
	  
	  JSLog.warn("Reconnect succeeded.", logData);
	  
	  logData.message = "Reconnect succeeded.";
	  LOGGER.info(JSON.stringify(logData));
	  
      dispatchReconnectionSucceededEvent(type);

      delete _connections[type];
      if (type == BIGBLUEBUTTON_CONNECTION) {
        reconnect();
      }

      _reestablished.addItem(type);
      if (connectionDictEmpty) {
        var msg:String = connectionReestablishedMessage();

        _dispatcher.dispatchEvent(new ClientStatusEvent(ClientStatusEvent.SUCCESS_MESSAGE_EVENT, 
          ResourceUtil.getInstance().getString('bbb.connection.reestablished'), 
          msg));

        _reconnectTimeout.reset();
        removePopUp();
      }
    }

    public function onCancelReconnection():void {
      _canceled = true;

      for (var type:Object in _connections) delete _connections[type];

      removePopUp();
    }

    private function removePopUp():void {
      if (_popup != null) {
        PopUpManager.removePopUp(_popup);
        _popup = null;
      }
    }

    private function connectionReestablishedMessage():String {
      var msg:String = "";
      for each (var conn:String in _reestablished) {
        switch (conn) {
          case BIGBLUEBUTTON_CONNECTION:
            msg += ResourceUtil.getInstance().getString('bbb.connection.bigbluebutton');
            break;
          case SIP_CONNECTION:
            msg += ResourceUtil.getInstance().getString('bbb.connection.sip');
            break;
          case VIDEO_CONNECTION:
            msg += ResourceUtil.getInstance().getString('bbb.connection.video');
            break;
          case DESKSHARE_CONNECTION:
            msg += ResourceUtil.getInstance().getString('bbb.connection.deskshare');
            break;
          default:
            break;
        }
        msg += " ";
      }
      _reestablished.removeAll();
      return msg;
    }
  }
}
