'http://blog.csdn.net/zhanghongju/article/details/18445591
Option Explicit
Const START_ROW As Integer = 20
Const START_TAB As Integer = 1
'Const MAX_COL As Integer = 50

Sub addCough()
'addRow "C", "咳嗽了一次"
addRow "咳嗽", "咳嗽了一次"
'Format(Now(), "yyyymmddhhMMss")

End Sub
Sub addAqi()
addRow "打喷嚏", "打了一次喷嚏"

End Sub

Sub addMedicine()
addRow "吃药", "吃了一次药"

End Sub
Sub addMilk()
addRow "吃奶", "吃了一次奶"

End Sub
Sub addRice()
addRow "吃米粉", "吃了一次米粉"

End Sub
Sub addVeg()
addRow "吃菜汁", "吃了一次蔬菜汁"

End Sub
Sub addFruit()
addRow "吃果汁", "吃了一次果汁"

End Sub
Sub addPepe()
addRow "换尿布", "换了一次尿布"

End Sub
Sub addBath()
addRow "洗澡", "洗了一次澡"

End Sub


Function addRow(ByVal topic As String, ByVal msg As String)
Dim row As Integer
Dim ws As Object
Dim sheetName As String
Dim timeStr As String
Dim wsNew As Object
Dim events As String
Dim col As Integer
Dim i As Integer
Dim date_str As String
Dim time_str As String
Dim datetime_str As String

'工作表名以日期格式命名
time_str = Format(Now(), "hh:nn:ss")
date_str = Format(Now(), "yyyy-mm-dd")
datetime_str = date_str & " " & time_str

sheetName = date_str

'如果取得工作表对象失败，则继续
On Error Resume Next
Set ws = Sheets(sheetName)

'从模板template工作表新建至模板之后
If Err.Number <> 0 Then
    Worksheets("template").Copy After:=Worksheets("template")
    Set ws = Sheets(Sheets("template").Index + 1)
    ws.Name = sheetName
    ws.Cells(START_TAB + 1, 1).Value = date_str & " 4:00:00"
    ws.Cells(START_TAB + 2, 1).Value = date_str & " 8:00:00"
    ws.Cells(START_TAB + 3, 1).Value = date_str & " 12:00:00"
    ws.Cells(START_TAB + 4, 1).Value = date_str & " 16:00:00"
    ws.Cells(START_TAB + 5, 1).Value = date_str & " 20:00:00"
    ws.Cells(START_TAB + 6, 1).Value = date_str & " 23:59:59"
    
End If

'从第一行查找对应主题的列名
'For i = 1 To MAX_COL
'    If ws.Cells(1, i).Value = topic Then
'        col = i
'        Debug.Print "Find " & topic & " column index = " & i
'        Exit For
'    End If
'Next i

i = 1
col = 0
Do While ws.Cells(START_ROW, i) <> ""
    If ws.Cells(START_ROW, i).Value = topic Then
        col = i
        Debug.Print "Find " & topic & " column index = " & i
        Exit Do
    End If
    i = i + 1
Loop

'如未找到这一列，则从下一个空列加入该列
If col = 0 Then
    col = i
    ws.Cells(START_ROW, i).Value = topic
End If

'查找下一个空行
row = START_ROW
'Do While ws.Range(area) <> ""
Do While ws.Cells(row, 1) <> ""
    row = row + 1
Loop

'在此空行记录时间，值，事件等
time_str = Format(Now(), "hh:nn:ss")
date_str = Format(Now(), "yyyy-mm-dd")
datetime_str = date_str & " " & time_str

'ws.Cells(row, 1).Value = Time
ws.Cells(row, 1).Value = time_str
'ws.Cells(row, col).Value = "1"
ws.Cells(row, col).Value = datetime_str

'events = "在" & Date & " " & Time & msg
events = "在" & datetime_str & msg
ws.Cells(row, 2).Value = events

ThisWorkbook.Save
MsgBox "已记录" & events

End Function



Sub test()
Dim ws As Object
Dim new_ws As Object
'MsgBox Format(Now(), "yyyy-mmddhhMMss")
MsgBox Now()
ActiveSheet.Range("A1").Value = 1
ActiveSheet.Cells(1, 2).Value = 1

'On Error Resume Next
'Set ws = Sheets("hello")
'If Err.Number <> 0 Then
'Set new_ws = Worksheets("template")
'new_ws.Select
'new_ws.Copy Before:=Worksheets("template")
'new_ws.Name = "hello"

'Worksheets("template").Copy Before:=Worksheets("template")
'Worksheets(Worksheets.Count - 1).Name = "hello"
'ActiveSheet.Name = "hello"

'End If



End Sub


