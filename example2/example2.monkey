'see license.txt for source licenses
'This example demonstrates how we can use a different atlas loader. The atlas loade we are using will load seperate images instead of loading packed images.
Import mojo
Import spine

Function Main:Int()
	New MyApp
	Return 0
End

Class MyApp Extends App
	Field timestamp:Int
	Field spineBoy:SpineEntity
	Field collided:Bool
	
	Method OnCreate:Int()
		' --- create the app ---
		'setup runtime
		SetUpdateRate(60)
		timestamp = Millisecs()
		
		'load spineboy
		Try
			spineBoy = New SpineEntity("spineboy.json", "spineboy_seperate", SpineSeperateImageLoader.instance)
			spineBoy.SetPosition(DeviceWidth() / 2, DeviceHeight() -100)
			spineBoy.SetAnimation("walk", True)
			spineBoy.SetDebugDraw(True, True, True)
			
		Catch exception:SpineException
			Error("Exception: " + exception)
		End
		
		'must alwasy return
		Return 0
	End
	
	Method OnRender:Int()
		' --- render the app ---
		Cls(128, 128, 128)
		
		'simples! render current item
		spineBoy.Render()
		
		If collided = False
			SetColor(255, 0, 0)
			DrawText("not collided", 5, 5)
		Else
			SetColor(0, 255, 0)
			DrawText("collided", 5, 5)
		EndIf
		
		'must alwasy return
		Return 0
	End
	
	Method OnUpdate:Int()
		' --- update the app ---
		'check for quit
		If KeyHit(KEY_ESCAPE) OnClose()
		
		'update time/delta
		Local newTimestamp:Int = Millisecs()
		Local deltaInt:Int = newTimestamp - timestamp
		Local deltaFloat:Float = deltaInt / 1000.0
		timestamp = newTimestamp
		
		'update item entity
		spineBoy.Update(deltaFloat)
		
		collided = spineBoy.PointInside(MouseX(), MouseY(), 2)
		
		'must alwasy return
		Return 0
	End
End