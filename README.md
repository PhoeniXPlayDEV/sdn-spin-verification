# Верификация протокола SDN

## Предисловие

В решении не использовались предложенные в задании сигналы TIME_TRANSITION, LOSS_Channel1 и LOSS_Channel2 для перехода по таймауту и из-за потери сообщений соответственно, т.к. их можно представить как недетерминированные переходы внутри подавтомата.

Переход по таймауту решено было сделать в виде недерминированного перехода без ввода счетчика аналогично следующему примеру:
```
byte timer = 0;
do
:: (timer <= TIMEOUT) -> {
      if
      :: nfull(ch5) -> {
            ch5 ? msg;
            state_Cont = 0;
            printf("[OUT] Cont: 5 ? ACK_Channel1 go from s2 to s0 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont, flow_entry_switch);
            break;
         }
      :: empty(ch5) -> timer = timer + 1;
      fi
   }
:: (timer > TIMEOUT) -> {
      state_Cont = 1;
      printf("[OUT] Cont: TIMEOUT go from s2 to s1 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont, flow_entry_switch);
      break;
   }
od
```
с целью уменьшения числа состояний.

Дополнительно введена глобальная переменная переменная errors для отладки программы-модели.

## Запуск

### Проверка на отсутствие отрицательного число правил

```
spin -run -bfs -ltl no_negative_rules sdn.pml
```

### Проверка отсутствия deadlock-а

```
spin -run -bfs -ltl no_deadlock sdn.pml
```

### Проверка отсутствия ошибок в программе

```
spin -run -bfs -ltl no_errors sdn.pml
```

## Проверка на неотрицательность числа правил

При выполнении следующей команды был найден контрпример с отрицательным числом правил:
```
spin -run -bfs -ltl no_negative_rules sdn.pml
```

Для краткого вывода можно использовать следующую команду:
```
spin -t -p sdn.pml | grep -P "\s+\[OUT\]"
```

### Вывод верификатора:
```
              [OUT] App: 1 ! PostFlow_App go from s0 to s1 (flow_entry_cont = 1 | flow_entry_switch = 0)
                  [OUT] Cont: 1 ? PostFlow_App go from s0 to s1 (flow_entry_cont = 1 | flow_entry_switch = 0)
                  [OUT] Cont: 2 ! PostFlow_Cont go from s1 to s2 (flow_entry_cont = 1 | flow_entry_switch = 0)
                      [OUT] Channel1: 2 ? PostFlow_Cont go from s0 to s1 (flow_entry_cont = 1 | flow_entry_switch = 0)
                      [OUT] Channel1: 3 ! PostFlow_Channel1 go from s1 to s0 (flow_entry_cont = 1 | flow_entry_switch = 0)
                              [OUT] Switch: 3 ? PostFlow_Channel1 go from s0 to s1 (flow_entry_cont = 1 | flow_entry_switch = 1)
                              [OUT] Switch: 4 ! ACK_Switch go from s1 to s0 (flow_entry_cont = 1 | flow_entry_switch = 1)
                          [OUT] Channel2: 4 ? ACK_Switch go from s0 to s1 (flow_entry_cont = 1 | flow_entry_switch = 1)
                          [OUT] Channel2: 5 ! ACK_Channel2 go from s1 to s0 (flow_entry_cont = 1 | flow_entry_switch = 1)
                  [OUT] Cont: 5 ? ACK_Channel1 go from s2 to s0 (flow_entry_cont = 1 | flow_entry_switch = 1)
              [OUT] App: 1 ! DeleteFlow_App go from s1 to s1 (flow_entry_cont = 0 | flow_entry_switch = 1)
                  [OUT] Cont: 1 ? DeleteFlow_App go from s0 to s3 (flow_entry_cont = 0 | flow_entry_switch = 1)
                  [OUT] Cont: 2 ! DeleteFlow_Cont go from s3 to s4 (flow_entry_cont = 0 | flow_entry_switch = 1)
                      [OUT] Channel1: 2 ? DeleteFlow_Cont go from s0 to s2 (flow_entry_cont = 0 | flow_entry_switch = 1)
                      [OUT] Channel1: 3 ! DeleteFlow_Channel1 go from s2 to s0 (flow_entry_cont = 0 | flow_entry_switch = 1)
                              [OUT] Switch: 3 ? DeleteFlow_Channel1 go from s0 to s1 (flow_entry_cont = 0 | flow_entry_switch = 0
)
                              [OUT] Switch: 4 ! ACK_Switch go from s1 to s0 (flow_entry_cont = 0 | flow_entry_switch = 0)
                  [OUT] Cont: TIMEOUT go from s4 to s3 (flow_entry_cont = 0 | flow_entry_switch = 0)
                  [OUT] Cont: 2 ! DeleteFlow_Cont go from s3 to s4 (flow_entry_cont = 0 | flow_entry_switch = 0)
                      [OUT] Channel1: 2 ? DeleteFlow_Cont go from s0 to s2 (flow_entry_cont = 0 | flow_entry_switch = 0)
                      [OUT] Channel1: 3 ! DeleteFlow_Channel1 go from s2 to s0 (flow_entry_cont = 0 | flow_entry_switch = 0)
                              [OUT] Switch: 3 ? DeleteFlow_Channel1 go from s0 to s1 (flow_entry_cont = 0 | flow_entry_switch = -
1)
```

