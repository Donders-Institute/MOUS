 active_buttons           = 3;                                  
 button_codes             = 1,2,3;	
begin;
trial {
	stimulus_event{ 
			sound{
				wavefile{
					filename ="EQ_Ramp_Int2_Int1LPF045.wav"; 
					preload = true; 
				}input;
			} soundfile; 
		time = 0;
		code = "start";
	}start;  
	
}sentence;

begin_pcl;
int row;
loop		
	row = 1; #loop for the blocks
	until
	row > 10
	begin	
	sentence.present();
	row = row +1;
end