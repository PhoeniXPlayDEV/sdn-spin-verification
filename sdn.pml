mtype = {
  PostFlow_App, DeleteFlow_App,
  PostFlow_Cont, DeleteFlow_Cont,
  PostFlow_Channel1, DeleteFlow_Channel1,
  ACK_Channel2, LOSS_Channel2,
  ACK_Switch
}

int flow_entry_cont = 0;
int flow_entry_switch = 0;

byte error_flag = 0;

byte state_App = 0;
byte state_Cont = 0;
byte state_Channel1 = 0;
byte state_Channel2 = 0;
byte state_Switch = 0;

chan ch1 = [0] of { mtype }
chan ch2 = [0] of { mtype }
chan ch3 = [0] of { mtype }
chan ch4 = [0] of { mtype }
chan ch5 = [0] of { mtype }

byte event = 0;

proctype App()
{
  printf("Start App\n")
  do
  :: (state_App == 0) -> {
        flow_entry_cont = 1;
        state_App = 1;
        printf("[OUT] App: 1 ! PostFlow_App go from s0 to s1 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont, flow_entry_switch);
        ch1 ! PostFlow_App;
     }

  :: (state_App == 1) -> {
        if
        :: flow_entry_cont <= 10 -> {
              printf("[OUT] App: 1 ! PostFlow_App go from s1 to s1 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont + 1, flow_entry_switch);
              flow_entry_cont = flow_entry_cont + 1;
              ch1 ! PostFlow_App;
           }
        :: flow_entry_cont >= 1 -> {
              printf("[OUT] App: 1 ! DeleteFlow_App go from s1 to s1 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont - 1, flow_entry_switch);
              flow_entry_cont = flow_entry_cont - 1;
              ch1 ! DeleteFlow_App;
           }
        :: flow_entry_cont == 1 -> {
              printf("[OUT] App: 1 ! DeleteFlow_App go from s1 to s0 (flow_entry_cont = %d | flow_entry_switch = %d)\n", 0, flow_entry_switch);
              flow_entry_cont = 0;
              state_App = 0;
              ch1 ! DeleteFlow_App;
           }
        :: else -> error_flag = 1;
        fi
     }
    od
}

proctype Cont()
{
  printf("Start Cont\n")
  byte msg;

  do
  :: (state_Cont == 0) -> {
        ch1 ? msg;
        if
        :: (msg == PostFlow_App) -> {
              state_Cont = 1;
              printf("[OUT] Cont: 1 ? PostFlow_App go from s0 to s1 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont, flow_entry_switch);
           }
        :: (msg == DeleteFlow_App) -> {
              state_Cont = 3;
              printf("[OUT] Cont: 1 ? DeleteFlow_App go from s0 to s3 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont, flow_entry_switch);
           }
        :: else -> error_flag = 1;
        fi
     }
  :: (state_Cont == 1) -> {
        printf("[OUT] Cont: 2 ! PostFlow_Cont go from s1 to s2 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont, flow_entry_switch);
        state_Cont = 2;
        ch2 ! PostFlow_Cont;
     }
  :: (state_Cont == 2) -> { 
        if
        :: nfull(ch5) -> {
              ch5 ? msg;
              state_Cont = 0;
              printf("[OUT] Cont: 5 ? ACK_Channel1 go from s2 to s0 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont, flow_entry_switch);
           }
        :: empty(ch5) -> {
              state_Cont = 1;
              printf("[OUT] Cont: TIMEOUT go from s2 to s1 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont, flow_entry_switch);
           }
        fi
     }
  :: (state_Cont == 3) -> {
        printf("[OUT] Cont: 2 ! DeleteFlow_Cont go from s3 to s4 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont, flow_entry_switch);
        state_Cont = 4;
        ch2 ! DeleteFlow_Cont;
     }
  :: (state_Cont == 4) -> {
        if
        :: nfull(ch5) -> {
              ch5 ? msg;
              state_Cont = 0;
              printf("[OUT] Cont: 5 ? ACK_Channel1 go from s4 to s0 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont, flow_entry_switch);
           }
        :: empty(ch5) -> {
              state_Cont = 3;
              printf("[OUT] Cont: TIMEOUT go from s4 to s3 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont, flow_entry_switch);
           }
        fi
     }
  od
}


proctype Channel1()
{
  printf("Start Channel 1\n")
  do
  :: (state_Channel1 == 0) -> {
        byte msg;
        ch2 ? msg;
        if
        :: (msg == PostFlow_Cont) -> {
              state_Channel1 = 1;
              printf("[OUT] Channel1: 2 ? PostFlow_Cont go from s0 to s1 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont, flow_entry_switch);
           }
        :: (msg == DeleteFlow_Cont) -> {
              state_Channel1 = 2;
              printf("[OUT] Channel1: 2 ? DeleteFlow_Cont go from s0 to s2 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont, flow_entry_switch);
           }
        :: else -> error_flag = 1;
        fi
     }
  :: (state_Channel1 == 1) -> {
        if
        :: 1 -> {
              printf("[OUT] Channel1: 3 ! PostFlow_Channel1 go from s1 to s0 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont, flow_entry_switch);
              ch3 ! PostFlow_Channel1;
           }
        :: 1 -> {
              printf("[OUT] Channel1: LOSS go from s1 to s0 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont, flow_entry_switch);
              skip;
           }
        fi
        state_Channel1 = 0;
     }
  :: (state_Channel1 == 2) -> {
        if
        :: 1 -> {
              printf("[OUT] Channel1: 3 ! DeleteFlow_Channel1 go from s2 to s0 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont, flow_entry_switch);
              ch3 ! DeleteFlow_Channel1;
           }
        :: 1 -> {
              printf("[OUT] Channel1: LOSS go from s2 to s0 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont, flow_entry_switch);
              skip;
           }
        fi
        state_Channel1 = 0;
     }
  od
}

proctype Channel2() {
  printf("Start Channel 2\n")
  do
  :: (state_Channel2 == 0) -> {
        byte msg;
        ch4 ? msg;
        if
        :: (msg == ACK_Switch) -> {
              state_Channel2 = 1;
              printf("[OUT] Channel2: 4 ? ACK_Switch go from s0 to s1 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont, flow_entry_switch);
           }
        :: else -> error_flag = 1;
        fi
     }
  :: (state_Channel2 == 1) -> {
        if
        :: 1 -> {
              printf("[OUT] Channel2: 5 ! ACK_Channel2 go from s1 to s0 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont, flow_entry_switch);
              ch5 ! ACK_Channel2;
           }
        :: 1 -> {
              printf("[OUT] Channel2: LOSS go from s1 to s0 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont, flow_entry_switch);
              skip;
           }
        fi
        state_Channel2 = 0;
     }
  od
}

proctype Switch()
{
  printf("Start Switch\n")
  do
  :: (state_Switch == 0) -> {
        byte msg;
        ch3 ? msg;
        if
        :: (msg == PostFlow_Channel1) -> {
              printf("[OUT] Switch: 3 ? PostFlow_Channel1 go from s0 to s1 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont, flow_entry_switch + 1);
              flow_entry_switch = flow_entry_switch + 1;
           }
        :: (msg == DeleteFlow_Channel1) -> {
              printf("[OUT] Switch: 3 ? DeleteFlow_Channel1 go from s0 to s1 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont, flow_entry_switch - 1);
              flow_entry_switch = flow_entry_switch - 1;
           }
        :: else -> error_flag = 1;
        fi
        state_Switch = 1;
     }
  :: (state_Switch == 1) -> {
        state_Switch = 0;
        printf("[OUT] Switch: 4 ! ACK_Switch go from s1 to s0 (flow_entry_cont = %d | flow_entry_switch = %d)\n", flow_entry_cont, flow_entry_switch);
        ch4 ! ACK_Switch;
     }
  od
}

init
{
    run App();
    run Cont();
    run Channel1();
    run Channel2();
    run Switch();
}




ltl no_negative_rules {
  [](flow_entry_cont >= 0 && flow_entry_switch >= 0)
}

ltl no_deadlock {
  []<>(1)
}

ltl no_errors {
  [](error_flag == 0)
}
