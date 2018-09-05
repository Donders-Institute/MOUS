 ################################################################
 # HEADER
 ################################################################
 #scenario = "BigUmVis";                           					# Name of scenario (for logfile use)

 active_buttons           = 12;                                  
 button_codes             = 1,2,3,4,5,6,7,8,9,10,11,12,;  
 response_matching = simple_matching;
 response_logging = log_active;
                              
 default_font_size        = 13.5;                                 # Default font size
 default_font             = "Courier new"; 							 # Font where all letter are equallt wide!!
 default_text_color		  = 0, 0, 0;
 default_background_color = 120, 120, 120;   
 write_codes		        = false; # true in MEG room!! 										 


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

picture { text emptyT;  x = 0; 	y = 50;} emptyP;
picture { text { caption = " "; };  x = 0; y = 50;} blank;
picture { text { caption = "+"; };  x = 0; y = 50;} fixP;

picture { text {caption = "Pauze \n 
Dit is het einde van de eerste helft. \n
Neem rustig even pauze. Beweeg NIET met je hoofd, 
maar blijf in dezelfde positie liggen. 
Wanneer je weer verder wilt gaan druk je op de knop."; font_size=16;};x=0;y=0;} pauze;

array {
picture { text { caption = "Waren de omstanders erg kritisch?"; };  x = 0; y = 0;} ;
picture { text { caption = "Werd er een koning genoemd?"; };  x = 0; y = 0;} ;
} myQuest;

 

 

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
		time = 500;
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
   trial_type = first_response;
   picture pauze;
   code = "pause";
   port_code = 30;
   target_button = 2;
}pause;

trial {
   trial_duration = forever;
   trial_type = first_response;
   
	stimulus_event {
		picture emptyP;
		time = 500;
		code = "QUESTION";
		port_code = 40;
		target_button = 1;
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
 include "D:/Users/annika/MOUS/Lib/fileLength.pcl";
 include "D:/Users/annika/MOUS/Lib/readfile.pcl";
 include "D:/Users/annika/MOUS/Lib/readfileLines.pcl";  
 include "D:/Users/annika/MOUS/Lib/getWordTime.pcl";

 
# INPUT TEXT FILEs should have 5 columns: 
# [wav file] [audio file length][target location] [Has question = 1] [Stimuli]

	int len = fileLength("Practice.txt"); # OBS! The files for sentences and sequences MUST be of equal length
 	array <string> Sent[len] = readfileLines("Practice.txt"); 	
	#array <string> Seq[len] = readfileLines("MEG1-B4B5-Seq.txt"); 		
	
# Question file has 2 columns:
# [Number of reference sentence/sequence] [Correct answer][Question]
# Answers:  1 == yes (left index); 2 == no (left middle finger)
## NOTE!! Question file names must be added later on in the code as well...###


	#array <string> Que[fileLength("Questions_2012-01-24.txt")] = readfileLines("Questions_2012-01-24.txt");
   array <string> parts[1];
   #array <string> QueParts[1];
   int row;
   int block1;
   int block2;
   int dur;
   int trg;
   int blockcounter = 0;
	
   #Sent.shuffle();
   #Seq.shuffle();
	
	
# Blocks of Sentences and Sequence interchange. In the BigUmVis_A version the Sentences start. In the BigUmVis_B version the Sequnces start.    
	loop		
		row = 1; #loop for the blocks
		until
		row > 10
		begin		
		if(row == 1)then
			emptyT.set_font_color(255,0,0); 		#set instruction color
			emptyT.set_caption("zinnen\n1/1");	#fMRI has only 6 blocks
			emptyT.redraw();
			instcode.set_event_code("ZINNEN"); 
			instruction.present(); 
			emptyT.set_font_color(0,0,0); #set color back to default
			elseif (row == 6)then 
			emptyT.set_font_color(255,0,0);		#set instruction color
			emptyT.set_caption("woorden\n1/1");
			emptyT.redraw();
			instcode.set_event_code("WOORDEN");
			instruction.present();
			emptyT.set_font_color(0,0,0); #set color back to default
		end;
		
		int ran = random(3200, 4200); 
		nextString.set_duration(ran);
		fix.set_event_code("FIX "+string(ran));
		nextString.present();   # Present fixation cross with jittering duration
		string tmp = Sent[row]; 
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
			if	(int(parts[1])<= 200)then		#MIX < 200 sentWord = 1; sent target = 2;
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
			que.set_stimulus( myQuest[int(parts[4])]);
			question.present();
		end;	
		row = row+1;		
	end; # block loop end
	
