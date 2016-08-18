 ################################################################
 # HEADER
 ################################################################
 #scenario = "BigUmVis";                           					# Name of scenario (for logfile use)

 active_buttons           = 13;                                  
 button_codes             = 1,2,3,4,5,6,7,8,9,10,11,12,13;  
# 11 == yes (left index), 12 == no (left middle finger), 13 = space bar continue after break
 response_matching = simple_matching;
 response_logging = log_active;
                              
 default_font_size        = 14;                                 # Default font size
 default_font             = "Courier new"; 							 # Font where all letter are equallt wide!!
 default_text_color		  = 0, 0, 0;
 default_background_color = 120, 120, 120;   
 write_codes		        = true; # true in MEG room!! 										 


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
# Question = 40; (target buttons 11,12)
# Pause = 30; After n number of block there will automatically be a pause. Scenario continues when 
# experimeter presses [space bar] on keyboard (terminator button 13)
# At the end a screen will appear instructing the subject not to move before we let them out. This screen
# is also coded with trigger 30
#
#---------------------------------------------------------------#

begin;                                                                
#--------------objects array-----------------------------------------#

text  { caption = " "; } emptyT;
picture {} default;    # blank screen

picture { text emptyT;  x = 0; 	y = 0;} emptyP;
picture { text { caption = " "; };  x = 0; y = 0;} blank;
picture { text { caption = "+"; };  x = 0; y = 0;} fixP;

