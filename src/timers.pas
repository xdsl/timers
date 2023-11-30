{$mode objfpc}
unit timers;

// tmUseLIBC определяет использование clock_gettime библиотеки Си
// вместо системного вызова
{$DEFINE tmUseLIBC}

// tmRangeCheck генерирует проверки корректности номера таймера
{$DEFINE tmRangeCheck}

interface
uses unix,linux;

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

// инлайн-функции быстрых замеров времени, без проверок на возможные ошибки;
// возвращает результат в заявленных единицах - время,
// прошедшее от начала загрузки системы
function nanotime:QWord;inline;
function microtime:QWord;inline;
function millitime:QWord;inline;

// Определения clock_gettime_c и CLOCK_BOOTTIME формально могут быть перенесены
// из интерфейсной секции в секцию реализации модуля, но в таком случае
// инлайн-функции быстрых замеров времени будут реализованы как обычные функции,
// с потерями в скорости выполнения.

{$IFDEF tmUseLIBC}
// Функция clock_gettime в модуле linux реализована через системный вызов,
// что в общем случае медленнее, чем обращение к библиотечной функции, так как
// системные вызовы переключаются в режим работы ядра ОС с повышением привилегий,
// а библиотечные функции исполняются в пользовательском пространстве текущего процесса.
// Здесь определяется clock_gettime_c, с гарантией доступа к функции clock_gettime библиотеки Си.
function clock_gettime_c(clock_id:clockid_t; tp:Ptimespec):cint;cdecl;external 'c' name 'clock_gettime';
{$ENDIF}

// /usr/include/time.h
// # define CLOCK_BOOTTIME			7
// /* Like CLOCK_REALTIME but also wakes suspended system.  */
const CLOCK_BOOTTIME=7;

// используемый счетчик времени

var timerClock:clockid_t=CLOCK_MONOTONIC;

implementation

var tm:array [0..MaxTimers-1] of QWord;
    useClock:boolean=true;

function GetNanoClock: QWord;
 var ts: TTimeSpec;
     tp: TTimeVal;
begin
{$IFDEF tmUseLIBC}
 if clock_gettime_c(timerClock, @ts)=0 then
{$ELSE}
 if clock_gettime(timerClock, @ts)=0 then
{$ENDIF}
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

function nanotime:QWord;inline;
  var ts: TTimeSpec;
 begin
 {$IFDEF tmUseLIBC}
  clock_gettime_c(timerClock, @ts);
 {$ELSE}
  clock_gettime(timerClock, @ts);
 {$ENDIF}
  result:=QWord(ts.tv_sec) * 1000000000 + QWord(ts.tv_nsec);
 end;

function microtime:QWord;inline;
  var ts: TTimeSpec;
 begin
 {$IFDEF tmUseLIBC}
  clock_gettime_c(timerClock, @ts);
 {$ELSE}
  clock_gettime(timerClock, @ts);
 {$ENDIF}
  result:=QWord(ts.tv_sec) * 1000000 + QWord(ts.tv_nsec) div 1000;
 end;

function millitime:QWord;inline;
  var ts: TTimeSpec;
 begin
 {$IFDEF tmUseLIBC}
  clock_gettime_c(timerClock, @ts);
 {$ELSE}
  clock_gettime(timerClock, @ts);
 {$ENDIF}
  result:=QWord(ts.tv_sec) * 1000 + QWord(ts.tv_nsec) div 1000000;
 end;

end.