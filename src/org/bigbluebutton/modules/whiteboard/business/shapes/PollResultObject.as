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

package org.bigbluebutton.modules.whiteboard.business.shapes
{
  import flash.text.TextField;
  import flash.text.TextFormat;
  import flash.text.TextFormatAlign;
  
  import org.as3commons.logging.api.ILogger;
  import org.as3commons.logging.api.getClassLogger;
  import org.as3commons.logging.util.jsonXify;
  import org.bigbluebutton.modules.whiteboard.models.Annotation;
  import org.bigbluebutton.util.i18n.ResourceUtil;
  
  public class PollResultObject extends DrawObject {
	private static const LOGGER:ILogger = getClassLogger(PollResultObject);      

	//private const h:uint = 100;
    //private const w:uint = 280;
    private const marginFill:uint = 0xFFFFFF;
    private const bgFill:uint = 0xFFFFFF;
    private const colFill:uint = 0x333333;
    private const margin:Number = 0.025;
    private const vPaddingPercent:Number = 0.25;
    private const hPaddingPercent:Number = 0.1;
    private const labelWidthPercent:Number = 0.3;
    
    private var sampledata:Array = [{a:"A", v:3}, {a:"B", v:1}, {a:"C", v:5}, {a:"D", v:8}];
    private var _data:Array;
    private var _textFields:Array;

    public function PollResultObject(id:String, type:String, status:String) {
      super(id, type, status)
      
      _textFields = new Array();
      data = null;
      // temp setter for testing purposes
      //data = sampledata;
      
    }
    
    public function set data(d:Array):void {
      _data = d;
    }
    
    public function get data():Array {
      return _data;
    }
    
    private function makeTextFields(num:int):void {
      if (num > _textFields.length) {
        var textField:TextField;
        for (var i:int=_textFields.length; i < num; i++) {
          textField = new TextField();
          addChild(textField);
          _textFields.push(textField);
        }
      } else if (num < _textFields.length) {
        for (var j:int=_textFields.length; i > num; i--) {
          removeChild(_textFields.pop());
        }
      }
    }
    
    private function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
      graphics.clear();
    
      if (_data != null && _data.length > 0) {
        graphics.lineStyle(0, marginFill);
        graphics.beginFill(marginFill, 1.0);
        graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
        graphics.endFill();
        
        var calcMargin:int = unscaledWidth * margin;
        var graphX:int = calcMargin;
        var graphY:int = calcMargin;
        var graphWidth:int = unscaledWidth - calcMargin*2;
        var graphHeight:int = unscaledHeight - calcMargin*2;
        
        graphics.lineStyle(2, colFill);
        graphics.beginFill(bgFill, 1.0);
        graphics.drawRect(calcMargin, calcMargin, graphWidth, graphHeight);
        graphics.endFill();
        
        var vpadding:int = (graphHeight*vPaddingPercent)/(_data.length+1);
        var hpadding:int = (graphWidth*hPaddingPercent)/(4);
        
        var actualRH:Number = (graphHeight-vpadding*(_data.length+1)) / _data.length;
        LOGGER.debug("PollGraphic - as raw {0} int {1}", [actualRH, int(actualRH)]);
        // Current problem is that the rowHeight is truncated. It would be nice if the extra pixels 
        // could be distributed for a more even look.
        var avgRowHeight:int = (graphHeight-vpadding*(_data.length+1)) / _data.length;
        var extraVPixels:int = graphHeight - (_data.length * (avgRowHeight+vpadding) + vpadding);
        LOGGER.debug("PollGraphic - extraVPixels {0}", [extraVPixels]);
        var largestVal:int = -1;
        var totalCount:Number = 0;
        //find largest value
        for (var i:int=0; i<_data.length; i++) {
          if (_data[i].v > largestVal) largestVal = _data[i].v;
          totalCount += _data[i].v;
        }
        
        var currTFIdx:int = 0;
        var answerText:TextField;
        var percentText:TextField;
        var answerArray:Array = new Array();
        var percentArray:Array = new Array();
        var minFontSize:int = 30;
        var currFontSize:int;
        
        //var startingLabelWidth:Number = Math.min(labelWidthPercent*graphWidth, labelMaxWidthInPixels);
		var startingLabelWidth:Number = labelWidthPercent*graphWidth;
		
        graphics.lineStyle(2, colFill);
        graphics.beginFill(colFill, 1.0);
        for (var j:int=0, vp:int=extraVPixels, ry:int=graphY, curRowHeight:int=0; j<_data.length; j++) {
          ry += Math.round(curRowHeight/2)+vpadding; // add the last row's height plus padding
          
          curRowHeight = avgRowHeight;
          if (j%2==0 && vp > 0) {
            curRowHeight += 1;
            vp--;
          }
          ry += curRowHeight/2;
          
          //ry += curRowHeight * (j+0.5) + vpadding*(j+1);
          // add row label
          answerText = _textFields[currTFIdx++];
          answerText.text = _data[j].a;
          answerText.width = startingLabelWidth;
          answerText.height = curRowHeight;
          answerText.selectable = false;
          //addChild(answerText);
          answerArray.push(answerText);
          currFontSize = findFontSize(answerText, minFontSize);
          if (currFontSize < minFontSize) minFontSize = currFontSize;
          //rowText.height = rowText.textHeight;
          answerText.x = graphX + hpadding;
          //rowText.y = ry-rowText.height/2;
          
          // add percentage
          percentText = _textFields[currTFIdx++];;// new TextField();
          var percentNum:Number = (totalCount == 0 ? 0 : ((_data[j].v/totalCount)*100));
          percentText.text = Math.round(percentNum).toString() + "%";
          percentText.width = startingLabelWidth;
          percentText.height = curRowHeight;
          percentText.selectable = false;
          //addChild(percentText);
          percentArray.push(percentText);
          currFontSize = findFontSize(percentText, minFontSize);
          if (currFontSize < minFontSize) minFontSize = currFontSize;
          //percentText.height = percentText.textHeight;
          //percentText.x = graphWidth-percentStartWidth/2-percentText.width/2;
          //percentText.y = ry-percentText.height/2;
        }
        
        var maxAnswerWidth:int = 0;
        var maxPercentWidth:int = 0;
        
        for (j=0, vp=extraVPixels, ry=graphY, curRowHeight=0; j<_data.length; j++) {
          ry += Math.round(curRowHeight/2)+vpadding; // add the last row's height plus padding
          
          curRowHeight = avgRowHeight;
          if (j%2==0 && vp > 0) {
            curRowHeight += 1;
            vp--;
          }
          ry += curRowHeight/2;
          
          //ry = curRowHeight * (j+0.5) + vpadding*(j+1);
          
          answerText = TextField(answerArray[j]);
          findFontSize(answerText, minFontSize);
          answerText.width = answerText.textWidth+4;
          answerText.height = answerText.textHeight+4;
          answerText.textColor = colFill;
          answerText.y = ry-answerText.height/2;
          if (answerText.width > maxAnswerWidth) maxAnswerWidth = answerText.width;
          
          percentText = TextField(percentArray[j]);
          findFontSize(percentText, minFontSize);
          percentText.width = percentText.textWidth+4;
          percentText.height = percentText.textHeight+4;
          percentText.textColor = colFill;
          percentText.x = graphX + graphWidth - hpadding - percentText.width;
          percentText.y = ry-percentText.height/2;
          if (percentText.width > maxPercentWidth) maxPercentWidth = percentText.width;
          
        }
        
        var countText:TextField;
        var maxBarWidth:int = graphWidth - (hpadding*4) - maxAnswerWidth - maxPercentWidth;
        var barStartX:int = graphX + maxAnswerWidth + (hpadding*2);
        
        for (j=0, vp=extraVPixels, ry=graphY, curRowHeight=0; j<_data.length; j++) {
          ry += Math.round(curRowHeight/2)+vpadding; // add the last row's height plus padding
          
          curRowHeight = avgRowHeight;
          if (j%2==0 && vp > 0) {
            curRowHeight += 1;
            vp--;
          }
          ry += curRowHeight/2;
          
          //ry = curRowHeight * (j+0.5) + vpadding*(j+1);
          
          // draw rect
          var rectWidth:int = maxBarWidth*(_data[j].v/largestVal);
          graphics.drawRect(barStartX, ry-curRowHeight/2, rectWidth, curRowHeight);
          // add vote count in middle of rect
          countText = _textFields[currTFIdx++]; // new TextField();
          countText.text = _data[j].v;
          countText.width = startingLabelWidth;
          countText.height = curRowHeight;
          countText.textColor = bgFill;
          countText.selectable = false;
          //addChild(countText);
          findFontSize(countText, minFontSize);
          countText.width = countText.textWidth+4;
          countText.height = countText.textHeight+4;
          countText.y = ry-countText.height/2;
          if (countText.width > rectWidth) {
            countText.x = barStartX + rectWidth + hpadding/2;
            countText.textColor = colFill;
          } else {
            countText.x = barStartX + rectWidth/2 - countText.width/2;
            countText.textColor = bgFill;
          }
        }
        
        graphics.endFill();
      }
    }
    
    private function findFontSize(textField:TextField, defaultSize:Number):int {
      var tFormat:TextFormat = new TextFormat();
      tFormat.size = defaultSize;
      tFormat.font = "arial";
      tFormat.align = TextFormatAlign.CENTER;
      textField.setTextFormat(tFormat);
      var size:Number = defaultSize;
      while((textField.textWidth+4 > textField.width || textField.textHeight+4 > textField.height) && size > 0) {
        size = size - 1;
        tFormat.size = size;
        textField.setTextFormat(tFormat);
      }
      
      return size;
    }
    
    private function drawRect(a:Annotation, parentWidth:Number, parentHeight:Number, zoom:Number):void {
      var ao:Object = a.annotation;
      this.graphics.lineStyle(1 * zoom, 0);
      
      var arrayEnd:Number = (ao.points as Array).length;
      var startX:Number = denormalize(21.845575, parentWidth);
      var startY:Number = denormalize(23.145401, parentHeight);
      var width:Number = denormalize(46.516006, parentWidth) - startX;
      var height:Number = denormalize(61.42433, parentHeight) - startY;
      
      this.graphics.drawRect(startX, startY, width, height);
      
    }
    
    override public function draw(a:Annotation, parentWidth:Number, parentHeight:Number, zoom:Number):void {
      var ao:Object = a.annotation;
	  LOGGER.debug("RESULT = {0}", [jsonXify(a)]);

      var arrayEnd:Number = (ao.points as Array).length;
      var startX:Number = denormalize((ao.points as Array)[0], parentWidth);
      var startY:Number = denormalize((ao.points as Array)[1], parentHeight);
      var pwidth:Number = denormalize((ao.points as Array)[2], parentWidth);
      var pheight:Number = denormalize((ao.points as Array)[3], parentHeight);
           
      var answers:Array = ao.result as Array;
      var ans:Array = new Array();
      for (var j:int = 0; j < answers.length; j++) {
	      var ar:Object = answers[j];
		  var localizedKey: String = ResourceUtil.getInstance().getString('bbb.polling.answer.' + ar.key);
		  
		  if (localizedKey == null || localizedKey == "" || localizedKey == "undefined") {
			  localizedKey = ar.key;
		  } 
	      var rs:Object = {a: localizedKey, v: ar.num_votes as Number};
	      LOGGER.debug("poll result a=[{0}] v=[{1}]", [ar.key, ar.num_votes]);
	      ans.push(rs);
      }
      
	  data = ans;
	  makeTextFields((answers != null ? answers.length*3 : 0));
	  
	  this.x = startX;
	  this.y = startY;
	  
	  updateDisplayList(pwidth, pheight);
	  
    }
    
    override public function redraw(a:Annotation, parentWidth:Number, parentHeight:Number, zoom:Number):void {
      draw(a, parentWidth, parentHeight, zoom);
    }
  }
}