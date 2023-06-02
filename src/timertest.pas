{$mode objfpc}
uses timers,sysutils;
 var adv: TTimerUnit;
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

end.