text {caption = "Pauze \n 
Dit is het einde van de eerste helft. \n
Neem rustig even pauze. Beweeg NIET met je hoofd, 
maar blijf in dezelfde positie zitten.\n
Laat het de onderzoeker weten wanneer je weer verder wilt gaan."; font_size=16;}pausetext;

text {caption = "Dit is het einde van het experiment. \n
Gelieve nog niet te bewegen Beweeg nog NIET met je hoofd, 
maar blijf in dezelfde positie zitten.\n"; font_size=16;} endtext;


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
		port_code = 14;		      #RC sentStart= 5; seqStart = 7; 		
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
   trial_duration = forever;
   trial_type = specific_response;
   terminator_button = 13;
	picture { 
		text pausetext;
		x = 0; y = 0;
	}pausePic;
   code = "pause";
   port_code = 30;
}pause;


trial {
   trial_duration = forever; #Comment out for dry runs 
   #trial_duration = 3000;   #uncomment for dry runs - automatically runs through Qs
   trial_type = first_response;
	stimulus_event {
		picture emptyP;
		time = 500;
		code = "QUESTION";
		port_code = 40;
		target_button = 11;
   }que;

}question ;

trial {
   trial_duration = 5000; 
	stimulus_event { picture emptyP;	time = 10; code = "PULSE MODE 0"; port_code = 0; }tri1;
	stimulus_event { picture emptyP;	time = 500; code = "PULSE MODE 2"; port_code = 2; }tri2;
	stimulus_event { picture emptyP;	time = 1000; code = "PULSE MODE 0"; port_code = 0; }tri3;
}setBitsibox ;


################################################################################
##				PCL																					##
################################################################################

begin_pcl;

bool   Debug                 = false;
string Modality              = "Text";

#-------SET LIBRARY-----------------------
 include "D:/Users/annika/MOUS/Lib/fileLength.pcl";
 include "D:/Users/annika/MOUS/Lib/readfile.pcl";
 include "D:/Users/annika/MOUS/Lib/readfileLines.pcl";  
 include "D:/Users/annika/MOUS/Lib/getWordTime.pcl";


# INPUT TEXT FILEs should have 4 columns: 
# [wav file] [senstence onset][target location] [audio file length][Has question > 0 (answer = 1 | 2)] 

	int len = fileLength("5MEG-A6A4-Sent-05-Dec-2012.txt"); # OBS! The files for sentences and sequences MUST be of equal length
 	array <string> Sent[len] = readfileLines("5MEG-A6A4-Sent-05-Dec-2012.txt"); 	
	array <string> Seq[len] = readfileLines("5MEG-B3B1-Seq-05-Dec-2012.txt"); 	
	
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
	

# Set bitsi box first to pulse mode (default trial)	
setBitsibox.present(); 

# Set bisti pulse length to 5 ms
tri2.set_port_code(1); 
tri2.set_event_code("PULSE MODE 1");
tri3.set_port_code(5); 
tri3.set_event_code("PULSE MODE 5");	
setBitsibox.present(); 

	
# Blocks of Sentences and Sequence interchange. In the BigUmVis_A version the Sentences start. In the BigUmVis_B version the Sequnces start.    
	loop		
		row = 1; #loop for the blocks
		until
		row > len/5
		begin
		
		#SEQUENCES (block2)begins
		loop 	
 			blockcounter = blockcounter+1; # This line in the first block only								
			block2 = (row-1)*5 + 1; # increment loop by size of block
			until
			block2 > (row-1)*5 + 5
			begin
			if(block2 == (row-1)*5 + 1)then
				emptyT.set_font_color(255,0,0);		#set instruction color
				emptyT.set_caption("woorden\n"+string(blockcounter)+"/24");
				emptyT.redraw();
				instcode.set_event_code("WOORDEN");
				instruction.present();
				emptyT.set_font_color(255,255,255); #set color back to default
			end;
			
			int ran = random(3200, 4200); 
			nextString.set_duration(ran);
			fix.set_event_code("FIX "+string(ran));
			nextString.present();   # Present fixation cross with jittering duration
			
			string tmp = Seq[block2]; 
			tmp.split(" ", parts); # Split the intput into an array of words
			
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
			
			target.set_time(int(parts[3])); #target time in column 3
			target.set_port_code(trg+1); 	
			target.set_event_code(string(trg+1)+" target");	

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
						que.set_target_button(10 + int(tmp2.substring(5,1)));	# corect button code 11 or 12 (marked 1 / 2 in input						
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
		end; 				# Sequence block (block2) ends
		#SENTENCES (block1) begins
		loop	
			block1 = (row-1)*5 + 1; # increment loop by size of block (block size == 5 sentences)
			until
			block1  > (row-1)*5 + 5
			begin			
			if(block1 == (row-1)*5 + 1)then
				emptyT.set_font_color(255,0,0); 		#set instruction color
				emptyT.set_caption("zinnen\n"+ string(blockcounter)+"/24");	#fMRI has only 6 blocks
				emptyT.redraw();
				instcode.set_event_code("ZINNEN"); 
				instruction.present(); 
				emptyT.set_font_color(255,255,255); #set color back to default
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
							
			input.set_filename(audiofilebase+ parts[1]+".wav"); #load file
			input.load();
			
			start.set_event_code("14 Start File " + parts[1]+".wav"); 	
				
			soundBegin.set_time(int(parts[2])); #speaking onset time in column 2
			soundBegin.set_port_code(trg); 
			soundBegin.set_event_code(string(trg)+ " Audio onset");
				
			target.set_time(int(parts[3]));  #target time in column 3
			target.set_port_code(trg+1); 	
			target.set_event_code(string(trg+1)+" target");	
			
			soundEnd.set_time(int(parts[4])); #file end time in column 4
				
			words.present();
			input.unload();
			
			if (int(parts[5]) > 0)then #Does column 5 indicates question (question == 1) 
				loop int q = 1;
				until q > fileLength("Questions_2012-01-24.txt") 
				begin
					string tmp2 = Que[q]; 
					tmp2.split(" ", QueParts);
					if (QueParts[1].find(parts[1]) > 0 ) then  # search for corresponding questions from the questions file
						que.set_event_code("QUESTION " + tmp2.substring(1,3));
						que.set_target_button(10+int(tmp2.substring(5,1))); # corect button code 11 or 12 (marked 1 / 2 in input						
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
		
		row = row+1;
		
		if (blockcounter == 12) then # After 6 blocks of sent and 6 blocks of seq pause
			pause.present();
		end;	
		
	end; # block loop end
	
	pause.set_duration(10000);		
	pausePic.set_part( 1, endtext);
	pause.present();

	# Set bisti pulse length to 30 ms
	emptyT.set_caption(" ");
	emptyT.redraw();	
	tri2.set_port_code(1); 
	tri3.set_port_code(30); 		
	setBitsibox.present(); 