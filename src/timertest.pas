{$mode objfpc}

uses timers,sysutils;
 var adv: TTimerUnit;
     tm:qword;
     i:integer;
begin

 adv:=timerAdvice();
 Writeln('Рекомендуемые единицы измерения времени');
 Writeln(adv);

 Writeln('Замеряем на таймере номер 0 время работы sleep(500) рекомендуемыми единицами измерения');
 timerStart(0);
 sleep(500);
 writeln(timerGet(0,adv));

 Writeln('Замеряем в НАНОсекундах на таймере номер 1 время работы sleep(500)');
 timerStart(1);
 sleep(500);
 writeln(timerNano(1));

 Writeln('Замеряем в МИКРОсекундах на таймере номер 1 время работы sleep(500)');
 timerStart(1);
 sleep(500);
 writeln(timerMicro(1));

 Writeln('Замеряем в МИЛЛИсекундах на таймере номер 0 время работы всех предыдущих sleep');
 writeln(timerMilli());

 Writeln('Делаем 10 последовательных замеров в наносекундах на таймере номер 0');
 for i:=1 to 10 do begin
    timerStart();
    writeln(timerNano());
 end;

 Writeln('Делаем 10 последовательных замеров в наносекундах высокоскоростной функцией nanotime');
 for i:=1 to 10 do begin
    tm:=nanotime();
    writeln(nanotime-tm);
 end;

end.