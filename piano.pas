
Program piano;
{$apptype gui}
{$MODE objfpc}
{$codepage UTF8}

Uses 
windows,fgl;

Const 
  //窗口名称
  AppName =   'piano';
  //窗口标题
  AppTitle =   'piano';
  //窗口的宽度
  WINDOW_WIDTH =   1100;
  //窗口的高度
  WINDOW_HEIGHT =   200;
  //channel: 0-127， (0-4) 是不同类形的钢琴
  Channel  =  3;

Type 
  Imap = specialize TFPGmap<longint,integer>;

Var 
  //对应的 88个 按键坐标的位置
  key:   array[1..88] Of RECT;
  //已经按下的键
  keyDown:   array[1..88] Of boolean;
  //内存DC
  Memory_DC:   hdc;
  //
  midBMP:   HBITMAP;
  keyBroadWidth:   integer =   0;
  //窗口画图的偏移量
  shift: integer;
  //鼠标最后一个经过
  lastMousePitch: integer = 0;
  keymap: Imap;
  hMidiOut: longint;
  mWindow  : hwnd;

Function midiOutClose(hMidiOut : Longint): longint;
cdecl;
external 'winmm.dll' name 'midiOutClose';
Function midiOutOpen(lphMidiOut: pointer;uDeviceID ,dwCallback ,dwInstance ,dwFlags : Longint) :
                                                                                             Longint
;
cdecl;
external 'winmm.dll' name 'midiOutOpen';
Function midiOutShortMsg(hMidiOut, dwMsg : longint): longint;
cdecl;
external 'winmm.dll' name 'midiOutShortMsg';

{初始化midi}
Procedure initmidi();
Begin
  If midiOutOpen(@hMidiOut,-1,0,0,0)<>0 Then
    Begin
      MessageBoxW(0,'不能打开midi设备','error',0);
      exitprocess(0);
    End;
End;

{播放}
Procedure playPitch(n: Integer; Volumet : Integer=127);

Var 
  Midimsg: longint;
Begin
  //'23第一音符
  Midimsg := $90 + ((23 + n) * $100) + (Volumet * $10000) + Channel;
  midiOutShortMsg(hMidiOut, Midimsg);
End;

{初始化键盘}
Procedure initKey();

Var 
  //k第k个按键
  i,j,k:   integer;
{p下一个按键的起始位置left偏移量, 下白键left:=p, 下一个黑键left:=p-7;}
  p:   integer =   0;
Begin
  For i:=1 To 88 Do
    keyDown[i] := false;

  //pitch 1 白键
  k := 1;
  key[k].left := p;
  key[k].top := 0;
  key[k].right := key[k].left+20;
  key[k].bottom := 144;
  P := key[k].right;

  //pitch 2 黑键
  inc(k);
  key[k].left := p-7;
  key[k].top := 0;
  key[k].right := key[k].left+14;
  key[k].bottom := 96;

  //pitch 3白键
  inc(k);
  key[k].left := p;
  key[k].top := 0;
  key[k].right := key[k].left+20;
  key[k].bottom := 144;
  P := key[k].right;

  For i := 1 To 7 Do
    Begin
{每一组的键 (白黑白黑白白黑白黑白黑白) 白 （1，3，5，6，8，10，12}
      For j:=1 To 12 Do
        Begin
          If (j=1) Or (j=3) Or (j=5) Or (j=6) Or (j=8) Or (j=10) Or (j
             =12) Then
            Begin
              inc(k);
              key[k].left := p;
              key[k].top := 0;
              key[k].right := key[k].left+20;
              key[k].bottom := 144;
              P := key[k].right;
            End
          Else
            Begin
              inc(k);
              key[k].left := p-7;
              key[k].top := 0;
              key[k].right := key[k].left+14;
              key[k].bottom := 96;
            End;
        End;
    End;

  //pitch 88
  inc(k);
  key[k].left := p;
  key[k].top := 0;
  key[k].right := key[k].left+20;
  key[k].bottom := 144;
  P := key[k].right;
  keyBroadWidth := p;
End;

