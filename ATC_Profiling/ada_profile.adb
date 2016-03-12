pragma Task_Dispatching_Policy(FIFO_Within_Priorities);
with Ada.Text_IO; use Ada.Text_IO; 
with Ada.Real_Time; use Ada.Real_Time; 

procedure Ada_Profile is 
    pragma Priority(90); 
    Clock_Before : Time; 
    Clock_During : Time; 
    Clock_After  : Time; 

    Setup_Duration : Time_Span; 
    TearDown_Duration : Time_Span; 

begin 

    --for i in 1..100 loop
        
        Clock_Before := Clock; 
        select 
            delay 1.0;--until x; 
            Clock_During := Clock;
            Put("Cancelled");
        then abort
            loop 
                null;
            end loop; 
        end select; 
        Clock_After := Clock; 

    Setup_Duration := Clock_During - Clock_Before; 
    TearDown_Duration := Clock_After - Clock_Before; 
    Put_Line("Setup: " & Duration'Image(To_Duration(Setup_Duration))); 
    Put_Line("Teardown: " & Duration'Image(To_Duration(TearDown_Duration))); 

    --end loop;
end Ada_Profile; 
