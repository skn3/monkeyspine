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
	Field spineBoy:SpineEntity
	Field animation:String = "walk"
	Field showMessageText:String
	Field showMessageAlpha:Float = 4.0
	
	Method OnSpineEntityAnimationComplete:Void(entity:SpineEntity, name:String)
		' --- animation has finished ---
		Select entity
			Case spineBoy
				'switch between animations
				If spineBoy.GetAnimation() = "walk"
					spineBoy.SetAnimation("jump", False)
					showMessageText = "Switching to 'jump' animation"
					showMessageAlpha = 4.0
				Else
					spineBoy.SetAnimation("walk", False)
					showMessageText = "Switching to 'walk' animation"
					showMessageAlpha = 4.0
				EndIf
		End
	End
	
	Method OnSpineEntityEvent:Void(entity:SpineEntity, event:String, intValue:Int, floatValue:Float, stringValue:String)
	End
	
	Method OnCreate:Int()
		' --- create the app ---
		'setup runtime
		SetUpdateRate(60)
		timestamp = Millisecs()
		
		'load spineboy
		Try
			spineBoy = New SpineEntity("spineboy.json", "spineboy_atlas.json", SpineMakeAtlasLoader.instance)
			spineBoy.SetPosition(DeviceWidth() / 2, DeviceHeight() -100)
			spineBoy.SetAnimation("jump")
			spineBoy.SetCallback(Self)
			spineBoy.SetSpeed(0.3)
			spineBoy.SetDebugDraw(True)
			
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
		spineBoy.Render()
		
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
		spineBoy.Update(deltaFloat)
		
		'update fading message
		If showMessageAlpha > 0
			showMessageAlpha -= 0.05
		EndIf
		
		'must alwasy Return
		Return 0
	End
End