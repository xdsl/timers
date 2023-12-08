
unit timers_mono;
// tmRangeCheck генерирует проверки корректности номера таймера
{$DEFINE tmRangeCheck}

interface
type QWord=uInt64;
// единицы измерения времени
type TTimerUnit=longint;
const
    cNano=1;
    cMicro=1000;
    cMilli=1000000;
// максимальное кол-во таймеров
// пользователю доступны таймеры от 0 до maxTimers-1
const maxTimers=100;

// старт таймера tmNumber
procedure timerStart(tmNumber:integer:=0);
// время, прошедшее со старта таймера tmNumber в единицах tmUnit
function timerGet(tmNumber:integer:=0; tmUnit:TTimerUnit:=cNano): QWord;
// время, прошедшее со старта таймера tmNumber в наносекундах
function timerNano(tmNumber:integer:=0): QWord;
// время, прошедшее со старта таймера tmNumber в микросекундах
function timerMicro(tmNumber:integer:=0): QWord;
// время, прошедшее со старта таймера tmNumber в миллисекундах
function timerMilli(tmNumber:integer:=0): QWord;

// рекомендует использование единицы измерения
// tmEpsilon - максимальная погрешность в процентах
function timerAdvice(tmEpsilon:QWord:=1): TTimerUnit;

// функции быстрых замеров времени, без проверок на возможные ошибки;
// возвращает результат в заявленных единицах - время, определяемое счетчиком timerClock
function nanotime:QWord;
function microtime:QWord;
function millitime:QWord;
// инлайн-функции - псевдонимы для nanotime, microtime и millitime
function nanosec:QWord;
function microsec:QWord;
function millisec:QWord;

const
    CLOCK_BOOTTIME=7;
    CLOCK_MONOTONIC=1;

// используемый счетчик времени
var timerClock:longint=CLOCK_MONOTONIC;

implementation

type
 ptimespec=^timespec;
 timespec = record
  tv_sec: int64;
  tv_nsec: int64;
 end;

function clock_gettime_c(clock_id:longint; tp:ptimespec):longint; external 'libc.so.6' name 'clock_gettime';

var tm:array [0..MaxTimers-1] of QWord;
    useClock:boolean=true;

function GetNanoClock: QWord;
 var ts: TimeSpec;
begin
 if clock_gettime_c(timerClock, @ts)=0 then
  result:=QWord(ts.tv_sec) * 1000000000 + QWord(ts.tv_nsec)
 else result:=System.DateTime.Now.Ticks*100;
end;

procedure timerStart(tmNumber:integer);
begin
{$IFDEF tmRangeCheck}
  if (tmNumber<0)or(tmNumber>=MaxTimers) then exit;
{$ENDIF}
 tm[tmNumber]:=GetNanoClock;
end;

function timerGet(tmNumber:integer; tmUnit:TTimerUnit): QWord;
 begin
{$IFDEF tmRangeCheck}
  if (tmNumber<0)or(tmNumber>=MaxTimers) then begin result:=0; exit; end;
{$ENDIF}
  result:=(GetNanoClock()-tm[tmNumber]) div QWord(tmUnit);
 end;

function timerNano(tmNumber:integer): QWord; begin result:=timerGet(tmNumber,cNano); end;
function timerMicro(tmNumber:integer): QWord; begin result:=timerGet(tmNumber,cMicro); end;
function timerMilli(tmNumber:integer): QWord; begin result:=timerGet(tmNumber,cMilli); end;

function timerAdvice(tmEpsilon:QWord): TTimerUnit;
  var delta:QWord;
 begin
  delta:=GetNanoClock();
  delta:=GetNanoClock()-delta;
  tmEpsilon*=10;
  writeln(delta,' ',tmepsilon);
  result:=cNano;
  if useClock and (delta<tmEpsilon) then exit;
  tmEpsilon*=100;
  writeln(delta,' ',tmepsilon);
  result:=cMicro;
  if delta<tmEpsilon then exit;
  result:=cMilli;
 end;

function nanotime:QWord;
  var ts: TimeSpec;
 begin
  clock_gettime_c(timerClock, @ts);
  result:=QWord(ts.tv_sec) * 1000000000 + QWord(ts.tv_nsec);
 end;

function microtime:QWord;
  var ts: TimeSpec;
 begin
  clock_gettime_c(timerClock, @ts);
  result:=QWord(ts.tv_sec) * 1000000 + QWord(ts.tv_nsec) div 1000;
 end;

function millitime:QWord;
  var ts: TimeSpec;
 begin
  clock_gettime_c(timerClock, @ts);
  result:=QWord(ts.tv_sec) * 1000 + QWord(ts.tv_nsec) div 1000000;
 end;

function nanosec:QWord;begin result:=nanotime(); end;
function microsec:QWord;begin result:=microtime(); end;
function millisec:QWord;begin result:=millitime(); end;

end.