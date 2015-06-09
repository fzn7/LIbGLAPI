OpenGL For Stage3D for AS3
==================

This project is an OpenGL wrapper swc for use in AS3 projects

Example:
==================

1. Please put LibGLAPI.swc in your libs folder
2. Write class GLS3DTest.as with following content

package {
	import GLS3D.GLAPI

	import flash.display.Sprite
	import flash.display.StageAlign
	import flash.display.StageQuality
	import flash.display.StageScaleMode
	import flash.display3D.Context3D
	import flash.display3D.Context3DProfile
	import flash.display3D.Context3DRenderMode
	import flash.events.ErrorEvent
	import flash.events.Event

	[SWF(width="600", height="400", frameRate="60", backgroundColor="#000000")]
	public class GLS3DTest extends Sprite {
		public var context3D:Context3D;

		public function GLS3DTest() {
			if (stage) {
				init();
			}
			else {
				addEventListener(Event.ADDED_TO_STAGE, init);
			}
		}

		// called once Flash is ready
		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			stage.quality = StageQuality.LOW;
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.addEventListener(Event.RESIZE, onResizeEvent);
			trace("Init Stage3D...");

			stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreate);
			stage.stage3Ds[0].addEventListener(ErrorEvent.ERROR, errorHandler);
			stage.stage3Ds[0].requestContext3D(Context3DRenderMode.AUTO, Context3DProfile.STANDARD);
			trace("Stage3D requested...");
		}

		private function onContext3DCreate(e:Event):void {
			trace("Stage3D context created! Init sprite engine...");
			context3D = stage.stage3Ds[0].context3D;
			context3D.enableErrorChecking = true;
			context3D.configureBackBuffer(this.stage.stageWidth, this.stage.stageHeight, 0);

			GLAPI.init(context3D, {send: function (s:String) {
				trace(s);
			}}, stage);

			addEventListener(Event.ENTER_FRAME, render)
		}

		private function render(event:Event):void {
			GLAPI.instance.context.clear();

			LibGLAPI.glLoadIdentity();
			LibGLAPI.glOrtho(0.0, 1.0, 0.0, 1.0, -1.0, 1.0);
			LibGLAPI.glColor3f(mouseX / stage.stageWidth, 1.0, 0);
			LibGLAPI.glBegin(LibGLAPI.GL_POLYGON);
			LibGLAPI.glVertex3f(0.25, 0.25, 0.0);
			LibGLAPI.glVertex3f(0.75, 0.25, 0.0);
			LibGLAPI.glVertex3f(0.75, 0.75, 0.0);
			LibGLAPI.glVertex3f(0.25, 0.75, 0.0);
			LibGLAPI.glEnd();
			LibGLAPI.glFlush();

			GLAPI.instance.context.present();
		}

		private function errorHandler(e:ErrorEvent):void {
			trace("Error while setting up Stage3D: " + e.errorID + " - " + e.text);
		}

		protected function onResizeEvent(event:Event):void {
			trace("resize event...");
		}
	}
}

3. Compile it with the latest FlexSDk and enjoy

License
=======

The Adobe written portion of this project is provided under the MIT license. The headers for OpenGL come from the Mesa project. The examples are all licensed differently, please check carefully before reusing any of their code.