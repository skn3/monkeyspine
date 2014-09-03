'see license.txt for source licenses
'This example demonstrates how we can see when an animation has finished.
Import mojo
Import spine

Function Main:Int()
	New MyApp
	Return 0
End

Class MyApp Extends App Implements SpineEntityCallback
	Field timestamp:Int
	Field spinetest:SpineEntity
	Field showMessageText:String
	Field showMessageAlpha:Float = 4.0
	
	Method OnSpineEntityAnimationComplete:Void(entity:SpineEntity, name:String)
		' --- animation has finished ---
		Select entity
			Case spinetest
		End
	End
	
	Method OnSpineEntityEvent:Void(entity:SpineEntity, event:String, intValue:Int, floatValue:Float, stringValue:String)
		' --- event has triggered ---
		Select entity
			Case spinetest
				showMessageText = "event:" + event + ", Int:" + intValue + ", Float: " + floatValue + ", String: " + stringValue
				showMessageAlpha = 4.0
		End
	End
	
	Method OnCreate:Int()
		' --- create the app ---
		'setup runtime
		SetUpdateRate(60)
		timestamp = Millisecs()
		
		'load spinetest
		Try
			spinetest = New SpineEntity("spinetest.json", "spinetest.atlas")
			spinetest.SetPosition(DeviceWidth() / 2, DeviceHeight() -100)
			spinetest.SetAnimation("animation", True)
			spinetest.SetCallback(Self)
			spinetest.SetSpeed(0.8)
			spinetest.SetSnapToPixels(True)
			
		Catch exception:SpineException
			Error("Exception: " + exception)
		End
		
		'must alwasy Return
		Return 0
	End
	
	Method OnRender:Int()
		' --- render the app ---
		Cls(128, 128, 128)
		
		'simples! render current item
		spinetest.Render()
		
		'render message
		If showMessageAlpha > 0.0
			SetColor(255, 255, 255)
			SetAlpha(Min(1.0, showMessageAlpha))
			DrawText(showMessageText, 5, 5)
		EndIf
		
		'must alwasy Return
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
		spinetest.Update(deltaFloat)
		
		'update fading message
		If showMessageAlpha > 0
			showMessageAlpha -= 0.05
		EndIf
		
		'must alwasy Return
		Return 0
	End
End