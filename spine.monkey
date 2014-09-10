'see license.txt for source licenses
Strict

'version 19
' - ported to latest runtime
'version 18
' - added RevertColor() and RevertAlpha() to spine entity (cheers rikman)
'version 17
' - added MixAnimation to gluespineentity see example2 for example of usage
'version 16
' - fixed issue with draworder not resetting for non loopd animations (cheers rikman)
'version 15
' - added SetDebugHideImages() to entity so we can disable drawing of images
' - fixed issue where transform/scale/rotation animation was being ignored for root bone, cheers rikman
' - made atlas, data and skeleton fields in spineentity public for hackables, cheers rikman
' - fixed issue where scale on single axis was deforming in monkey, cheers rikman.
'version 14
' - added small fix so snap to turns image handles into ints
'version 13
' - MASSIVE UPDATE
' - added support for native spine texture atlas
' - changed so default texture atlas loader type is the spine texture atlas loader
' - renamed the seperate image loader to SpineSeperateImageLoader
' - fixed file stream wrapper so eof works
' - added event callback to SpineEntityCallback interface
' - implemented spine events
' - implemeneted spine draw order
' - added SetSnapToPixels() to spineentity, this will draw images at Int coordinates
' - Added GetSlotAlpha() and SetSlotAlpha()
' - fixed seperate image loader collisions + bounding not working
'version 12
' - added GetFirstSlot() GetLastSlot() GetNextSlot(slot) GetPreviousSlot(slot) for iterating over slots in spine entity
' - added FindFirstSlotWithAttachment() FindLastSlotWithAttachment() FindNextSlotWithAttachment(slot) FindPreviousSloWithAttachmentt(slot) for iterating over attachment slots in spine entity
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
' - changed SpineAtlas.Free(force=false) added a force flag which will force teh atlas to be freed.
'   If force is false and atlas is being used by something Else then only a eference count will be decreased
'version 7
' - fixed map issues, thanks ziggy
'version 6
' - Added IsAnimationRunning() to SpineEntity this will Return true if the animation is still running
' - Added GetAnimationTime() to SpineEntity this will get the current time in ms for the animation
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
' - first public commit

'spine requires these file types to operate normally
#TEXT_FILES += "*.atlas|*.json"

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



