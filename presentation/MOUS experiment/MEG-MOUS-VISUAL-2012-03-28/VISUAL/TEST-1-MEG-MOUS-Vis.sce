 ################################################################
 # HEADER
 ################################################################
 #scenario = "BigUmVis";                           					# Name of scenario (for logfile use)

 active_buttons           = 3;                                  
 target_button_codes      = 1,2,3;  # 1 == yes (left index), 2 == no (left middle finger), space bar continue after break
 response_matching = simple_matching;
 response_logging = log_active;
                              
 default_font_size        = 14;                                 # Default font size
 default_font             = "Courier new"; 							 # Font where all letter are equallt wide!!
 default_text_color		  = 0, 0, 0;
 default_background_color = 120, 120, 120;   
 write_codes		        = true; # true in MEG room!! 										 


#--------------Triggers-----------------------------------------#
#
# MIX sentWord = 1; sent target = 2; seqWord = 3; seqTarget = 4
# RC sentWord = 5; sent target = 6; seqWord = 7; seqTarget = 8
# 
# Offset = 15; the offset of any word 
# Fixation = 20; (fix is preceeded by blank scren 2sec. Fix duration between 1,2 - 2,2 sex.)
# Block title (zinnen/worden) = 10;
# Question = 40; (target buttons 1,2)
# Pause = 30; After n number of block there will automatically be a pause. Scenario continues when 
# experimeter presses [space bar] on keyboard 
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
		picture emptyP;
		code = "word";
		port_code = 1; #MIX sentWord = 1; sent target = 2; seqWord = 3; seqTarget = 4
	}target;	         #RC sentWord = 5; sent target = 6; seqWord = 7; seqTarget = 8
	
	stimulus_event{
		picture blank;  # This event needs a different empty object than in the words trial
		deltat = 0;		 # otherwise the empty content must be redrawn at every ISI which may 
		duration = 300; # effect the timing accuracy.
		code = "ISI";
		port_code = 15; # onset of ISI is also offset of the word
	}ISI;	
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
   trial_type = correct_response;
   picture pauze;
   code = "pause";
   port_code = 30;
   target_button = 3;
}pause;

trial {
   trial_duration = forever;
   trial_type = first_response;
   
	stimulus_event {
		picture emptyP;
		time = 500;
		code = "QUESTION";
		port_code = 40;
		target_button = 2;
   }que;
   # Add responce buttons
}question ;


################################################################################
##				PCL																					##
################################################################################

begin_pcl;

bool   Debug                 = false;
string Modality              = "Text";

#-------SET LIBRARY-----------------------
 include "D:/annika/MOUS/Lib/fileLength.pcl";
 include "D:/annika/MOUS/Lib/readfile.pcl";
 include "D:/annika/MOUS/Lib/readfileLines.pcl";  
 include "D:/annika/MOUS/Lib/getWordTime.pcl";

 
# INPUT TEXT FILEs should have 5 columns: 
# [wav file] [audio file length][target location] [Has question = 1] [Stimuli]

	int len = fileLength("1MEG-A1A2-Sent-28-Mar-2012.txt"); # OBS! The files for sentences and sequences MUST be of equal length
 	array <string> Sent[len] = readfileLines("1MEG-A1A2-Sent-28-Mar-2012.txt"); 	
	array <string> Seq[len] = readfileLines("1MEG-B4B5-Seq-28-Mar-2012.txt"); 		
	
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
	
	
# Blocks of Sentences and Sequence interchange. In the BigUmVis_A version the Sentences start. In the BigUmVis_B version the Sequnces start.    
	loop		
		row = 1; #loop for the blocks
		until
		row > len/5
		begin
		#SENTENCES (block1) begins
		loop	
			blockcounter = blockcounter+1;
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
				emptyT.set_font_color(0,0,0); #set color back to default
			end;
			
			int ran = random(3200, 4200); 
			nextString.set_duration(ran);
			fix.set_event_code("FIX "+string(ran));
			nextString.present();   # Present fixation cross with jittering duration
			
			string tmp = Sent[block1]; 
			tmp.split(" ", parts);  # Split the intput into an array of words				
			loop 							# Present sentence one-by-one
				int r = 5;				# Skip the first 4 columns with parameters
				until 
				r > (parts.count())
				begin
				emptyT.set_caption(parts[r]);
				emptyT.redraw();
				dur = getWordTime(parts[r],int(parts[2]),tmp); #set the presentations time for each word
				target.set_duration(dur);
				ISI.set_deltat(dur);
				if	(int(parts[1])<= 204)then		#MIX < 200 sentWord = 1; sent target = 2;
					trg = 1;							   #RC > 200 sentWord = 5; sent target = 6; 
				else
					trg = 5;								# 1 OR 5 = normal word in Sent
				end; 			
				if (r-4 == int(parts[3]))then # If word (minus 4 intial columns) is target (indicated in column 3)set target port_code
				   trg = trg + 1;					# 2 or 6 = Sent target
				end;									
				target.set_port_code(trg); 	
				target.set_event_code(string(trg)+" " + parts[r]+" " + string(dur));	
				words.present();
				r = r+1;
			end;
			
			if (int(parts[4]) > 0)then #Does column 4 indicates question (question == 1) 
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
				emptyT.set_caption("woorden\n"+string(blockcounter)+"/24");
				emptyT.redraw();
				instcode.set_event_code("WOORDEN");
				instruction.present();
				emptyT.set_font_color(0,0,0); #set color back to default
			end;
			
			string tmp = Seq[block2]; 
			tmp.split(" ", parts); # Split the intput into an array of words
			
			int ran = random(3200, 4200); 
			nextString.set_duration(ran);
			fix.set_event_code("FIX "+string(ran));
			nextString.present();   # Present fixation cross with jittering duration
			
			loop  					  # Present sequence one-by-one 
				int r = 5;			  # Skip the first 4 columns with parameters
				until 
				r == (parts.count())
				begin
				emptyT.set_caption(parts[r]);
				emptyT.redraw();
				dur = getWordTime(parts[r],int(parts[2]),tmp); 
				target.set_duration(dur);
				ISI.set_deltat(dur);
				if	(int(parts[1])<= 704)then		#MIX < 200  seqWord = 3; seqTarget = 4
					trg = 3;							   #RC > 200 seqWord = 7; seqTarget = 8
				else
					trg = 7;							# 3 or 7 = normal word in Seq
				end;
				if (r-4 == int(parts[3]))then # If word (minus 4 intial columns) is target (indicated in column 3)set target port_code
				   trg = trg + 1;					# 4 or 8 = Seq target 
				end; 									
				target.set_port_code(trg); 	
				target.set_event_code(string(trg)+ parts[r]+" " + string(dur));					
				words.present();
				r = r+1;
			end;
			if (int(parts[4]) > 0)then
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
		end; 				# Sequence block (block2) ends
		row = row+1;
		
		if (blockcounter == 12) then # After 6 blocks of sent and 6 blocks of seq pause
			pause.present();
		end;	
		
	end; # block loop end
		
