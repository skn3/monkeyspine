'see license.txt For source licenses
Strict

'version 24
' - renamed SpineMojoRendererObject to SpineMojoTextureRenderObject
' - added SpineMojoImageRenderObject
' - added SpineMojoImageAttachment
' - added new example to demonstrate custom attachment
' - added SetSlotAttachment() and  SetSlotCustomAttachment() to spine entity
'version 23
' - small tweak to set initial atlasScale in spineentity to 1.0 (otherwise images would render with 0x0 scale because multiplied by atlasScale = 0.0)
'version 22
' - issue with merging pull request with different line-end-encoding ~r is now stripped out in mojo file reader
'version 21
' - fixed event data not coming through, cheers mouser
' - added SetIgnoreRootPosition to SpineEntity. By default now spineentity will utilise the root bone position compared to 0,0 in spine editor. Set this to true if spine entity should ignore root bone position and force set to x,y of SpineEntity.
'version 20
' - major fix to UpdateCache and UpdateWorldTransform in spine skeleton. Now has fully functional IK
' - updated license in accordance with spines new license
' - small tweak to fix bug when switching from old skin to new skin
'version 19 (sep 2014)
' - ported to latest runtime (tons of stuff added)
'version 18
' - added RevertColor() and RevertAlpha() to spine entity (cheers rikman)
'version 17
' - added MixAnimation to gluespineentity see example2 For example of usage
'version 16
' - fixed issue with draworder not resetting For non loopd animations (cheers rikman)
'version 15
' - added SetDebugHideImages() to entity so we can disable drawing of images
' - fixed issue where transform/scale/rotation animation was being ignored For root bone, cheers rikman
' - made atlas, data and skeleton fields in spineentity Public For hackables, cheers rikman
' - fixed issue where scale on single axis was deforming in monkey, cheers rikman.
'version 14
' - added small fix so snap to turns image handles into ints
'version 13
' - MASSIVE UPDATE
' - added support For native spine texture atlas
' - changed so default texture atlas loader type is the spine texture atlas loader
' - renamed the seperate image loader to SpineSeperateImageLoader
' - fixed file stream wrapper so eof works
' - added event callback to SpineEntityCallback Interface
' - implemented spine events
' - implemeneted spine draw order
' - added SetSnapToPixels() to spineentity, this will draw images at Int coordinates
' - Added GetSlotAlpha() and SetSlotAlpha()
' - fixed seperate image loader collisions + bounding not working
'version 12
' - added GetFirstSlot() GetLastSlot() GetNextSlot(slot) GetPreviousSlot(slot) For iterating over slots in spine entity
' - added FindFirstSlotWithAttachment() FindLastSlotWithAttachment() FindNextSlotWithAttachment(slot) FindPreviousSloWithAttachmentt(slot) For iterating over attachment slots in spine entity
' - changed RectOverlapsSlot() and PointInsideSlot() so precision param is boolean
'version 11
' - added PointInsideSlot() and RectOverlapsSlot() methods to spineentity. There are two versions of the method one accepst name:String and the other slot:SpineSlot
'version 10
' - added SetAlpha() and GetAlpha() to spineentity
'version 9
' - fixed mid handle issue with source images that have padding around edges (reported by ziggy)
'version 8
' - added spineEntity.GetAtlas() to get atlas of spine entity (thanks ziggy)
' - added SpineLoadAtlas() function to load an atlas outside of creating a spine entity
' - added SpineAtlas.Use() so that the spine glue will reference count an atlas
' - changed SpineAtlas.Free(force=False) added a force flag which will force teh atlas to be freed.
'   If force is False and atlas is being used by something Else then only a eference count will be decreased
'version 7
' - fixed map issues, thanks ziggy
'version 6
' - Added IsAnimationRunning() to SpineEntity this will Return True if the animation is still running
' - Added GetAnimationTime() to SpineEntity this will get the current time in ms For the animation
' - Added Free() to spineentity and certain acompanying objects
'version 5
' - more fixes by ziggy
'version 4
' - fixed lots of typo-ish bugs reported by ziggy
'version 3
' - moved module into root modules folder
'version 2
' - fixed getflip Return type to Bool, cheers Zwer99
'version 1
' - first Public commit

'spine requires these file types to operate normally
#TEXT_FILES += "*.atlas|*.json"

'preprocessor vars
#SPINE_DEBUG_RENDER = True
#SPINE_ATLAS_ROTATE = False'leave false, as support is broken

'core
Import mojo
Import monkey.map
Import monkey.boxes
Import brl.databuffer

'3rd party
Import json

'glue code
Import glue.spineatlas
Import glue.spineatlasloader
Import glue.spineatlaspage
Import glue.spineatlasregion
Import glue.spineconstants
Import glue.spineentity
Import glue.spineexceptions
Import glue.spinefile
Import glue.spinefileloader
Import glue.spinefunctions
Import glue.spinerendererobject
Import glue.spinetexture
Import glue.spinetextureloader
Import glue.spinetexturefilter
Import glue.spinetexturewrap
Import glue.spineformat

'spine lib
Import lib.spinepolygon
Import lib.spineanimation
Import lib.spineanimationstate
Import lib.spineanimationstatedata
Import lib.spinebone
Import lib.spinebonedata
Import lib.spineevent
Import lib.spineeventdata
Import lib.spineikconstraint
Import lib.spineikconstraintdata
Import lib.spineskeleton
Import lib.spineskeletonbounds
Import lib.spineskeletondata
Import lib.spineskeletonjson
Import lib.spineskin
Import lib.spineslot
Import lib.spineslotdata
Import lib.attachments.spineatlasattachmentloader
Import lib.attachments.spineattachment
Import lib.attachments.spineattachmentloader
Import lib.attachments.spineattachmenttype
Import lib.attachments.spineboundingboxattachment
Import lib.attachments.spinemeshattachment
Import lib.attachments.spineregionattachment
Import lib.attachments.spineskinnedmeshattachment



