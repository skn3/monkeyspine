'see license.txt For source licenses
Import spine.spinemojo

Function Main:Int()
	New MyApp
	Return 0
End

Class MyApp Extends App Implements SpineEntityCallback
	Field timestamp:Int
	Field spineTest:SpineEntity
	Field showMessageText:String
	Field showMessageAlpha:Float = 4.0

	Field canvas:Canvas
	
	Method OnSpineEntityAnimationComplete:Void(entity:SpineEntity, name:String)
		' --- animation has finished ---
		Select entity
			Case spineTest
		End
	End
	
	Method OnSpineEntityEvent:Void(entity:SpineEntity, event:String, intValue:Int, floatValue:Float, stringValue:String)
		' --- event has triggered ---
		Print "SpineEvent: " + event + " int:" + intValue + " float:" + floatValue + " string:" + stringValue
	End
	
	Method OnCreate:Int()
		' --- create the app ---
		'setup runtime
		canvas = New Canvas()
		SetUpdateRate(60)
		timestamp = Millisecs()
		
		spineTest = LoadMojoSpineEntity("monkey://data/player.json")
		spineTest.SetAnimation("walking", True)
		spineTest.SetSpeed(0.3)
		spineTest.SetScale(3, 3)
		
		spineTest.SetDebug(True, False)
		spineTest.SetCallback(Self)
		spineTest.SetSnapToPixels(False)
		spineTest.SetIgnoreRootPosition(False)
		spineTest.SetFlip(False, False)
		spineTest.SetPosition(DeviceWidth() / 2, DeviceHeight() / 2)
		
		'must alwasy Return
		Return 0
	End
	
	Method OnRender:Int()
		' --- render the app ---
		canvas.Clear(0.6, 0.6, 0.6)
		canvas.SetBlendMode(BlendMode.Alpha)

		'simples! render current item
		spineTest.Render(canvas)
		
		'render message
		If showMessageAlpha > 0.0
			canvas.SetColor(1.0, 1.0, 1.0, Min(1.0, showMessageAlpha))
			canvas.DrawText(showMessageText, 5, 5)
		EndIf

		canvas.Flush()
		
		Return 0
	End
	
	Method OnUpdate:Int()
		' --- update the app ---
		'check For quit
		If KeyHit(KEY_ESCAPE) OnClose()
		
		'update time/delta
		Local newTimestamp:Int = Millisecs()
		Local deltaInt:Int = newTimestamp - timestamp
		Local deltaFloat:Float = deltaInt / 1000.0
		timestamp = newTimestamp
		
		'make changes to the entity before updating
		spineTest.SetPosition(MouseX(), MouseY())
		If MouseDown(MOUSE_LEFT)
			spineTest.Update(deltaFloat)
		EndIf
		
		'update fading message
		If showMessageAlpha > 0
			showMessageAlpha -= 0.05
		EndIf
		
		'must alwasy Return
		Return 0
	End
End