Procedure initkeymap();
Begin
  keymap := Imap.create;
  keymap.add(VK_Z, 16);
  keymap.add(VK_X, 18);
  keymap.add(VK_C, 20);
  keymap.add(VK_V, 21);
  keymap.add(VK_B, 23);
  keymap.add(VK_N, 25);
  keymap.add(VK_M, 27);
  keymap.add(VK_A, 28);
  keymap.add(VK_S, 30);
  keymap.add(VK_D, 32);
  keymap.add(VK_F, 33);
  keymap.add(VK_G, 35);
  keymap.add(VK_H, 37);
  keymap.add(VK_J, 39);
  keymap.add(VK_Q, 40);
  keymap.add(VK_W, 42);
  keymap.add(VK_E , 44);
  keymap.add(VK_R , 45);
  keymap.add(VK_T , 47);
  keymap.add(VK_Y , 49);
  keymap.add(VK_U , 51);
  keymap.add($31 , 52);
  keymap.add($32 , 54);
  keymap.add($33 , 56);
  keymap.add($34 , 57);
  keymap.add($35 , 59);
  keymap.add($36 , 61);
  keymap.add($37 , 63);
  keymap.add(VK_K, 64);
  keymap.add(VK_L, 66);
  //;
  keymap.add(186, 68);
  keymap.add(VK_I, 69);
  keymap.add(VK_O, 71);
  keymap.add(VK_P, 73);
  keymap.add($38, 75);
  keymap.add(VK_NUMPAD1, 40);
  keymap.add(VK_NUMPAD2, 42);
  keymap.add(VK_NUMPAD3 , 44);
  keymap.add(VK_NUMPAD4 , 45);
  keymap.add(VK_NUMPAD5 , 47);
  keymap.add(VK_NUMPAD6 , 49);
  keymap.add(VK_NUMPAD7, 51);
End;


{将键盘画在 Memory_DC中}
Procedure DrawMemoryDC();

Var 
  i:   integer;
  brush:   hBrush;
Begin
  SelectObject (Memory_DC,GetStockObject (BLACK_PEN)) ;
  //先画白键
  For i:=1 To 88 Do
    Begin
      If key[i].bottom<>144 Then continue;
      If keyDown[i] Then
        brush := CreateSolidBrush (RGB(253,198,104))
      Else
        brush := CreateSolidBrush (RGB(255,255,255));
      //选择我们创建的笔刷
      SelectObject (Memory_DC,brush) ;
      //画矩形
      Rectangle(Memory_DC,key[i].left,key[i].top,key[i].right,key[i].
                bottom);
      //删除刚创建的笔刷
      DeleteObject(brush);
    End;
  //再画黑键
  For i:=1 To 88 Do
    Begin
      If key[i].bottom<>96 Then continue;
      If keyDown[i] Then
        brush := CreateSolidBrush (RGB(253,198,104))
      Else
        brush := CreateSolidBrush (RGB(0,0,0));
      //选择我们创建的笔刷
      SelectObject (Memory_DC,brush) ;
      //画矩形
      Rectangle(Memory_DC,key[i].left,key[i].top,key[i].right,key[i].
                bottom);
      //删除刚创建的笔刷
      DeleteObject(brush);
    End;
End;

{根据鼠标坐标x,y，返回pitch(n)}
Function getPitchByXY(x,y:longint): integer;

Var 
  i: integer;
Begin

  If (x<shift) Or (x>shift+keyBroadWidth)  Or (y>144)Then exit(0);

    {先检查黑键}
  For i:=1 To 88 Do
    Begin
      If key[i].bottom<>96 Then continue;
      If ((key[i].left+shift)<=x) And (key[i].top<=y) And (x<=(key[i].right+shift)) And (y<=key[i].
         bottom) Then
        exit(i);
    End;

    {再检查白键}
  For i:=1 To 88 Do
    Begin
      If key[i].bottom<>144 Then continue;
      If ((key[i].left+shift)<=x) And (key[i].top<=y) And (x<=(key[i].right+shift)) And (y<=key[i].
         bottom) Then
        exit(i);
    End;
  exit(0);
End;

{按下第 n个键}
Procedure SetPitchDown(n:integer);
Begin
  If (n>0) And (n<=88) Then
    Begin
      If Not keyDown[n] Then playPitch(n);
      keyDown[n] := true;

    End;
End;

{弹起第 n个键}
Procedure SetPitchUp(n:integer);
Begin
  If (n>0) And (n<=88) Then
    Begin
      playPitch(n,0);
      keyDown[n] := false;
    End;
End;

procedure music(kk:string; time:integer);
var
    i,n:integer;
    r:RECT;
    c:char;
