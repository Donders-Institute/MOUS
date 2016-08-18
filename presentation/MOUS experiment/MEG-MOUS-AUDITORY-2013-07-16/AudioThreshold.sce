 active_buttons           = 12;                          
 button_codes             = 1,2,3,4,5,6,7,8,9,10,11,12,; 	
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
	row > 50
	begin	
	sentence.present();
	row = row +1;
end