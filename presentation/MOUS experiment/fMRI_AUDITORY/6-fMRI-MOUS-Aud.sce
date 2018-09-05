 ################################################################
 # HEADER
 ################################################################
 
scenario = "6-fMRI-MOUS-Aud";                           					# Name of scenario (for logfile use)

 active_buttons           = 3;                                  
 button_codes             = 1,2,3;  # 1 == yes (left index), 2 == no (left middle finger), space bar continue after break
 response_matching = simple_matching;
 response_logging = log_active;
                              
 default_font_size        = 14;                                 # Default font size
 default_font             = "Courier new"; 							 # Font where all letter are equallt wide!!
 default_text_color		  = 0, 0, 0;
 default_background_color = 90, 90, 90;   
							 

#
# FMRI part
#

scenario_type				  = fMRI;							# trials, fMRI_emulation or fMRI
scan_period					  = 2000;										# TR (ms)
pulses_per_scan			  = 1;
pulse_code 					  = 50;


#--------------Triggers-----------------------------------------#
#
# Onset of sound in file & onset of Target file
# RC sentWord = 1; sent target = 2; seqWord = 3; seqTarget = 4
# MIX sentWord = 5; sent target = 6; seqWord = 7; seqTarget = 8 
# 
# Begining of sound file = 14
# Offset = 15; end of a sentence/sequence
# Fixation = 20; (fix is preceeded by blank scren 2sec. Fix duration between 1,2 - 2,2 sex.)
# Block title (zinnen/worden) = 10;
# Question = 40; (target buttons 1,2)
# 
# Note that question answers (yes/no) have the same trigger code as the RC sentWord = 1; sent target = 2;
#
#---------------------------------------------------------------#

begin;                                                                
#--------------objects array-----------------------------------------#

text  { caption = " "; } emptyT;
picture {} default;    # blank screen

picture { text emptyT;  x = 0; 	y = 0;} emptyP;
picture { text { caption = " "; };  x = 0; y = 0;} blank;
picture { text { caption = "+"; };  x = 0; y = 0;} fixP;