### Пояснения к выводу

1: Приложение отправляет сообщение контроллеру с желанием увеличить число правил на единицу и увеличивает свой внутренний счётчик числа правил на единицу. Т. е. теперь с точки зрения приложения выставлено одно правило (flow_entry_cont = 1).

2 - 3: Контроллер получает сообщение от приложения и передаёт его по ненадёжному каналу №1.

4 - 5: Первый канал успешно передаёт сообщение от контроллера на маршрутизатор без его потери.

6: Маршрутизатор, успешно получив сообщение об увеличении числа правил на единицу, увеличивает свой счётчик числа правил на единицу. Теперь с точки зрения маршрутизатора выставлено одно правило (flow_entry_switch = 1).

7: Маршрутизатор по ненадёжному каналу №2 отправляет сообщение о том, что команда была успешно выполнена.

8 - 10: Сообщение от маршрутизатора успешно доставляется на контроллер без потери. Причём с момента отправки сообщения-команды с контроллера на маршрутизатор и получения сообщения-подтверждения от маршрутизатора проходит меньше времени, чем установлено для таймаута. Автомат "Контроллер" возвращается в своё исходное состояние.

11: Поскольку число правил с точки зрения приложения на данном шаге равно 1, возможно либо его уменьшение, либо увеличение на единицу. Приложение решает уменьшить число правил и сообщает об этом желании контроллеру, уменьшая свой внутренний счётчик числа правил на единицу. Теперь с точки зрения приложения не выставлено ни одного правила на маршрутизаторе (flow_entry_cont = 0).

12 - 13: Контроллер получает сообщение от приложения и передаёт его по ненадёжному каналу №2.

14 - 15: Второй канал успешно передаёт сообщение от контроллера на маршрутизатор без его потери.

16: Маршрутизатор, успешно получив сообщение об уменьшении числа правил на единицу, уменьшает свой счётчик числа правил на единицу. Теперь с точки зрения маршрутизатора не выставлено ни одного правила (flow_entry_switch = 0).

17: Маршрутизатор по ненадёжному каналу №2 отправляет сообщение о том, что команда была успешно выполнена.

18 - 19: К данному моменту контроллер всё ещё не получает сообщения-подтверждения от маршрутизатора и считает, что отправленная им команда была потеряна вторым каналом, что, как можно заметить, неверно. Автомат "Контроллер" переходит по таймауту из состояния s4 в состояние s3 и повторяет отправку команды уменьшения числа правил на единицу.

20 - 21: Второй канал снова успешно передаёт сообщение от контроллера на маршрутизатор без его потери.

22: Маршрутизатор, в очередной раз успешно получив сообщение об уменьшении числа правил на единицу от контроллера, уменьшает свой счётчик числа правил ещё на единицу, т. е. счётчик правил маршрутизатора меняется с 0 на -1 (flow_entry_switch = -1), что, естественно, является неверным поведением программы. Очевидно, что подобным образом можно установить число правил на маршрутизаторе больше 10, что тоже нарушает корректность работы системы.

Таким образом, проблема протокола заключается в отсутствии механизма проверки текущего состояния маршрутизатора перед выполнением команды. Это приводит к накоплению ошибок при повторной передаче команды из-за задержек или потерь подтверждающих сообщений. Решением может быть введение механизма согласования состояния между контроллером и маршрутизатором, а также защита от некорректных изменений счётчика правил.

## Проверка на отсутствие тупиковой ситуации в системе (deadlock)

Для данной проверки использовалась следующая LTL-формула, которая указывает, что программа всегда может сделать следующий ход:
```
[]<>(1)
```

Доказать наличие тупиковой ситуации (deadlock) в системе или её отсутствие не удалось, поскольку вычислительных ресурсов машины, на которой проводилась верификация, оказалось недостаточно.

Вывод после приостановки программы спустя более 30 минут работы:
```
Depth=     649 States=  9.6e+07 Transitions= 2.38e+08 Memory= 12414.414 t= 1.84e+03 R=   5e+04
^CInterrupted

(Spin Version 6.5.2 -- 6 December 2019)
Warning: Search not completed
        + Breadth-First Search
        + Partial Order Reduction

Full statespace search for:
        never claim             + (no_deadlock)
        assertion violations    + (if within scope of claim)
        cycle checks            - (disabled by -DSAFETY)
        invalid end states      - (disabled by never claim)

State-vector 124 byte, depth reached 649, errors: 0
 96152713 states, stored
        7.09651e+07 nominal states (- rv and atomic)
        2.12713e+06 rvs succeeded
1.4206058e+08 states, matched
2.3821329e+08 transitions (= stored+matched)
        0 atomic steps
hash conflicts:  90163332 (resolved)

Stats on memory usage (in Megabytes):
13938.153       equivalent memory usage for states (stored*(State-vector + overhead))
11921.317       actual memory usage for states (compression: 85.53%)
                state-vector as stored = 102 byte + 28 byte overhead
  512.000       memory used for hash table (-w26)
12433.066       total actual memory usage
```
