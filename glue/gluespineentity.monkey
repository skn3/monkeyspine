'see license.txt for source licenses
Strict

Import spine

'interface to handle spine entity notifications
Interface SpineEntityCallback
	Method OnSpineEntityAnimationComplete:Void(entity:SpineEntity, name:String)
End

'class to wrap spine
Class SpineEntity
	Private
	Field atlas:SpineAtlas
	Field data:SpineSkeletonData
	Field skeleton:SpineSkeleton
	Field callback:SpineEntityCallback
	
	Field animation:SpineAnimation
	Field speed:Float = 1.0
	Field playing:Bool
	Field looping:Bool
	Field finished:Bool
	
	Field debugSlots:Bool = False
	Field debugBones:Bool = False
	Field debugBounding:Bool = False
	
	Field updating:Bool = False
	Field rendering:Bool = False
	
	Field dirty:Bool
	Field dirtyBounding:Bool
	
	Field bounding:Float[8]
	
	Field x:Float = 0.0
	Field y:float = 0.0
	Field scaleX:Float = 1.0
	Field scaleY:Float = 1.0
	Field rotation:float = 0.0
	Field flipX:Bool
	Field flipY:Bool
	
	Field lastSlotLookupName:String
	Field lastSlotLookup:SpineSlot
	Field lastBoneLookupName:String
	Field lastBoneLookup:SpineBone
	Public
	
	'constructor/destructor
	'there are lots of variations here to make it easy to use
	Method New(skeletonPath:String = "", atlasPath:String = "")
		' --- load a new spine entity ---
		Load(skeletonPath, SpineMakeAtlasJSONAtlasLoader.instance.LoadAtlas(atlasPath, SpineDefaultFileLoader.instance), SpineDefaultFileLoader.instance)
	End
	
	Method New(skeletonPath:String = "", atlasPath:String = "", atlasLoader:SpineAtlasLoader)
		' --- load a new spine entity ---
		'call the Load method with given details
		Load(skeletonPath, atlasLoader.LoadAtlas(atlasPath, SpineDefaultFileLoader.instance), SpineDefaultFileLoader.instance)
	End
	
	Method New(skeletonPath:String = "", atlasPath:String = "", fileLoader:SpineFileLoader)
		' --- load a new spine entity ---
		'call the Load method with given details
		Load(skeletonPath, SpineMakeAtlasJSONAtlasLoader.instance.LoadAtlas(atlasPath, fileLoader), fileLoader)
	End
	
	Method New(skeletonPath:String = "", atlasPath:String = "", atlasLoader:SpineAtlasLoader, fileLoader:SpineFileLoader)
		' --- load a new spine entity ---
		'call the Load method with given details
		Load(skeletonPath, atlasLoader.LoadAtlas(atlasPath, fileLoader), fileLoader)
	End

	Method New(skeletonPath:String, atlas:SpineAtlas)
		' --- load a new spine entity ---
		'atlas has already been loaded
		Load(skeletonPath, atlas, SpineDefaultFileLoader.instance)
	End
		
	Method New(skeletonPath:String, atlas:SpineAtlas, fileLoader:SpineFileLoader)
		' --- load a new spine entity ---
		'atlas has already been loaded
		Load(skeletonPath, atlas, fileLoader)
	End
	
	Method Load:Bool(skeletonPath:String, atlas:SpineAtlas, fileLoader:SpineFileLoader)
		' --- load a new spine entity ---
		'load skeleton data
		'we lock the atlas again
		atlas.Lock()
		Local skeletonJson:= New SpineSkeletonJson(atlas)
		data = skeletonJson.ReadSkeletonData(skeletonPath)
		atlas.UnLock()
		
		'increase reference count on the atlas
		'it is upto the speciffic atlas implementation to make sure it doesn't free an atlas if its currently being used
		atlas.Use()
		
		'create skeleton
		skeleton = New SpineSkeleton(data)
		skeleton.SetToBindPose()
		
		'return success
		Return True
	End
	
	Method Free:Void()
		' --- free the spine entity ---
		'decrease reference count for atlas
		'it is upto the atlas implementation if it should also free any images resources
		If atlas atlas.Free()
		
		'cleanup pointers
		atlas = Null
		data = Null
		skeleton = Null
		callback = Null
		animation = Null
		lastSlotLookup = Null
		lastBoneLookup = Null
	End
	
	'events
	Private
	Method OnCalculate:Void()
		' --- need to calculate ---
		'this will update the state of the skeleton so anything we access after it is correctly updated
		dirty = False
		
		'update the root bone
		Local rootBone:= skeleton.RootBone()
		If rootBone
			rootBone.X = x
			rootBone.Y = y
			rootBone.ScaleX = scaleX
			rootBone.ScaleY = scaleY
			rootBone.Rotation = rotation
		EndIf
		
		'update the skeleton
		skeleton.FlipX = flipX
		skeleton.FlipY = flipY
		
		'update world transform
		skeleton.UpdateWorldTransform()
		
		'update region vertices
		Local slot:SpineSlot
		Local attachment:SpineRegionAttachment
		For Local index:= 0 Until skeleton.Slots.Length
			slot = skeleton.Slots[index]
			If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region Continue
			
			'get attachment in correct format
			attachment = SpineRegionAttachment(slot.Attachment)
			
			'update the attachment using the current state of bone
			attachment.Update(slot)
		Next
		
		'flag bounding as dirty
		'this will mean next time we retrieve bounding info it will recalculate
		dirtyBounding = True
	End
	
	Method OnCalculateBounding:Void()
		' --- calculate bounding ---
		'unflag dirty
		dirtyBounding = False
		
		Local minX:Float
		Local minY:Float
		Local maxX:Float
		Local maxY:Float
		Local first:Bool = True
		Local boundingIndex:Int
		Local slot:SpineSlot
		Local attachment:SpineRegionAttachment
		
		'iterate over visible elements
		For Local index:= 0 Until skeleton.Slots.Length
			'get slot
			slot = skeleton.Slots[index]
			
			'skip if not a region attachment
			If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region Continue
			
			'get attachment in correct format
			attachment = SpineRegionAttachment(slot.Attachment)

			'we can use bounds of each item
			If first
				minX = attachment.BoundingVertices[0]
				minY = attachment.BoundingVertices[1]
				maxX = attachment.BoundingVertices[4]
				maxY = attachment.BoundingVertices[5]
			Else
				If attachment.BoundingVertices[0] < minX minX = attachment.BoundingVertices[0]
				If attachment.BoundingVertices[0] > maxX maxX = attachment.BoundingVertices[0]
				If attachment.BoundingVertices[1] < minY minY = attachment.BoundingVertices[1]
				If attachment.BoundingVertices[1] > maxY maxY = attachment.BoundingVertices[1]
				If attachment.BoundingVertices[4] < minX minX = attachment.BoundingVertices[4]
				If attachment.BoundingVertices[4] > maxX maxX = attachment.BoundingVertices[4]
				If attachment.BoundingVertices[5] < minY minY = attachment.BoundingVertices[5]
				If attachment.BoundingVertices[5] > maxY maxY = attachment.BoundingVertices[5]
			EndIf
			
			'unflag first
			first = False
		Next
		
		'dump into bounding
		bounding[0] = minX
		bounding[1] = minY
		bounding[2] = maxX
		bounding[3] = minY
		bounding[4] = maxX
		bounding[5] = maxY
		bounding[6] = minX
		bounding[7] = maxY		
	End
	
	Method OnUpdate:Void(delta:Float)
		' --- update the entity ---
		If animation And playing
			'increase animation time in skeleton
			skeleton.Update(delta * speed)
			
			'update the animation
			animation.Apply(skeleton, skeleton.Time, looping)
			dirty = True
			
			'check for completion of animation
			If looping = False and skeleton.Time >= animation.Duration
				StopAnimation()
				finished = True
				
				'fire callback
				If callback callback.OnSpineEntityAnimationComplete(Self, animation.Name)
			EndIf
		EndIf
	End
	
	Method OnRender:Void()
		' --- render the entity ---
		Local index:Int
		Local slot:SpineSlot
		Local attachment:SpineRegionAttachment
		
		'calculate again just incase something has changed
		'this wont do any calculation if the entity has not been flagged as dirty!
		Calculate()
		
		'render bounding for regions
		If debugBounding
			For index = 0 Until skeleton.Slots.Length
				'get slot
				slot = skeleton.Slots[index]
				
				'skip if not a region attachment
				If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region Continue
				
				'get attachment in correct format
				attachment = SpineRegionAttachment(slot.Attachment)

				'draw lines rect around bounding of region
				mojo.SetColor(0, 255, 0)
				SpineDrawLinePoly(attachment.BoundingVertices)
			Next
		EndIf
		
		'render images
		For index = 0 Until skeleton.DrawOrder.Length
			'get slot
			slot = skeleton.DrawOrder[index]
			
			'skip if not a region attachment
			If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region Continue
			
			'get attachment in correct format
			attachment = SpineRegionAttachment(slot.Attachment)
			
			'draw it
			mojo.SetColor(attachment.WorldR * 255, attachment.WorldG * 255, attachment.WorldB * 255)
			mojo.SetAlpha(attachment.WorldAlpha)
			attachment.Region.Draw(attachment.WorldX, attachment.WorldY, attachment.WorldRotation, attachment.WorldScaleX, attachment.WorldScaleY, attachment.Vertices)
		Next
		
		'render slots
		If debugSlots
			For index = 0 Until skeleton.Slots.Length
				'get slot
				slot = skeleton.Slots[index]
				
				'skip if not a region attachment
				If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region Continue
				
				'get attachment in correct format
				attachment = SpineRegionAttachment(slot.Attachment)
				
				'draw lined rect around region
				mojo.SetColor(0, 0, 255)
				SpineDrawLinePoly(attachment.Vertices)
			Next
		EndIf
		
		'render bones
		If debugBones
			Local bone:SpineBone
			
			'draw line bones
			mojo.SetColor(255, 0, 0)
			mojo.SetAlpha(1.0)
			For index = 0 Until skeleton.Bones.Length
				bone = skeleton.Bones[index]
				DrawLine(bone.WorldX, bone.WorldY, bone.Data.Length * bone.M00 + bone.WorldX, bone.Data.Length * bone.M10 + bone.WorldY)
			Next
			
			'bone origins
			For index = 0 Until skeleton.Bones.Length
				bone = skeleton.Bones[index]
				
				If index = 0
					'root bone
					'draw a cross hair
					mojo.SetColor(0, 0, 255)
					DrawLine(bone.WorldX - 4, bone.WorldY - 4, bone.WorldX + 4, bone.WorldY - 4)
					DrawLine(bone.WorldX + 4, bone.WorldY - 4, bone.WorldX + 4, bone.WorldY + 4)
					DrawLine(bone.WorldX + 4, bone.WorldY + 4, bone.WorldX - 4, bone.WorldY + 4)
					DrawLine(bone.WorldX - 4, bone.WorldY + 4, bone.WorldX - 4, bone.WorldY - 4)
					DrawLine(bone.WorldX, bone.WorldY - 6, bone.WorldX, bone.WorldY + 6)
					DrawLine(bone.WorldX - 6, bone.WorldY, bone.WorldX + 6, bone.WorldY)
				Else
					'other bones
					'draw just a box
					mojo.SetColor(0, 255, 0)
					DrawRect(bone.WorldX - 2, bone.WorldY - 2, 4, 4)
				EndIf
			Next
		EndIf
		
		'render bounding for entire skeleton
		If debugBounding
			CalculateBounding()
			mojo.SetColor(255, 0, 0)
			SpineDrawLinePoly(bounding)
		EndIf
	End
	Public
	
	'debug api
	Method SetDebugDraw:Void(slotsBonesBounding:Bool)
		' --- set debug draw options ---
		debugSlots = slotsBonesBounding
		debugBones = slotsBonesBounding
		debugBounding = slotsBonesBounding
	End
	
	Method SetDebugDraw:Void(slots:Bool, bones:Bool, bounding:Bool)
		' --- set debug draw options ---
		debugSlots = slots
		debugBones = bones
		debugBounding = bounding
	End
	
	Method GetDebugDraw:Bool()
		' --- get combined debug state ---
		Return debugSlots or debugBones or debugBounding
	End
	
	Method GetDebugDrawSlots:Bool()
		' --- return state of debug draw ---
		Return debugSlots
	End
	
	Method GetDebugDrawBones:Bool()
		' --- return state of debug draw ---
		Return debugBones
	End
	
	Method GetDebugDrawBounding:Bool()
		' --- return state of debug draw ---
		Return debugBounding
	End
	
	'collision api
	Method PointInside:Bool(x:Float, y:Float, precision:Int = 0)
		' --- check if a point is inside using varying levels of precision ---
		' 0 - entity bounds
		' 1 - region bounds
		' 2 - region rect
		'calculate first
		CalculateBounding()
		
		'check compelte bounding
		If SpinePointInRect(x, y, bounding) = False Return False
		If precision < 1 Return True
		
		'check region bounding
		Local slot:SpineSlot
		Local attachment:SpineRegionAttachment
				
		'go in reverse order using the zOrder so we return the attachment closest to screen
		For Local index:= skeleton.DrawOrder.Length - 1 To 0 Step - 1
			'get slot
			slot = skeleton.DrawOrder[index]
			
			'skip if not a region attachment
			If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region Continue
			
			'get attachment in correct format
			attachment = SpineRegionAttachment(slot.Attachment)
			
			'need to do a hit test with point
			'first do simple rect test, then poly test
			If SpinePointInRect(x, y, attachment.BoundingVertices)
				If precision < 2 Return True
				
				'check with rotated polys
				If SpinePointInPoly(x, y, attachment.Vertices)
					'hwere we could go one step further and check pixels.. but no.. not really in current monkey!
					Return True
				EndIf
			EndIf
		Next
		
		'return fail
		Return False
	End
	
	Method RectOverlaps:Bool(x:Float, y:Float, width:Float, height:Float, precision:Int = 1)
		' --- check if a rect overlaps using varying levels of precision ---
		' 0 - entity bounds
		' 1 - region bounds
		' 2 - region rect
		'calculate first
		CalculateBounding()
		
		'check compelte bounding
		If SpineRectsOverlap(x, y, width, height, bounding) = False Return False
		If precision < 1 Return True
		
		'check region bounding
		Local slot:SpineSlot
		Local attachment:SpineRegionAttachment
		
		'setup temp vertices for poly check
		If precision > 1
			spineTempVertices[0] = x
			spineTempVertices[1] = y
			spineTempVertices[2] = x + width
			spineTempVertices[3] = y
			spineTempVertices[4] = x + width
			spineTempVertices[5] = y + height
			spineTempVertices[6] = x
			spineTempVertices[7] = y + height
		EndIf
				
		'go in reverse order using the zOrder so we return the attachment closest to screen
		For Local index:= skeleton.DrawOrder.Length - 1 To 0 Step - 1
			'get slot
			slot = skeleton.DrawOrder[index]
			
			'skip if not a region attachment
			If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region Continue
			
			'get attachment in correct format
			attachment = SpineRegionAttachment(slot.Attachment)
			
			'need to do a hit test with point
			'first do simple rect test, then poly test
			If SpineRectsOverlap(x, y, width, height, attachment.BoundingVertices)
				If precision < 2 Return True
				
				'check with rotated polys
				If SpinePolyToPoly(spineTempVertices, attachment.Vertices)
					'here we could go one step further and check pixels.. but no.. not really in current monkey!
					Return True
				EndIf
			EndIf
		Next
		
		'return fail
		Return False
	End
	
	'color/alpha api
	Method SetColor:Void(r:Int, g:Int, b:Int)
		' --- change color of the entity ---
		skeleton.R = r / 255.0
		skeleton.G = g / 255.0
		skeleton.B = b / 255.0
		
		'flag dirty
		dirty = True
	End
	
	Method SetAlpha:Void(alpha:Float)
		' --- change alpha ---
		skeleton.A = alpha
	End
	
	Method GetColor:Int[] ()
		' --- get color of skeleton ---
		Return[Int(skeleton.R * 255), Int(skeleton.G * 255), Int(skeleton.B * 255)]
	End
	
	Method GetColor:Void(rgb:Int[])
		' --- get color of skeleton ---
		rgb[0] = skeleton.R * 255
		rgb[1] = skeleton.G * 255
		rgb[2] = skeleton.B * 255
	End
	
	Method GetR:Int()
		' --- get color of skeleton ---
		Return skeleton.R
	End
	
	Method GetG:Int()
		' --- get color of skeleton ---
		Return skeleton.G
	End
	
	Method GetB:Int()
		' --- get color of skeleton ---
		Return skeleton.B
	End
	
	Method GetAlpha:Float()
		' --- get alpha ---
		Return skeleton.A
	End
	
	Method GetAtlas:SpineAtlas()
		Return atlas
	End

	'skin api
	Method SetSkin:Void(name:String)
		' --- change the skin ---
		SetSkin(GetSkin(name))
	End
	
	Method SetSkin:Void(skin:SpineSkin)
		' --- change teh skin ---
		If skin = Null
			'remove skin
		Else
			'set skin
			skeleton.SetSkin(skin)
			skeleton.SetToBindPose()
		EndIf
	End
	
	Method GetSkin:String()
		' --- get the current skin name ---
		If skeleton.Skin = Null Return ""
		Return skeleton.Skin.Name
	End
	
	Method GetSkin:SpineSkin(name:String)
		' --- get a skin object by name ---
		Return data.FindSkin(name)
	End
	
	'animation api
	Method SetAnimation:Void(name:String, looping:Bool = False)
		' --- change animation by id ---
		SetAnimation(GetAnimation(name), looping)
	End
	
	Method SetAnimation:Void(animation:SpineAnimation, looping:Bool = False)
		' --- change animation by animation ---
		'set the current animation
		Self.animation = animation
		skeleton.Time = 0.0
		Self.looping = looping
		finished = False
		playing = True
		
		'apply the animation to the skeleton
		animation.Apply(skeleton, skeleton.Time, looping)
		skeleton.SetToBindPose()
		
		'flag that the entity is dirty again
		dirty = True
	End
	
	Method IsAnimationRunning:Bool()
		' --- check if the previously set animation is running ---
		Return finished = False
	End
	
	Method SetSpeed:Void(speed:Float)
		' --- change speed multiplier ---
		Self.speed = speed
	End
	
	Method StopAnimation:Void()
		' --- stops teh animation ---
		If playing
			playing = False
		EndIf
	End
	
	Method StartAnimation:Void()
		' --- resumes teh animation ---
		If playing = False
			If animation
				playing = True
				
				'restart?
				If finished SetAnimation(animation, looping)
			EndIf
		EndIf
	End
	
	Method GetAnimation:String()
		' --- returns the name of the current animation ---
		If animation = Null Return ""
		Return animation.Name
	End
	
	Method GetAnimation:SpineAnimation(id:String)
		' --- return teh animation object ---
		Return data.FindAnimation(id)
	End
	
	Method GetAnimationTime:Int()
		' --- return time of animation ---
		Return skeleton.Time * 1000
	End
	
	Method GetSpeed:Float()
		' --- get speed multiplier ---
		Return speed
	End
	
	'position api
	Method SetPosition:Void(x:Float, y:Float)
		' --- move the spine entity ---
		If x = Self.x And y = Self.y Return
		Self.x = x
		Self.y = y
		dirty = True
	End
	
	Method SetPosition:Void(xy:Float)
		' --- move the spine entity ---
		If xy = x and xy = y Return
		x = xy
		y = xy
		dirty = True
	End
	
	Method GetPosition:Float[] ()
		' --- return local position ---
		Return[x, y]
	End
	
	Method GetPosition:Void(xy:Float[])
		' --- return local position ---
		xy[0] = x
		xy[1] = y
	End
	
	Method GetX:Float()
		' --- return local position ---
		Return x
	End
	
	Method GetY:Float()
		' --- return local position ---
		Return y
	End
	
	'scale api
	Method SetScale:Void(scaleX:Float, scaleY:Float)
		' --- scale the spine entity ---
		If scaleX = Self.scaleX and scaleY = Self.scaleY Return
		Self.scaleX = scaleX
		Self.scaleY = scaleY
		dirty = True
	End
	
	Method SetScale:Void(scaleXY:Float)
		' --- scale the spine entity ---
		If scaleXY = scaleX and scaleXY = scaleY Return
		scaleX = scaleXY
		scaleY = scaleXY
		dirty = True
	End
	
	Method GetScale:Float[] ()
		' --- return local scale ---
		Return[scaleX, scaleY]
	End
	
	Method GetScale:Void(scaleXY:Float[])
		' --- return local scale ---
		scaleXY[0] = scaleX
		scaleXY[1] = scaleY
	End
	
	Method GetScaleX:Float()
		' --- return local scale ---
		Return scaleX
	End
	
	Method GetScaleY:Float()
		' --- return local scale ---
		Return scaleY
	End	
	
	'rotation api
	Method SetRotation:Void(rotation:Float)
		' --- rotate the spine entity ---
		If rotation = Self.rotation Return
		Self.rotation = rotation
		dirty = True
	End
	
	Method GetRotation:Float()
		' --- return local angle ---
		Return rotation
	End
	
	'flip api
	Method SetFlip:Void(flipX:Bool, flipY:Bool)
		' --- flip the skeleton ---
		If flipX = Self.flipX And flipY = Self.flipY Return
		Self.flipX = flipX
		Self.flipY = flipY
		dirty = True
	End
	
	Method GetFlip:Bool[] ()
		' --- get local flip ---
		Return[flipX, flipY]
	End
	
	Method GetFlip:Void(flipXY:Bool[])
		' --- get local flip ---
		flipXY[0] = flipX
		flipXY[1] = flipY
	End
	
	Method GetFlipX:Bool()
		' --- get local flip ---
		Return flipX
	End
	
	Method GetFlipY:Bool()
		' --- get local flip ---
		Return flipY
	End
	
	'bounding api
	Method GetBounding:Float[] ()
		' --- this will get the bounding box of the entity ---
		'calculate first
		CalculateBounding()
		
		'copy bounding into return
		Local out:Float[8]
		For Local index:Int = 0 Until 8
			out[index] = bounding[index]
		Next
		Return out
	End
	
	Method GetBounding:Void(out:Float[])
		' --- this will get the bounding box of the entity ---
		'calculate first
		CalculateBounding()
		
		'copy bounding into return
		For Local index:Int = 0 Until 8
			out[index] = bounding[index]
		Next
	End
	
	'slot api
	Method GetSlot:SpineSlot(name:String)
		' --- find a slot by name ---
		'check for quick lookup
		If name = lastSlotLookupName Return lastSlotLookup
		
		'lookup
		lastSlotLookupName = name
		lastSlotLookup = skeleton.FindSlot(lastSlotLookupName)
		Return lastSlotLookup
	End
	
	Method FindSlotWithAttachment:SpineSlot(name:String, ignoreInvisible:Bool = False)
		' --- find a slot that contains an attachment ---
		'do it
		Local index:Int
		Local slot:SpineSlot
		Local attachment:SpineRegionAttachment
		
		'go in reverse order using the zOrder so we return the attachment closest to screen
		For index = skeleton.DrawOrder.Length - 1 To 0 Step - 1
			'get slot
			slot = skeleton.DrawOrder[index]
			
			'skip if not a region attachment
			If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region Continue
			
			'get attachment in correct format
			attachment = SpineRegionAttachment(slot.Attachment)
			
			'need to do a hit test with point
			If (ignoreInvisible = False or attachment.WorldAlpha > 0.0) Return slot
		Next
		
		'return nothing found
		Return Null		
	End
	
	Method FindSlotAtPoint:SpineSlot(x:Float, y:Float, ignoreInvisible:Bool = True)
		' --- this will return the highest zorder attachment at point ---
		'only region attachments will return
		'need to calculate first (wont do anything if not flagged as dirty)
		'this will also cause a calculate()
		CalculateBounding()
		
		'check we are within full bounding of entity first (nice n quick!)
		If SpinePointInRect(x, y, bounding) = False Return Null
	
		'do it
		Local index:Int
		Local slot:SpineSlot
		Local attachment:SpineRegionAttachment
				
		'go in reverse order using the zOrder so we return the attachment closest to screen
		For index = skeleton.DrawOrder.Length - 1 To 0 Step - 1
			'get slot
			slot = skeleton.DrawOrder[index]
			
			'skip if not a region attachment
			If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region Continue
			
			'get attachment in correct format
			attachment = SpineRegionAttachment(slot.Attachment)
			
			'need to do a hit test with point
			'first do simple rect test, then poly test
			If (ignoreInvisible = False or attachment.WorldAlpha > 0.0) and SpinePointInRect(x, y, attachment.BoundingVertices) and SpinePointInPoly(x, y, attachment.Vertices) Return slot
		Next
		
		'return nothing found
		Return Null
	End
	
	'slot color api
	Method SetSlotColor:Void(name:String, rgb:Int[])
		' --- change the color of a slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null Return
		
		slot.R = rgb[0] / 255.0
		slot.G = rgb[1] / 255.0
		slot.B = rgb[2] / 255.0
		
		'flag dirty
		dirty = True
	End
	
	Method SetSlotColor:Void(name:String, r:Int, g:Int, b:Int)
		' --- change the color of a slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null Return
		
		slot.R = r / 255.0
		slot.G = g / 255.0
		slot.B = b / 255.0
		
		'flag dirty
		dirty = True
	End
	
	Method GetSlotColor:Int[] (name:String)
		' --- get color of a particular slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null Return[0, 0, 0]
		
		'local
		Return[int(slot.R * 255), int(slot.G * 255), int(slot.B * 255)]
	End
	
	Method GetSlotColor:Void(name:String, rgb:Int[])
		' --- get color of a particular slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null
			rgb[0] = 0
			rgb[1] = 0
			rgb[2] = 0
			Return
		EndIf
		
		'local
		rgb[0] = slot.R * 255
		rgb[1] = slot.G * 255
		rgb[2] = slot.B * 255
	End
	
	Method GetSlotColorR:Int(name:String)
		' --- get color of a particular slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null Return 0
		Return slot.R * 255
	End
	
	Method GetSlotColorG:Int(name:String)
		' --- get color of a particular slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null Return 0
		Return slot.G * 255
	End
	
	Method GetSlotColorB:Int(name:String)
		' --- get color of a particular slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null Return 0
		Return slot.B * 255
	End
	
	'slot position api
	Method GetSlotPosition:Float[] (name:String, world:Bool = False)
		' --- this will return the position of the given slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null Return[0.0, 0.0]
		
		'must calculate first
		Calculate()
		
		'return bone if slot doesn't have a psotional attachment
		If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region
			'world or local?
			If world Return[slot.Bone.WorldX, slot.Bone.WorldY]
			Return[0.0, 0.0]
		EndIf
		
		'return attachment psotion
		Local attachment:= SpineRegionAttachment(slot.Attachment)
		
		'world or local?
		If world Return[attachment.WorldX, attachment.WorldY]
		Return[attachment.X, attachment.Y]
	End
	
	Method GetSlotPosition:Void(name:String, xy:float[], world:Bool = False)
		' --- this will return the position of the given slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null
			xy[0] = 0.0
			xy[1] = 0.0
			Return
		EndIf
		
		'must calculate first
		Calculate()
		
		'return bone if slot doesn't have a psotional attachment
		If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region
			'world or local?
			If world
				xy[0] = slot.Bone.WorldX
				xy[1] = slot.Bone.WorldX
			Else
				xy[0] = 0.0
				xy[1] = 0.0
			EndIf
			Return
		EndIf
		
		'return attachment psotion
		Local attachment:= SpineRegionAttachment(slot.Attachment)
		
		'world or local?
		If world
			xy[0] = attachment.WorldX
			xy[1] = attachment.WorldY
		Else
			xy[0] = attachment.X
			xy[1] = attachment.Y
		EndIf
		Return
	End
	
	Method GetSlotX:Float(name:String, world:Bool = False)
		' --- this will return the position of the given slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null Return 0.0
		
		'must calculate first
		Calculate()
		
		'return bone if slot doesn't have a psotional attachment
		If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region
			'world or local?
			If world Return slot.Bone.WorldX
			Return 0.0
		EndIf
		
		'return attachment psotion
		Local attachment:= SpineRegionAttachment(slot.Attachment)
		
		'world or local?
		If world Return attachment.WorldX
		Return attachment.X
	End
	
	Method GetSlotY:Float(name:String, world:Bool = False)
		' --- this will return the position of the given slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null Return 0.0
		
		'must calculate first
		Calculate()
		
		'return bone if slot doesn't have a psotional attachment
		If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region
			'world or local?
			If world Return slot.Bone.WorldY
			Return 0.0
		EndIf
		
		'return attachment psotion
		Local attachment:= SpineRegionAttachment(slot.Attachment)
		
		'world or local?
		If world Return attachment.WorldY
		Return attachment.Y
	End
	
	'slot rotation api
	Method GetSlotRotation:Float(name:String, world:Bool = False)
		' --- return bone rotation for a given slot ---
		'must be applied after calling Update() on entity
		'lookup slot
		Local slot:= GetSlot(name)
		If slot = Null Return 0.0
		
		'must calculate first
		Calculate()
		
		'return bone if slot doesn't have a psotional attachment
		If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region
			'world or local?
			If world Return slot.Bone.WorldRotation
			Return 0.0
		EndIf
			
		'return attachment rotation
		Local attachment:= SpineRegionAttachment(slot.Attachment)
		
		'world or local?
		If world Return attachment.WorldRotation
		Return attachment.Rotation
	End
	
	'slot scale api
	Method GetSlotScale:Float[] (name:String, world:Bool = False)
		' --- this will return the position of the given slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null Return[0.0, 0.0]
		
		'must calculate first
		Calculate()
		
		'return bone if slot doesn't have a psotional attachment
		If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region
			'world or local?
			If world Return[slot.Bone.WorldScaleX, slot.Bone.WorldScaleY]
			Return[0.0, 0.0]
		EndIf
		
		'return attachment scale
		Local attachment:= SpineRegionAttachment(slot.Attachment)
		
		'world or local?
		If world Return[attachment.WorldScaleX, attachment.WorldScaleY]
		Return[attachment.ScaleX, attachment.ScaleY]
	End
	
	Method GetSlotScale:Void(name:String, scaleXY:Float[], world:Bool = False)
		' --- this will return the position of the given slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null
			scaleXY[0] = 0.0
			scaleXY[1] = 0.0
			Return
		EndIf
		
		'must calculate first
		Calculate()
		
		'return bone if slot doesn't have a psotional attachment
		If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region
			'world or local?
			If world
				scaleXY[0] = slot.Bone.WorldScaleX
				scaleXY[1] = slot.Bone.WorldScaleY
			Else
				scaleXY[0] = 0.0
				scaleXY[1] = 0.0
			EndIf
		Else
		
			'return attachment scale
			Local attachment:= SpineRegionAttachment(slot.Attachment)
		
			'world or local?
			If world
				'world
				scaleXY[0] = attachment.WorldScaleX
				scaleXY[1] = attachment.WorldScaleY
			Else
				'local
				scaleXY[0] = attachment.ScaleX
				scaleXY[1] = attachment.ScaleY
			EndIf
		EndIf
	End
	
	Method GetSlotScaleX:Float(name:String, world:Bool = False)
		' --- this will return the position of the given slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null Return 0.0
		
		'must calculate first
		Calculate()
		
		'return bone if slot doesn't have a psotional attachment
		If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region
			'world or local?
			If world Return slot.Bone.WorldScaleX
			Return 0.0
		EndIf
		
		'return attachment scale
		Local attachment:= SpineRegionAttachment(slot.Attachment)
		
		'world or local?
		If world Return attachment.WorldScaleX
		Return attachment.ScaleX
	End
	
	Method GetSlotScaleY:Float(name:String, world:Bool = False)
		' --- this will return the position of the given slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null Return 0.0
		
		'must calculate first
		Calculate()
		
		'return bone if slot doesn't have a psotional attachment
		If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region
			'world or local?
			If world Return slot.Bone.WorldScaleY
			Return 0.0
		EndIf
		
		'return attachment scale
		Local attachment:= SpineRegionAttachment(slot.Attachment)
		
		'world or local?
		If world Return attachment.WorldScaleY
		Return attachment.ScaleY
	End
	
	'bone api
	Method ResetBones:Void()
		' --- this will reset bones to their default state at current frame ---
		skeleton.SetBonesToBindPose()
		dirty = True
	End
	
	Method HasBone:Bool(name:String)
		' --- return true if bone exists ---
		'this is a lazy way of doing it
		Return GetBone(name) <> Null
	End
	
	Method GetBone:SpineBone(name:string)
		' --- find bone by name ---
		'check for quick lookup
		If name = lastBoneLookupName Return lastBoneLookup
		
		'lookup bone
		lastBoneLookupName = name
		lastBoneLookup = skeleton.FindBone(name)
		Return lastBoneLookup
	End
	
	'bone position api
	Method SetBonePosition:Void(name:String, x:Float, y:Float, world:Bool = False)
		' --- set bone position ---
		'must be applied after calling Update() on entity
		'if the world flag is specified it will calculate the bones local rotation based on parent rotation to achieve the angle specified
		
		'lookup bone
		Local bone:= GetBone(name)
		If bone = Null Return
		
		'world or local?
		If world = False or bone.Parent = Null
			'local
			'offset from base position
			bone.X = bone.Data.X + x
			bone.Y = bone.Data.Y + y
		Else
			'world
			'offset from base position
			
			'need to calculate first
			Calculate()
			
			'now calculate the world position in bone space
			x = (x - bone.Parent.WorldX) / bone.Parent.WorldScaleX
			y = (y - bone.Parent.WorldY) / bone.Parent.WorldScaleY
			
			bone.X = (x * bone.Parent.M00 + y * bone.Parent.M01) / bone.Parent.WorldScaleX
			bone.Y = (x * bone.Parent.M10 + y * bone.Parent.M11) / bone.Parent.WorldScaleY
		EndIf
		
		'flag dirty
		dirty = True
	End
	
	Method SetBonePosition:Void(name:String, xy:Float[], world:Bool = False)
		' --- override to pass in array ---
		SetBonePosition(name, xy[0], xy[1], world)
	End
	
	Method GetBonePosition:Float[] (name:String, world:Bool = False)
		' --- get position of bone ---
		'lookup bone
		Local bone:= GetBone(name)
		If bone = Null Return[0.0, 0.0]
		
		'must calculate first
		Calculate()
		
		'return
		If world Return[bone.WorldX, bone.WorldY]
		Return[bone.X, bone.Y]
	End
	
	Method GetBonePosition:Void(name:String, xy:Float[], world:Bool = False)
		' --- get position of bone ---
		'lookup bone
		Local bone:= GetBone(name)
		If bone = Null
			xy[0] = 0.0
			xy[1] = 0.0
		EndIf
		
		'must calculate first
		Calculate()
		
		'return
		If world
			xy[0] = bone.WorldX
			xy[1] = bone.WorldY
		Else
			xy[0] = bone.X
			xy[1] = bone.Y
		EndIf
	End
	
	Method GetBoneX:Float(name:String, world:Bool = False)
		' --- get position of bone ---
		'lookup bone
		Local bone:= GetBone(name)
		If bone = Null Return 0.0
		
		'must calculate first
		Calculate()
		
		'return
		If world Return bone.WorldX
		Return bone.X
	End
	
	Method GetBoneY:Float(name:String, world:Bool = False)
		' --- get position of bone ---
		'lookup bone
		Local bone:= GetBone(name)
		If bone = Null Return 0.0
		
		'must calculate first
		Calculate()
		
		'return
		If world Return bone.WorldY
		Return bone.Y
	End
	
	'bone rotation api
	Method SetBoneRotation:Void(name:String, angle:Float, world:Bool = False)
		' --- rotate a given bone ---
		'must be applied after calling Update() on entity
		'if the world flag is specified it will calculate the bones local rotation based on parent rotation to achieve the angle specified
		
		'lookup bone
		Local bone:= GetBone(name)
		If bone = Null Return
		
		'world or local
		If world = False or bone.Parent = Null
			'apply to the bone
			bone.Rotation = angle
		Else
			'do calculation first
			Calculate()
			
			'offset angle from parent
			bone.Rotation = angle - bone.Parent.WorldRotation
		EndIf
		
		'flag dirty
		dirty = True
	End
	
	Method GetBoneRotation:Float(name:String, world:Bool = False)
		' --- return bone rotation for a given bone ---
		'must be applied after calling Update() on entity
		'lookup bone
		Local bone:= GetBone(name)
		If bone = Null Return 0.0
		
		'must calculate first
		Calculate()
		
		'return it world or local?
		If world Return bone.WorldRotation
		Return bone.Rotation
	End
	
	'bone scale api
	Method SetBoneScale:Void(name:String, scaleX:Float, scaleY:Float, world:Bool = False)
		' --- set scale of bone ---
		'must be applied after calling Update() on entity
		
		'lookup bone
		Local bone:= GetBone(name)
		If bone = Null Return
		
		'world or local
		If world = False or bone.Parent = Null
			'local 
			bone.ScaleX = scaleX
			bone.ScaleY = scaleY
		Else
			'do calculation first
			Calculate()
			
			'work out a scale based on parent scale
			bone.ScaleX = scaleX / bone.Parent.WorldScaleX
			bone.ScaleY = scaleY / bone.Parent.WorldScaleY
		EndIf
		
		'flag dirty
		dirty = True
	End

	Method SetBoneScale:Void(name:String, scaleXY:Float, world:Bool = False)
		' -- overide to pass in single value ---
		SetBoneScale(name, scaleXY, scaleXY, world)
	End
		
	Method SetBoneScale:Void(name:String, scaleXY:Float[], world:Bool = False)
		' -- overide to pass in array ---
		SetBoneScale(name, scaleXY[0], scaleXY[1], world)
	End
	
	Method GetBoneScale:Float[] (name:String, world:Bool = False)
		' --- get scale of bone ---
		'lookup bone
		Local bone:= GetBone(name)
		If bone = Null Return[0.0, 0.0]
		
		'must calculate first
		Calculate()
		
		'return
		If world Return[bone.WorldScaleX, bone.WorldScaleY]
		Return[bone.ScaleX, bone.ScaleY]
	End
	
	Method GetBoneScale:Void(name:String, scaleXY:Float[], world:Bool = False)
		' --- get scale of bone ---
		'lookup bone
		Local bone:= GetBone(name)
		If bone = Null
			scaleXY[0] = 0.0
			scaleXY[1] = 1.0
			Return
		EndIf
		
		'must calculate first
		Calculate()
		
		'return
		If world
			scaleXY[0] = bone.WorldScaleX
			scaleXY[1] = bone.WorldScaleY
		Else
			scaleXY[0] = bone.ScaleX
			scaleXY[1] = bone.ScaleY
		EndIf
	End
	
	Method GetBoneScaleX:Float(name:String, world:Bool = False)
		' --- get scale of bone ---
		'lookup bone
		Local bone:= GetBone(name)
		If bone = Null Return 0.0
		
		'must calculate first
		Calculate()
		
		'return
		If world Return bone.WorldScaleX
		Return bone.ScaleX
	End
	
	Method GetBoneScaleY:Float(name:String, world:Bool = False)
		' --- get scale of bone ---
		'lookup bone
		Local bone:= GetBone(name)
		If bone = Null Return 0.0
		
		'must calculate first
		Calculate()
		
		'return
		If world Return bone.WorldScaleY
		Return bone.ScaleY
	End
	
	'state api
	Method Calculate:Void(force:Bool = False)
		' --- this will calculate the entity ---
		If force or dirty OnCalculate()
	End
	
	Method CalculateBounding:Void(force:Bool = False)
		' --- call this to calculate bounding ---
		If force or dirtyBounding
			'first we calculate (if there are calculations to be made)
			Calculate()
			
			'now we calculate bounding
			OnCalculateBounding()
		EndIf
	End
	
	Method Update:Void(delta:Float)
		' --- update this entity ---
		'only update if not updating or rendering
		If updating or rendering Return
		updating = True
		OnUpdate(delta)
		updating = False
	End
	
	Method Render:Void()
		' --- render the entity --
		'only render if not rendering or updating
		If rendering or updating Return
		rendering = True
		OnRender()
		rendering = False
	End
	
	'api
	Method GetName:String()
		' --- return name of skeleton ---
		Return skeleton.Data.Name
	End
	
	Method SetCallback:Void(callback:SpineEntityCallback)
		' --- change the callback ---
		Self.callback = callback
	End
End
