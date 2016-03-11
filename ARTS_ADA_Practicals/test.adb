with Ada.text_io; use Ada.Text_Io; 

procedure Test is 

    procedure Main is 
        task Abortable; 
        task body Abortable is 
        begin 
            select 
                delay 2.0;
                put("Exited");
            then abort
                loop 
                    put("Hello, World!"); 
                    delay 0.1; 
                end loop; 
            end select;
        end Abortable;
    begin 
        null; 
    end Main;

begin 
    Main; 
    delay 2.0; 
end Test;
