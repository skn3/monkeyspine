'see license.txt for source licenses
Strict

'version 3
' - moved module into root modules folder
' - updated reference to json module to "import monkeyjson" instead of "import json"
'version 2
' - fixed getflip return type to bool, cheers Zwer99
'version 1
' - first public commit

'core
Import mojo
Import monkey.map
Import brl.databuffer

'3rd party
Import monkeyjson

'glue code
Import glue.gluevalues
Import glue.gluefunctions
Import glue.glueexceptions
Import glue.gluefiles
Import glue.glueatlas
Import glue.gluespineentity

'spine lib
Import spineanimation
Import spineanimationstate
Import spineanimationstatedata
Import spineatlas
Import spinebone
Import spinebonedata
Import spineskeleton
Import spineskeletondata
Import spineskeletonjson
Import spineskin
Import spineslot
Import spineslotdata
Import attachments.spineatlasattachmentloader
Import attachments.spineattachment
Import attachments.spineattachmentloader
Import attachments.spineattachmenttype
Import attachments.spineregionattachment