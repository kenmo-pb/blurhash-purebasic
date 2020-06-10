; +----------+
; | BlurHash |
; +----------+
; | 2020-05-15 : Creation (PureBasic 5.72)

; ==============================================================================
; References:
;   https://blurha.sh
;   https://github.com/woltapp/blurhash
;   https://github.com/woltapp/blurhash/pull/42
;   https://github.com/halcy/blurhash-python
; ==============================================================================

CompilerIf (Not Defined(_BlurHash_Included, #PB_Constant))
#_BlurHash_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf



;-
;- Declares (Public)

; Encode an image (already loaded) and return its BlurHash string
Declare.s BlurHashEncodeFromImage(Image.i, xComponents.i = #PB_Default, yComponents.i = #PB_Default, PreShrink.i = #False)

; Encode an image (from file path) and return its BlurHash string
Declare.s BlurHashEncodeFromFile(File.s, xComponents.i = #PB_Default, yComponents.i = #PB_Default, PreShrink.i = #False)

; Decode a BlurHash string to an image in memory
Declare.i BlurHashDecodeToImage(Hash.s, DestImage.i = #PB_Any, width.i = #PB_Default, height.i = #PB_Default, PreShrink.i = #False)

; Decode a BlurHash string to an image file
Declare.i BlurHashDecodeToFile(Hash.s, DestFile.s, width.i = #PB_Default, height.i = #PB_Default, PreShrink.i = #False)

; Directly BlurHash an input image (already loaded) to an output image
Declare.i BlurHashImageToImage(SourceImage.i, DestImage.i = #PB_Any, xComponents.i = #PB_Default, yComponents.i = #PB_Default, width.i = #PB_Default, height.i = #PB_Default, PreShrink.i = #False)

; Directly BlurHash an input image (from file path) to an output file
Declare.i BlurHashFileToFile(SourceFile.s, DestFile.s, xComponents.i = #PB_Default, yComponents.i = #PB_Default, width.i = #PB_Default, height.i = #PB_Default, PreShrink.i = #False)



;-
;- Constants (Public)

#BlurHash_IncludeVersion = 100 ; PureBasic format, eg. 100 = 1.00

CompilerIf (Not Defined(BlurHash_UseSinglePrecision, #PB_Constant))
  #BlurHash_UseSinglePrecision = #False
CompilerEndIf

CompilerIf (Not Defined(BlurHash_PreShrinkSize, #PB_Constant))
  #BlurHash_PreShrinkSize = 32
CompilerEndIf



;-
;- Macros (Private)

CompilerIf (#BlurHash_UseSinglePrecision)
  Macro _BH_f
    f
  EndMacro
  Macro _BH_FLOAT
    FLOAT
  EndMacro
CompilerElse
  Macro _BH_f
    d
  EndMacro
  Macro _BH_FLOAT
    DOUBLE
  EndMacro
CompilerEndIf




;-
;- Structures (Private)

Structure _BH_FloatArr
  v._BH_f[0]
EndStructure


;-
;- Variables (Private)

Global _BH_Characters.s = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~"





;-
;- Procedures (Private)

Procedure._BH_f _BH_MaxF(a._BH_f, b._BH_f)
  If (a > b)
    ProcedureReturn (a)
  EndIf
  ProcedureReturn (b)
EndProcedure

Procedure._BH_f _BH_MinF(a._BH_f, b._BH_f)
  If (a < b)
    ProcedureReturn (a)
  EndIf
  ProcedureReturn (b)
EndProcedure

Procedure._BH_f _BH_sRGBToLinear(value.i)
  Protected v._BH_f = value / 255.0
  If (v <= 0.04045)
    ProcedureReturn (v / 12.92)
  Else
    ProcedureReturn (Pow((v + 0.055) / 1.055, 2.4))
  EndIf
EndProcedure

Procedure.i _BH_LinearToSRGB(value._BH_f)
  Protected v._BH_f = _BH_MaxF(0, _BH_MinF(1, value))
  If (v <= 0.0031308)
    ;ProcedureReturn (Round(v * 12.92 * 255 + 0.5, #PB_Round_Nearest)) ; TypeScript version adds 0.5 AND calls round()
    ProcedureReturn (Int(v * 12.92 * 255 + 0.5)) ; C version adds 0.5 and implicitly floors
  Else
    ;ProcedureReturn (Round((1.055 * Pow(v, 1/2.4) - 0.055) * 255 + 0.5, #PB_Round_Nearest)) ; TypeScript version adds 0.5 AND calls round()
    ProcedureReturn (Int((1.055 * Pow(v, 1/2.4) - 0.055) * 255 + 0.5)) ; C version adds 0.5 and implicitly floors
  EndIf
EndProcedure

Procedure._BH_f _BH_SignPow(value._BH_f, exp._BH_f)
  ProcedureReturn (Pow(Abs(value), exp) * Sign(value))
EndProcedure

Procedure.s _BH_EncodeInt(value.i, length.i)
  Protected Result.s
  
  Protected divisor.i = 1
  Protected i.i
  For i = 0 To length - 2
    divisor * 83
  Next i
  
  For i = 0 To length - 1
    Protected digit.i = (value / divisor) % 83
    divisor / 83
    Result + Mid(_BH_Characters, digit+1, 1)
  Next i
  
  ProcedureReturn (Result)
EndProcedure

Procedure.i _BH_DecodeInt(String.s)
  Protected Result.i = 0
  
  Protected i.i
  For i = 1 To Len(String)
    Result * 83
    Protected j.i = FindString(_BH_Characters, Mid(String, i, 1))
    If (j)
      Result + (j - 1)
    EndIf
  Next i
  
  ProcedureReturn (Result)
EndProcedure

Procedure.i _BH_EncodeDC(r._BH_f, g._BH_f, b._BH_f)
  Protected roundedR.i = _BH_LinearToSRGB(r)
  Protected roundedG.i = _BH_LinearToSRGB(g)
  Protected roundedB.i = _BH_LinearToSRGB(b)
  ProcedureReturn ((roundedR << 16) + (roundedG << 8) + roundedB)
EndProcedure

Procedure.i _BH_EncodeAC(r._BH_f, g._BH_f, b._BH_f, maximumValue._BH_f)
  Protected quantR.i = _BH_MaxF(0, _BH_MinF(18, Int(_BH_SignPow(r / maximumValue, 0.5) * 9 + 9.5)))
  Protected quantG.i = _BH_MaxF(0, _BH_MinF(18, Int(_BH_SignPow(g / maximumValue, 0.5) * 9 + 9.5)))
  Protected quantB.i = _BH_MaxF(0, _BH_MinF(18, Int(_BH_SignPow(b / maximumValue, 0.5) * 9 + 9.5)))
  ProcedureReturn (quantR * 19 * 19 + quantG * 19 + quantB)
EndProcedure

Procedure _BH_MultiplyBasisFunction(xComponent.i, yComponent.i, w.i, h.i, *f0._BH_FLOAT)
  Protected *f1._BH_FLOAT = *f0 + SizeOf(_BH_FLOAT)
  Protected *f2._BH_FLOAT = *f1 + SizeOf(_BH_FLOAT)
  
  Protected._BH_f r, g, b
  Protected normalisation._BH_f = 2.0
  If ((xComponent = 0) And (yComponent = 0))
    normalisation = 1.0
  EndIf
  
  Protected._BH_f rs1, bs1, gs1
  
  Protected x.i, y.i
  For y = 0 To h - 1
    rs1 = 0
    gs1 = 0
    bs1 = 0
    For x = 0 To w - 1
      Protected basis._BH_f = Cos(#PI * xComponent * x / w) * Cos(#PI * yComponent * y / h)
      Protected Color.i = Point(x, y)
      rs1 + basis * _BH_sRGBToLinear(Red(Color))
      gs1 + basis * _BH_sRGBToLinear(Green(Color))
      bs1 + basis * _BH_sRGBToLinear(Blue(Color))
    Next x
    r + rs1
    g + gs1
    b + bs1
  Next y
  
  Protected scale._BH_f = normalisation / (w * h)
  *f0\_BH_f = r * scale
  *f1\_BH_f = g * scale
  *f2\_BH_f = b * scale
  
EndProcedure

Procedure.i _BH_ImageToFile(Image.i, File.s, Free.i = #False)
  Protected Result.i = #False
  Select (LCase(GetExtensionPart(File)))
    Case "png"
      Result = Bool(SaveImage(Image, File, #PB_ImagePlugin_PNG))
    Case "jpg", "jpeg"
      Result = Bool(SaveImage(Image, File, #PB_ImagePlugin_JPEG, 9))
    Default
      Result = Bool(SaveImage(Image, File, #PB_ImagePlugin_BMP))
  EndSelect
  If (Free)
    FreeImage(Image)
  EndIf
  ProcedureReturn (Result)
EndProcedure









;-
;- Procedures (Public)

Procedure.s BlurHashEncodeFromImage(Image.i, xComponents.i = #PB_Default, yComponents.i = #PB_Default, PreShrink.i = #False)
  Protected Result.s
  
  ; Validate image dimensions
  Protected w.i = ImageWidth(Image)
  Protected h.i = ImageHeight(Image)
  If ((w <= 0) Or (h <= 0))
    ProcedureReturn ("")
  EndIf
  
  ; Validate x/y components
  If (xComponents = #PB_Default)
    xComponents = 4
  EndIf
  If (yComponents = #PB_Default)
    yComponents = 3
  EndIf
  If ((xComponents < 1) Or (xComponents > 9))
    ProcedureReturn ("")
  ElseIf ((yComponents < 1) Or (yComponents > 9))
    ProcedureReturn ("")
  EndIf
  
  Protected TempImage.i
  If (PreShrink And (w > #BlurHash_PreShrinkSize) Or (h > #BlurHash_PreShrinkSize))
    TempImage = CopyImage(Image, #PB_Any)
    If (TempImage)
      ResizeImage(TempImage, #BlurHash_PreShrinkSize, #BlurHash_PreShrinkSize)
      Image = TempImage
      w = ImageWidth(TempImage)
      h = ImageHeight(TempImage)
    EndIf
  EndIf
  
  Dim factors._BH_f(yComponents - 1, xComponents - 1, 3 - 1)
  If (StartDrawing(ImageOutput(Image)))
    Protected x.i, y.i
    For y = 0 To yComponents - 1
      For x = 0 To xComponents - 1
        _BH_MultiplyBasisFunction(x, y, w, h, @factors(y, x, 0))
      Next x
    Next y
    StopDrawing()
  EndIf
  
  Result = _BH_EncodeInt((xComponents - 1) + (yComponents - 1) * 9, 1)
  
  Protected acCount.i = xComponents * yComponents - 1
  Protected *ac._BH_FloatArr = @factors(0,0,0) + 3 * SizeOf(_BH_FLOAT)
  Protected i.i
  Protected maximumValue._BH_f
  If (acCount > 0)
    Protected actualMaximumValue._BH_f = 0
    For i = 0 To acCount * 3 - 1
      actualMaximumValue = _BH_MaxF(Abs(*ac\v[i]), actualMaximumValue)
    Next i
    Protected quantisedMaximumValue.i = _BH_MaxF(0, _BH_MinF(82, Int(actualMaximumValue * 166 - 0.5)))
    maximumValue = (1.0 + quantisedMaximumValue) / 166.0
    Result + _BH_EncodeInt(quantisedMaximumValue, 1)
  Else
    maximumValue = 1
    Result + _BH_EncodeInt(0, 1)
  EndIf
  
  Result + _BH_EncodeInt(_BH_EncodeDC(factors(0,0,0), factors(0,0,1), factors(0,0,2)), 4)
  
  For i = 0 To acCount - 1
    Protected r._BH_f = *ac\v[i*3 + 0]
    Protected g._BH_f = *ac\v[i*3 + 1]
    Protected b._BH_f = *ac\v[i*3 + 2]
    Result + _BH_EncodeInt(_BH_EncodeAC(r, g, b, maximumValue), 2)
  Next i
  
  If (TempImage)
    FreeImage(TempImage)
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.s BlurHashEncodeFromFile(File.s, xComponents.i = #PB_Default, yComponents.i = #PB_Default, PreShrink.i = #False)
  Protected Result.s
  
  Protected TempImg.i = LoadImage(#PB_Any, File)
  If (TempImg)
    Result = BlurHashEncodeFromImage(TempImg, xComponents, yComponents, PreShrink)
    FreeImage(TempImg)
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.i BlurHashDecodeToImage(Hash.s, DestImage.i = #PB_Any, width.i = #PB_Default, height.i = #PB_Default, PreShrink.i = #False)
  Protected Result.i = #Null
  
  If (Len(Hash) < 6)
    ProcedureReturn (#Null)
  EndIf
  
  Protected size_info.i = _BH_DecodeInt(Mid(Hash, 1, 1))
  Protected yComponents.i = Int(size_info / 9) + 1
  Protected xComponents.i = (size_info % 9) + 1
  
  If (Len(Hash) <> 4 + 2 * xComponents * yComponents)
    ProcedureReturn (#Null)
  EndIf
  
  
  If (width = #PB_Default)
    width = #BlurHash_PreShrinkSize
  EndIf
  If (height = #PB_Default)
    height = #BlurHash_PreShrinkSize
  EndIf
  
  If (PreShrink)
    Protected ExpandWidth.i  = width
    Protected ExpandHeight.i = height
    width  = #BlurHash_PreShrinkSize
    height = #BlurHash_PreShrinkSize
  EndIf
  
  
  Protected quant_max_value.i = _BH_DecodeInt(Mid(Hash, 2, 1))
  Protected real_max_value._BH_f = (1.0 + quant_max_value) / 166.0
  
  Dim factors._BH_f(yComponents - 1, xComponents - 1, 3 - 1)
  
  Protected i.i, j.i
  Protected value.i, intermediate.i
  Protected index.i = 6 + 1
  For j = 0 To yComponents - 1
    For i = 0 To xComponents - 1
      If ((i = 0) And (j = 0))
        value = _BH_DecodeInt(Mid(Hash, 3, 4))
        intermediate = (value >> 16) & $FF
        factors(0, 0, 0) = _BH_sRGBToLinear(intermediate)
        intermediate = (value >> 8) & $FF
        factors(0, 0, 1) = _BH_sRGBToLinear(intermediate)
        intermediate = (value >> 0) & $FF
        factors(0, 0, 2) = _BH_sRGBToLinear(intermediate)
      Else
        value = _BH_DecodeInt(Mid(Hash, index, 2))
        intermediate = (value / (19*19)) % 19
        factors(j, i, 0) = _BH_SignPow((intermediate - 9) / 9.0, 2.0) * real_max_value
        intermediate = (value / 19) % 19
        factors(j, i, 1) = _BH_SignPow((intermediate - 9) / 9.0, 2.0) * real_max_value
        intermediate = value % 19
        factors(j, i, 2) = _BH_SignPow((intermediate - 9) / 9.0, 2.0) * real_max_value
        index + 2
      EndIf
    Next i
  Next j
  
  Result = CreateImage(DestImage, width, height, 32)
  If (Result)
    If (DestImage = #PB_Any)
      DestImage = Result
    EndIf
    If (StartDrawing(ImageOutput(DestImage)))
      Protected x.i, y.i
      For y = 0 To height - 1
        For x = 0 To width - 1
          Dim pixel._BH_f(3 - 1)
          For j = 0 To yComponents - 1
            For i = 0 To xComponents - 1
              Protected basis._BH_f = Cos(#PI * i * x / width) * Cos(#PI * j * y / height)
              pixel(0) + factors(j, i, 0) * basis
              pixel(1) + factors(j, i, 1) * basis
              pixel(2) + factors(j, i, 2) * basis
            Next i
          Next j
          Plot(x, y, RGBA(_BH_LinearToSRGB(pixel(0)), _BH_LinearToSRGB(pixel(1)), _BH_LinearToSRGB(pixel(2)), $FF))
        Next x
      Next y
      StopDrawing()
      If (PreShrink)
        ResizeImage(DestImage, ExpandWidth, ExpandHeight)
      EndIf
    EndIf
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.i BlurHashDecodeToFile(Hash.s, DestFile.s, width.i = #PB_Default, height.i = #PB_Default, PreShrink.i = #False)
  Protected Result.i = #Null
  Protected TempImg.i = BlurHashDecodeToImage(Hash, #PB_Any, width, height, PreShrink)
  If (TempImg)
    Result = _BH_ImageToFile(TempImg, DestFile, #True)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i BlurHashImageToImage(SourceImage.i, DestImage.i = #PB_Any, xComponents.i = #PB_Default, yComponents.i = #PB_Default, width.i = #PB_Default, height.i = #PB_Default, PreShrink.i = #False)
  Protected Result.i = #Null
  Protected Hash.s = BlurHashEncodeFromImage(SourceImage, xComponents, yComponents, PreShrink)
  If (Hash)
    If (width = #PB_Default)
      width = ImageWidth(SourceImage)
    EndIf
    If (height = #PB_Default)
      height = ImageHeight(SourceImage)
    EndIf
    Result = BlurHashDecodeToImage(Hash, DestImage, width, height, PreShrink)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i BlurHashFileToFile(SourceFile.s, DestFile.s, xComponents.i = #PB_Default, yComponents.i = #PB_Default, width.i = #PB_Default, height.i = #PB_Default, PreShrink.i = #False)
  Protected Result.i = #False
  
  Protected TempImg.i = LoadImage(#PB_Any, SourceFile)
  If (TempImg)
    If (width = #PB_Default)
      width = ImageWidth(TempImg)
    EndIf
    If (height = #PB_Default)
      height = ImageHeight(TempImg)
    EndIf
    Protected Hash.s = BlurHashEncodeFromFile(SourceFile, xComponents, yComponents, PreShrink)
    FreeImage(TempImg)
    If (Hash)
      TempImg = BlurHashDecodeToImage(Hash, #PB_Any, width, height, PreShrink)
      If (TempImg)
        Result = _BH_ImageToFile(TempImg, DestFile, #True)
      EndIf
    EndIf
  EndIf
  
  ProcedureReturn (Result)
EndProcedure


CompilerEndIf
;-