begin
    kk:=upcase(kk);
    for i := 1 to length(kk) do
    begin
        c:=kk[i];
        if c='0' then
        begin
            sleep(time);
            continue;
        end;
        try
            if c=';' then
                n:=keymap[186]
            else
                n := keymap[ord(c)];
        Except
            sleep(time);
            continue;
        end;
        
        SetPitchdown(n);

        //sendmessage(window,WM_PAINT,0,0);
        r.left := key[n].left+shift;
        r.top := key[n].top;
        r.right := key[n].right+shift;
        r.bottom := key[n].bottom;
        InvalidateRect(mWindow,&r,true);
        UpdateWindow(mWindow);

        sleep(time);
        
        SetPitchup(n);
        //sendmessage(window,WM_PAINT,0,0);
        r.left := key[n].left+shift;
        r.top := key[n].top;
        r.right := key[n].right+shift;
        r.bottom := key[n].bottom;
        InvalidateRect(mWindow,&r,true);
        UpdateWindow(mWindow);
    end;
end;

{两只老虎 two tigers}
procedure music1();
var
    kk:string='qweqqweqerterttytreqtytreqwgqwgq';
    time:integer=500;
begin
    music(kk,time);
end;

{生日快乐 happy birthday}
procedure music2();
var
    kk:string='ttyt1uttyt21tt531uy443121';
begin
    music(kk,500);
end;


{消息处理}
Function WindowProc(Window: HWnd; AMessage: UINT; WParam : WPARAM;
                    LParam: LPARAM):   LRESULT;
stdcall;
export;

Var 
  dc :   hdc;
  x,y:   longint;
  r  :   RECT;
  n : integer;
  tid : longword;
Begin
  WindowProc := 0;
  Case AMessage Of 
    wm_create:{}
               Begin
                 mWindow:=window;
                 initmidi;
                 dc := getDc(window);
                 Memory_DC := CreateCompatibleDC (0);
                 midBMP := CreateCompatibleBitmap(dc,WINDOW_WIDTH,
                           WINDOW_HEIGHT);
                 SelectObject(Memory_DC,midBMP);
                 ReleaseDC(window,dc);
                 initKey();
                 initkeymap();
                 GetClientRect(window,&r);
                 shift := (r.right-r.left-keyBroadWidth) Div 2;
                 If shift<0 Then shift := 0;
                 exit;
               End;
    wm_paint: {}
              Begin
                DefWindowProc(Window, AMessage, WParam, LParam);
                dc := GetDC(window);
                DrawMemoryDC();
                BitBlt(dc,shift,0,keyBroadWidth,144,Memory_DC,0,0,SRCCOPY);
                ReleaseDC(window, dc) ;
                Exit;
              End;
    wm_keydown:{按下键盘}
                Begin
                  //writeln(WPARAM);
                  //writeln(LParam);
                  Try
                    n := keymap[WPARAM];
                    SetPitchDown(n);
                    lastMousePitch := n;

                    //sendmessage(window,WM_PAINT,0,0);
                    r.left := key[n].left+shift;
                    r.top := key[n].top;
                    r.right := key[n].right+shift;
                    r.bottom := key[n].bottom;
                    InvalidateRect(window,&r,true);
                    UpdateWindow(window);
                  Except
                    ;
                End;
    exit;
  End;
  wm_keyup:{键盘按键弹起}
            Begin
              Try
                if WPARAM= VK_F1 then begin createthread(nil,0,@music1,nil,0,tid); exit;end;
                if WPARAM= VK_F2 then begin createthread(nil,0,@music2,nil,0,tid); exit;end;
                n := keymap[WPARAM];
                
                SetPitchup(n);
                lastMousePitch := n;

                //sendmessage(window,WM_PAINT,0,0);
                r.left := key[n].left+shift;
                r.top := key[n].top;
                r.right := key[n].right+shift;
                r.bottom := key[n].bottom;
                InvalidateRect(window,&r,true);
                UpdateWindow(window);
              Except
                ;
            End;
  exit;
