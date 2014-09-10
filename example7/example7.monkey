'see license.txt for source licenses
'This example demonstrates how we can see when an animation has finished.
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
	
	Method OnSpineEntityAnimationComplete:Void(entity:SpineEntity, name:String)
		' --- animation has finished ---
		Select entity
			Case spineTest
		End
	End
	
	Method OnSpineEntityEvent:Void(entity:SpineEntity, event:String, intValue:Int, floatValue:Float, stringValue:String)
		' --- event has triggered ---
		Select entity
			Case spineTest
		End
	End
	
	Method OnCreate:Int()
		' --- create the app ---
		'setup runtime
		SetUpdateRate(60)
		timestamp = Millisecs()
		
		'load spineTest
		Try
			spineTest = LoadMojoSpineEntity("monkey://data/smile_skeleton.json", "monkey://data/smile_skeleton.atlas")
			'spineTest = LoadMojoSpineEntity("monkey://data/mesh_skeleton.json", "monkey://data/mesh_skeleton.atlas")
			'spineTest = LoadMojoSpineEntity("monkey://data/simple_mesh_skeleton.json", "monkey://data/simple_mesh_skeleton.atlas")
			'spineTest = LoadMojoSpineEntity("monkey://data/goblins-ffd.json", "monkey://data/goblins-ffd.atlas")
			spineTest.SetDebugDraw(True)
			spineTest.SetPosition(DeviceWidth() / 2, DeviceHeight() -100)
			spineTest.SetAnimation("animation", True)
			spineTest.SetCallback(Self)
			spineTest.SetSpeed(0.8)
			spineTest.SetSnapToPixels(True)
			
		Catch exception:SpineException
			Error("Exception: " + exception)
		End
		
		'must alwasy Return
		Return 0
	End
	
	Method OnRender:Int()
		' --- render the app ---
		Cls(0, 0, 0)
		
		'simples! render current item
		spineTest.Render()
		
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
		spineTest.Update(deltaFloat)
		
		spineTest.SetPosition(MouseX(), MouseY())
		
		'update fading message
		If showMessageAlpha > 0
			showMessageAlpha -= 0.05
		EndIf
		
		'must alwasy Return
		Return 0
	End
End