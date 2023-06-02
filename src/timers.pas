{$mode objfpc}

{$DEFINE tmUseLIBC}
{$DEFINE tmRangeCheck}

unit timers;
interface

// единицы измерения времени
type TTimerUnit=(cNano=1, cMicro=1000, cMilli=1000000);
// максимальное кол-во таймеров
// пользователю доступны таймеры от 0 до maxTimers-1
const maxTimers=100;

// старт таймера tmNumber
procedure timerStart(tmNumber:integer=0);
// время, прошедшее со старта таймера tmNumber в единицах tmUnit
function timerGet(tmNumber:integer=0; tmUnit:TTimerUnit=cNano): QWord;
// время, прошедшее со старта таймера tmNumber в наносекундах
function timerNano(tmNumber:integer=0): QWord;
// время, прошедшее со старта таймера tmNumber в микросекундах
function timerMicro(tmNumber:integer=0): QWord;
// время, прошедшее со старта таймера tmNumber в миллисекундах
function timerMilli(tmNumber:integer=0): QWord;

// рекомендует использование единицы измерения
// tmEpsilon - максимальная погрешность в процентах
function timerAdvice(tmEpsilon:QWord=1): TTimerUnit;

implementation
uses unix,linux;
{$IFDEF tmUseLIBC}
// clock_gettime в модуле linux может быть реализована через системный вызов,
// что в общем случае медленнее, чем обращение к библиотечной функции, так как
// системные вызовы переключаются в режим работы ядра ОС с повышением привелегий,
// а библиотечные функции исполняются в пользовательском пространстве текущего процесса.
// Здесь переопределяется clock_gettime, с гарантией доступа к функции библиотеки Си.
function clock_gettime(clock_id:clockid_t; tp:Ptimespec):cint;cdecl;external 'c' name 'clock_gettime';
{$ENDIF}

var tm:array [0..MaxTimers-1] of QWord;
    useClock:boolean=true;

function GetNanoClock: QWord;
 var ts: TTimeSpec;
     tp: TTimeVal;
begin
 if clock_gettime(CLOCK_MONOTONIC, @ts)=0 then
  result:=QWord(ts.tv_sec) * 1000000000 + QWord(ts.tv_nsec)
 else begin
  useClock:=false;
  fpgettimeofday(@tp, nil);
  result:=QWord(tp.tv_sec) * 1000000000 + QWord(tp.tv_usec * 1000);
 end;
end;

procedure timerStart(tmNumber:integer=0);
begin
{$IFDEF tmRangeCheck}
  if (tmNumber<0)or(tmNumber>=MaxTimers) then exit;
{$ENDIF}
 tm[tmNumber]:=GetNanoClock;
end;

function timerGet(tmNumber:integer=0; tmUnit:TTimerUnit=cNano): QWord;
 begin
{$IFDEF tmRangeCheck}
  if (tmNumber<0)or(tmNumber>=MaxTimers) then exit(0);
{$ENDIF}
  result:=(GetNanoClock()-tm[tmNumber]) div QWord(tmUnit);
 end;

function timerNano(tmNumber:integer=0): QWord; begin result:=timerGet(tmNumber,cNano); end;
function timerMicro(tmNumber:integer=0): QWord; begin result:=timerGet(tmNumber,cMicro); end;
function timerMilli(tmNumber:integer=0): QWord; begin result:=timerGet(tmNumber,cMilli); end;

function timerAdvice(tmEpsilon:QWord=1): TTimerUnit;
  var delta:QWord;
 begin
  delta:=GetNanoClock();
  delta:=GetNanoClock()-delta;
  tmEpsilon*=10;
  if useClock and (delta<tmEpsilon) then exit(cNano);
  tmEpsilon*=1000;
  if delta<tmEpsilon then exit(cMicro);
  result:=cMilli;
 end;

end.