End;
wm_mousemove:{鼠标移动}
              Begin
                If (MK_LBUTTON And wParam ) <> 0 Then
                  Begin
                    y := LParam shr 16;
                    x := LParam And $ffff;
                    n := getPitchByXY(x,y);
                    If n=0 Then
                      Begin
                        SetPitchUp(lastMousePitch);
                        r.left := key[lastMousePitch].left+shift;
                        r.top := key[lastMousePitch].top;
                        r.right := key[lastMousePitch].right+shift;
                        r.bottom := key[lastMousePitch].bottom;
                        InvalidateRect(window,&r,true);
                        UpdateWindow(window);
                        lastMousePitch := 0;
                      End
                    Else If n<> lastMousePitch Then
                           Begin
                             SetPitchUp(lastMousePitch);
                             SetPitchDown(n);
                             //write(n,' ');
                             lastMousePitch := n;

                             //sendmessage(window,WM_PAINT,0,0);
                             r.left := key[n].left+shift;
                             r.top := key[n].top;
                             r.right := key[n].right+shift;
                             r.bottom := key[n].bottom;
                             InvalidateRect(window,&r,true);
                             UpdateWindow(window);
                           End;
                  End
                Else
                  Begin
                    lastMousePitch := 0;
                  End;
                exit;
              End;
WM_LBUTTONDOWN:{鼠标左键按下}
                Begin
                  y := LParam shr 16;
                  x := LParam And $ffff;
                  n := getPitchByXY(x,y);
                  If n<> lastMousePitch Then
                    Begin
                      SetPitchUp(lastMousePitch);
                      SetPitchDown(n);
                      lastMousePitch := n;

                      //sendmessage(window,WM_PAINT,0,0);
                      r.left := key[n].left+shift;
                      r.top := key[n].top;
                      r.right := key[n].right+shift;
                      r.bottom := key[n].bottom;
                      InvalidateRect(window,&r,true);
                      UpdateWindow(window);
                    End;
                  exit;
                End;
WM_LBUTTONUP:{鼠标左键弹起}
              Begin
                y := LParam shr 16;
                x := LParam And $ffff;
                n := getPitchByXY(x,y);
                SetPitchUp(n);
                lastMousePitch := 0;
                r.left := key[n].left+shift;
                r.top := key[n].top;
                r.right := key[n].right+shift;
                r.bottom := key[n].bottom;
                InvalidateRect(window,&r,true);
                UpdateWindow(window);
                exit;
              End;
wm_Destroy: { }
            Begin
              midiOutClose(hMidiOut);
              deleteDC(Memory_DC);
              keymap.free;
              PostQuitMessage(0);
              Exit;
            End;
End;
WindowProc := DefWindowProc(Window, AMessage, WParam, LParam);
End;

{ Register the Window Class }
Function WinRegister:   Boolean;

Var 
  WindowClass:   WndClass;
Begin
  WindowClass.Style := cs_hRedraw Or cs_vRedraw;
  WindowClass.lpfnWndProc := WndProc(@WindowProc);
  WindowClass.cbClsExtra := 0;
  WindowClass.cbWndExtra := 0;
  WindowClass.hInstance := system.MainInstance;
  WindowClass.hIcon := LoadIcon(0, idi_Application);
  WindowClass.hCursor := LoadCursor(0, idc_Arrow);
  WindowClass.hbrBackground := GetStockObject(WHITE_BRUSH);
  WindowClass.lpszMenuName := Nil;
  WindowClass.lpszClassName := AppName;
  Result := RegisterClass(WindowClass) <> 0;
End;{End Register}

{ Create the Window Class }
Function WinCreate:   HWnd;

Var 
  hWindow:   HWnd;
Begin
  hWindow := CreateWindow(AppName, AppTitle,
             ws_OverlappedWindow, cw_UseDefault, cw_UseDefault,
             WINDOW_WIDTH, WINDOW_HEIGHT, 0, 0, system.MainInstance, Nil);

  If hWindow <> 0 Then
    Begin
      ShowWindow(hWindow, CmdShow);
      ShowWindow(hWindow, SW_SHOW);
      UpdateWindow(hWindow);
    End;

  Result := hWindow;
End;{end create }

{main}

Var 
  AMessage :   Msg;
  hWindow :   hwnd;
Begin
  If Not WinRegister Then
    Begin
      MessageBox(0, 'Register failed', Nil, mb_Ok);
      Exit;
    End;
  hWindow := WinCreate;
  If longint(hWindow) = 0 Then
    Begin
      MessageBox(0, 'WinCreate failed', Nil, mb_Ok);
      Exit;
    End;
  While GetMessage(@AMessage, 0, 0, 0) Do
    Begin
      TranslateMessage(AMessage);
      DispatchMessage(AMessage);
    End;
  Halt(AMessage.wParam);
End. {end of main}
