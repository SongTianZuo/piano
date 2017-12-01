program player;
{$MODE objfpc}
{$codepage UTF8}

Uses 
windows,fgl;

const
    //channel: 0-127， (0-4) 是不同类形的钢琴
    Channel  =  3;

type
    Imap = specialize TFPGmap<longint,integer>;

var
    keymap: Imap;
    hMidiOut: longint;

Function midiOutClose(hMidiOut : Longint): longint;cdecl;external 'winmm.dll' name 'midiOutClose';
Function midiOutOpen(lphMidiOut: pointer;uDeviceID ,dwCallback ,dwInstance ,dwFlags : Longint) :Longint;cdecl;external 'winmm.dll' name 'midiOutOpen';
Function midiOutShortMsg(hMidiOut, dwMsg : longint): longint;cdecl;external 'winmm.dll' name 'midiOutShortMsg';

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
    Midimsg:   longint;
Begin
    //'23第一音符
    Midimsg := $90 + ((23 + n) * $100) + (Volumet * $10000) + Channel;
    midiOutShortMsg(hMidiOut, Midimsg);
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

{按下第 n个键}
Procedure SetPitchDown(n:integer);
Begin
    If (n>0) And (n<=88) Then
        playPitch(n);
End;

{弹起第 n个键}
Procedure SetPitchUp(n:integer);
Begin
    playPitch(n,0);
End;


var
    f:text;
    bplay:boolean=true;
    kk:ansistring;
    time:integer;
    i,n:integer;
    c:char;
begin
    if not((paramcount=1) or (paramcount=2)) then
    begin
        writeln('usage:');
        writeln('  player File');
        writeln('  player File noplay');
        exit;
    end;
    keymap:=Imap.create;
    initkeymap();
    if (paramcount=2) and (paramstr(2)='noplay') Then
        bplay:=false;
    assign(f,paramstr(1));
    reset(f);
    readln(f,time);
    readln(f,kk);
    close(f);
    kk:=upcase(kk);
    if bplay Then
        initmidi();
    //writeln(length(kk));
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

        try
            writeln(c);
            if bplay then SetPitchdown(n);
            sleep(time);       
            if bplay then SetPitchup(n);
        Except
            ;
        end;
    end;
    try
        keymap.free;
        if bplay then 
            midiOutClose(hMidiOut);
    finally
        exitprocess(0);
    end;
end.