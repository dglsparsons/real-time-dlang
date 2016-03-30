pragma Task_Dispatching_Policy(FIFO_Within_Priorities);
with Ada.Text_IO; use Ada.Text_IO; 
with Ada.Real_Time; use Ada.Real_Time; 

procedure Ada_Profile is 
    pragma Priority(90); 
    Clock_Before : Time; 
    Cancel_Time : Time; 
    Clock_After  : Time; 
    Clock_Starting : Time; 

    Setup_Duration : Time_Span; 
    TearDown_Duration : Time_Span; 

begin 

    for i in 1..10000 loop
        
        Clock_Before := Clock; 
        Cancel_Time := Clock_Before + Milliseconds(10);

        select 
            delay until Cancel_Time;
        then abort
            Clock_Starting := Clock; 
            loop 
                delay 0.0; 
            end loop; 
        end select; 
        Clock_After := Clock; 

        if i mod 10 = 0 then
            Put("Cancelled " & Integer'image(i));
        end if;
        if i = 1 then 
            Setup_Duration := Clock_Starting - Clock_Before; 
            TearDown_Duration := Clock_After - Cancel_Time; 
        else
            Setup_Duration    := Setup_Duration + Clock_Starting - Clock_Before; 
            TearDown_Duration := TearDown_Duration + Clock_After - Cancel_Time; 
        end if;

    end loop;

    Put_Line(" ");
    Put_Line("Total setup:    " & Duration'Image(To_Duration(Setup_Duration)));
    Put_Line("Total teardown: " & Duration'Image(To_Duration(TearDown_Duration)));
end Ada_Profile; 
