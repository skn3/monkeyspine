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
	
	Method OnSpineEntityAnimationComplete:Void(entity:SpineEntity, name:String)
		' --- animation has finished ---
	End
	
	Method OnSpineEntityEvent:Void(entity:SpineEntity, event:String, intValue:Int, floatValue:Float, stringValue:String)
		' --- event has triggered ---
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
			spinetest.SetSpeed(0.8)
			spinetest.StartAnimation()
			spinetest.SetSnapToPixels(True)
			spinetest.SetDebugDraw(True, True, True)
			spinetest.SetDebugHideImages(False)
			
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

		'must alwasy Return
		Return 0
	End
End