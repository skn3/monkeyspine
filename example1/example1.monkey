'see license.txt for source licenses
'This is a complex example that demonstrated multiple entities, animations, skins, collisions, speed and more!

Import mojo
Import spine

'Syntax checks in order to let all the Spine APIS be compiled:
Import reflection
#REFLECTION_FILTER="*" 

Function Main:Int()
	New MyApp
	Return 0
End

Class ExampleItem
	Field entity:SpineEntity
	Field skins:String[]
	Field skinIndex:Int = -1
	Field animations:String[]
	Field animationIndex:Int
End

Class MyApp Extends App
	Field showInfo:Bool
	Field timestamp:Int
	Field overSlot:SpineSlot
	Field items:ExampleItem[]
	Field itemIndex:Int = -1
	Field currentItem:ExampleItem
	Field currentEntity:SpineEntity
	Field debug:Bool
	Field speed:Float = 1.0
	Field precision:Int = 2
	Field collisionMode:Int = False
	Field collisionSlotOn:Bool = False
	Field collisionSlot:SpineSlot
	
	Method OnCreate:Int()
		' --- create the app ---
		'setup runtime
		SetUpdateRate(60)
		timestamp = Millisecs()
		
		'load spineboy
		Try
			'create example items
			Local item:ExampleItem
			items = New ExampleItem[5]
			
			'spine boy
			item = New ExampleItem
			item.animations =["walk", "jump"]
			item.entity = New SpineEntity("spineboy.json", "spineboy_atlas.json", SpineMakeAtlasLoader.instance)
			item.entity.SetPosition(DeviceWidth() / 2, DeviceHeight() -100)
			item.entity.SetScale(1.0)
			item.entity.SetAlpha(0.5)
			items[0] = item
			
			'globlins
			item = New ExampleItem
			item.skins =["goblin", "goblingirl"]
			item.animations =["walk"]
			item.entity = New SpineEntity("goblins.json", "goblins_atlas.json", SpineMakeAtlasLoader.instance)
			item.entity.SetPosition(DeviceWidth() / 2, DeviceHeight() -100)
			items[1] = item
			
			'powerup
			item = New ExampleItem
			item.animations =["animation"]
			item.entity = New SpineEntity("powerup.json", "powerup_atlas.json", SpineMakeAtlasLoader.instance)
			item.entity.SetPosition(DeviceWidth() / 2, DeviceHeight() -100)
			items[2] = item
			
			'spinosaurus
			item = New ExampleItem
			item.animations =["animation"]
			item.entity = New SpineEntity("spinosaurus.json", "spinosaurus_atlas.json", SpineMakeAtlasLoader.instance)
			item.entity.SetPosition(DeviceWidth() / 2, DeviceHeight())
			item.entity.SetScale(0.5, 0.5)
			items[3] = item
			
			'dragon
			item = New ExampleItem
			item.animations =["flying"]
			item.entity = New SpineEntity("dragon.json", "dragon_atlas.json", SpineMakeAtlasLoader.instance)
			item.entity.SetPosition(DeviceWidth() / 2, DeviceHeight() -100)
			item.entity.SetScale(0.5, 0.5)
			items[4] = item

			'set starting skeleton
			NextEntity()
			
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
		If currentEntity currentEntity.Render()
		
		'render help
		SetColor(255, 255, 255)
		SetAlpha(1.0)
		
		'draw hilight overlay
		If overSlot
			Local attachment:SpineRegionAttachment = SpineRegionAttachment(overSlot.Attachment)
			If attachment
				SetColor(255, 255, 255)
				SpineDrawLinePoly(attachment.Vertices)
			EndIf
		EndIf
		
		If collisionSlot And collisionSlotOn
			Local attachment:SpineRegionAttachment = SpineRegionAttachment(collisionSlot.Attachment)
			If attachment
				SetColor(0, 0, 0)
				SpineDrawLinePoly(attachment.Vertices)
				SetColor(255, 255, 255)
			EndIf			
		EndIf
		
		
		'draw text stuff
		DrawText("Press <space> to toggle controls/info", 5, 5)
		
		If showInfo
			DrawText("Press D to toggle debug rendering", 5, 20)
			DrawText("Press E to change entity", 5, 35)
			DrawText("Press S to change skin", 5, 50)
			DrawText("Press A to change animation", 5, 65)
			DrawText("Press Up/Down to change speed multiplier [x" + String(speed)[0 .. 4] + "]", 5, 80)
			
			Select precision
				Case 0
					DrawText("Press 1 - 3 to change hit test precision [entity bounding]", 5, 95)
				Case 1
					DrawText("Press 1 - 3 to change hit test precision [region bounding]", 5, 95)
				Case 2
					DrawText("Press 1 - 3 to change hit test precision [transformed region]", 5, 95)
			End Select
			
			Select collisionMode
				Case 0
					DrawText("Press C to change collision type [none]", 5, 110)
				Case 1
					DrawText("Press C to change collision type [point]", 5, 110)
				Case 2
					DrawText("Press C to change collision type [rect]", 5, 110)
			End
			
			If collisionSlotOn = False
				DrawText("Checking for collision with entire entity", 5, 125)
			Else
				If collisionSlot = Null
					DrawText("Checking for collision with slot <Null> (press left or right to change)", 5, 125)
				Else
					DrawText("Checking for collision with slot '" + collisionSlot.Data.Name + "' (press left or right to change)", 5, 125)
				EndIf
			EndIf
			
			If collisionSlotOn = False
				DrawText("Press W to change collision checking to slot", 5, 140)
			Else
				DrawText("Press W to change collision checking to entire entity", 5, 140)
			EndIf
						
			If overSlot = Null
				DrawText("Mouse is over: <Null>", 5, 155)
			Else
				DrawText("Mouse is over: '" + overSlot.Data.Name + "'", 5, 155)
			EndIf
		EndIf
		
		If currentEntity
			Local entityText:String = "Entity: '" + currentEntity.GetName() + "'   Skin: '" + currentEntity.GetSkin() + "'   Animation '" + currentEntity.GetAnimation() + "'"
			DrawText(entityText, DeviceWidth() -TextWidth(entityText) - 5, DeviceHeight() -FontHeight() -5)
		EndIf
		
		'draw collision overlay
		Select collisionMode
			Case 1
				'point.. dross hair
				SetColor(0, 0, 0)
				DrawLine(MouseX() -5, MouseY(), MouseX() +5, MouseY())
				DrawLine(MouseX(), MouseY() -5, MouseX(), MouseY() +5)
			Case 2
				'rect
				SetColor(0, 0, 0)
				SpineDrawLineRect(MouseX() -40, MouseY() -40, 80, 80)
		End
		
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
		Local deltaFloat:Float = deltaInt / 1000.0 * speed
		timestamp = newTimestamp
		
		If MouseHit(MOUSE_LEFT)
			currentEntity.Free()
			currentEntity = Null
		EndIf
		
		'change info display
		If KeyHit(KEY_SPACE)
			If showInfo = False
				showInfo = True
			Else
				showInfo = False
			EndIf
		EndIf
		
		'change debug draw setting
		If KeyHit(KEY_D)
			If debug
				ChangeDebug(False)
			Else
				ChangeDebug(True)
			EndIf
		EndIf
		
		'change entity
		If KeyHit(KEY_E) NextEntity()
		
		'change skin
		If KeyHit(KEY_S) NextSkin()
		
		'change animation
		If KeyHit(KEY_A) NextAnimation()
		
		'change collisions stuff
		If KeyHit(KEY_1) precision = 0
		If KeyHit(KEY_2) precision = 1
		If KeyHit(KEY_3) precision = 2
		If KeyHit(KEY_C)
			If collisionMode = 2
				collisionMode = 0
			Else
				collisionMode += 1
			EndIf
		EndIf
		If KeyHit(KEY_W)
			If collisionSlotOn
				collisionSlotOn = False
				collisionSlot = Null
			Else
				collisionSlotOn = True
			EndIf
		EndIf
		
		'change speed
		If KeyDown(KEY_UP)
			speed += 0.01
		ElseIf KeyDown(KEY_DOWN)
			speed -= 0.01
		EndIf
		
		If currentEntity
			'update item entity
			currentEntity.Update(deltaFloat)
			
			'make head look at mouse
			If currentEntity.HasBone("head")
				If MouseX() > currentEntity.GetBoneX("head", True)
					'get angle between mouse and eyes slot
					Local eyesPosition:= currentEntity.GetSlotPosition("eyes", True)
					Local angle:Float = -ATan2( (MouseY() -eyesPosition[1]), (MouseX() -eyesPosition[0]))' + 180.0
					If angle < 0 angle = 180 + (180 + angle)
					
					'limit angel so it doesn't break the neck
					If angle > 15 And angle < 310
						If angle < 180
							angle = 15
						Else
							angle = 310
						EndIf
					EndIf
					
					'set the world rotation of the bone
					currentEntity.SetBoneRotation("head", angle + 90, True)
				EndIf
			EndIf
			
			'find the bone we are currently over
			overSlot = currentEntity.FindSlotAtPoint(MouseX(), MouseY())
			
			'do collision stuff
			Local collided:Bool = False
			If collisionSlotOn = False
				'with entire entity
				Select collisionMode
					Case 1
						collided = currentEntity.PointInside(MouseX(), MouseY(), precision)
					Case 2
						collided = currentEntity.RectOverlaps(MouseX() -40, MouseY() -40, 80, 80, precision)
				End
			Else
				'with particular slot
				'select slot
				If collisionSlot = Null collisionSlot = currentEntity.FindFirstSlotWithAttachment()
				
				If KeyHit(KEY_LEFT)
					collisionSlot = currentEntity.FindPreviousSlotWithAttachment(collisionSlot)
					If collisionSlot = Null collisionSlot = currentEntity.FindLastSlotWithAttachment()
				EndIf
				If KeyHit(KEY_RIGHT)
					collisionSlot = currentEntity.FindNextSlotWithAttachment(collisionSlot)
					If collisionSlot = Null collisionSlot = currentEntity.FindFirstSlotWithAttachment()
				EndIf
				
				'do collision test
				If collisionSlot
					Select collisionMode
						Case 1
							collided = currentEntity.PointInsideSlot(MouseX(), MouseY(), collisionSlot, precision = 2)
						Case 2
							collided = currentEntity.RectOverlapsSlot(MouseX() -40.0, MouseY() -40.0, 80.0, 80.0, collisionSlot, precision = 2)
					End
				EndIf
			EndIf
			
			'change color based on collision
			If collided
				currentEntity.SetColor(0, 255, 0)
			Else
				currentEntity.SetColor(255, 255, 255)
			EndIf
		EndIf
			
		'must alwasy Return
		Return 0
	End
	
	Method NextSkin:Void()
		' --- change skin if there are any to change ---
		If currentItem.skins.Length() = 0
			currentItem.skinIndex = 0
			Return
		EndIf
		
		'next ot wrap
		If currentItem.skinIndex = currentItem.skins.Length() - 1
			currentItem.skinIndex = 0
		Else
			currentItem.skinIndex += 1
		EndIf
		
		'change skin
		If currentEntity currentEntity.SetSkin(currentItem.skins[currentItem.skinIndex])
	End
	
	Method NextAnimation:Void()
		' --- change to next animation in current entity ---
		'next ot wrap
		If currentItem.animationIndex = currentItem.animations.Length() - 1
			currentItem.animationIndex = 0
		Else
			currentItem.animationIndex += 1
		EndIf
		
		'change animation
		If currentEntity currentEntity.SetAnimation(currentItem.animations[currentItem.animationIndex], True)
	End
	
	Method NextEntity:Void()
		' --- hange to new item ---
		'next or wrap
		If itemIndex = items.Length() - 1
			itemIndex = 0
		Else
			itemIndex += 1
		EndIf
		currentItem = items[itemIndex]
		currentEntity = currentItem.entity
		
		'change skin
		If currentItem.skinIndex = -1 NextSkin()
		
		If currentEntity
			'change animation
			currentEntity.SetAnimation(currentItem.animations[currentItem.animationIndex], True)
		
			'change debug setting
			currentEntity.SetDebugDraw(debug)
		EndIf
		
		'remove collision slot so we get a new one next update
		collisionSlot = Null
	End
	
	Method ChangeDebug:Void(on:Bool)
		' --- change debug draw setting ---
		If currentEntity
			currentEntity.SetDebugDraw(on)
		EndIf
		debug = on
	End
End