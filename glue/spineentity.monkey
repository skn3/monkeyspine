'see license.txt For source licenses
Strict

Import spine

'Interface to handle spine entity notifications
Interface SpineEntityCallback
	Method OnSpineEntityAnimationComplete:Void(entity:SpineEntity, name:String)
	Method OnSpineEntityEvent:Void(entity:SpineEntity, event:String, intValue:Int, floatValue:Float, stringValue:String)
End

'Class to wrap spine
Class SpineEntity
	Global tempVertices:Float[8]
	Global tempSnapToIntTriangles:Float[]
	
	Field atlas:SpineAtlas
	Field data:SpineSkeletonData
	Field skeleton:SpineSkeleton
	
	Private

	Field atlasScale:Float = 1.0

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
	Field ignoreRootPosition:Bool = False
	
	#If SPINE_DEBUG_RENDER = True
	Field debugHull:Bool = False
	Field debugMesh:Bool = False
	Field debugSlots:Bool = False
	Field debugBones:Bool = False
	Field debugBounding:Bool = False
	Field debugHideImages:Bool = False
	#EndIf
	
	Field updating:Bool = False
	Field rendering:Bool = False
	
	Field dirty:= True
	Field dirtyBounding:= True
	Field dirtyPose:= True
	
	Field slotWorldBounding:Float[][]
	Field slotWorldVertices:Float[][]
	Field slotWorldVerticesLength:Int[]
	Field slotWorldTriangleVerts:Float[][]
	Field slotWorldTriangleUVs:Float[][]
	Field slotWorldTriangleTotals:Int[]
	Field slotWorldHull:Float[][]
	Field slotWorldHullLength:Int[]
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
	
	Field lastTime:Float
	Field lastSlotLookupIndex:Int
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
		atlas = atlasLoader.Load(atlasFile, atlasDir, textureLoader)
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
		slotWorldBounding = New Float[total][]
		
		slotWorldVertices = New Float[total][]
		slotWorldVerticesLength = New Int[total]
		
		slotWorldTriangleVerts = New Float[total][]
		slotWorldTriangleUVs = New Float[total][]
		slotWorldTriangleTotals = New Int[total]
		
		slotWorldHull = New Float[total][]
		slotWorldHullLength = New Int[total]
		
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
			slotWorldBounding[index] = New Float[8]
		Next
	End
		
	Method Free:Void()
		' --- free the spine entity ---
		'decrease reference count For atlas
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
		
		'store values
		Local rootBone:= skeleton.RootBone()
		If rootBone
			Local length:Int
			Local oldRootX:= rootBone.X
			Local oldRootY:= rootBone.Y
			Local oldRootScaleX:= rootBone.ScaleX
			Local oldRootScaleY:= rootBone.ScaleY
			Local oldRootRotation:= rootBone.Rotation
			
			'update the skeleton/root bone properties
			If ignoreRootPosition
				rootBone.X = x
				rootBone.Y = y
			Else
				rootBone.X = oldRootX + x
				rootBone.Y = oldRootY + y
			EndIf
			rootBone.ScaleX = oldRootScaleX * scaleX
			rootBone.ScaleY = oldRootScaleY * scaleY
			rootBone.Rotation = oldRootRotation + rotation
					
			'let spine update
			skeleton.UpdateWorldTransform()
			
			'update attachments
			Local slot:SpineSlot
			Local attachment:SpineAttachment
			Local bone:SpineBone
			Local totalSlots:= skeleton.Slots.Length()
			Local worldTriangleOffset:Int
			Local vertIndex:Int
			Local vertOffset:Int
			
			For Local slotIndex:= 0 Until totalSlots
				slot = skeleton.Slots[slotIndex]
				attachment = slot.Attachment
				
				If attachment = Null Continue
				
				'update attachment specifics
				Select attachment.Type
					Case SpineAttachmentType.BoundingBox
						Local box:= SpineBoundingBoxAttachment(attachment)
						
						'vertices
						length = box.Vertices.Length()
						slotWorldVerticesLength[slotIndex] = length
						If length > slotWorldVertices[slotIndex].Length() slotWorldVertices[slotIndex] = New Float[length]
						box.ComputeWorldVertices(slot.Bone, slotWorldVertices[slotIndex])
						
						'hull
						OnCalculateWorldHull(slotIndex, length)
						
					Case SpineAttachmentType.Region
						Local region:= SpineRegionAttachment(attachment)
						bone = slot.Bone
						
						'vertices
						length = 8
						slotWorldVerticesLength[slotIndex] = length
						If length > slotWorldVertices[slotIndex].Length()
							slotWorldVertices[slotIndex] = New Float[length]
						EndIf
						
						region.ComputeWorldVertices(slot.Bone, slotWorldVertices[slotIndex])
						
						'get world properties
						slotWorldX[slotIndex] = bone.WorldX + region.X * bone.M00 + region.Y * bone.M01
						slotWorldY[slotIndex] = bone.WorldY + region.X * bone.M10 + region.Y * bone.M11
						slotWorldRotation[slotIndex] = bone.WorldRotation + region.Rotation
						slotWorldScaleX[slotIndex] = bone.WorldScaleX * region.ScaleX
						slotWorldScaleY[slotIndex] = bone.WorldScaleY * region.ScaleY
		
						'do we need to flip it?
						If skeleton.FlipX
							slotWorldScaleX[slotIndex] = -slotWorldScaleX[slotIndex]
							slotWorldRotation[slotIndex] = -slotWorldRotation[slotIndex]
						EndIf
						If skeleton.FlipY
							slotWorldScaleY[slotIndex] = -slotWorldScaleY[slotIndex]
							slotWorldRotation[slotIndex] = -slotWorldRotation[slotIndex]
						EndIf
						
						'color
						OnCalculateWorldColor(slot, slotIndex)
						
						'hull
						length = 8
						slotWorldHullLength[slotIndex] = length
						If length > slotWorldHull[slotIndex].Length() slotWorldHull[slotIndex] = New Float[length]
						slotWorldHull[slotIndex][0] = slotWorldVertices[slotIndex][0]
						slotWorldHull[slotIndex][1] = slotWorldVertices[slotIndex][1]
						slotWorldHull[slotIndex][2] = slotWorldVertices[slotIndex][2]
						slotWorldHull[slotIndex][3] = slotWorldVertices[slotIndex][3]
						
						slotWorldHull[slotIndex][4] = slotWorldVertices[slotIndex][4]
						slotWorldHull[slotIndex][5] = slotWorldVertices[slotIndex][5]
						slotWorldHull[slotIndex][6] = slotWorldVertices[slotIndex][6]
						slotWorldHull[slotIndex][7] = slotWorldVertices[slotIndex][7]
						
					Case SpineAttachmentType.Mesh
						Local mesh:= SpineMeshAttachment(attachment)
						
						'vertices
						length = mesh.Vertices.Length()
						slotWorldVerticesLength[slotIndex] = length
						If length = 0
							slotWorldTriangleTotals[slotIndex] = 0
							Continue
						EndIf
						
						If length > slotWorldVertices[slotIndex].Length()
							slotWorldVertices[slotIndex] = New Float[length]
						EndIf
						mesh.ComputeWorldVertices(slot, slotWorldVertices[slotIndex])
						
						'triangles
						slotWorldTriangleTotals[slotIndex] = (mesh.Triangles.Length() / 3)
						
						length = slotWorldTriangleTotals[slotIndex] * 6
						
						If length > slotWorldTriangleVerts[slotIndex].Length()
							slotWorldTriangleVerts[slotIndex] = New Float[length]
							slotWorldTriangleUVs[slotIndex] = New Float[length]
						EndIf
												
						worldTriangleOffset = 0
						For Local triangleIndex:= 0 Until slotWorldTriangleTotals[slotIndex] * 3 Step 3
							'build triangle verts
							For vertOffset = 0 Until 3
								vertIndex = mesh.Triangles[triangleIndex + vertOffset] * 2
				
								slotWorldTriangleVerts[slotIndex][worldTriangleOffset] = slotWorldVertices[slotIndex][vertIndex]
								slotWorldTriangleVerts[slotIndex][worldTriangleOffset + 1] = slotWorldVertices[slotIndex][vertIndex + 1]
								slotWorldTriangleUVs[slotIndex][worldTriangleOffset] = mesh.UVs[vertIndex]
								slotWorldTriangleUVs[slotIndex][worldTriangleOffset + 1] = mesh.UVs[vertIndex + 1]
							
								worldTriangleOffset += 2
							Next
						Next
						
						'color
						OnCalculateWorldColor(slot, slotIndex)
						
						'hull
						'If slot.Data.Name = "head" DebugStop()
						OnCalculateWorldHull(slotIndex, mesh.HullLength)
						
					Case SpineAttachmentType.SkinnedMesh
						Local mesh:= SpineSkinnedMeshAttachment(attachment)
						
						'vertices
						'have to count vertices using same method as in skinnedmeshattachment compute world vertices
						length = 0
						Local v:= 0
						Local n:= mesh.Bones.Length()
						Local nn:Int
						While v < n
							nn = mesh.Bones[v] + v
							v += (nn - (v + 1)) + 2
							length += 2
						Wend

						slotWorldVerticesLength[slotIndex] = length
						If length = 0
							slotWorldTriangleTotals[slotIndex] = 0
							Continue
						EndIf
						
						If length > slotWorldVertices[slotIndex].Length()
							slotWorldVertices[slotIndex] = New Float[length]
						EndIf
						mesh.ComputeWorldVertices(slot, slotWorldVertices[slotIndex])
						
						'triangles
						slotWorldTriangleTotals[slotIndex] = (mesh.Triangles.Length() / 3)
						
						length = slotWorldTriangleTotals[slotIndex] * 6
						
						If length > slotWorldTriangleVerts[slotIndex].Length()
							slotWorldTriangleVerts[slotIndex] = New Float[length]
							slotWorldTriangleUVs[slotIndex] = New Float[length]
						EndIf
												
						worldTriangleOffset = 0
						For Local triangleIndex:= 0 Until slotWorldTriangleTotals[slotIndex] * 3 Step 3
							'build triangle verts
							For vertOffset = 0 Until 3
								vertIndex = mesh.Triangles[triangleIndex + vertOffset] * 2
				
								slotWorldTriangleVerts[slotIndex][worldTriangleOffset] = slotWorldVertices[slotIndex][vertIndex]
								slotWorldTriangleVerts[slotIndex][worldTriangleOffset + 1] = slotWorldVertices[slotIndex][vertIndex + 1]
								slotWorldTriangleUVs[slotIndex][worldTriangleOffset] = mesh.UVs[vertIndex]
								slotWorldTriangleUVs[slotIndex][worldTriangleOffset + 1] = mesh.UVs[vertIndex + 1]
								'DebugStop()
							
								worldTriangleOffset += 2
							Next
						Next
						
						'color
						OnCalculateWorldColor(slot, slotIndex)
						
						'hull
						OnCalculateWorldHull(slotIndex, mesh.HullLength)
				End
			Next
			
			'restore
			rootBone.X = oldRootX
			rootBone.Y = oldRootY
			rootBone.ScaleX = oldRootScaleX
			rootBone.ScaleY = oldRootScaleY
			rootBone.Rotation = oldRootRotation
			
			'flag bounding as dirty
			dirtyBounding = True
		EndIf
	End
	
	Method OnCalculateWorldColor:Void(slot:SpineSlot, index:Int)
		slotWorldR[index] = skeleton.R * slot.R
		slotWorldG[index] = skeleton.G * slot.G
		slotWorldB[index] = skeleton.B * slot.B
		slotWorldAlpha[index] = skeleton.A * slot.A
	End
	
	Method OnCalculateWorldHull:Void(index:Int, hullLength:Int)
		slotWorldHullLength[index] = hullLength
		If hullLength > slotWorldHull[index].Length() slotWorldHull[index] = New Float[hullLength]
		
		Local hull:= slotWorldHull[index]
		Local vertices:= slotWorldVertices[index]
		For Local vertIndex:= 0 Until hullLength
			hull[vertIndex] = vertices[vertIndex]
		Next
	End
	
	Method OnCalculateBounding:Void()
		' --- calculate bounding ---
		dirtyBounding = False
				
		Local minX:Float = SPINE_MAX_FLOAT
		Local minY:Float = SPINE_MAX_FLOAT
		Local maxX:Float = SPINE_MIN_FLOAT
		Local maxY:Float = SPINE_MIN_FLOAT
		Local slot:SpineSlot
		Local attachment:SpineAttachment
		Local vertices:Float[]
		Local total:Int
		
		'iterate over visible elements
		For Local index:= 0 Until skeleton.Slots.Length()
			'get slot
			slot = skeleton.Slots[index]
			
			'skip empty slots
			attachment = slot.Attachment
			If attachment = Null Continue
			
			total = slotWorldVerticesLength[index]
			If total < 6 Continue
			vertices = slotWorldBounding[index]
			
			'apply slot bounding to overal min/max values
			SpineGetPolyBounding(slotWorldVertices[index], vertices, total)

			'compute min/max
			If vertices[0] < minX minX = vertices[0]
			If vertices[0] > maxX maxX = vertices[0]
			If vertices[1] < minY minY = vertices[1]
			If vertices[1] > maxY maxY = vertices[1]
			If vertices[4] < minX minX = vertices[4]
			If vertices[4] > maxX maxX = vertices[4]
			If vertices[5] < minY minY = vertices[5]
			If vertices[5] > maxY maxY = vertices[5]
		Next

		'set entity bounding
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
			If delta <> 0.0 skeleton.Update(delta * speed)
			
			'reset the skeleton
			skeleton.SetBonesToSetupPose()
			
			'we now pass in an events list
			animation.Apply(skeleton, lastTime, skeleton.Time, events, looping)
			
			'mix in animations
			If mixAnimation mixAnimation.Mix(skeleton, lastTime, skeleton.Time, looping, events, mixAmount)
			
			'flag dirty as its dirty!
			dirty = True
			
			'need to process events
			OnProcessEvents()
						
			'check For completion of animation
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
		'check For firing of events
		If events.IsEmpty() = False
			'iterate over all events that were fired
			Local node:= events.FirstNode()
			Local event:SpineEvent
			While node
				'get event
				event = node.Value()
				
				'fire it to callback
				If callback callback.OnSpineEntityEvent(Self, event.Data.Name, event.IntValue, event.FloatValue, event.StringValue)
				
				'Next event
				node = node.NextNode()
			Wend
			
			'make sure to clear the event list afterwards
			events.Clear()
		EndIf
	End
	
	Method OnRender:Void(target:DrawList)
		' --- render the entity ---
		Local index:Int
		Local subIndex:Int
		Local slot:SpineSlot
		Local attachment:SpineAttachment
		Local total:Int
		Local length:Int
				
		'calculate again just incase something has changed
		'this wont do any calculation if the entity has not been flagged as dirty!
		Calculate()
		
		'render images
		#If SPINE_DEBUG_RENDER = True
		If debugHideImages = False
		#EndIf
		total = skeleton.DrawOrder.Length()
		For index = 0 Until total
			'get slot
			slot = skeleton.DrawOrder[index]
			attachment = slot.Attachment
				
			'skip if not a valid region
			If attachment = Null Continue
				
			'draw it
			Select attachment.Type
				Case SpineAttachmentType.Region
					Local region:= SpineRegionAttachment(attachment)
					
					'apply color
					target.SetColor(slotWorldR[index], slotWorldG[index], slotWorldB[index], slotWorldAlpha[index])
					
					'render
					If snapToPixels
						region.RenderObject.Draw(target, Int(slotWorldX[index]), Int(slotWorldY[index]), slotWorldRotation[index], slotWorldScaleX[index], slotWorldScaleY[index], Self.atlasScale)
					Else
						region.RenderObject.Draw(target, slotWorldX[index], slotWorldY[index], slotWorldRotation[index], slotWorldScaleX[index], slotWorldScaleY[index], Self.atlasScale)
					EndIf
					
				Case SpineAttachmentType.Mesh, SpineAttachmentType.SkinnedMesh
					'apply color
					target.SetColor(slotWorldR[index], slotWorldG[index], slotWorldB[index], slotWorldAlpha[index])
					
					'render all as batch
					If snapToPixels
						'need to make int versions of triangle verts
						If tempSnapToIntTriangles.Length < slotWorldTriangleVerts[index].Length
							tempSnapToIntTriangles = New Float[slotWorldTriangleVerts[index].Length]
						EndIf
						For Local snapIndex:= 0 Until slotWorldTriangleVerts[index].Length
							tempSnapToIntTriangles[snapIndex] = Int(slotWorldTriangleVerts[index][snapIndex])
						Next
						
						attachment.RenderObject.Draw(target, tempSnapToIntTriangles, slotWorldTriangleUVs[index], slotWorldTriangleTotals[index])
					Else
						attachment.RenderObject.Draw(target, slotWorldTriangleVerts[index], slotWorldTriangleUVs[index], slotWorldTriangleTotals[index])
					EndIf
					
			End
		Next
		#If SPINE_DEBUG_RENDER = True
		EndIf
		#EndIf
		
		'do debug rendering
		#If SPINE_DEBUG_RENDER = True
		total = skeleton.Slots.Length()
		
		'prpeare some stuff
		If total
			If debugBounding CalculateBounding()
		EndIf
		
		For index = 0 Until total
			'get slot
			slot = skeleton.Slots[index]
			attachment = slot.Attachment
			
			'skip if not a valid region
			If attachment = Null Continue
						
			Select attachment.Type
				Case SpineAttachmentType.BoundingBox, SpineAttachmentType.Mesh, SpineAttachmentType.SkinnedMesh, SpineAttachmentType.Region
					'mesh
					If debugMesh
						length = slotWorldTriangleTotals[index]
						If length > 0
							target.SetColor(0.0, (1.0 / 255) * 229, 1.0)
							If snapToPixels
								For subIndex = 0 Until length Step 6
									target.DrawLine(Int(slotWorldTriangleVerts[index][subIndex]), Int(slotWorldTriangleVerts[index][subIndex + 1]), Int(slotWorldTriangleVerts[index][subIndex + 2]), Int(slotWorldTriangleVerts[index][subIndex + 3]))
									target.DrawLine(Int(slotWorldTriangleVerts[index][subIndex + 2]), Int(slotWorldTriangleVerts[index][subIndex + 3]), Int(slotWorldTriangleVerts[index][subIndex + 4]), Int(slotWorldTriangleVerts[index][subIndex + 5]))
									target.DrawLine(Int(slotWorldTriangleVerts[index][subIndex + 4]), Int(slotWorldTriangleVerts[index][subIndex + 5]), Int(slotWorldTriangleVerts[index][subIndex]), Int(slotWorldTriangleVerts[index][subIndex + 1]))
								Next
							Else
								For subIndex = 0 Until length Step 6
									target.DrawLine(slotWorldTriangleVerts[index][subIndex], slotWorldTriangleVerts[index][subIndex + 1], slotWorldTriangleVerts[index][subIndex + 2], slotWorldTriangleVerts[index][subIndex + 3])
									target.DrawLine(slotWorldTriangleVerts[index][subIndex + 2], slotWorldTriangleVerts[index][subIndex + 3], slotWorldTriangleVerts[index][subIndex + 4], slotWorldTriangleVerts[index][subIndex + 5])
									target.DrawLine(slotWorldTriangleVerts[index][subIndex + 4], slotWorldTriangleVerts[index][subIndex + 5], slotWorldTriangleVerts[index][subIndex], slotWorldTriangleVerts[index][subIndex + 1])
								Next
							EndIf
						EndIf
					EndIf
					
					'hull
					If debugHull
						length = slotWorldHullLength[index]
						If length > 0
							target.SetColor(1.0, 0.0, 0.0)
							SpineDrawLinePoly(target, slotWorldHull[index], slotWorldHullLength[index], snapToPixels)
						EndIf
					EndIf
					
					'bounding
					If debugBounding
						target.SetColor(0.5, 0, 1.0)
						SpineDrawLinePoly(target, slotWorldBounding[index], -1, snapToPixels)
					EndIf
			End
		Next
		
		'bones
		If debugBones
			Local bone:SpineBone
			Local size:Int
			
			'draw line bones
			target.SetColor(0.0, 0.0, 0.0, 1.0)
			length = skeleton.Bones.Length()
			For index = 0 Until length
				bone = skeleton.Bones[index]
				target.DrawLine(bone.WorldX, bone.WorldY, bone.Data.Length * bone.M00 + bone.WorldX, bone.Data.Length * bone.M10 + bone.WorldY)
			Next
			
			'bone origins
			For index = 0 Until length
				bone = skeleton.Bones[index]
				
				If index = 0
					'root bone
					'draw a cross hair
					target.SetColor(0.0, 0.0, 0.0)
					
					size = 8
					target.DrawLine(bone.WorldX - size, bone.WorldY - size, bone.WorldX + size, bone.WorldY - size)
					target.DrawLine(bone.WorldX + size, bone.WorldY - size, bone.WorldX + size, bone.WorldY + size)
					target.DrawLine(bone.WorldX + size, bone.WorldY + size, bone.WorldX - size, bone.WorldY + size)
					target.DrawLine(bone.WorldX - size, bone.WorldY + size, bone.WorldX - size, bone.WorldY - size)
					target.DrawLine(bone.WorldX, bone.WorldY - size + 2, bone.WorldX, bone.WorldY + size + 2)
					target.DrawLine(bone.WorldX - size+2, bone.WorldY, bone.WorldX + size+2, bone.WorldY)
				Else
					'other bones
					'draw just a box
					target.SetColor(0.0, 0.0, 1.0)

					size = 4
					target.DrawLine(bone.WorldX - size, bone.WorldY - size, bone.WorldX + size, bone.WorldY - size)
					target.DrawLine(bone.WorldX + size, bone.WorldY - size, bone.WorldX + size, bone.WorldY + size)
					target.DrawLine(bone.WorldX + size, bone.WorldY + size, bone.WorldX - size, bone.WorldY + size)
					target.DrawLine(bone.WorldX - size, bone.WorldY + size, bone.WorldX - size, bone.WorldY - size)
					'target.DrawLine(bone.WorldX, bone.WorldY - size + 2, bone.WorldX, bone.WorldY + size + 2)
					'target.DrawLine(bone.WorldX - size+2, bone.WorldY, bone.WorldX + size+2, bone.WorldY)
				EndIf
			Next
		EndIf
		
		'entity bounding
		If debugBounding
			target.SetColor(0.5, 0, 1.0)
			SpineDrawLinePoly(target, bounding, -1, snapToPixels)
		EndIf
		#EndIf
		
		#rem
		If debugHideImages = False
			For index = 0 Until skeleton.DrawOrder.Length()
				'get slot
				slot = skeleton.DrawOrder[index]
				
				'skip if not a region attachment
				If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.Region Continue
				
				'get attachment in correct format
				attachment = SpineRegionAttachment(slot.Attachment)
				
				'draw it
				target.SetColor(attachment.WorldR, attachment.WorldG, attachment.WorldB,attachment.WorldAlph)
				If snapToPixels
					'attachment.RenderObject.Draw(target,Int(attachment.WorldX), Int(attachment.WorldY), attachment.WorldRotation, attachment.WorldScaleX, attachment.WorldScaleY, -Int(attachment.RenderObject.GetWidth() / 2.0), -Int(attachment.RenderObject.GetHeight() / 2.0), attachment.Vertices)
				Else
					'attachment.RenderObject.Draw(target,attachment.WorldX, attachment.WorldY, attachment.WorldRotation, attachment.WorldScaleX, attachment.WorldScaleY, - (attachment.RenderObject.GetWidth() / 2.0), -Int(attachment.RenderObject.GetHeight() / 2.0), attachment.Vertices)
				EndIf
			Next
		EndIf
		
		'render slots
		If debugSlots
			For index = 0 Until skeleton.Slots.Length()
				'get slot
				slot = skeleton.Slots[index]
				
				'skip if not a region attachment
				If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.Region Continue
				
				'get attachment in correct format
				attachment = SpineRegionAttachment(slot.Attachment)
				
				'draw lined rect around region
				target.SetColor(0.0, 0.0, 1.0)
				SpineDrawLinePoly(target,attachment.Vertices)
			Next
		EndIf
		
		'render bones
		If debugBones
			Local bone:SpineBone
			
			'draw line bones
			target.SetColor(1.0, 0.0, 0.0,1.0)
			For index = 0 Until skeleton.Bones.Length()
				bone = skeleton.Bones[index]
				target.DrawLine(bone.WorldX, bone.WorldY, bone.Data.Length * bone.M00 + bone.WorldX, bone.Data.Length * bone.M10 + bone.WorldY)
			Next
			
			'bone origins
			For index = 0 Until skeleton.Bones.Length()
				bone = skeleton.Bones[index]
				
				If index = 0
					'root bone
					'draw a cross hair
					target.SetColor(0.0, 0.0, 1.0)
					target.DrawLine(bone.WorldX - 4, bone.WorldY - 4, bone.WorldX + 4, bone.WorldY - 4)
					target.DrawLine(bone.WorldX + 4, bone.WorldY - 4, bone.WorldX + 4, bone.WorldY + 4)
					target.DrawLine(bone.WorldX + 4, bone.WorldY + 4, bone.WorldX - 4, bone.WorldY + 4)
					target.DrawLine(bone.WorldX - 4, bone.WorldY + 4, bone.WorldX - 4, bone.WorldY - 4)
					target.DrawLine(bone.WorldX, bone.WorldY - 6, bone.WorldX, bone.WorldY + 6)
					target.DrawLine(bone.WorldX - 6, bone.WorldY, bone.WorldX + 6, bone.WorldY)
				Else
					'other bones
					'draw just a box
					target.SetColor(0.0, 1.0, 0)
					DrawRect(bone.WorldX - 2, bone.WorldY - 2, 4, 4)
				EndIf
			Next
		EndIf
		
		'render bounding For entire skeleton
		If debugBounding
			CalculateBounding()
			target.SetColor(1.0, 0.0, 0.0)
			SpineDrawLinePoly(target,bounding)
		EndIf
		#End
	End
	Public
	
	'main api
	Method Calculate:Void(force:Bool = False)
		' --- this will calculate the entity ---
		If dirtyPose
			dirtyPose = False
			skeleton.SetToSetupPose()
			dirty = True
		EndIf
		
		If force or dirty OnCalculate()
	End
	
	Method CalculateBounding:Void(force:Bool = False)
		' --- call this to calculate bounding ---
		If force or dirtyBounding
			Calculate()
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
	
	Method Render:Void(target:DrawList)
		' --- render the entity --
		'only render if not rendering or updating
		If rendering or updating Return
		rendering = True
		OnRender(target)
		rendering = False
	End
	
	'debug api
	Method SetDebug:Void(all:Bool, hideImages:Bool = False)
		' --- set debug draw options ---
		#If SPINE_DEBUG_RENDER = True
		debugHideImages = hideImages
		debugHull = all
		debugSlots = all
		debugBones = all
		debugBounding = all
		debugMesh = all
		#EndIf
	End
	
	Method SetDebug:Void(hideImages:Bool, hull:Bool, slots:Bool, bones:Bool, bounding:Bool, mesh:Bool)
		' --- set debug draw options ---
		#If SPINE_DEBUG_RENDER = True
		debugHideImages = hideImages
		debugHull = hull
		debugSlots = slots
		debugBones = bones
		debugBounding = bounding
		debugMesh = mesh
		#EndIF
	End
	
	Method GetDebug:Bool()
		' --- get combined debug state ---
		#If SPINE_DEBUG_RENDER = True
		Return debugHideImages or debugHull or debugSlots or debugBones or debugBounding or debugMesh
		#Else
		Return False
		#EndIF
	End
	
	Method GetDebugHideImages:Bool()
		' --- Return state of debug draw ---
		#If SPINE_DEBUG_RENDER = True
		Return debugHideImages
		#Else
		Return False
		#EndIF
	End
	
	Method GetDebugHull:Bool()
		' --- Return state of debug draw ---
		#If SPINE_DEBUG_RENDER = True
		Return debugHull
		#Else
		Return False
		#EndIF
	End
	
	Method GetDebugSlots:Bool()
		' --- Return state of debug draw ---
		#If SPINE_DEBUG_RENDER = True
		Return debugSlots
		#Else
		Return False
		#EndIF
	End
	
	Method GetDebugBones:Bool()
		' --- Return state of debug draw ---
		#If SPINE_DEBUG_RENDER = True
		Return debugBones
		#Else
		Return False
		#EndIF
	End
	
	Method GetDebugBounding:Bool()
		' --- Return state of debug draw ---
		#If SPINE_DEBUG_RENDER = True
		Return debugBounding
		#Else
		Return False
		#EndIF
	End
	
	Method GetDebugMesh:Bool()
		' --- Return state of debug draw ---
		#If SPINE_DEBUG_RENDER = True
		Return debugMesh
		#Else
		Return False
		#EndIF
	End
	
	'collision api
	Method PointInside:Bool(x:Float, y:Float, precision:Int = 0)
		' --- check if a point is inside using varying levels of precision ---
		'calculate first
		CalculateBounding()
		
		'check compelte bounding
		If SpinePointInRect(x, y, bounding) = False Return False
		If precision < SPINE_PRECISION_ATTACHMENT Return True
		
		'check region bounding
		Local slot:SpineSlot
				
		'go in reverse order using the zOrder so we Return the attachment closest to screen
		For Local index:= skeleton.DrawOrder.Length() - 1 To 0 Step - 1
			'get slot
			slot = skeleton.DrawOrder[index]
			If slot.Attachment = Null Continue
			
			If SpinePointInRect(x, y, slotWorldBounding[index])
				If SPINE_PRECISION_HULL < 2 Return True
				If SpinePointInPoly(x, y, slotWorldHull[index], slotWorldHullLength[index]) Return True
			EndIf
		Next
		
		'Return fail
		Return False
	End
	
	Method RectOverlaps:Bool(x:Float, y:Float, width:Float, height:Float, precision:Int = SPINE_PRECISION_ATTACHMENT)
		' --- check if a rect overlaps using varying levels of precision ---
		'calculate first
		CalculateBounding()
		
		'check compelte bounding
		If SpineRectsOverlap(x, y, width, height, bounding) = False Return False
		If precision < SPINE_PRECISION_ATTACHMENT Return True
		
		'check region bounding
		Local slot:SpineSlot
		
		'setup temp vertices For poly check
		If precision > SPINE_PRECISION_ATTACHMENT
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
			If slot.Attachment = Null Continue
			
			If SpineRectsOverlap(x, y, width, height, slotWorldBounding[index])
				If SPINE_PRECISION_HULL < 2 Return True
				If SpinePolyToPoly(tempVertices, slotWorldHull[index], slotWorldHullLength[index], -1, slotWorldHullLength[index]) Return True
			EndIf
		Next
		
		'Return fail
		Return False
	End
	
	Method PointInsideBoundingBox:Bool(x:Float, y:Float, precision:Int = 0)
		' --- check if a point is inside using varying levels of precision ---
		'calculate first
		CalculateBounding()
		
		'check compelte bounding
		If SpinePointInRect(x, y, bounding) = False Return False
		
		'check region bounding
		Local slot:SpineSlot
				
		'go in reverse order using the zOrder so we Return the attachment closest to screen
		For Local index:= skeleton.DrawOrder.Length() - 1 To 0 Step - 1
			'get slot
			slot = skeleton.DrawOrder[index]
			If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.BoundingBox Continue
			
			If SpinePointInRect(x, y, slotWorldBounding[index])
				If SPINE_PRECISION_HULL < 2 Return True
				If SpinePointInPoly(x, y, slotWorldHull[index], slotWorldHullLength[index]) Return True
			EndIf
		Next
		
		'Return fail
		Return False
	End
	
	Method RectOverlapsBoundingBox:Bool(x:Float, y:Float, width:Float, height:Float, precision:Int = SPINE_PRECISION_ATTACHMENT)
		' --- check if a rect overlaps using varying levels of precision ---
		'calculate first
		CalculateBounding()
		
		'check compelte bounding
		If SpineRectsOverlap(x, y, width, height, bounding) = False Return False
		
		'check region bounding
		Local slot:SpineSlot
		
		'setup temp vertices For poly check
		If precision > SPINE_PRECISION_ATTACHMENT
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
			If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.BoundingBox Continue
			
			If SpineRectsOverlap(x, y, width, height, slotWorldBounding[index])
				If SPINE_PRECISION_HULL < 2 Return True
				If SpinePolyToPoly(tempVertices, slotWorldHull[index], slotWorldHullLength[index], -1, slotWorldHullLength[index]) Return True
			EndIf
		Next
		
		'Return fail
		Return False
	End
	
	Method PointInsideSlot:Bool(x:Float, y:Float, name:String, precise:Bool = True)
		' --- shortcut For name lookup ---
		Return PointInsideSlot(x, y, GetSlot(name), precise)
	End
	
	Method PointInsideSlot:Bool(x:Float, y:Float, slot:SpineSlot, precise:Bool = True)
		' --- check if a point is inside using varying levels of precision ---
		If slot = Null or slot.Attachment = Null Return False
		
		CalculateBounding()
						
		Local index:= GetSlotIndex(slot.Data.Name)
		If SpinePointInRect(x, y, slotWorldBounding[index])
			If precise = False Return True
			
			If SpinePointInPoly(x, y, slotWorldHull[index]) Return True
		EndIf
		
		'Return fail
		Return False
	End
	
	Method RectOverlapsSlot:Bool(x:Float, y:Float, width:Float, height:Float, name:String, precise:Bool = True)
		' --- shortcut For slot lookup ---
		Return RectOverlapsSlot(x, y, width, height, GetSlot(name), precise)
	End
	
	Method RectOverlapsSlot:Bool(x:Float, y:Float, width:Float, height:Float, slot:SpineSlot, precise:Bool = True)
		' --- check if a rect overlaps using varying levels of precision ---
		'skip if not a region attachment
		If slot = Null or slot.Attachment = Null Return False
		
		CalculateBounding()
		
		If SpineRectsOverlap(x, y, width, height, bounding) = False Return False
					
		Local index:= GetSlotIndex(slot.Data.Name)
		If SpineRectsOverlap(x, y, width, height, slotWorldBounding[index])
			If precise = False Return True
			
			tempVertices[0] = x
			tempVertices[1] = y
			tempVertices[2] = x + width
			tempVertices[3] = y
			tempVertices[4] = x + width
			tempVertices[5] = y + height
			tempVertices[6] = x
			tempVertices[7] = y + height
			
			If SpinePolyToPoly(tempVertices, slotWorldHull[index], -1, slotWorldHullLength[index]) Return True
		EndIf
		
		'Return fail
		Return False
	End
	
	'color api
	Method SetColor:Void(r:Float, g:Float, b:Float)
		' --- change color of the entity ---
		skeleton.R = r
		skeleton.G = g
		skeleton.B = b
		
		'flag dirty
		dirty = True
	End
	
	Method SetAlpha:Void(alpha:Float)
		' --- change alpha ---
		skeleton.A = alpha
		
		'flag dirty
		dirty = True
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
		
		'flag dirty
		dirty = True
	End
	
	Method GetColor:Float[] ()
		' --- get color of skeleton ---
		Return[skeleton.R, skeleton.G, skeleton.B]
	End
	
	Method GetColor:Void(rgb:Float[])
		' --- get color of skeleton ---
		rgb[0] = skeleton.R
		rgb[1] = skeleton.G
		rgb[2] = skeleton.B
	End
	
	Method GetR:Float()
		' --- get color of skeleton ---
		Return skeleton.R
	End
	
	Method GetG:Float()
		' --- get color of skeleton ---
		Return skeleton.G
	End
	
	Method GetB:Float()
		' --- get color of skeleton ---
		Return skeleton.B
	End
	
	Method GetAlpha:Float()
		' --- get alpha ---
		Return skeleton.A
	End
	
	'atlas api
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
		If animation
			skeleton.SetToSetupPose()
			animation.Apply(skeleton, skeleton.Time, skeleton.Time, events, looping)
		
			'need to process events this will probably never do anything...
			OnProcessEvents()
		EndIf
		
		'flag that the entity is dirty again
		dirty = True
		dirtyPose = True
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
		' --- Return Local position ---
		Return[x, y]
	End
	
	Method GetPosition:Void(xy:Float[])
		' --- Return Local position ---
		xy[0] = x
		xy[1] = y
	End
	
	Method GetX:Float()
		' --- Return Local position ---
		Return x
	End
	
	Method GetY:Float()
		' --- Return Local position ---
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
		' --- Return Local scale ---
		Return[scaleX, scaleY]
	End
	
	Method GetScale:Void(scaleXY:Float[])
		' --- Return Local scale ---
		scaleXY[0] = scaleX
		scaleXY[1] = scaleY
	End
	
	Method GetScaleX:Float()
		' --- Return Local scale ---
		Return scaleX
	End
	
	Method GetScaleY:Float()
		' --- Return Local scale ---
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
		' --- Return Local angle ---
		Return rotation
	End
	
	'flip api
	Method SetFlip:Void(flipX:Bool, flipY:Bool)
		' --- flip the skeleton ---
		If flipX = skeleton.FlipX And flipY = skeleton.FlipY Return
		skeleton.FlipX = flipX
		skeleton.FlipY = flipY
		dirty = True
	End
	
	Method GetFlip:Bool[] ()
		' --- get Local flip ---
		Return[skeleton.FlipX, skeleton.FlipY]
	End
	
	Method GetFlip:Void(flipXY:Bool[])
		' --- get Local flip ---
		flipXY[0] = skeleton.FlipX
		flipXY[1] = skeleton.FlipY
	End
	
	Method GetFlipX:Bool()
		' --- get Local flip ---
		Return skeleton.FlipX
	End
	
	Method GetFlipY:Bool()
		' --- get Local flip ---
		Return skeleton.FlipY
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
		' --- get Next slot ---
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
		'check For quick lookup
		If name = lastSlotLookupName Return lastSlotLookup
		
		'lookup
		lastSlotLookupName = name
		lastSlotLookupIndex = skeleton.FindSlotIndex(lastSlotLookupName)
		If lastSlotLookupIndex = -1
			lastSlotLookup = Null
		Else
			lastSlotLookup = skeleton.Slots[lastSlotLookupIndex]
		EndIf
		Return lastSlotLookup
	End
	
	Method GetSlotIndex:Int(name:String)
		GetSlot(name)
		Return lastSlotLookupIndex
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
		' --- Return Next slot with attachment ---
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
			If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.Region Continue
			
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
			If slot.Attachment = Null or slot.Attachment.Type <> SpineAttachmentType.Region Continue
			
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
	Method SetSlotAttachment:Void(slotName:String, attachmentName:string)
		' --- change the attachment of a slot ---
		'check a slot exists
		Local slot:= GetSlot(slotName)
		If slot = Null Return
		
		skeleton.SetAttachment(slotName, attachmentName)
		
		'flag dirty
		dirty = True
	End
	
	Method SetSlotCustomAttachment:Void(slotName:String, attachment:SpineAttachment)
		' --- change the attachment of a slot ---
		Local slot:= GetSlot(slotName)
		If slot = Null Return
		
		slot.Attachment = attachment
		
		'flag dirty
		dirty = True
	End
	
	Method SetSlotColor:Void(name:String, rgb:Float[])
		' --- change the color of a slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null Return
		
		slot.R = rgb[0]
		slot.G = rgb[1]
		slot.B = rgb[2]
		
		'flag dirty
		dirty = True
	End
	
	Method SetSlotColor:Void(name:String, r:Float, g:Float, b:Float)
		' --- change the color of a slot ---
		'check a slot exists
		Local slot:= GetSlot(name)
		If slot = Null Return
		
		slot.R = r
		slot.G = g
		slot.B = b
		
		'flag dirty
		dirty = True
	End
		
	Method GetSlotColor:Float[] (name:String, world:Bool = False)
		' --- get color of a particular slot ---
		If world
			Local index:= skeleton.FindSlotIndex(name)
			If index = -1 Return[0, 0, 0]
			
			Calculate()
			Return[slotWorldR[index], slotWorldG[index], slotWorldB[index]]
		Else
			'check a slot exists
			Local slot:= GetSlot(name)
			If slot = Null Return[0, 0, 0]
			
			'Local
			Return[slot.R, slot.G, slot.B]
		EndIf
	End
	
	Method GetSlotColor:Void(name:String, rgb:Float[], world:Bool = False)
		' --- get color of a particular slot ---
		If world
			Local index:= skeleton.FindSlotIndex(name)
			If index = -1
				rgb[0] = 0.0
				rgb[1] = 0.0
				rgb[2] = 0.0
				Return
			EndIf
			
			Calculate()
			rgb[0] = slotWorldR[index]
			rgb[1] = slotWorldG[index]
			rgb[2] = slotWorldB[index]
		Else
			'check a slot exists
			Local slot:= GetSlot(name)
			If slot = Null
				rgb[0] = 0.0
				rgb[1] = 0.0
				rgb[2] = 0.0
				Return
			EndIf
			
			'Local
			rgb[0] = slot.R
			rgb[1] = slot.G
			rgb[2] = slot.B
		EndIf
	End
	
	Method GetSlotColorR:Float(name:String, world:Bool = False)
		' --- get color of a particular slot ---
		If world
			Local index:= skeleton.FindSlotIndex(name)
			If index = -1 Return 0.0
			
			Calculate()
			Return slotWorldR[index]
		Else
			Local slot:= GetSlot(name)
			If slot = Null Return 0.0
			Return slot.R
		EndIf
	End
	
	Method GetSlotColorG:Float(name:String, world:Bool = False)
		' --- get color of a particular slot ---
		If world
			Local index:= skeleton.FindSlotIndex(name)
			If index = -1 Return 0.0
			
			Calculate()
			Return slotWorldG[index]
		Else
			Local slot:= GetSlot(name)
			If slot = Null Return 0.0
			Return slot.G
		EndIf
	End
	
	Method GetSlotColorB:Float(name:String, world:Bool = False)
		' --- get color of a particular slot ---
		If world
			Local index:= skeleton.FindSlotIndex(name)
			If index = -1 Return 0.0
			
			Calculate()
			Return slotWorldB[index]
		Else
			Local slot:= GetSlot(name)
			If slot = Null Return 0.0
			Return slot.B
		EndIf
	End
	
	Method GetSlotAlpha:Float(name:String, world:Bool = False)
		' --- change the alpha of a slot ---
		If world
			Local index:= skeleton.FindSlotIndex(name)
			If index = -1 Return 0
			
			Calculate()
			Return slotWorldAlpha[index]
		Else
			Local slot:= GetSlot(name)
			If slot = Null Return 0
			Return slot.A
		EndIf
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
		If world
			Local index:= skeleton.FindSlotIndex(name)
			If index = -1 Return[0.0, 0.0]
			Calculate()
			Return[slotWorldX[index], slotWorldY[index]]
		Else
			Local slot:= GetSlot(name)
			If slot = Null Return[0.0, 0.0]
			
			Local attachment:= slot.Attachment
			
			Select attachment.Type
				Case SpineAttachmentType.Region
					Local region:= SpineRegionAttachment(attachment)
					Return[region.X, region.Y]
				Default
					Return[slot.Bone.X, slot.Bone.Y]
			End
		EndIf
	End
	
	Method GetSlotPosition:Void(name:String, xy:Float[], world:Bool = False)
		' --- this will Return the position of the given slot ---
		If world
			Local index:= skeleton.FindSlotIndex(name)
			If index = -1
				xy[0] = 0.0
				xy[1] = 0.0
				Return
				Return
			EndIf
			Calculate()
			
			xy[0] = slotWorldX[index]
			xy[1] = slotWorldY[index]
		Else
			Local slot:= GetSlot(name)
			If slot = Null
				xy[0] = 0.0
				xy[1] = 0.0
				Return
			EndIf
			
			Local attachment:= slot.Attachment
			
			Select attachment.Type
				Case SpineAttachmentType.Region
					Local region:= SpineRegionAttachment(attachment)
					xy[0] = region.X
					xy[1] = region.Y
				Default
					xy[0] = slot.Bone.X
					xy[1] = slot.Bone.Y
			End
		EndIf
	End
	
	Method GetSlotX:Float(name:String, world:Bool = False)
		' --- this will Return the position of the given slot ---
		If world
			Local index:= skeleton.FindSlotIndex(name)
			If index = -1 Return 0.0
			Calculate()
			Return slotWorldX[index]
		Else
			Local slot:= GetSlot(name)
			If slot = Null Return 0.0
			
			Local attachment:= slot.Attachment
			
			Select attachment.Type
				Case SpineAttachmentType.Region
					Local region:= SpineRegionAttachment(attachment)
					Return region.X
				Default
					Return slot.Bone.X
			End
		EndIf
	End
	
	Method GetSlotY:Float(name:String, world:Bool = False)
		' --- this will Return the position of the given slot ---
		If world
			Local index:= skeleton.FindSlotIndex(name)
			If index = -1 Return 0.0
			Calculate()
			Return slotWorldY[index]
		Else
			Local slot:= GetSlot(name)
			If slot = Null Return 0.0
			
			Local attachment:= slot.Attachment
			
			Select attachment.Type
				Case SpineAttachmentType.Region
					Local region:= SpineRegionAttachment(attachment)
					Return region.Y
				Default
					Return slot.Bone.Y
			End
		EndIf
	End
	
	'slot rotation api
	Method GetSlotRotation:Float(name:String, world:Bool = False)
		' --- Return bone rotation For a given slot ---
		If world
			Local index:= skeleton.FindSlotIndex(name)
			If index = -1 Return 0.0
			Calculate()
			Return slotWorldRotation[index]
		Else
			Local slot:= GetSlot(name)
			If slot = Null Return 0.0
			
			Local attachment:= slot.Attachment
			
			Select attachment.Type
				Case SpineAttachmentType.Region
					Local region:= SpineRegionAttachment(attachment)
					Return region.Rotation
				Default
					Return slot.Bone.Rotation
			End
		EndIf
	End
	
	'slot scale api
	Method GetSlotScale:Float[] (name:String, world:Bool = False)
		' --- this will Return the position of the given slot ---
		If world
			Local index:= skeleton.FindSlotIndex(name)
			If index = -1 Return[0.0, 0.0]
			Calculate()
			Return[slotWorldScaleX[index], slotWorldScaleY[index]]
		Else
			Local slot:= GetSlot(name)
			If slot = Null Return[0.0, 0.0]
			
			Local attachment:= slot.Attachment
			
			Select attachment.Type
				Case SpineAttachmentType.Region
					Local region:= SpineRegionAttachment(attachment)
					Return[region.ScaleX, region.ScaleY]
				Default
					Return[slot.Bone.ScaleX, slot.Bone.ScaleY]
			End
		EndIf
	End
	
	Method GetSlotScale:Void(name:String, scaleXY:Float[], world:Bool = False)
		' --- this will Return the position of the given slot ---
		If world
			Local index:= skeleton.FindSlotIndex(name)
			If index = -1
				xy[0] = 0.0
				xy[1] = 0.0
				Return
				Return
			EndIf
			Calculate()
			
			xy[0] = slotWorldScaleX[index]
			xy[1] = slotWorldScaleY[index]
		Else
			Local slot:= GetSlot(name)
			If slot = Null
				xy[0] = 0.0
				xy[1] = 0.0
				Return
			EndIf
			
			Local attachment:= slot.Attachment
			
			Select attachment.Type
				Case SpineAttachmentType.Region
					Local region:= SpineRegionAttachment(attachment)
					xy[0] = region.ScaleX
					xy[1] = region.ScaleY
				Default
					xy[0] = slot.Bone.ScaleX
					xy[1] = slot.Bone.ScaleY
			End
		EndIf
	End
	
	Method GetSlotScaleX:Float(name:String, world:Bool = False)
		' --- this will Return the position of the given slot ---
		If world
			Local index:= skeleton.FindSlotIndex(name)
			If index = -1 Return 0.0
			Calculate()
			Return slotWorldScaleX[index]
		Else
			Local slot:= GetSlot(name)
			If slot = Null Return 0.0
			
			Local attachment:= slot.Attachment
			
			Select attachment.Type
				Case SpineAttachmentType.Region
					Local region:= SpineRegionAttachment(attachment)
					Return region.ScaleX
				Default
					Return slot.Bone.ScaleX
			End
		EndIf
	End
	
	Method GetSlotScaleY:Float(name:String, world:Bool = False)
		' --- this will Return the position of the given slot ---
		If world
			Local index:= skeleton.FindSlotIndex(name)
			If index = -1 Return 0.0
			Calculate()
			Return slotWorldScaleY[index]
		Else
			Local slot:= GetSlot(name)
			If slot = Null Return 0.0
			
			Local attachment:= slot.Attachment
			
			Select attachment.Type
				Case SpineAttachmentType.Region
					Local region:= SpineRegionAttachment(attachment)
					Return region.ScaleY
				Default
					Return slot.Bone.ScaleY
			End
		EndIf
	End
	'1083.76
	'bone api
	Method ResetBones:Void()
		' --- this will reset bones to their default state at current frame ---
		skeleton.SetBonesToSetupPose()
		dirty = True
	End
	
	Method HasBone:Bool(name:String)
		' --- Return True if bone exists ---
		'this is a lazy way of doing it
		Return GetBone(name) <> Null
	End
	
	Method GetBone:SpineBone(name:String)
		' --- find bone by name ---
		'check For quick lookup
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
		'if the world flag is specified it will calculate the bones Local rotation based on parent rotation to achieve the angle specified
		
		'lookup bone
		Local bone:= GetBone(name)
		If bone = Null Return
		
		'world or Local?
		Local newX:Float
		Local newY:Float
		If world and bone.Parent
			Calculate()
			x = (x - bone.Parent.WorldX) / bone.Parent.WorldScaleX
			y = (y - bone.Parent.WorldY) / bone.Parent.WorldScaleY
			
			newX = (x * bone.Parent.M00 + y * bone.Parent.M01) / bone.Parent.WorldScaleX
			newY = (x * bone.Parent.M10 + y * bone.Parent.M11) / bone.Parent.WorldScaleY
		Else
			newX = bone.Data.X + x
			newY = bone.Data.Y + y
		EndIf
		
		'only make changes if it has changed
		If newX <> bone.X or newY <> bone.Y
			bone.X = newX
			bone.Y = newY
			dirty = True
		EndIf
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
		
		'Return
		If world
			Calculate()
			Return[bone.WorldX, bone.WorldY]
		Else
			Return[bone.X, bone.Y]
		EndIf
	End
	
	Method GetBonePosition:Void(name:String, xy:Float[], world:Bool = False)
		' --- get position of bone ---
		'lookup bone
		Local bone:= GetBone(name)
		If bone = Null
			xy[0] = 0.0
			xy[1] = 0.0
		EndIf
		
		'Return
		If world
			Calculate()
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
		
		If world
			Calculate()
			Return bone.WorldX
		EndIf
		Return bone.X
	End
	
	Method GetBoneY:Float(name:String, world:Bool = False)
		' --- get position of bone ---
		'lookup bone
		Local bone:= GetBone(name)
		If bone = Null Return 0.0
		
		If world
			Calculate()
			Return bone.WorldY
		EndIf
		Return bone.Y
	End
	
	'bone rotation api
	Method SetBoneRotation:Void(name:String, angle:Float, world:Bool = False)
		' --- rotate a given bone ---
		'must be applied after calling Update() on entity
		'if the world flag is specified it will calculate the bones Local rotation based on parent rotation to achieve the angle specified
		
		'lookup bone
		Local bone:= GetBone(name)
		If bone = Null Return
		
		'world or Local
		Local newRotation:Float
		If world And bone.Parent
			Calculate()
			newRotation = angle - bone.Parent.WorldRotation
		Else
			newRotation = angle
		EndIf
		
		If newRotation <> bone.Rotation
			bone.Rotation = newRotation
			dirty = True
		EndIf
	End
	
	Method GetBoneRotation:Float(name:String, world:Bool = False)
		' --- Return bone rotation For a given bone ---
		'must be applied after calling Update() on entity
		'lookup bone
		Local bone:= GetBone(name)
		If bone = Null Return 0.0
		
		If world
			Calculate()
			Return bone.WorldRotation
		EndIf
		Return bone.Rotation
	End
	
	'bone scale api
	Method SetBoneScale:Void(name:String, scaleX:Float, scaleY:Float, world:Bool = False)
		' --- set scale of bone ---
		'must be applied after calling Update() on entity
		
		'lookup bone
		Local bone:= GetBone(name)
		If bone = Null Return
		
		'world or Local
		Local newScaleX:Float
		Local newScaleY:Float
		If world and bone.Parent
			Calculate()
			newScaleX = scaleX / bone.Parent.WorldScaleX
			newScaleY = scaleY / bone.Parent.WorldScaleY
		Else
			newScaleX = scaleX
			newScaleY = scaleY
		EndIf
		
		If newScaleX <> bone.ScaleX or newScaleY <> bone.ScaleY
			bone.ScaleX = newScaleX
			bone.ScaleY = newScaleY
			dirty = True
		EndIf
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
		
		If world
			Calculate()
			Return[bone.WorldScaleX, bone.WorldScaleY]
		EndIf
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
		
		If world
			Calculate()
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
		
		If world
			Calculate()
			Return bone.WorldScaleX
		EndIf
		Return bone.ScaleX
	End
	
	Method GetBoneScaleY:Float(name:String, world:Bool = False)
		' --- get scale of bone ---
		'lookup bone
		Local bone:= GetBone(name)
		If bone = Null Return 0.0
		
		If world
			Calculate()
			Return bone.WorldScaleY
		EndIf
		Return bone.ScaleY
	End
		
	'settings api
	Method SetSnapToPixels:Void(snapToPixels:Bool)
		' --- change if images should be snapped to pixels ---
		Self.snapToPixels = snapToPixels
	End
	
	Method SetIgnoreRootPosition:Void(ignoreRootPosition:Bool)
		' --- change if entity should ignore positional data for the root bone ---
		Self.ignoreRootPosition = ignoreRootPosition
	End
	
	'api
	Method GetName:String()
		' --- Return name of skeleton ---
		Return skeleton.Data.Name
	End
	
	Method SetCallback:Void(callback:SpineEntityCallback)
		' --- change the callback ---
		Self.callback = callback
	End

	Method SetAtlasScale:Void( value:Float )
		' --- manually set scale for scaled atlas ---
		Self.atlasScale = 1.0 / value
	End
End
