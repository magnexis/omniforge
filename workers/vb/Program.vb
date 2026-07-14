Imports System
Imports System.Text.Json

Module Program
    Private Sub Send(payload As String)
        Console.WriteLine(payload)
    End Sub

    Sub Main()
        Dim line As String = Console.ReadLine()
        While line IsNot Nothing
            Using document = JsonDocument.Parse(line)
                Dim root = document.RootElement
                Dim messageType = root.GetProperty("type").GetString()
                If messageType = "HELLO" Then
                    Send("{""type"":""REGISTER"",""protocol"":""ofp/1"",""workerId"":""vb-reverse-01"",""language"":""vb"",""runtimeVersion"":""net9.0"",""workerVersion"":""0.1.0"",""capabilities"":[{""name"":""text.reverse""}]}")
                ElseIf messageType = "JOB_START" Then
                    Dim capability = root.GetProperty("capability").GetString()
                    Dim jobId = root.GetProperty("jobId").GetString()
                    If capability <> "text.reverse" Then
                        Send("{""type"":""JOB_ERROR"",""jobId"":""" & jobId & """,""error"":""unsupported capability""}")
                    Else
                        Dim text = root.GetProperty("input").GetProperty("text").GetString()
                        Dim chars = text.ToCharArray()
                        Array.Reverse(chars)
                        Dim reversed = New String(chars)
                        Dim escaped = reversed.Replace("\", "\\").Replace("""", "\""")
                        Send("{""type"":""JOB_RESULT"",""jobId"":""" & jobId & """,""output"":{""reversed"":""" & escaped & """}}")
                    End If
                ElseIf messageType = "SHUTDOWN" Then
                    Exit While
                End If
            End Using
            line = Console.ReadLine()
        End While
    End Sub
End Module
