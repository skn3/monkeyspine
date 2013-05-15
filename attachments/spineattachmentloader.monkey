'see license.txt for source licenses
Strict

Import spine

Interface SpineAttachmentLoader
	'return May be null to not load any attachment. 
	Method NewAttachment:SpineAttachment(skin:SpineSkin, type:Int, name:String)
End
