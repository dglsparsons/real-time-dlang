pragma Task_Dispatching_Policy(FIFO_Within_Priorities);
with Ada.Text_IO; use Ada.Text_IO; 
with Ada.Real_Time; use Ada.Real_Time; 

procedure Ada_Profile is 
    pragma Priority(90); 
    Clock_Before : Time; 
    Clock_During : Time; 
    Clock_After  : Time; 
    Clock_Starting : Time; 

    Setup_Duration : Time_Span; 
    TearDown_Duration : Time_Span; 

begin 

    for i in 1..1000 loop
        
        Clock_Before := Clock; 
        select 
            delay 1.0;--until x; 
            Clock_During := Clock;
            Put("Cancelled " & Integer'image(i));
        then abort
            Clock_Starting := Clock; 
            loop 
                delay 0.0; 
            end loop; 
        end select; 
        Clock_After := Clock; 

        if i = 1 then 
            Setup_Duration := Clock_Starting - Clock_Before; 
            TearDown_Duration := Clock_After - Clock_During; 
        else
            Setup_Duration    := Setup_Duration + Clock_Starting - Clock_Before; 
            TearDown_Duration := TearDown_Duration + Clock_After - Clock_During; 
        end if;

    end loop;

    Put_Line(" ");
    Put_Line("Total setup:    " & Duration'Image(To_Duration(Setup_Duration)));
    Put_Line("Total teardown: " & Duration'Image(To_Duration(TearDown_Duration)));
end Ada_Profile; 
