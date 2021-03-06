'see license.txt For source licenses
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
	
	Field banana:SpineMojoImageAttachment
	
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
		
		'load some stuff to maybe use
		banana = New SpineMojoImageAttachment("banana_attachment", "monkey://data/banana.png")
		
		'load spineTest
		Try
			#TEST = "player"
			
			'which mode ?
			#If TEST = "goblin"
			spineTest = LoadMojoSpineEntity("monkey://data/goblins-ffd.json")
			spineTest.SetAnimation("walk", True)
			spineTest.SetSkin("goblin")
			'spineTest.SetSkin("goblingirl")
			spineTest.SetScale(1.0)
			spineTest.SetSpeed(0.2)
			
			#ElseIf TEST = "spear"
			spineTest = LoadMojoSpineEntity("monkey://data/goblins-spear.json")
			spineTest.SetAnimation("walk", True)
			'spineTest.SetSkin("goblingirl")
			spineTest.SetScale(1.0)
			spineTest.SetSpeed(0.2)
			
			#ElseIf TEST = "powerup"
			spineTest = LoadMojoSpineEntity("monkey://data/powerup.json")
			spineTest.SetAnimation("animation", True)
			
			#ElseIf TEST = "player"
			spineTest = LoadMojoSpineEntity("monkey://data/player.json")
			spineTest.SetAnimation("walking", True)
			
			#ElseIf TEST = "regions"
			spineTest = LoadMojoSpineEntity("monkey://data/smile_skeleton.json")
			spineTest.SetAnimation("animation", True)
			
			#ElseIf TEST = "ffd"
			spineTest = LoadMojoSpineEntity("monkey://data/mesh_skeleton.json")
			spineTest.SetAnimation("animation", True)
			
			#ElseIf TEST = "ffd_simple"
			spineTest = LoadMojoSpineEntity("monkey://data/simple_mesh_skeleton.json")
			spineTest.SetAnimation("animation", True)
			
			#ElseIf TEST = "skinned_mesh"
			spineTest = LoadMojoSpineEntity("monkey://data/skinned_mesh_skeleton.json")
			spineTest.SetAnimation("animation", True)
			
			#ElseIf TEST = "skinned_mesh_really_simple"
			spineTest = LoadMojoSpineEntity("monkey://data/skinned_mesh_really_simple.json")
			spineTest.SetAnimation("animation", True)
			
			#ElseIf TEST = "bounding_boxes"
			spineTest = LoadMojoSpineEntity("monkey://data/bounding_boxes_skeleton.json")
			spineTest.SetAnimation("animation", True)
			spineTest.SetSpeed(0.3)
			
			#ElseIf TEST = "ik"
			spineTest = LoadMojoSpineEntity("monkey://data/ik_skeleton.json")
			spineTest.SetAnimation("animation", True)
			spineTest.SetSpeed(0.3)
			
			#ElseIf TEST = "events"
			spineTest = LoadMojoSpineEntity("monkey://data/events_skeleton.json")
			spineTest.SetAnimation("animation", True)
			spineTest.SetSpeed(0.5)

			#ElseIf TEST = "custom_attachment"
			spineTest = LoadMojoSpineEntity("monkey://data/spineboy.json")
			spineTest.SetAnimation("run", True)
			spineTest.SetScale(0.4)
			spineTest.SetSpeed(0.2)
			
			#Else
			Error("no test specified")
				
			#EndIf
			
			spineTest.SetDebug(True, False)
			spineTest.SetCallback(Self)
			spineTest.SetSnapToPixels(False)
			spineTest.SetIgnoreRootPosition(False)
			spineTest.SetFlip(False, False)
			spineTest.SetPosition(DeviceWidth() / 2, DeviceHeight() / 2)
			
		Catch exception:SpineException
			Error("Exception: " + exception)
		End
		
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
		
		'SetColor(0, 0, 0)
		'DrawRect(MouseX(), MouseY(), 32, 32)
		
		canvas.Flush()
		
		'must alwasy Return
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
		'spineTest.SetPosition(MouseX(), MouseY())
		'spineTest.SetRotation(spineTest.GetRotation() +1.0)
		'spineTest.SetRotation(MouseY())
		'spineTest.SetBonePosition("bone4", MouseX(), MouseY(), True)
		spineTest.Update(deltaFloat)
		
		'do stuff based on test
		#If TEST = "custom_attachment"
			spineTest.SetSlotCustomAttachment("gun", banana)
		#EndIf
		
		'make changes to certain bones after it has been updated
		'spineTest.SetBonePosition("bone4", MouseX(), MouseY(), True)
		'spineTest.SetBoneRotation("head", MouseX(), True)
		
		'If spineTest.RectOverlapsSlot(MouseX(), MouseY(), 32, 32, "bounding_slot", True)
		'If spineTest.PointInsideBoundingBox(MouseX(), MouseY(), SPINE_PRECISION_HULL)
		If spineTest.PointInside(MouseX(), MouseY(), SPINE_PRECISION_HULL)
			spineTest.SetColor(1.0, 0.0, 0.0)
		Else
			spineTest.SetColor(1.0, 1.0, 1.0)
		EndIf
		
		If MouseDown(MOUSE_LEFT)
			spineTest.SetPosition(MouseX(), MouseY())
		EndIf
		
		'update fading message
		If showMessageAlpha > 0
			showMessageAlpha -= 0.05
		EndIf
		
		'must alwasy Return
		Return 0
	End
End