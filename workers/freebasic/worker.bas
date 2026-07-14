Dim Shared As String inputLine

Function ExtractValue(ByVal source As String, ByVal marker As String) As String
    Dim As Integer startPos = Instr(source, marker)
    If startPos = 0 Then Return ""
    Dim As Integer firstPos = startPos + Len(marker)
    Dim As Integer lastPos = Instr(firstPos, source, """")
    If lastPos = 0 Then Return ""
    Return Mid(source, firstPos, lastPos - firstPos)
End Function

Sub Emit(ByVal message As String)
    Print message
End Sub

Dim As String inputPath = Command(1)
If inputPath = "" Then End 1

If Open(inputPath For Input As #1) <> 0 Then End 1

While Not Eof(1)
    Line Input #1, inputLine
    If InStr(inputLine, """type"":""HELLO""") > 0 Then
        Emit("{""type"":""WELCOME"",""protocol"":""ofp/1"",""workerId"":""freebasic-sum-01"",""language"":""freebasic"",""runtimeVersion"":""1.10.1"",""workerVersion"":""0.1.0"",""status"":""ready""}")
        Emit("{""type"":""REGISTER"",""protocol"":""ofp/1"",""workerId"":""freebasic-sum-01"",""language"":""freebasic"",""runtimeVersion"":""1.10.1"",""workerVersion"":""0.1.0"",""capabilities"":[{""name"":""math.sum""}]}")
    ElseIf InStr(inputLine, """type"":""REGISTER_ACK""") > 0 Then
        Continue While
    ElseIf InStr(inputLine, """type"":""JOB_START""") > 0 Then
        If InStr(inputLine, """capability"":""math.sum""") = 0 Then
            Emit("{""type"":""JOB_ERROR"",""jobId"":""unknown"",""error"":""unsupported capability""}")
        Else
            Dim As String jobId = ExtractValue(inputLine, """jobId"":""")
            If jobId = "" Then jobId = "job-1"
            Emit("{""type"":""JOB_ACCEPTED"",""jobId"":""" & jobId & """,""status"":""running""}")
            Emit("{""type"":""JOB_LOG"",""jobId"":""" & jobId & """,""severity"":""info"",""message"":""starting math.sum""}")
            Dim As Integer openPos = InStr(inputLine, """numbers"":[")
            Dim As Double total = 0
            Dim As Integer count = 0
            If openPos > 0 Then
                Dim As Integer beginPos = openPos + Len("""numbers"":[")
                Dim As Integer endPos = InStr(beginPos, inputLine, "]")
                If endPos > beginPos Then
                    Dim As String body = Mid(inputLine, beginPos, endPos - beginPos)
                    Do While Len(body) > 0
                        Dim As Integer commaPos = InStr(body, ",")
                        Dim As String piece
                        If commaPos > 0 Then
                            piece = Trim(Left(body, commaPos - 1))
                            body = Mid(body, commaPos + 1)
                        Else
                            piece = Trim(body)
                            body = ""
                        End If
                        If piece <> "" Then
                            total += Val(piece)
                            count += 1
                        End If
                    Loop
                End If
            End If
            Emit("{""type"":""JOB_RESULT"",""jobId"":""" & jobId & """,""output"":{""count"":" & LTrim(Str(count)) & ",""sum"":" & LTrim(Str(total)) & "}}")
        End If
    ElseIf InStr(inputLine, """type"":""JOB_CANCEL""") > 0 Then
        Dim As String jobId = ExtractValue(inputLine, """jobId"":""")
        If jobId = "" Then jobId = "job-unknown"
        Emit("{""type"":""JOB_CANCELLED"",""jobId"":""" & jobId & """,""status"":""cancelled""}")
    ElseIf InStr(inputLine, """type"":""SHUTDOWN""") > 0 Then
        Emit("{""type"":""SHUTDOWN_ACK"",""workerId"":""freebasic-sum-01"",""status"":""stopped""}")
        Exit While
    End If
Wend

Close #1
