; +---------------------------+
; | BlurHash Reference Hashes |
; +---------------------------+
; | 2020-05-30 : Creation (PureBasic 5.72)

;-

XIncludeFile "../BlurHash.pbi"

UsePNGImageDecoder()
UseJPEGImageDecoder()
UseJPEG2000ImageDecoder()

Macro AssertBlurHash(File, xComponents, yComponents, ExpectedHash)
  OutputHash.s = BlurHashEncodeFromFile(File, xComponents, yComponents, #False)
  If (OutputHash = ExpectedHash)
    Debug File + ": OK"
  ElseIf (OutputHash = "")
    Debug File + ": Failed to BlurHash"
  Else
    Debug File + ": Expected " + ExpectedHash + " , Generated " + OutputHash
  EndIf
EndMacro


; https://github.com/woltapp/blurhash/issues/38
AssertBlurHash("pic2.png", 4, 3, "LlMF%n00%#MwS|WCWEM{R*bbWBbH")

; https://github.com/crozone/blurhash/blob/add-reference-hashes/Reference/Hashes.csv
AssertBlurHash("pic4.png", 4, 3, "L08ia?o|fQo|tkfQfQfQfQfQfQfQ")

; https://github.com/halcy/blurhash-python/blob/master/README.md
AssertBlurHash("cool_cat_small.jpg", 4, 4, "UBL_:rOpGG-oBUNG,qRj2so|=eE1w^n4S5NH")

;-
