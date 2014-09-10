'see license.txt for source licenses
Strict

Import spine

'interface to handle spine entity notifications
Interface SpineEntityCallback
	Method OnSpineEntityAnimationComplete:Void(entity:SpineEntity, name:String)
	Method OnSpineEntityEvent:Void(entity:SpineEntity, event:String, intValue:Int, floatValue:Float, stringValue:String)
End

'class to wrap spine
Class SpineEntity
	Global tempVertices:Float[8]
	
	Field atlas:SpineAtlas
	Field data:SpineSkeletonData
	Field skeleton:SpineSkeleton
	
	Private
	Field callback:SpineEntityCallback
	
	Field animation:SpineAnimation
	Field mixAnimation:SpineAnimation
	Field mixAmount:Float
	Field mixLooping:Bool
	
	Field speed:Float = 1.0
	Field playing:Bool
	Field looping:Bool
	Field finished:Bool
	
	Field snapToPixels:Bool = False
	
	#If SPINE_DEBUG_RENDER = True
	Field debugOutline:Bool = False
	Field debugMesh:Bool = False
	Field debugSlots:Bool = False
	Field debugBones:Bool = False
	Field debugBounding:Bool = False
	Field debugHideImages:Bool = False
	#EndIf
	
	Field updating:Bool = False
	Field rendering:Bool = False
	
	Field dirty:Bool
	Field dirtyBounding:Bool
	
	Field slotBoundingVertices:Float[][]
	Field slotWorldX:Float[]
	Field slotWorldY:Float[]
	Field slotWorldRotation:Float[]
	Field slotWorldScaleX:Float[]
	Field slotWorldScaleY:Float[]
	Field slotWorldR:Float[]
	Field slotWorldG:Float[]
	Field slotWorldB:Float[]
	Field slotWorldAlpha:Float[]
	
	Field bounding:Float[8]
	
	Field events:= New List<SpineEvent>
	
	Field x:Float = 0.0
	Field y:Float = 0.0
	Field scaleX:Float = 1.0
	Field scaleY:Float = 1.0
	Field rotation:Float = 0.0
	Field flipX:Bool
	Field flipY:Bool
	
	Field lastTime:Float
	Field lastSlotLookupName:String
	Field lastSlotLookup:SpineSlot
	Field lastBoneLookupName:String
	Field lastBoneLookup:SpineBone
	Public
	
	'constructor/destructor
	'there are lots of variations here to make it easy to use
	Method New(skeletonPath:String, atlasPath:String, atlasDir:String, fileLoader:SpineFileLoader, atlasLoader:SpineAtlasLoader, textureLoader:SpineTextureLoader)
		'load the atlas
		Local atlasFile:= fileLoader.Load(atlasPath)
		Local atlas:= atlasLoader.Load(atlasFile, atlasDir, textureLoader)
		atlasFile.Close()
		
		'load the skelton data
		Local skeletonFile:= fileLoader.Load(skeletonPath)
		Local skeletonJson:= New SpineSkeletonJson(atlas, skeletonFile)
		data = skeletonJson.ReadSkeletonData()
		
		'create the skeleton
		skeleton = New SpineSkeleton(data)
		skeleton.SetToSetupPose()
		
		'create slot arrays so we dont have to polute the spine lib files
		Local index:Int
		Local total:= data.Slots.Length()
		slotBoundingVertices = New Float[total][]
		slotWorldX = New Float[total]
		slotWorldY = New Float[total]
		slotWorldRotation = New Float[total]
		slotWorldScaleX = New Float[total]
		slotWorldScaleY = New Float[total]
		slotWorldR = New Float[total]
		slotWorldG = New Float[total]
		slotWorldB = New Float[total]
		slotWorldAlpha = New Float[total]
		
		'fill slot arrays
		For index = 0 Until total
			slotBoundingVertices[index] = New Float[8]
		Next
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
		
		'update the skeleton properties
		skeleton.FlipX = flipX
		skeleton.FlipY = flipY
		skeleton.X = x
		skeleton.Y = y
		
		'update skeleton
		skeleton.UpdateWorldTransform()
				
		'update attachments
		Local slot:SpineSlot
		Local attachment:SpineAttachment
		Local total:= skeleton.Slots.Length()
		Local slotArray1:Float[]
		For Local index:= 0 Until total
			slot = skeleton.Slots[index]
			attachment = slot.Attachment
			
			'update bounding
			slotArray1 = slotBoundingVertices[index]
			Select attachment.Type
				Case SpineAttachmentType.boundingbox
				Case SpineAttachmentType.mesh
					'Local mesh:= SpineMeshAttachment(attachment)
					'SpineGetPolyBounding(mesh.Vertices, slotArray1)
					
				Case SpineAttachmentType.region
					Local region:= SpineRegionAttachment(attachment)
					Local bone:= slot.Bone

					'get world properties
					slotWorldX[index] = skeleton.X + bone.WorldX + region.X * bone.M00 + region.Y * bone.M01
					slotWorldY[index] = skeleton.Y + bone.WorldY + region.X * bone.M10 + region.Y * bone.M11
					slotWorldRotation[index] = bone.WorldRotation + region.Rotation
					slotWorldScaleX[index] = bone.WorldScaleX + region.ScaleX - 1.0
					slotWorldScaleY[index] = bone.WorldScaleY + region.ScaleY - 1.0
					
					'SpineGetPolyBounding(mesh.Vertices, slotArray1)
					
				Case SpineAttachmentType.skinnedmesh
					'Local mesh:= SpineSkinnedMeshAttachment(attachment)
					'SpineGetPolyBounding(mesh.Vertices, slotArray1)
			End
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
		Local slot:SpineSlot
		Local attachment:SpineAttachment
		
		'iterate over visible elements
		For Local index:= 0 Until skeleton.Slots.Length()
			'get slot
			slot = skeleton.Slots[index]
			
			'skip if not attachment
			attachment = slot.Attachment
			If attachment = Null Continue

			'we can use bounds of each item
			attachment.GetBounding()
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
			lastTime = skeleton.Time
			skeleton.Update(delta * speed)
			
			'reset the draw order
			'skeleton.ResetSlotOrder()
						
			'we now pass in an events list
			animation.Apply(skeleton, lastTime, skeleton.Time, events, looping)
			
			'mix in animations
			If mixAnimation mixAnimation.Mix(skeleton, lastTime, skeleton.Time, looping, events, mixAmount)
			
			'flag dirty as its dirty!
			dirty = True
			
			'need to process events
			OnProcessEvents()
						
			'check for completion of animation
			If skeleton.Time >= animation.Duration
				If looping = False
					StopAnimation()
					finished = True
				
					'fire callback
					If callback callback.OnSpineEntityAnimationComplete(Self, animation.Name)
				Else
					'reset time
					'skeleton.SetToSetupPose()'dont do this because it messes up teh animation
					'this has been disabled because the spine system deals with it anyway!
					'skeleton.Time = 0.0
					'skeleton.LastTime = 0.0
				EndIf
			EndIf
		EndIf
	End
	
	Method OnProcessEvents:Void()
		' --- process the internal events list ---
		'check for firing of events
		If events.IsEmpty() = False
			'iterate over all events that were fired
			Local node:= events.FirstNode()
			Local event:SpineEvent
			While node
				'get event
				event = node.Value()
				
				'fire it to callback
				If callback callback.OnSpineEntityEvent(Self, event.Data.Name, event.IntValue, event.FloatValue, event.StringValue)
				
				'next event
				node = node.NextNode()
			Wend
			
			'make sure to clear the event list afterwards
			events.Clear()
		EndIf
	End
	
	Method OnRender:Void()
		' --- render the entity ---
		Local index:Int
		Local slot:SpineSlot
		Local attachment:SpineAttachment
		Local total:Int
				
		'calculate again just incase something has changed
		'this wont do any calculation if the entity has not been flagged as dirty!
		Calculate()
		
		'render images
		total = skeleton.DrawOrder.Length()
		For index = 0 Until total
			'get slot
			slot = skeleton.DrawOrder[index]
			attachment = slot.Attachment
				
			'skip if not a valid region
			If attachment = Null Continue
				
			'draw it
			Select attachment.Type
				Case SpineAttachmentType.mesh
					Local verts:Float[12]
					Local mesh:= SpineMeshAttachment(attachment)
					Local vertices:Float[mesh.Vertices.Length()]
					Local rendererObject:SpineRendererObject = mesh.RendererObject
					Local uvs:= mesh.UVs
					Local vertIndex:Int
					Local vertOffset:Int
					Local triangleOFfset:Int
					mesh.ComputeWorldVertices(slot, vertices)
					
					For Local triangleIndex:= 0 Until mesh.Triangles.Length() Step 3
						'build triangle verts
						triangleOFfset = 0
						For vertIndex = 0 Until 3
							vertOffset = mesh.Triangles[triangleIndex + vertIndex] * 2
							
							'x,y
							If snapToPixels
								verts[triangleOFfset] = Int(vertices[vertOffset])
								verts[triangleOFfset + 1] = Int(vertices[vertOffset + 1])
							Else
								verts[triangleOFfset] = vertices[vertOffset]
								verts[triangleOFfset + 1] = vertices[vertOffset + 1]
							EndIf
							
							'u,v (ugh have to convert "uvs" into image dimensions..????)
							verts[triangleOFfset + 2] = (rendererObject.width / 1.0) * uvs[vertOffset]
							verts[triangleOFfset + 3] = (rendererObject.height / 1.0) * uvs[vertOffset + 1]
							
							triangleOFfset += 4
						Next
						
						'draw the poly
						rendererObject.Draw(verts)
					Next
					
				Case SpineAttachmentType.region
					Local region:= SpineRegionAttachment(attachment)
					region.RendererObject.Draw(slotWorldX[index], slotWorldY[index], slotWorldRotation[index], slotWorldScaleX[index], slotWorldScaleY[index])
			End
			'mojo.SetColor(attachment.WorldR * 255, attachment.WorldG * 255, attachment.WorldB * 255)
			'mojo.SetAlpha(attachment.WorldAlpha)
			If snapToPixels
				'attachment.RendererObject.Draw(Int(attachment.WorldX), Int(attachment.WorldY), attachment.WorldRotation, attachment.WorldScaleX, attachment.WorldScaleY, -Int(attachment.RendererObject.GetWidth() / 2.0), -Int(attachment.RendererObject.GetHeight() / 2.0), attachment.Vertices)
			Else
				'attachment.RendererObject.Draw(attachment.WorldX, attachment.WorldY, attachment.WorldRotation, attachment.WorldScaleX, attachment.WorldScaleY, - (attachment.RendererObject.GetWidth() / 2.0), -Int(attachment.RendererObject.GetHeight() / 2.0), attachment.Vertices)
			EndIf
		Next
		
		'do debug rendering
		#If SPINE_DEBUG_RENDER = True
		Local vert1:Int
		Local vert2:Int
		Local vert3:Int
		total = skeleton.Slots.Length()
		For index = 0 Until total
			'get slot
			slot = skeleton.Slots[index]
			attachment = slot.Attachment
			
			'skip if not a valid region
			If attachment = Null Continue
						
			Select attachment.Type
				Case SpineAttachmentType.mesh
					Local mesh:= SpineMeshAttachment(attachment)
					Local vertices:Float[mesh.Vertices.Length()]
					mesh.ComputeWorldVertices(slot, vertices)
					
					'bounding
					If debugBounding
						'draw lines rect around bounding of region
						'mojo.SetColor(0, 255, 0)
						'SpineDrawLinePoly(slotBoundingVertices[index])
					EndIf
					
					'mesh
					If debugMesh
						mojo.SetColor(40, 40, 40)
						For Local triangleIndex:= 0 Until mesh.Triangles.Length() Step 3
							vert1 = mesh.Triangles[triangleIndex] * 2
							vert2 = mesh.Triangles[triangleIndex + 1] * 2
							vert3 = mesh.Triangles[triangleIndex + 2] * 2

							DrawLine(vertices[vert1], vertices[vert1 + 1], vertices[vert2], vertices[vert2 + 1])
							DrawLine(vertices[vert2], vertices[vert2 + 1], vertices[vert3], vertices[vert3 + 1])
							DrawLine(vertices[vert3], vertices[vert3 + 1], vertices[vert1], vertices[vert1 + 1])
						Next
					EndIf
					
					'outline
					If debugOutline
						mojo.SetColor(180, 180, 180)
						For Local edgeIndex:= 0 Until mesh.Edges.Length() Step 2
							vert1 = mesh.Edges[edgeIndex]
							vert2 = mesh.Edges[edgeIndex + 1]
							DrawLine(vertices[vert1], vertices[vert1 + 1], vertices[vert2], vertices[vert2 + 1])
						Next
					EndIf
			End
		Next
		#EndIf
		
		#rem
		If debugHideImages = False
			For index = 0 Until skeleton.DrawOrder.Length()
				'get slot
				slot = skeleton.DrawOrder[index]
				
				'skip if not a region attachment
				If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region Continue
				
				'get attachment in correct format
				attachment = SpineRegionAttachment(slot.Attachment)
				
				'draw it
				mojo.SetColor(attachment.WorldR * 255, attachment.WorldG * 255, attachment.WorldB * 255)
				mojo.SetAlpha(attachment.WorldAlpha)
				If snapToPixels
					'attachment.RendererObject.Draw(Int(attachment.WorldX), Int(attachment.WorldY), attachment.WorldRotation, attachment.WorldScaleX, attachment.WorldScaleY, -Int(attachment.RendererObject.GetWidth() / 2.0), -Int(attachment.RendererObject.GetHeight() / 2.0), attachment.Vertices)
				Else
					'attachment.RendererObject.Draw(attachment.WorldX, attachment.WorldY, attachment.WorldRotation, attachment.WorldScaleX, attachment.WorldScaleY, - (attachment.RendererObject.GetWidth() / 2.0), -Int(attachment.RendererObject.GetHeight() / 2.0), attachment.Vertices)
				EndIf
			Next
		EndIf
		
		'render slots
		If debugSlots
			For index = 0 Until skeleton.Slots.Length()
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
			For index = 0 Until skeleton.Bones.Length()
				bone = skeleton.Bones[index]
				DrawLine(bone.WorldX, bone.WorldY, bone.Data.Length * bone.M00 + bone.WorldX, bone.Data.Length * bone.M10 + bone.WorldY)
			Next
			
			'bone origins
			For index = 0 Until skeleton.Bones.Length()
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
		#End
	End
	Public
	
	'main api
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
	
	'debug api
	#If SPINE_DEBUG_RENDER = True
	Method SetDebugDraw:Void(all:Bool, hideImages:Bool = False)
		' --- set debug draw options ---
		debugHideImages = hideImages
		debugOutline = all
		debugSlots = all
		debugBones = all
		debugBounding = all
		debugMesh = all
	End
	
	Method SetDebugDraw:Void(hideImages:Bool, outline:Bool, slots:Bool, bones:Bool, bounding:Bool, mesh:Bool)
		' --- set debug draw options ---
		debugHideImages = hideImages
		debugOutline = outline
		debugSlots = slots
		debugBones = bones
		debugBounding = bounding
		debugMesh = mesh
	End
	
	Method GetDebugDraw:Bool()
		' --- get combined debug state ---
		Return debugHideImages or debugOutline or debugSlots or debugBones or debugBounding or debugMesh
	End
	
	Method GetDebugDrawHideImages:Bool()
		' --- Return state of debug draw ---
		Return debugHideImages
	End
	
	Method GetDebugDrawOutline:Bool()
		' --- Return state of debug draw ---
		Return debugOutline
	End
	
	Method GetDebugDrawSlots:Bool()
		' --- Return state of debug draw ---
		Return debugSlots
	End
	
	Method GetDebugDrawBones:Bool()
		' --- Return state of debug draw ---
		Return debugBones
	End
	
	Method GetDebugDrawBounding:Bool()
		' --- Return state of debug draw ---
		Return debugBounding
	End
	
	Method GetDebugDrawMesh:Bool()
		' --- Return state of debug draw ---
		Return debugMesh
	End
	#EndIf
	
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
				
		'go in reverse order using the zOrder so we Return the attachment closest to screen
		For Local index:= skeleton.DrawOrder.Length() - 1 To 0 Step - 1
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
		
		'Return fail
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
			tempVertices[0] = x
			tempVertices[1] = y
			tempVertices[2] = x + width
			tempVertices[3] = y
			tempVertices[4] = x + width
			tempVertices[5] = y + height
			tempVertices[6] = x
			tempVertices[7] = y + height
		EndIf
				
		'go in reverse order using the zOrder so we Return the attachment closest to screen
		For Local index:= skeleton.DrawOrder.Length() - 1 To 0 Step - 1
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
				If SpinePolyToPoly(tempVertices, attachment.Vertices)
					'here we could go one step further and check pixels.. but no.. not really in current monkey!
					Return True
				EndIf
			EndIf
		Next
		
		'Return fail
		Return False
	End
	
	Method PointInsideSlot:Bool(x:Float, y:Float, name:String, precise:Bool = True)
		' --- shortcut for name lookup ---
		Return PointInsideSlot(x, y, GetSlot(name), precise)
	End
	
	Method PointInsideSlot:Bool(x:Float, y:Float, slot:SpineSlot, precise:Bool = True)
		' --- check if a point is inside using varying levels of precision ---

		'skip if not a region attachment
		If slot = Null or slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region Return False
		
		'calculate first
		CalculateBounding()
						
		'get attachment in correct format
		Local attachment:= SpineRegionAttachment(slot.Attachment)
		
		'need to do a hit test with point
		'first do simple rect test, then poly test
		If SpinePointInRect(x, y, attachment.BoundingVertices)
			If precise = False Return True
			
			'check with rotated polys
			If SpinePointInPoly(x, y, attachment.Vertices)
				'hwere we could go one step further and check pixels.. but no.. not really in current monkey!
				Return True
			EndIf
		EndIf
		
		'Return fail
		Return False
	End
	
	Method RectOverlapsSlot:Bool(x:Float, y:Float, width:Float, height:Float, name:String, precise:Bool = True)
		' --- shortcut for slot lookup ---
		Return RectOverlapsSlot(x, y, width, height, GetSlot(name), precise)
	End
	
	Method RectOverlapsSlot:Bool(x:Float, y:Float, width:Float, height:Float, slot:SpineSlot, precise:Bool = True)
		' --- check if a rect overlaps using varying levels of precision ---
		'skip if not a region attachment
		If slot = Null or slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region Return False
		
		'calculate first
		CalculateBounding()
		
		'check compelte bounding
		If SpineRectsOverlap(x, y, width, height, bounding) = False Return False
				
		'setup temp vertices for poly check
		If precise
			tempVertices[0] = x
			tempVertices[1] = y
			tempVertices[2] = x + width
			tempVertices[3] = y
			tempVertices[4] = x + width
			tempVertices[5] = y + height
			tempVertices[6] = x
			tempVertices[7] = y + height
		EndIf
						
		'get attachment in correct format
		Local attachment:= SpineRegionAttachment(slot.Attachment)
			
		'need to do a hit test with point
		'first do simple rect test, then poly test
		If SpineRectsOverlap(x, y, width, height, attachment.BoundingVertices)
			If precise = False Return True
			
			'check with rotated polys
			If SpinePolyToPoly(tempVertices, attachment.Vertices)
				'here we could go one step further and check pixels.. but no.. not really in current monkey!
				Return True
			EndIf
		EndIf
		
		'Return fail
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
	
	Method RevertColor:Void()
		' --- revert color to its built in value ---
		skeleton.R = 1.0
		skeleton.G = 1.0
		skeleton.B = 1.0
		
		'flag dirty
		dirty = True
	End
	
	Method RevertAlpha:Void()
		' --- revert alpha to its built in value ---
		skeleton.A = 1.0
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
			skeleton.SetToSetupPose()
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
		'clear out the mix
		mixAnimation = Null
		mixAmount = 0.0
		
		'set the current animation
		Self.animation = animation
		skeleton.Time = 0.0
		Self.looping = looping
		finished = False
		playing = True
		
		'apply the animation to the skeleton
		animation.Apply(skeleton, skeleton.Time, skeleton.Time, events, looping)
		skeleton.SetToSetupPose()
		
		'need to process events
		'this will probably never do anything...
		OnProcessEvents()
		
		'flag that the entity is dirty again
		dirty = True
	End
	
	Method MixAnimation:Void(name:String, amount:Float, looping:Bool = False)
		' --- set another animation to mix in ---
		'calling set animation will reset this
		MixAnimation(GetAnimation(name), amount, looping)
	End
	
	Method MixAnimation:Void(animation:SpineAnimation, amount:Float, looping:Bool = False)
		' --- set another animation to mix in ---
		'calling set animation will reset this
		mixAnimation = animation
		mixAmount = amount
		mixLooping = looping
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
		' --- Return teh animation object ---
		Return data.FindAnimation(id)
	End
	
	Method GetAnimationTime:Int()
		' --- Return time of animation ---
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
		' --- Return local position ---
		Return[x, y]
	End
	
	Method GetPosition:Void(xy:Float[])
		' --- Return local position ---
		xy[0] = x
		xy[1] = y
	End
	
	Method GetX:Float()
		' --- Return local position ---
		Return x
	End
	
	Method GetY:Float()
		' --- Return local position ---
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
		' --- Return local scale ---
		Return[scaleX, scaleY]
	End
	
	Method GetScale:Void(scaleXY:Float[])
		' --- Return local scale ---
		scaleXY[0] = scaleX
		scaleXY[1] = scaleY
	End
	
	Method GetScaleX:Float()
		' --- Return local scale ---
		Return scaleX
	End
	
	Method GetScaleY:Float()
		' --- Return local scale ---
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
		' --- Return local angle ---
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
		
		'copy bounding into Return
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
		
		'copy bounding into Return
		For Local index:Int = 0 Until 8
			out[index] = bounding[index]
		Next
	End
	
	'slot api
	Method GetFirstSlot:SpineSlot()
		' --- Return first slot ---
		If skeleton.Slots.Length() = 0 Return Null
		Return skeleton.Slots[0]
	End
	
	Method GetLastSlot:SpineSlot()
		' --- Return last slot ---
		If skeleton.Slots.Length() = 0 Return Null
		Return skeleton.Slots[skeleton.Slots.Length() - 1]
	End
	
	Method GetNextSlot:SpineSlot(slot:SpineSlot)
		' --- get next slot ---
		If slot = Null Return Null
		Local index:= slot.parentIndex + 1
		If index >= skeleton.Slots.Length() Return Null
		Return skeleton.Slots[index]
	End
	
	Method GetPreviousSlot:SpineSlot(slot:SpineSlot)
		' --- get previous slot ---
		If slot = Null Return Null
		Local index:= slot.parentIndex - 1
		If index < 0 Return Null
		Return skeleton.Slots[index]
	End
		
	Method GetSlot:SpineSlot(name:String)
		' --- find a slot by name ---
		'check for quick lookup
		If name = lastSlotLookupName Return lastSlotLookup
		
		'lookup
		lastSlotLookupName = name
		lastSlotLookup = skeleton.FindSlot(lastSlotLookupName)
		Return lastSlotLookup
	End
	
	Method FindFirstSlotWithAttachment:SpineSlot()
		' --- Return first slot with attachment ---
		If skeleton.Slots.Length() = 0 Return Null
		
		Local attachment:SpineRegionAttachment
		For Local index:= 0 Until skeleton.Slots.Length()
			attachment = SpineRegionAttachment(skeleton.Slots[index].Attachment)
			If attachment Return skeleton.Slots[index]
		Next
		
		Return Null
	End
	
	Method FindLastSlotWithAttachment:SpineSlot()
		' --- Return last slot with attachment ---
		If skeleton.Slots.Length() = 0 Return Null
		
		Local attachment:SpineRegionAttachment
		For Local index:= skeleton.Slots.Length() - 1 To 0 Step - 1
			attachment = SpineRegionAttachment(skeleton.Slots[index].Attachment)
			If attachment Return skeleton.Slots[index]
		Next
		
		Return Null
	End
	
	Method FindNextSlotWithAttachment:SpineSlot(slot:SpineSlot)
		' --- Return next slot with attachment ---
		If slot = Null or skeleton.Slots.Length() = 0 or slot.parentIndex + 1 >= skeleton.Slots.Length() Return Null
		
		Local attachment:SpineRegionAttachment
		For Local index:= slot.parentIndex + 1 Until skeleton.Slots.Length()
			attachment = SpineRegionAttachment(skeleton.Slots[index].Attachment)
			If attachment Return skeleton.Slots[index]
		Next
		
		Return Null
	End
	
	Method FindPreviousSlotWithAttachment:SpineSlot(slot:SpineSlot)
		' --- Return previous slot with attachment ---
		If slot = Null or skeleton.Slots.Length() = 0 or slot.parentIndex - 1 < 0 Return Null
		
		Local attachment:SpineRegionAttachment
		For Local index:= slot.parentIndex - 1 To 0 Step - 1
			attachment = SpineRegionAttachment(skeleton.Slots[index].Attachment)
			If attachment Return skeleton.Slots[index]
		Next
		
		Return Null
	End
	
	Method FindSlotWithAttachment:SpineSlot(name:String, ignoreInvisible:Bool = False)
		' --- find a slot that contains an attachment ---
		'do it
		Local index:Int
		Local slot:SpineSlot
		Local attachment:SpineRegionAttachment
		
		'go in reverse order using the zOrder so we Return the attachment closest to screen
		For index = skeleton.DrawOrder.Length() - 1 To 0 Step - 1
			'get slot
			slot = skeleton.DrawOrder[index]
			
			'skip if not a region attachment
			If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region Continue
			
			'get attachment in correct format
			attachment = SpineRegionAttachment(slot.Attachment)
			
			'need to do a hit test with point
			If (ignoreInvisible = False or attachment.WorldAlpha > 0.0) Return slot
		Next
		
		'Return nothing found
		Return Null		
	End
	
	Method FindSlotAtPoint:SpineSlot(x:Float, y:Float, ignoreInvisible:Bool = True)
		' --- this will Return the highest zorder attachment at point ---
		'only region attachments will Return
		'need to calculate first (wont do anything if not flagged as dirty)
		'this will also cause a calculate()
		CalculateBounding()
		
		'check we are within full bounding of entity first (nice n quick!)
		If SpinePointInRect(x, y, bounding) = False Return Null
	
		'do it
		Local index:Int
		Local slot:SpineSlot
		Local attachment:SpineRegionAttachment
				
		'go in reverse order using the zOrder so we Return the attachment closest to screen
		For index = skeleton.DrawOrder.Length() - 1 To 0 Step - 1
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
		
		'Return nothing found
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
		Return[Int(slot.R * 255), Int(slot.G * 255), Int(slot.B * 255)]
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
	
	Method GetSlotAlpha:Float(name:String)
		' --- change the alpha of a slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null Return 0.0
		Return slot.A
	End
	
	Method SetSlotAlpha:Void(name:String, alpha:Float)
		' --- change the alpha of a slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null Return
		
		slot.A = alpha
		
		'flag dirty
		dirty = True
	End
	
	'slot position api
	Method GetSlotPosition:Float[] (name:String, world:Bool = False)
		' --- this will Return the position of the given slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null Return[0.0, 0.0]
		
		'must calculate first
		Calculate()
		
		'Return bone if slot doesn't have a psotional attachment
		If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region
			'world or local?
			If world Return[slot.Bone.WorldX, slot.Bone.WorldY]
			Return[0.0, 0.0]
		EndIf
		
		'Return attachment psotion
		Local attachment:= SpineRegionAttachment(slot.Attachment)
		
		'world or local?
		If world Return[attachment.WorldX, attachment.WorldY]
		Return[attachment.X, attachment.Y]
	End
	
	Method GetSlotPosition:Void(name:String, xy:Float[], world:Bool = False)
		' --- this will Return the position of the given slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null
			xy[0] = 0.0
			xy[1] = 0.0
			Return
		EndIf
		
		'must calculate first
		Calculate()
		
		'Return bone if slot doesn't have a psotional attachment
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
		
		'Return attachment psotion
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
		' --- this will Return the position of the given slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null Return 0.0
		
		'must calculate first
		Calculate()
		
		'Return bone if slot doesn't have a psotional attachment
		If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region
			'world or local?
			If world Return slot.Bone.WorldX
			Return 0.0
		EndIf
		
		'Return attachment psotion
		Local attachment:= SpineRegionAttachment(slot.Attachment)
		
		'world or local?
		If world Return attachment.WorldX
		Return attachment.X
	End
	
	Method GetSlotY:Float(name:String, world:Bool = False)
		' --- this will Return the position of the given slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null Return 0.0
		
		'must calculate first
		Calculate()
		
		'Return bone if slot doesn't have a psotional attachment
		If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region
			'world or local?
			If world Return slot.Bone.WorldY
			Return 0.0
		EndIf
		
		'Return attachment psotion
		Local attachment:= SpineRegionAttachment(slot.Attachment)
		
		'world or local?
		If world Return attachment.WorldY
		Return attachment.Y
	End
	
	'slot rotation api
	Method GetSlotRotation:Float(name:String, world:Bool = False)
		' --- Return bone rotation for a given slot ---
		'must be applied after calling Update() on entity
		'lookup slot
		Local slot:= GetSlot(name)
		If slot = Null Return 0.0
		
		'must calculate first
		Calculate()
		
		'Return bone if slot doesn't have a psotional attachment
		If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region
			'world or local?
			If world Return slot.Bone.WorldRotation
			Return 0.0
		EndIf
			
		'Return attachment rotation
		Local attachment:= SpineRegionAttachment(slot.Attachment)
		
		'world or local?
		If world Return attachment.WorldRotation
		Return attachment.Rotation
	End
	
	'slot scale api
	Method GetSlotScale:Float[] (name:String, world:Bool = False)
		' --- this will Return the position of the given slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null Return[0.0, 0.0]
		
		'must calculate first
		Calculate()
		
		'Return bone if slot doesn't have a psotional attachment
		If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region
			'world or local?
			If world Return[slot.Bone.WorldScaleX, slot.Bone.WorldScaleY]
			Return[0.0, 0.0]
		EndIf
		
		'Return attachment scale
		Local attachment:= SpineRegionAttachment(slot.Attachment)
		
		'world or local?
		If world Return[attachment.WorldScaleX, attachment.WorldScaleY]
		Return[attachment.ScaleX, attachment.ScaleY]
	End
	
	Method GetSlotScale:Void(name:String, scaleXY:Float[], world:Bool = False)
		' --- this will Return the position of the given slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null
			scaleXY[0] = 0.0
			scaleXY[1] = 0.0
			Return
		EndIf
		
		'must calculate first
		Calculate()
		
		'Return bone if slot doesn't have a psotional attachment
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
		
			'Return attachment scale
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
		' --- this will Return the position of the given slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null Return 0.0
		
		'must calculate first
		Calculate()
		
		'Return bone if slot doesn't have a psotional attachment
		If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region
			'world or local?
			If world Return slot.Bone.WorldScaleX
			Return 0.0
		EndIf
		
		'Return attachment scale
		Local attachment:= SpineRegionAttachment(slot.Attachment)
		
		'world or local?
		If world Return attachment.WorldScaleX
		Return attachment.ScaleX
	End
	
	Method GetSlotScaleY:Float(name:String, world:Bool = False)
		' --- this will Return the position of the given slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null Return 0.0
		
		'must calculate first
		Calculate()
		
		'Return bone if slot doesn't have a psotional attachment
		If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.region
			'world or local?
			If world Return slot.Bone.WorldScaleY
			Return 0.0
		EndIf
		
		'Return attachment scale
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
		' --- Return true if bone exists ---
		'this is a lazy way of doing it
		Return GetBone(name) <> Null
	End
	
	Method GetBone:SpineBone(name:String)
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
		
		'Return
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
		
		'Return
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
		
		'Return
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
		
		'Return
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
		' --- Return bone rotation for a given bone ---
		'must be applied after calling Update() on entity
		'lookup bone
		Local bone:= GetBone(name)
		If bone = Null Return 0.0
		
		'must calculate first
		Calculate()
		
		'Return it world or local?
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
		
		'Return
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
		
		'Return
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
		
		'Return
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
		
		'Return
		If world Return bone.WorldScaleY
		Return bone.ScaleY
	End
		
	'api
	Method GetName:String()
		' --- Return name of skeleton ---
		Return skeleton.Data.Name
	End
	
	Method SetSnapToPixels:Void(snap:Bool)
		' --- change if images should be snapped to pixels ---
		Self.snapToPixels = snap
	End
	
	Method SetCallback:Void(callback:SpineEntityCallback)
		' --- change the callback ---
		Self.callback = callback
	End
End