picture { text {caption = "Pauze \n 
Dit is het einde van de eerste helft. \n
Neem rustig even pauze. Beweeg NIET met je hoofd, 
maar blijf in dezelfde positie liggen.\n
Laat het de onderzoeker weten wanneer je weer verder wilt gaan."; font_size=16;};x=0;y=0;} pauze; 


#---Trials---------------------------------------#

trial {
	stimulus_event{ 
			sound{
				wavefile{
					filename =""; 
					preload = false; 
				}input;
			} soundfile; 
		time = 0;
		code = "14 Start File";
		port_code = 14; 
	}start;          

	stimulus_event{ 
		nothing {};
		time = 20;
		code = "Audio onset";  #MIX sentStart = 1; seqStart = 3;
		port_code = 1;		     #RC sentStart= 5; seqStart = 7; 		
	}soundBegin;  
	
	stimulus_event{ 
		nothing {};
		time = 200;
		code = "Target";
		port_code = 2; #MIX sentTarget = 2;seqTarget = 4
	}target;          #RC sentTarget = 6;seqTarget = 8	
	
	stimulus_event{ 
		nothing {};
		time = 200;
		code = "15 End of file";
		port_code = 15;
	}soundEnd;  

}words;


trial {
	trial_duration = 2000; 
	picture blank;
	time = 0;
	stimulus_event {
		picture emptyP;
		time = 300;
		code = "Instructions"; #show zinnen/worden for 1500 ms
		port_code = 10;
	} instcode;	
}instruction;

trial {
   trial_duration = 3200; #changed into random jitter
  
		picture blank;
		time = 0;
		code = "blank";		

  stimulus_event {
		picture fixP;
		deltat = 2000;
		code = "FIX";
		port_code = 20;
	}fix;	
}nextString;

trial {
   trial_duration = forever; #Comment out for dry runs 
   #trial_duration = 3000;   #uncomment for dry runs - automatically runs through Qs
   trial_type = first_response;
	stimulus_event {
		picture emptyP;
		time = 500;
		code = "QUESTION";
		port_code = 40;
		target_button = 1;
   }que;

}question ;


################################################################################
##				PCL																					##
################################################################################

begin_pcl;

bool   Debug                 = false;
string Modality              = "Text";

#-------SET LIBRARY-----------------------
 include "D:/Users/juludd/FMRI-MOUS-AUDITORY-2012-12-10/Lib/fileLength.pcl";
 include "D:/Users/juludd/FMRI-MOUS-AUDITORY-2012-12-10/Lib/readfile.pcl";
 include "D:/Users/juludd/FMRI-MOUS-AUDITORY-2012-12-10/Lib/readfileLines.pcl";  
 include "D:/Users/juludd/FMRI-MOUS-AUDITORY-2012-12-10/Lib/getWordTime.pcl";


# INPUT TEXT FILEs should have 4 columns: 
# [wav file] [sentence onset] [target onset] [audio file length][Has question > 0 (answer = 1 | 2)] 

	int len = fileLength("6fMRIvis-A4-Sent-05-Dec-2012.txt"); # OBS! The files for sentences and sequences MUST be of equal length
 	array <string> Sent[len] = readfileLines("6fMRIvis-A4-Sent-05-Dec-2012.txt"); 	
	array <string> Seq[len] = readfileLines("6fMRIvis-B1-Seq-05-Dec-2012.txt"); 	
	
	string audiofilebase = 	"EQ_Ramp_Int2_Int1LPF";
	
# Question file has 2 columns:
# [Number of reference sentence/sequence] [Correct answer][Question]
# Answers:  1 == yes (left index); 2 == no (left middle finger)
## NOTE!! Question file names must be added later on in the code as well...###
 
	array <string> Que[fileLength("Questions_2012-01-24.txt")] = readfileLines("Questions_2012-01-24.txt");
   array <string> parts[1];
   array <string> QueParts[1];
   int row;
   int block1;
   int block2;
   int dur;
   int trg;
   int blockcounter = 0;
	
   Sent.shuffle();
   Seq.shuffle();


# Wait for dummy pulses
	int NumPulses = 3;  
	int PreviousPulses = pulse_manager.main_pulse_count();            #|Get current number of FMRI pulses
   loop                                                              #|
   until                                                             #|
     pulse_manager.main_pulse_count() == PreviousPulses + NumPulses  #|Wait for NumPulses FMRI pulses
   begin                                                        	   #|
   #do nothing but wait until three pulses have gone
   end;    

		
	
# Blocks of Sentences and Sequence interchange. In the BigUmVis_A version the Sentences start. In the BigUmVis_B version the Sequnces start.    
	loop		
		row = 1; #loop for the blocks
		until
		row > len/5
		begin
		#SENTENCES (block1) begins
		loop
			blockcounter = blockcounter+1; # this line in first block only		
			block1 = (row-1)*5 + 1; # increment loop by size of block (block size == 5 sentences)
			until
			block1  > (row-1)*5 + 5
			begin			
			if(block1 == (row-1)*5 + 1)then
				emptyT.set_font_color(255,0,0); 		#set instruction color
				emptyT.set_caption("zinnen\n"+ string(blockcounter)+"/12");	#fMRI has only 6 blocks
				emptyT.redraw();
				instcode.set_event_code("ZINNEN"); 
				instruction.present(); 
				emptyT.set_font_color(0,0,0); #set color back to default
			end;
			
			int ran = random(3200, 4200); 
			nextString.set_duration(ran);
			fix.set_event_code("FIX "+string(ran));
			nextString.present();   # Present fixation cross with jittering duration
			
			string tmp = Sent[block1]; 
			tmp.split(" ", parts);  # Split the intput into an array of words		
			
			if	(int(parts[1])<= 204)then		#RC < 204 sentWord = 1; sent target = 2;
				trg = 1;							   #MIX > 204 sentWord = 5; sent target = 6; 
			else
				trg = 5;								# 1 OR 5 start of of RC(5) or MIX(1) sentence 
			end; 			
							
			input.set_filename(audiofilebase + parts[1]+".wav");
			input.load();
			
			start.set_event_code("14 Start File " + parts[1]+".wav"); 	
			
			soundBegin.set_time(int(parts[2])); #speaking onset time in column 2
			soundBegin.set_port_code(trg); 
			soundBegin.set_event_code(string(trg)+ " Audio onset");	
			
			target.set_time(int(parts[3])); #target time in column 3
			target.set_port_code(trg+1); 	
			target.set_event_code(string(trg+1)+" Target");	

			soundEnd.set_time(int(parts[4])); #file end time in column 4
			
			words.present();
			input.unload();
			
			if (int(parts[5]) > 0)then #Does column 4 indicates question (question == 1) 
				loop int q = 1;
				until q > fileLength("Questions_2012-01-24.txt") 
				begin
					string tmp2 = Que[q]; 
					tmp2.split(" ", QueParts);
					if (QueParts[1].find(parts[1]) > 0 ) then  # search for corresponding questions from the questions file
						que.set_event_code("QUESTION " + tmp2.substring(1,3));
						que.set_target_button(int(tmp2.substring(5,1)));						
						emptyT.set_caption(tmp2.substring(7,(tmp2.count()-7)));
						emptyT.redraw();				
						question.present();
						q = fileLength("Questions_2012-01-24.txt");
					else
						q = q+1;
					end;
				end;
			end;
			block1 = block1+1;	
		end; 			#Sentence block (block1)ends
	
		#SEQUENCES (block2)begins
		loop 						
			block2 = (row-1)*5 + 1; # increment loop by size of block
			until
			block2 > (row-1)*5 + 5
			begin
			if(block2 == (row-1)*5 + 1)then
				emptyT.set_font_color(255,0,0);		#set instruction color
				emptyT.set_caption("woorden\n"+string(blockcounter)+"/12");
				emptyT.redraw();
				instcode.set_event_code("WOORDEN");
				instruction.present();
				emptyT.set_font_color(0,0,0); #set color back to default
			end;
			
			int ran = random(3200, 4200); 
			nextString.set_duration(ran);
			fix.set_event_code("FIX "+string(ran));
			nextString.present();   # Present fixation cross with jittering duration
			
			string tmp = Seq[block2]; 
			tmp.split(" ", parts); # Split the intput into an array of columns
			
			if	(int(parts[1])<= 704)then		#RC < 704  seqWord = 3; seqTarget = 4
				trg = 3;							   #MIX > 704 seqWord = 7; seqTarget = 8
			else
				trg = 7;							# 3 or 7 = normal word in Seq
			end;							

			input.set_filename(audiofilebase + parts[1]+".wav");
			input.load();
			
			start.set_event_code("14 Start File " + parts[1]+".wav"); 	

			soundBegin.set_time(int(parts[2])); #speaking onset time in column 2
			soundBegin.set_port_code(trg); 
			soundBegin.set_event_code(string(trg)+ " Audio onset");			

			target.set_time(int(parts[3]));  #target time in column 3
			target.set_port_code(trg+1); 	
			target.set_event_code(string(trg+1)+" Target");	
			
			soundEnd.set_time(int(parts[4])); #file end time in column 4
			
			words.present();
			input.unload();
			
			if (int(parts[5]) > 0)then
				loop int q = 1;
				until q > fileLength("Questions_2012-01-24.txt") 
				begin
					string tmp2 = Que[q]; 
					tmp2.split(" ", QueParts);
					if (QueParts[1].find(parts[1]) > 0 ) then
						int y = tmp2.count();
						que.set_event_code("QUESTION " + tmp2.substring(1,3));
						que.set_target_button(int(tmp2.substring(5,1)));						
						emptyT.set_caption(tmp2.substring(7,(tmp2.count()-7)));
						emptyT.redraw();				
						question.present();
						q = fileLength("Questions_2012-01-24.txt") ;
					else
						q = q+1;
					end;
				end;
			end;
			block2 = block2+1;	
		end; 		# Sequence block (block2) ends
					
		row = row+1;
				
	end; # block loop end
		
