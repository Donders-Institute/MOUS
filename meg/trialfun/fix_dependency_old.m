% this script intends to check the mous_stimuli (sentences) for incorrectly
% parsed stuff.

% automatic detection based on more than 1 syntactic super-head, i.e.
% depind of 0. 
% what will be adjusted are stimuli(x).words.depind and
% stimuli(x).words.depjump: the rest will not be affected.

load('mous_stimuli_20141211.mat');
for k = 1:500
  try
    n(k,1) = sum([stimuli(k).words.depind]==0);
  end
end

sel = find(n>1);

% 1                                                                              
% Toen de barkeeper die de irritante klant bediende wegliep gingen de deuren open
% 1    2  3         4   5  6         7     8        9       10     11 12     13  
% 0    3  9         3   7  7         9     9        1       0      12 10     10  
% 10   3  9         3   7  7         9     4        1       0      12 10     10  
stimuli(1).words(1).depind  = 10;
stimuli(1).words(1).depjump = 9;
stimuli(1).words(8).depind  = 4;
stimuli(1).words(8).depjump = 4;

% 2                                                                       
% Toen de manke dronkaard die de barkeeper betaalde lachte viel de kruk om
% 1    2  3     4         5   6  7         8        9      10   11 12   13
% 0    4  4     9         4   7  8         5        1      0    12 10   12
% 10   4  4     9         4   7  8         5        1      0    12 10   12
stimuli(2).words(1).depind  = 10;
stimuli(2).words(1).depjump = 9; 
                                                                  
% 5                                                                        
% Vorige week kreeg de assistent die de bruine tanden behandelde de uitslag
% 1      2    3     4  5         6   7  8      9      10         11 12     
% 2      3    0     5  3         5   9  9      0      0          12 10     
% 2      3    0     5  3         5   9  9      10     6          12 3
stimuli(5).words(9).depind  = 10;
stimuli(5).words(9).depjump = 1;
stimuli(5).words(10).depind  = 6;
stimuli(5).words(10).depjump = 4;
stimuli(5).words(12).depind  = 3;
stimuli(5).words(12).depjump = 9;

% 7                                                                             
% Laatst kreeg de gevreesde psychiater die de verslaafde behandelde zijn ontslag
% 1      2     3  4         5          6   7  8          9          10   11     
% 2      0     5  5         2          5   8  9          6          11   9      
% 2      0     5  5         2          5   8  9          6          11   2      
stimuli(7).words(11).depind  = 2;
stimuli(7).words(11).depjump = 9;

% 8                                                                         
% De overtreder die de smeris ontvlucht was is een kronkelig paadje ingerend
% 1  2          3   4  5      6         7   8  9   10        11     12      
% 2  8          2   5  7      7         3   0  11  11        8      11      
% 2  8          2   5  7      7         3   0  11  11        12     8      
stimuli(8).words(11).depind  = 12;
stimuli(8).words(11).depjump = 1;
stimuli(8).words(12).depind  = 8;
stimuli(8).words(12).depjump = 4;

% 9                                                                          
% De eigenaars van het landgoed die honderden bezoekers rondleiden zijn trots
% 1  2         3   4   5        6   7         8         9          10   11   
% 2  10        2   5   3        7   3         7         10         0    10   
% 2  10        2   5   3        2   8         9         6          0    10   
stimuli(9).words(6).depind  = 2;
stimuli(9).words(6).depjump = 4;
stimuli(9).words(7).depind  = 8;
stimuli(9).words(7).depjump = 1;
stimuli(9).words(9).depind  = 6;
stimuli(9).words(9).depjump = 3;

% 10                                                                      
% Gisteren had de brede bodyguard die de filmster beschermde een vrije dag
% 1        2   3  4     5         6   7  8        9          10  11    12 
% 2        0   5  5     2         5   8  9        6          12  12    9  
% 2        0   5  5     2         5   8  9        6          12  12    2  
stimuli(10).words(12).depind  = 2;
stimuli(10).words(12).depjump = 10;

% 11                                                                    
% Morgen krijgt de ober die de beroemde president beledigde zijn ontslag
% 1      2      3  4    5   6  7        8         9         10   11     
% 2      0      4  2    4   8  8        9         5         11   9      
% 2      0      4  2    4   8  8        9         5         11   2      
stimuli(11).words(11).depind  = 2;
stimuli(11).words(11).depjump = 9;

% 13                                                                                       
% De sportarts die de hockeyer met de gescheurde pezen adviseert heeft er veel verstand van
% 1  2         3   4  5        6   7  8          9     10        11    12 13   14       15 
% 2  0         2   5  10       5   9  9          6     3         0     11 14   0        14 
% 2  11        2   5  10       5   9  9          6     3         0     11 14   11       14
stimuli(13).words(2).depind  = 11;
stimuli(13).words(2).depjump = 9;
stimuli(13).words(14).depind  = 11;
stimuli(13).words(14).depjump = 3;

% 14                                                                         
% De oma met het gebroken bekken die de verpleegster raadpleegde moest huilen
% 1  2   3   4   5        6      7   8  9            10          11    12    
% 2  0   2   6   6        3      6   9  10           7           7     11    
% 2  11  2   6   6        3      2   9  10           7           0     11    
stimuli(14).words(2).depind  = 11;
stimuli(14).words(2).depjump = 9;
stimuli(14).words(7).depind  = 2;
stimuli(14).words(7).depjump = 5;
stimuli(14).words(11).depind  = 0;
stimuli(14).words(11).depjump = 0;

% 15                                                                        
% De alcoholist die de bekende psycholoog behandelde heeft weer een terugval
% 1  2          3   4  5       6          7          8     9    10  11      
% 2  8          2   6  6       8          8          0     11   11  8       
% 2  8          2   6  6       8          3          0     11   11  8       
stimuli(15).words(7).depind  = 3;
stimuli(15).words(7).depjump = 4;

% 17
% Jochem die altijd te hoog springt tijdens basketbal heeft zijn enkel bezeerd
% 1      2   3      4  5    6       7       8         9     10   11    12
% 6      1   4      5  6    0       6       7         6     0    12    10
% 9      1   4      5  6    3       6       7         0     11   9     9
stimuli(17).words(1).depind  = 9;
stimuli(17).words(1).depjump = 8;
stimuli(17).words(6).depind  = 3;
stimuli(17).words(6).depjump = 3;
stimuli(17).words(9).depind  = 0;
stimuli(17).words(9).depjump = 0;
stimuli(17).words(10).depind  = 11;
stimuli(17).words(10).depjump = 1;
stimuli(17).words(11).depind  = 9;
stimuli(17).words(11).depjump = 2;
stimuli(17).words(12).depind  = 9;
stimuli(17).words(12).depjump = 3;

% 24
% De voorganger die het snoezige kleintje doopt houdt haar stevig vast
% 1  2          3   4   5        6        7     8     9    10     11
% 2  8          2   6   6        7        3     0     8    11     0
% 2  8          2   6   6        7        3     0     8    11     8
stimuli(24).words(11).depind  = 8;
stimuli(24).words(11).depjump = 3;

% 29
% De gedetineerde die de trage bewaker afschudt krijgt hulp van zijn handlanger
% 2  0            2   6  6     7       3        0      8    9   12   10
% 2  8            2   6  6     7       3        0      8    9   12   10
stimuli(29).words(2).depind  = 8;
stimuli(29).words(2).depjump = 6;

% 32
% Niemand wist dat een gevaarlijke tornado ontstond die veel slachtoffers zou eisen
% 1       2    3   4   5           6       7        8   9    10           11  12 
% 2       0    2   6   6           7       3        7   10   2            0   11
% 2       0    2   6   6           7       3        7   10   2            8   11
stimuli(32).words(8).depind  = 6;
stimuli(32).words(8).depjump = 2;
stimuli(32).words(11).depind  = 8;
stimuli(32).words(11).depjump = 3;

% 35
% Het derde getal dat de oplettende toehoorder signaleert is zes
% 1   2     3     4   5  6          7          8          9  10
% 3   3     9     3   7  7          8          4          0  0
% 3   3     9     3   7  7          8          4          0  9
stimuli(35).words(10).depind  = 9;
stimuli(35).words(10).depjump = 1;

% 36
% Mijn vriendin Mona is gek op jongens die gemixte drankjes kopen voor haar
% 1    2        3    4  5   6  7       8   9       10       11    12   13
% 2    4        2    0  4   11 6       7   10      11       4     11   0
% 2    3        4    0  4   4  6       7   10      11       8     11   12        
stimuli(36).words(2).depind  = 3;
stimuli(36).words(2).depjump = 1;
stimuli(36).words(3).depind  = 4;
stimuli(36).words(3).depjump = 1;
stimuli(36).words(6).depind  = 4;
stimuli(36).words(6).depjump = 2;
stimuli(36).words(11).depind  = 8;
stimuli(36).words(11).depjump = 3;
stimuli(36).words(13).depind  = 12;
stimuli(36).words(13).depjump = 1;

% 41
% De schilder die de knappe prinses tekent zit onder de verf
% 1  2        3   4  5      6       7      8   9     10 11
% 2  0        2   6  6      7       3      3   8     11 9
% 2  8        2   6  6      7       3      0   8     11 9
stimuli(41).words(2).depind  = 8;
stimuli(41).words(2).depjump = 6;
stimuli(41).words(8).depind  = 0;
stimuli(41).words(8).depjump = 0;

% 42
% De kokkin die pap voor dakloze burgers kookt heeft geen zin meer
% 2  8      4   8   4    7       5       0     0     11   9   9
% 2  9      2   8   8    7       5       3     0     11   9   9
stimuli(42).words(2).depind  = 9;
stimuli(42).words(2).depjump = 7;
stimuli(42).words(3).depind  = 2;
stimuli(42).words(3).depjump = 1;
stimuli(42).words(4).depind  = 8;
stimuli(42).words(4).depjump = 4;
stimuli(42).words(8).depind  = 3;
stimuli(42).words(8).depjump = 5;

% 43                                                      
% Nora die warme dekens voor arme mensen weeft is gelukkig
% 1    2   3     4      5    6    7      8     9  10      
% 0    1   4     8      4    7    5      2     0  9       
% 9    1   4     8      4    7    5      2     0  9
stimuli(43).words(1).depind  = 9;
stimuli(43).words(1).depjump = 8;

% 53                                                                            
% De fans die de gespannen bowlers aanmoedigen willen dat hun sporthelden winnen
% 1  2    3   4  5         6       7           8      9   10  11          12    
% 2  0    2   6  6         8       8           3      8   11  12          3     
% 2  8    2   6  6         8       3           0      8   11  12          9     
stimuli(53).words(2).depind  = 8;
stimuli(53).words(2).depjump = 6;
stimuli(53).words(7).depind  = 3;
stimuli(53).words(7).depjump = 4;
stimuli(53).words(8).depind  = 0;
stimuli(53).words(8).depjump = 0;
stimuli(53).words(12).depind  = 9;
stimuli(53).words(12).depjump = 3;
                                                                    
% 55                                                                            
% Toen de zwerver die de hulpverlener hielp de bereden politie zag rende hij weg
% 1    2  3       4   5  6            7     8  9       10      11  12    13  14 
% 12   3  11      3   6  7            4     10 10      7       1   0     12  12 
% 12   3  11      3   6  7            4     10 10      11      1   0     12  12 
stimuli(55).words(10).depind  = 11;
stimuli(55).words(10).depjump = 1;

% 56                                                                                
% Toen de heilsoldaat die de zieke dakloze huisvestte de kamer binnenkwam schrok hij
% 1    2  3           4   5  6     7       8          9  10    11         12     13 
% 12   3  12          3   11 11    8       11         10 8     4          0      12 
% 12   3  11          3   7  7     8       4          10 11    1          0      12 
stimuli(56).words(3).depind  = 11;
stimuli(56).words(3).depjump = 8;
stimuli(56).words(5).depind  = 7;
stimuli(56).words(5).depjump = 2;
stimuli(56).words(6).depind  = 7;
stimuli(56).words(6).depjump = 1;
stimuli(56).words(8).depind  = 4;
stimuli(56).words(8).depjump = 4;
stimuli(56).words(10).depind  = 11;
stimuli(56).words(10).depjump = 1;
stimuli(56).words(11).depind  = 1;
stimuli(56).words(11).depjump = 10;

% 58                                                                            
% Ik schrok toen de goedkope beunhaas die het achterste bordes repareerde lachte
% 1  2      3    4  5        6        7   8   9         10     11         12    
% 2  0      2    6  6        3        6   10  10        11     7          7     
% 2  0      2    6  6        12       6   10  10        11     7          3     
stimuli(58).words(6).depind  = 12;
stimuli(58).words(6).depjump = 6;
stimuli(58).words(12).depind  = 3;
stimuli(58).words(12).depjump = 9;

% 65                                                                    
% Mijn zuster Fransien die de duurste trompet uitkiest heeft geld genoeg
% 1    2      3        4   5  6       7       8        9     10   11    
% 2    0      2        3   7  7       9       9        4     9    9     
% 2    9      2        3   7  7       8       4        0     9    9     
stimuli(65).words(2).depind  = 9;
stimuli(65).words(2).depjump = 7;
stimuli(65).words(7).depind  = 8;
stimuli(65).words(7).depjump = 1;
stimuli(65).words(8).depind  = 4;
stimuli(65).words(8).depjump = 4;
stimuli(65).words(9).depind  = 0;
stimuli(65).words(9).depjump = 0;

% 67                                                            
% Joke die de Spaanse tamboerijn speelt staat het liefst vooraan
% 1    2   3  4       5          6      7     8   9      10     
% 6    1   5  5       6          0      0     10  10     7      
% 7    1   5  5       6          2      0     10  10     7
stimuli(67).words(1).depind  = 7;
stimuli(67).words(1).depjump = 6;
stimuli(67).words(6).depind  = 2;
stimuli(67).words(6).depjump = 4;

% 70                                                                                   
% Het behoorlijk stugge diafragma dat buikholte en borstholte scheidt is erg belangrijk
% 1   2          3      4         5   6         7  8          9       10 11  12        
% 4   3          4      7         4   5         0  7          7       0  12  10        
% 4   3          4      10        4   9         9  9          4       0  12  10
stimuli(70).words(4).depind  = 10;
stimuli(70).words(4).depjump = 6;
stimuli(70).words(6).depind  = 9;
stimuli(70).words(6).depjump = 3;
stimuli(70).words(7).depind  = 9;
stimuli(70).words(7).depjump = 2;
stimuli(70).words(8).depind  = 9;
stimuli(70).words(8).depjump = 1;
stimuli(70).words(9).depind  = 4;
stimuli(70).words(9).depjump = 5;

% 72                                                   
% De puber die de kwade bazin haatte was ten einde raad
% 1  2     3   4  5     6     7      8   9   10    11  
% 2  8     2   6  6     7     3      10  10  8     8   
% 2  8     2   6  6     7     3      0   8   11    9   
stimuli(72).words(8).depind  = 0;
stimuli(72).words(8).depjump = 0;
stimuli(72).words(9).depind  = 8;
stimuli(72).words(9).depjump = 1;
stimuli(72).words(10).depind  = 11;
stimuli(72).words(10).depjump = 1;
stimuli(72).words(11).depind  = 9;
stimuli(72).words(11).depjump = 2;

% 74                                                                            
% Vorige week kreeg de zielige bangerik die de tandarts inschakelde heftige pijn
% 1      2    3     4  5       6        7   8  9        10          11      12  
% 2      3    0     6  6       3        6   9  3        12          12      0   
% 2      3    0     6  6       3        6   9  10       7           12      3
stimuli(74).words(9).depind   = 10;
stimuli(74).words(9).depjump  = 1;
stimuli(74).words(10).depind  = 7;
stimuli(74).words(10).depjump = 3;
stimuli(74).words(12).depind  = 3;
stimuli(74).words(12).depjump = 9;

% 75                                                                                      
% Afgelopen maand kreeg de gewonde die een bekende paragnost inschakelde vele complicaties
% 1         2     3     4  5       6   7   8       9         10          11   12          
% 2         3     0     5  3       5   9   9       10        6           12   10          
% 2         3     0     5  3       5   9   9       10        6           12   3          
stimuli(75).words(12).depind  = 3;
stimuli(75).words(12).depjump = 9;

% 77                                                                 
% Ik keek naar mijn broer die de grote takken voor het vuur gebruikte
% 1  2    3    4    5     6   7  8     9      10   11  12   13       
% 2  0    2    5    3     5   9  9     13     9    12  13   6        
% 2  0    2    5    3     5   9  9     13     13   12  10   6        
stimuli(77).words(10).depind  = 13;
stimuli(77).words(10).depjump = 3;
stimuli(77).words(12).depind  = 10;
stimuli(77).words(12).depjump = 2;

% 78                                                         
% De ervaren agent die daar liep heeft de bange toerist gered
% 1  2       3     4   5    6    7     8  9     10      11   
% 3  3       7     3   7    7    0     10 10    7       7    
% 3  3       7     3   6    4    0     10 10    7       7    
stimuli(78).words(5).depind  = 6;
stimuli(78).words(5).depjump = 1;
stimuli(78).words(6).depind  = 4;
stimuli(78).words(6).depjump = 2;

% 79                                                               
% De ervaren makelaars die de nieuwe kopers rondleiden zijn gehaaid
% 1  2       3         4   5  6      7      8          9    10     
% 3  3       9         3   7  7      9      9          0    9      
% 3  3       9         3   7  7      8      4          0    9      
stimuli(79).words(7).depind  = 8;
stimuli(79).words(7).depjump = 1;
stimuli(79).words(8).depind  = 4;
stimuli(79).words(8).depjump = 4;

% 82                                                                
% Mijn tante die heerlijke jam van verse bramen maakt gaat verhuizen
% 1    2     3   4         5   6   7     8      9     10   11       
% 2    10    5   5         9   5   8     6      2     0    10       
% 2    10    2   5         9   5   8     6      2     0    10       
stimuli(82).words(3).depind  = 2;
stimuli(82).words(3).depjump = 1;

% 83                                                          
% De jonge dief die vluchtte had haar nieuwe paspoort gestolen
% 1  2     3    4   5        6   7    8      9        10      
% 3  3     0    3   4        4   9    9      10       6       
% 3  3     6    3   4        0   9    9      6        6       
stimuli(83).words(3).depind  = 6;
stimuli(83).words(3).depjump = 3;
stimuli(83).words(6).depind  = 0;
stimuli(83).words(6).depjump = 0;
stimuli(83).words(9).depind  = 6;
stimuli(83).words(9).depjump = 3;

% 85                                                              
% De orthopeed die de blessure behandelt heeft er weinig benul van
% 1  2         3   4  5        6         7     8  9      10    11 
% 2  7         2   5  6        3         0     7  10     0     10 
% 2  7         2   5  6        3         0     7  10     7     10
stimuli(85).words(10).depind   = 7;
stimuli(85).words(10).depjump  = 3;

% 86                                                                             
% De secretaresse geeft de advocaat die de mannelijke beambte adviseert een brief
% 1  2            3     4  5        6   7  8          9       10        11  12   
% 2  3            0     5  3        5   9  9          10      6         12  10   
% 2  3            0     5  3        5   9  9          10      6         12  3   
stimuli(86).words(12).depind  = 3;
stimuli(86).words(12).depjump = 9;

% 87                                                     
% De wijze oude man die ieders dromen uitlegt komt morgen
% 1  2     3    4   5   6      7      8       9    10    
% 2  0     4    2   7   7      0      7       0    9     
% 4  4     4    9   4   7      8      5       0    9
stimuli(87).words(1).depind   = 4;
stimuli(87).words(1).depjump  = 3;
stimuli(87).words(2).depind   = 4;
stimuli(87).words(2).depjump  = 2;
stimuli(87).words(4).depind   = 9;
stimuli(87).words(4).depjump  = 5;
stimuli(87).words(5).depind   = 4;
stimuli(87).words(5).depjump  = 1;
stimuli(87).words(7).depind   = 8;
stimuli(87).words(7).depjump  = 1;
stimuli(87).words(8).depind   = 5;
stimuli(87).words(8).depjump  = 3;

% 88                                                                      
% Maandag heeft de aardige docent die de scholier onderwijst een vrije dag
% 1       2     3  4       5      6   7  8        9          10  11    12 
% 2       0     5  5       2      5   8  9        6          12  12    0  
% 2       0     5  5       2      5   8  9        6          12  12    2
stimuli(88).words(12).depind  = 2;
stimuli(88).words(12).depjump = 10;

% 90                                                          
% Mijn kleine nichtje die jaloers is wil dit mooie potlood ook
% 1    2      3       4   5       6  7   8   9     10      11 
% 3    3      0       3   6       4  0   10  10    7       10 
% 3    3      7       3   6       4  0   10  10    7       10
stimuli(90).words(3).depind  = 7;
stimuli(90).words(3).depjump = 4;

% 91                                                                      
% Alleen mensen die verstand hebben van wilde honden mogen pitbulls houden
% 1      2      3   4        5      6   7     8      9     10       11    
% 2      9      2   5        3      5   8     6      0     9        0     
% 2      9      2   5        3      5   8     6      0     9        9
stimuli(91).words(11).depind  = 9;
stimuli(91).words(11).depjump = 2;

% 92                                                                   
% Alleen een echte taaie die doorzet krijgt een plekje op de eerste rij
% 1      2   3     4     5   6       7      8   9      10 11 12     13 
% 0      0   0     0     6   7       0      9   7      9  13 13     10 
% 7      4   4     1     4   5       0      9   7      9  13 13     10
stimuli(92).words(1).depind  = 7;
stimuli(92).words(1).depjump = 6;
stimuli(92).words(2).depind  = 4;
stimuli(92).words(2).depjump = 2;
stimuli(92).words(3).depind  = 4;
stimuli(92).words(3).depjump = 1;
stimuli(92).words(4).depind  = 1;
stimuli(92).words(4).depjump = 3;
stimuli(92).words(5).depind  = 4;
stimuli(92).words(5).depjump = 1;
stimuli(92).words(6).depind  = 5;
stimuli(92).words(6).depjump = 1;

% 93                                                                   
% Het jonge hondje van mijn buurman die de dikke duiven opjaagt is wild
% 1   2     3      4   5    6       7   8  9     10     11      12 13  
% 3   3     0      3   6    4       6   10 10    11     7       0  12  
% 3   3     12     3   6    4       6   10 10    11     7       0  12
stimuli(93).words(3).depind  = 12;
stimuli(93).words(3).depjump = 9;

% 95                                                                             
% De vrouw die prachtige tekeningen maakt mag vanaf dinsdag naar de kunstacademie
% 1  2     3   4         5          6     7   8     9       10   11 12           
% 2  6     5   5         6          0     0   7     8       7    12 10           
% 2  7     2   5         6          3     0   7     8       7    12 10
stimuli(95).words(2).depind  = 7;
stimuli(95).words(2).depjump = 5;
stimuli(95).words(3).depind  = 2;
stimuli(95).words(3).depjump = 1;
stimuli(95).words(6).depind  = 3;
stimuli(95).words(6).depjump = 3;

% 102                                                   
% De clown die op het zonnige terras zit is uit op wraak
% 1  2     3   4  5   6       7      8   9  10  11 12   
% 2  8     2   8  7   7       4      0   0  9   9  11   
% 2  9     2   8  7   7       4      3   0  9   9  11
stimuli(102).words(2).depind  = 9;
stimuli(102).words(2).depjump = 7;
stimuli(102).words(8).depind  = 3;
stimuli(102).words(8).depjump = 5;

% 108                                                                       
% De overvaller stal alle kostbaarheden die de verbaasde buurman in huis had
% 1  2          3    4    5             6   7  8         9       10 11   12 
% 2  0          2    5    0             5   9  9         12      9  10   6  
% 2  3          0    5    3             5   9  9         12      12 10   6
stimuli(108).words(2).depind  = 3;
stimuli(108).words(2).depjump = 1;
stimuli(108).words(3).depind  = 0;
stimuli(108).words(3).depjump = 0;
stimuli(108).words(5).depind  = 3;
stimuli(108).words(5).depjump = 2;
stimuli(108).words(10).depind  = 12;
stimuli(108).words(10).depjump = 2;

% 113                                                                 
% Zonder groot protest nam het meisje dat moest huilen een hap groente
% 1      2     3       4   5   6      7   8     9      10  11  12     
% 4      3     1       0   6   4      8   0     8      12  12  0      
% 4      3     1       0   6   4      6   7     8      12  12  4
stimuli(113).words(7).depind  = 6;
stimuli(113).words(7).depjump = 1;
stimuli(113).words(8).depind  = 7;
stimuli(113).words(8).depjump = 1;
stimuli(113).words(12).depind  = 4;
stimuli(113).words(12).depjump = 8;

% 114                                                          
% Het zeldzame plantje dat in het venster stond had water nodig
% 1   2        3       4   5  6   7       8     9   10    11   
% 3   3        8       3   3  7   5       0     0   9     9    
% 3   3        9       3   8  7   8       4     0   9     9
stimuli(114).words(3).depind  = 9;
stimuli(114).words(3).depjump = 6;
stimuli(114).words(5).depind  = 8;
stimuli(114).words(5).depjump = 3;
stimuli(114).words(7).depind  = 8;
stimuli(114).words(7).depjump = 1;
stimuli(114).words(8).depind  = 4;
stimuli(114).words(8).depjump = 4;

% 132                                                               
% De flinke bonus die werd uitgedeeld aan het bestuur werd opgemerkt
% 1  2      3     4   5    6          7   8   9       10   11       
% 3  3      0     3   4    8          8   9   9       0    9        
% 3  3      10    3   4    5          6   9   7       0    10
stimuli(132).words(3).depind  = 10;
stimuli(132).words(3).depjump = 7;
stimuli(132).words(6).depind  = 5;
stimuli(132).words(6).depjump = 1;
stimuli(132).words(7).depind  = 6;
stimuli(132).words(7).depjump = 1;
stimuli(132).words(11).depind  = 10;
stimuli(132).words(11).depjump = 1;

% 134                                                                           
% De vrouw die zwanger was werd in kritieke toestand opgenomen in het ziekenhuis
% 1  2     3   4       5   6    7  8        9        10        11 12  13        
% 2  0     2   5       3   0    10 9        7        6         10 13  11        
% 1  6     2   5       3   0    10 9        7        6         10 13  11
stimuli(134).words(2).depind  = 6;
stimuli(134).words(2).depjump = 4;

% 151                                                                 
% De Hollandse bossen die prachtig zijn bezoekt de Zwitserse man graag
% 1  2         3      4   5        6    7       8  9         10  11   
% 3  3         6      3   6        0    0       10 10        7   10   
% 3  3         7      3   6        4    0       10 10        7   7
stimuli(151).words(3).depind  = 7;
stimuli(151).words(3).depjump = 4;
stimuli(151).words(6).depind  = 4;
stimuli(151).words(6).depjump = 2;
stimuli(151).words(11).depind  = 7;
stimuli(151).words(11).depjump = 4;

% 153                                                           
% Modieuze Sarah die wollen tassen op de markt bracht had succes
% 1        2     3   4      5      6  7  8     9      10  11    
% 2        6     4   4      8      8  8  6     0      0   7     
% 2        10    2   5      9      9  8  9     3      0   10
stimuli(153).words(2).depind  = 10;
stimuli(153).words(2).depjump = 8;
stimuli(153).words(3).depind  = 2;
stimuli(153).words(3).depjump = 1;
stimuli(153).words(4).depind  = 5;
stimuli(153).words(4).depjump = 1;
stimuli(153).words(5).depind  = 9;
stimuli(153).words(5).depjump = 1;
stimuli(153).words(6).depind  = 9;
stimuli(153).words(6).depjump = 3;
stimuli(153).words(8).depind  = 9;
stimuli(153).words(8).depjump = 1;
stimuli(153).words(9).depind  = 3;
stimuli(153).words(9).depjump = 6;
stimuli(153).words(11).depind  = 10;
stimuli(153).words(11).depjump = 1;

% 155                                                                        
% Voor twintig dollar die minder waard zijn dan voorheen krijg je maar weinig
% 1    2       3      4   5      6     7    8   9        10    11 12   13    
% 0    3       1      3   7      7     4    7   10       0     10 13   0     
% 13   3       1      3   7      7     4    7   8        0     10 10   12 
stimuli(155).words(1).depind  = 13;
stimuli(155).words(1).depjump = 12;
stimuli(155).words(9).depind  = 8;
stimuli(155).words(9).depjump = 1;
stimuli(155).words(9).depind  = 8;
stimuli(155).words(9).depjump = 1;
stimuli(155).words(12).depind  = 10;
stimuli(155).words(12).depjump = 2;
stimuli(155).words(13).depind  = 12;
stimuli(155).words(13).depjump = 1;

% 156                                                                               
% De staat betaalde de talentvolle advocaat die een uitstekend pleidooi had gehouden
% 1  2     3        4  5           6        7   8   9          10       11  12      
% 0  3     0        6  6           3        6   10  10         11       7   11      
% 2  3     0        6  6           3        6   10  10         11       7   11
stimuli(156).words(1).depind  = 2;
stimuli(156).words(1).depjump = 1;

% 158                                                                 
% De hevige bliksem die een kilometer verder insloeg zorgde voor brand
% 1  2      3       4   5   6         7      8       9      10   11   
% 3  3      0       3   6   8         8      4       0      9    10   
% 3  3      9       3   6   8         8      4       0      9    10
stimuli(158).words(3).depind  = 9;
stimuli(158).words(3).depjump = 6;

% 174                                                      
% Met kromme tenen die ze niet meer recht kreeg stond ze op
% 1   2      3     4   5  6    7    8     9     10    11 12
% 0   3      1     3   9  9    6    9     4     0     10 10
% 10  3      1     3   9  9    6    9     4     0     10 10
stimuli(174).words(1).depind  = 10;
stimuli(174).words(1).depjump = 9;

% 176                                                                     
% Opa Jan die bakker is wilde vroeger altijd piloot worden of brandweerman
% 1   2   3   4      5  6     7       8      9      10     11 12          
% 6   1   2   5      3  0     10      10     10     6      0  11          
% 6   1   2   5      3  0     10      10     10     6      10 10          
stimuli(176).words(11).depind  = 10;
stimuli(176).words(11).depjump = 1;
stimuli(176).words(12).depind  = 10;
stimuli(176).words(12).depjump = 2;
                                                                
% 177                                                    
% Ik at de muffe toast die niet goed smaakte toch maar op
% 1  2  3  4     5     6   7    8    9       10   11   12
% 2  0  5  5     9     5   8    9    0       11   9    9 
% 2  0  5  5     2     5   8    9    6       11   2    2
stimuli(177).words(5).depind  = 2;
stimuli(177).words(5).depjump = 3;
stimuli(177).words(9).depind  = 6;
stimuli(177).words(9).depjump = 3;
stimuli(177).words(11).depind  = 2;
stimuli(177).words(11).depjump = 9;
stimuli(177).words(12).depind  = 2;
stimuli(177).words(12).depjump = 10;

% 179                                                                       
% Mijn vriendin die de pas overleden tennisser kende ging naar de begrafenis
% 1    2        3   4  5   6         7         8     9    10   11 12        
% 2    9        2   7  6   7         8         3     0    9    12 0         
% 2    9        2   7  6   7         8         3     0    9    12 10 
stimuli(179).words(12).depind  = 10;
stimuli(179).words(12).depjump = 2;

% 187                                                                   
% De kleine gans die de andere persoon vasthield begon hard te fladderen
% 1  2      3    4   5  6      7       8         9     10   11 12       
% 3  3      0    3   7  7      8       4         0     9    9  11       
% 3  3      9    3   7  7      8       4         0     9    9  11
stimuli(187).words(3).depind  = 9;
stimuli(187).words(3).depjump = 6;

% 195                                                                                         
% Kreta dat prachtige stranden heeft is vanwege het massale toerisme veel minder aantrekkelijk
% 1     2   3         4        5     6  7       8   9       10       11   12     13           
% 0     0   4         0        0     0  6       10  10      7        12   13     6            
% 6     1   4         5        2     0  6       10  10      7        12   13     6
stimuli(195).words(1).depind  = 6;
stimuli(195).words(1).depjump = 5;
stimuli(195).words(2).depind  = 1;
stimuli(195).words(2).depjump = 1;
stimuli(195).words(4).depind  = 5;
stimuli(195).words(4).depjump = 1;
stimuli(195).words(5).depind  = 2;
stimuli(195).words(5).depjump = 3;

% 196                                                                   
% Peter die de gemene duivel had uitgedreven was doodmoe en sliep meteen
% 1     2   3  4      5      6   7           8   9       10 11    12    
% 8     1   5  5      6      2   6           0   10      0  10    11    
% 8     1   5  5      6      2   6           0   8       8  0     11    
stimuli(196).words(9).depind  = 8;
stimuli(196).words(9).depjump = 1;
stimuli(196).words(10).depind  = 8;
stimuli(196).words(10).depjump = 2;
stimuli(196).words(11).depind  = 0;
stimuli(196).words(11).depjump = 0;

% 205                                                             
% in Rotterdam hebben we samen prachtige dingen tot stand gebracht
% 1  2         3      4  5     6         7      8   9     10      
% 0  1         0      3  3     7         9      9   9     3       
% 3  1         0      3  3     7         10     3   3     3  
stimuli(205).words(1).depind  = 3;
stimuli(205).words(1).depjump = 2;
stimuli(205).words(7).depind  = 10;
stimuli(205).words(7).depjump = 3;
stimuli(205).words(8).depind  = 3;
stimuli(205).words(8).depjump = 5;
stimuli(205).words(9).depind  = 3;
stimuli(205).words(9).depjump = 6;

% 209                                                               
% De afgelopen dagen zijn politiek niet de meest succesvolle geweest
% 1  2         3     4    5        6    7  8     9           10     
% 3  3         0     5    10       10   9  9     10          0      
% 3  3         4     0    10       10   9  9     10          0      
stimuli(209).words(3).depind  = 4;
stimuli(209).words(3).depjump = 1;
stimuli(209).words(4).depind  = 5;
stimuli(209).words(4).depjump = 1;

% 214                                                               
% Vorig jaar zijn deze dertig dossiers allemaal aan elkaar gekoppeld
% 1     2    3    4    5      6        7        8   9      10       
% 2     0    0    6    6      3        9        9   9      3        
% 2     10   0    6    6      3        3        10  8      3        
stimuli(214).words(2).depind  = 10;
stimuli(214).words(2).depjump = 8;
stimuli(214).words(7).depind  = 3;
stimuli(214).words(7).depjump = 4;
stimuli(214).words(8).depind  = 10;
stimuli(214).words(8).depjump = 2;
stimuli(214).words(9).depind  = 8;
stimuli(214).words(9).depjump = 1;

% 223                                                      
% De drukke pubers in mijn straat zorgen voor veel overlast
% 1  2      3      4  5    6      7      8    9    10      
% 3  3      0      3  6    4      0      7    10   8       
% 3  3      7      3  6    4      0      7    10   8       
stimuli(223).words(3).depind  = 7;
stimuli(223).words(3).depjump = 4;

% 229                                                    
% De man maakte een diepe buiging voor de nieuwe koningin
% 1  2   3      4   5     6       7    8  9      10      
% 2  0   0      6   6     3       6    10 10     7       
% 2  3   0      6   6     3       6    10 10     7       
stimuli(229).words(2).depind  = 3;
stimuli(229).words(2).depjump = 1;
                                                        
% 234                                                                        
% De auto moest naar de garage voor een grote beurt en een periodieke keuring
% 1  2    3     4    5  6      7    8   9     10    11 12  13         14     
% 2  3    0     0    6  4      6    10  10    11    7  14  14         11     
% 2  3    0     3    6  4      3    10  10    7     7  14  14         7     
stimuli(234).words(4).depind  = 3;
stimuli(234).words(4).depjump = 1;
stimuli(234).words(7).depind  = 3;
stimuli(234).words(7).depjump = 4;
stimuli(234).words(10).depind  = 7;
stimuli(234).words(10).depjump = 3;
stimuli(234).words(14).depind  = 7;
stimuli(234).words(14).depjump = 7;
                                     
% 242                                                                                                
% Op kantoor gebruiken ze voor simpel kopieerwerk uitsluitend ongekleurd papier voor een beter milieu
% 1  2       3         4  5    6      7           8           9          10     11   12  13    14    
% 3  1       0         3  9    7      5           9           10         0      10   14  14    11    
% 3  1       0         3  3    7      5           3           10         3      10   14  14    11    
stimuli(242).words(5).depind  = 3;
stimuli(242).words(5).depjump = 2;
stimuli(242).words(8).depind  = 3;
stimuli(242).words(8).depjump = 5;
stimuli(242).words(10).depind  = 3;
stimuli(242).words(10).depjump = 7;

% 244                                                         
% De bloemist bezorgde bij Lisa een prachtig boeket rode rozen
% 1  2        3        4   5    6   7        8      9    10   
% 2  3        0        3   4    8   8        0      10   8    
% 2  3        0        3   4    8   8        3      10   8    
stimuli(244).words(8).depind  = 3;
stimuli(244).words(8).depjump = 5;
                                                           
% 248                                                                       
% Om niet herkend te worden droeg de overvaller een blonde pruik met krullen
% 1  2    3       4  5      6     7  8          9   10     11    12  13     
% 3  3    0       3  4      0     8  6          11  11     6     11  12     
% 3  3    5       3  4      0     8  6          11  11     6     11  12     
stimuli(248).words(3).depind  = 5;
stimuli(248).words(3).depjump = 2;

% 255                                                                  
% Waarschijnlijk maken duiven de grootste rotzooi op het centrale plein
% 1              2     3      4  5        6       7  8   9        10   
% 2              0     2      6  6        0       6  10  10       7    
% 2              0     2      6  6        2       6  10  10       7    
stimuli(255).words(6).depind  = 2;
stimuli(255).words(6).depjump = 4;

% 261                                                                     
% Het meisje moest van haar nieuwe tandarts een beugel tot haar achttiende
% 1   2      3     4   5    6      7        8   9      10  11   12        
% 2   3      0     0   7    7      4        9   4      9   12   10        
% 2   3      0     3   7    7      4        9   3      9   12   10        
stimuli(261).words(4).depind  = 3;
stimuli(261).words(4).depjump = 1;
stimuli(261).words(9).depind  = 3;
stimuli(261).words(9).depjump = 6;

% 271                                                              
% Aan het maken van reclame besteden lucratieve bedrijven veel geld
% 1   2   3     4   5       6        7          8         9    10  
% 0   3   1     3   4       0        8          6         10   6   
% 0   3   1     3   4       0        8          6         10   6   
stimuli(271).words(1).depind  = 6;
stimuli(271).words(1).depjump = 5;

% 272                                                                 
% Voor de aankoop van een auto sluiten mijn nieuwe buren een lening af
% 1    2  3       4   5   6    7       8    9      10    11  12     13
% 7    3  1       3   6   4    0       10   10     0     12  0      0 
% 7    3  1       3   6   4    0       10   10     7     12  7      7 
stimuli(272).words(10).depind  = 7;
stimuli(272).words(10).depjump = 3;
stimuli(272).words(12).depind  = 7;
stimuli(272).words(12).depjump = 5;
stimuli(272).words(13).depind  = 7;
stimuli(272).words(13).depjump = 6;
                                                                     
% 280                                                                           
% Tot ergernis van de strenge beheerder gooien de tieners rotzooi op het terrein
% 1   2        3   4  5       6         7      8  9       10      11 12  13     
% 0   1        2   6  6       3         0      9  7       7       10 13  11     
% 7   1        2   6  6       3         0      9  7       7       10 13  11     
stimuli(280).words(1).depind  = 7;
stimuli(280).words(1).depjump = 6;

% 288                                                                                    
% De lachwekkende clowns vermaken met talloze dwaasheden het laaiend enthousiaste publiek
% 1  2            3      4        5   6       7          8   9       10           11     
% 3  3            4      0        4   7       5          11  10      11           0      
% 3  3            4      0        4   7       5          11  10      11           4      
stimuli(288).words(11).depind  = 4;
stimuli(288).words(11).depjump = 7;

% 293                                                                         
% in indische restaurants wordt pikant vlees vaak met groene pepers geserveerd
% 1  2        3           4     5      6     7    8   9      10     11        
% 0  3        1           0     6      4     11   11  10     8      4         
% 11 3        1           0     6      4     11   11  10     8      4         
stimuli(293).words(1).depind  = 11;
stimuli(293).words(1).depjump = 10;

% 305                                                   
% Op die goede prestatie was helemaal niets af te dingen
% 1  2   3     4         5   6        7     8  9  10    
% 5  4   4     1         0   7        5     5  0  9     
% 5  4   4     1         0   7        5     5  5  9     
stimuli(305).words(9).depind  = 5;
stimuli(305).words(9).depjump = 4;

% 309                                                 
% De naam van de huidige president kon hij niet noemen
% 1  2    3   4  5       6         7   8   9    10    
% 2  0    2   6  6       7         0   7   10   7
% 2  7    2   6  6       3         0   7   10   7
stimuli(309).words(2).depind  = 7;
stimuli(309).words(2).depjump = 5;
stimuli(309).words(6).depind  = 3;
stimuli(309).words(6).depjump = 3;

% 311                                                           
% Bij het komende congres willen ze dat goede bestuur weer terug
% 1   2   3       4       5      6  7   8     9       10   11   
% 5   4   4       1       0      5  5   9     5       9    0    
% 5   4   4       1       0      5  5   9     5       9    5    
stimuli(311).words(11).depind  = 5;
stimuli(311).words(11).depjump = 6;

% 312                                                            
% Zijn houding lijkt hem vanaf het vroege begin te zijn ingegeven
% 1    2       3     4   5     6   7      8     9  10   11       
% 2    3       0     3   3     7   8      0     8  9    10       
% 2    3       0     3   3     7   8      5     8  9    10       
stimuli(312).words(8).depind  = 5;
stimuli(312).words(8).depjump = 3;

% 316                                                              
% De betere behuizing is afgedwongen door de nieuwe Europese regels
% 1  2      3         4  5           6    7  8      9        10    
% 3  3      4         0  4           5    0  10     10       0     
% 3  3      4         0  4           5    10 10     10       6     
stimuli(316).words(7).depind  = 10;
stimuli(316).words(7).depjump = 3;
stimuli(316).words(10).depind  = 6;
stimuli(316).words(10).depjump = 4;

% 317                                                          
% Wanneer krijgt die lakse puber nu eindelijk eens zijn diploma
% 1       2      3   4     5     6  7         8    9    10     
% 2       0      5   5     2     5  8         10   10   0      
% 2       0      5   5     2     5  8         10   10   0      
stimuli(317).words(8).depind  = 2;
stimuli(317).words(8).depjump = 6;
stimuli(317).words(10).depind  = 2;
stimuli(317).words(10).depjump = 8;

% 319                                                                
% Ook de vermoeide troepen in het gebied werden nog verder uitgebreid
% 1   2  3         4       5  6   7      8      9   10     11        
% 0   4  4         8       4  7   5      0      10  8      0         
% 8   4  4         8       4  7   5      0      10  8      8         
stimuli(319).words(1).depind  = 8;
stimuli(319).words(1).depjump = 7;
stimuli(319).words(11).depind  = 8;
stimuli(319).words(11).depjump = 3;

% 326                                                              
% Vanwege zijn eigen bekentenis wordt hij veroordeeld voor de moord
% 1       2    3     4          5     6   7           8    9  10   
% 0       4    4     1          0     5   5           7    10 8    
% 5       4    4     1          0     5   5           7    10 8    
stimuli(326).words(1).depind  = 5;
stimuli(326).words(1).depjump = 4;

% 331                                                                     
% Een paar mensen doen er alles aan om het populaire boekje te bemachtigen
% 1   2    3      4    5  6     7   8  9   10        11     12 13         
% 2   0    4      0    4  4     4   4  11  11        4      11 12         
% 2   3    4      0    4  4     4   4  11  11        8      11 12         
stimuli(331).words(2).depind  = 3;
stimuli(331).words(2).depjump = 1;
stimuli(331).words(11).depind  = 8;
stimuli(331).words(11).depjump = 3;

% 333                                                         
% Vandaar dat kippen zich op hun magere pootjes staande houden
% 1       2   3      4    5  6   7      8       9       10    
% 0       0   10     10   9  8   8      5       10      2     
% 2       0   10     10   10  8   8      5       10      2     
stimuli(333).words(1).depind  = 2;
stimuli(333).words(1).depjump = 1;
stimuli(333).words(5).depind  = 10;
stimuli(333).words(5).depjump = 5;

% 335                                           
% Op de tweede dinsdag ging het echter bijna mis
% 1  2  3      4       5    6   7      8     9  
% 5  4  4      1       0    5   5      9     0  
% 5  4  4      1       0    5   5      9     5  
stimuli(335).words(9).depind  = 5;
stimuli(335).words(9).depjump = 4;

% 337                                                
% in Japan en China komt een geringe deflatie op gang
% 1  2     3  4     5    6   7       8        9  10  
% 0  3     1  5     0    8   8       10       10 5   
% 5  3     1  5     0    8   8       5        5  9   
stimuli(337).words(1).depind  = 5;
stimuli(337).words(1).depjump = 4;
stimuli(337).words(8).depind  = 5;
stimuli(337).words(8).depjump = 3;
stimuli(337).words(9).depind  = 5;
stimuli(337).words(9).depjump = 4;
stimuli(337).words(10).depind  = 9;
stimuli(337).words(10).depjump = 1;

% 360                                                                              
% De vakkundige tandarts trok bij Nico zijn achterste kies met de ontstoken wortels
% 1  2          3        4    5   6    7    8         9    10  11 12        13     
% 3  3          4        0    4   5    8    9         0    9   13 13        10     
% 3  3          4        0    4   5    9    9         4    9   13 13        10     
stimuli(360).words(7).depind  = 9;
stimuli(360).words(7).depjump = 2;
stimuli(360).words(9).depind  = 4;
stimuli(360).words(9).depjump = 5;
                                                                            
% 361                                                                               
% Tijdens de vliegreis mocht het jongetje bij de ervaren piloot in de cockpit kijken
% 1       2  3         4     5   6        7   8  9       10     11 12 13      14    
% 4       3  1         0     6   14       6   10 10      7      10 13 11      0     
% 4       3  1         0     6   14       6   10 10      7      10 13 11      4     
stimuli(361).words(14).depind  = 4;
stimuli(361).words(14).depjump = 10;

% 370                                                                            
% De waarzegster voorspelde mijn bijgelovige tante de toekomst met een glazen bol
% 1  2           3          4    5           6     7  8        9   10  11     12 
% 2  3           0          6    6           3     8  3        0   12  12     9  
% 2  3           0          6    6           3     8  3        8   12  12     9  
stimuli(370).words(9).depind  = 8;
stimuli(370).words(9).depjump = 1;

% 380                                                            
% Ria gaat in de avonduren vaak lekker tennissen met een vriendin
% 1   2    3  4  5         6    7      8         9   10  11      
% 2   0    2  5  3         7    8      0         8   11  9       
% 2   0    2  5  3         7    8      2         8   11  9       
stimuli(380).words(8).depind  = 2;
stimuli(380).words(8).depjump = 6;

% 384                                                                                       
% Na jaren voor iemand anders gewerkt te hebben startte Luuk zijn eigen bedrijf in Eindhoven
% 1  2     3    4      5      6       7  8      9       10   11   12    13      14 15       
% 6  1     2    3      4      0       6  7      0       9    13   13    0       13 14       
% 6  1     2    3      4      0       6  7      0       9    13   13    9       13 14       
stimuli(384).words(13).depind  = 9;
stimuli(384).words(13).depjump = 4;

% 388                                                                
% Na afloop van het gezellige feest bellen de vrolijke dames een taxi
% 1  2      3   4   5         6     7      8  9        10    11  12  
% 7  1      2   6   6         3     0      10 10       0     12  0   
% 7  1      2   6   6         3     0      10 10       7     12  7   
stimuli(388).words(10).depind  = 7;
stimuli(388).words(10).depjump = 3;
stimuli(388).words(12).depind  = 7;
stimuli(388).words(12).depjump = 5;

% 389                                                                           
% Met de buitenlandse werknemers zoekt de arrogante directeur nauwelijks contact
% 1   2  3            4          5     6  7         8         9          10     
% 5   4  4            1          0     8  8         5         8          0      
% 5   4  4            1          0     8  8         5         8          5      
stimuli(389).words(10).depind  = 5;
stimuli(389).words(10).depjump = 5;

% 391                                                                                                
% Naar aanleiding van de boeiende toespraak over toenemend vandalisme leveren de studenten commentaar
% 1    2          3   4  5        6         7    8         9          10      11 12        13        
% 0    1          2   6  6        3         6    9         7          0       12 10        10        
% 0    1          2   6  6        3         6    9         7          0       12 10        10        
stimuli(391).words(1).depind  = 10;
stimuli(391).words(1).depjump = 9;

% 403                                                                     
% in de kleine zaal van het hotel vieren onze aardige buren hun verjaardag
% 1  2  3      4    5   6   7     8      9    10      11    12  13        
% 8  4  4      1    4   7   5     0      11   11      0     13  0         
% 8  4  4      1    4   7   5     0      11   11      8     13  0         
stimuli(403).words(11).depind  = 8;
stimuli(403).words(11).depjump = 3;
stimuli(403).words(13).depind  = 8;
stimuli(403).words(13).depjump = 5;

% 405                                                                              
% Mede dankzij de uitstekende organisatie komen de jonge bezoekers in groten getale
% 1    2       3  4           5           6     7  8     9         10 11     12    
% 2    6       5  5           2           0     9  9     12        12 12     0     
% 2    6       5  5           2           0     9  9     6         6  12     10     
stimuli(405).words(9).depind  = 6;
stimuli(405).words(9).depjump = 3;
stimuli(405).words(10).depind  = 6;
stimuli(405).words(10).depjump = 4;
stimuli(405).words(12).depind  = 10;
stimuli(405).words(12).depjump = 2;

% 407                                                                     
% in de moderne drogist betalen de meeste klanten uitsluitend elektronisch
% 1  2  3       4       5       6  7      8       9           10          
% 5  4  4       1       0       8  8      5       10          0           
% 5  4  4       1       0       8  8      5       10          5           
stimuli(407).words(10).depind  = 5;
stimuli(407).words(10).depjump = 5;
                                                               
% 408                                                           
% De blije jongeren zorgen voor intens plezier in hun woonplaats
% 1  2     3        4      5    6      7       8  9   10        
% 3  3     0        0      4    7      5       7  10  8       
% 3  3     4        0      4    7      5       7  10  8       
stimuli(408).words(3).depind  = 4;
stimuli(408).words(3).depjump = 1;



% 21                                                                 
% De zuster die de aan tuberculose lijdende bejaarde wast is zorgzaam
% 1  2      3   4  5   6           7        8        9    10 11      
% 2  10     2   9  7   5           8        9        3    0  10      
% 2  10     2   8  7   5           8        9        3    0  10      
stimuli(21).words(4).depind  = 8;
stimuli(21).words(4).depjump = 4;

% 23                                                      
% De geduldige dominee die de baby doopt begint te spreken
% 1  2         3       4   5  6    7     8      9  10     
% 3  3         8       3   6  7    4     10     10 8      
% 3  3         8       3   6  7    4     0     10 8      
stimuli(23).words(8).depind  = 0;
stimuli(23).words(8).depjump = 0;

% 26                                                            
% Robert die de schone dochter van Jan ten huwelijk vroeg slikte
% 1      2   3  4      5       6   7   8   9        10    11    
% 0      1   5  5      11      5   6   5   8        11    2     
% 11     1   5  5      10      5   6   10  8        2     0     
stimuli(26).words(1).depind  = 11;
stimuli(26).words(1).depjump = 10;
stimuli(26).words(5).depind  = 10;
stimuli(26).words(5).depjump = 5;
stimuli(26).words(8).depind  = 10;
stimuli(26).words(8).depjump = 2;
stimuli(26).words(10).depind  = 2;
stimuli(26).words(10).depjump = 8;
stimuli(26).words(11).depind  = 0;
stimuli(26).words(11).depjump = 0;

% 27                                                                         
% De detective die criminelen opspoort krijgt een vette beloning van de staat
% 1  2         3   4          5        6      7   8     9        10  11 12   
% 2  6         4   6          4        0      9   9     6        9   12 10   
% 2  6         2   6          3        0      9   9     6        9   12 10   
stimuli(27).words(3).depind  = 2;
stimuli(27).words(3).depjump = 1;
stimuli(27).words(5).depind  = 3;
stimuli(27).words(5).depjump = 2;

% 37                                                                     
% Gisteren had de aannemer die de bejaarde bewoner matste een goed humeur
% 1        2   3  4        5   6  7        8       9      10  11   12    
% 2        0   4  2        4   8  8        9       5      12  12   9     
% 2        0   4  2        4   8  8        9       5      12  12   2     
stimuli(37).words(12).depind  = 2;
stimuli(37).words(12).depjump = 10;

% 39                                                                       
% Onlangs gaf de jongeman die de populaire portier inhuurde een groot feest
% 1       2   3  4        5   6  7         8       9        10  11    12   
% 2       0   4  2        4   8  8         9       5        12  12    9    
% 2       0   4  2        4   8  8         9       5        12  12    2    
stimuli(39).words(12).depind  = 2;
stimuli(39).words(12).depjump = 10;

% 41                                                        
% De schilder die de knappe prinses tekent zit onder de verf
% 1  2        3   4  5      6       7      8   9     10 11  
% 2  0        2   6  6      7       3      3   8     11 9   
% 2  8        2   6  6      7       3      0   8     11 9   
stimuli(41).words(2).depind  = 8;
stimuli(41).words(2).depjump = 6;
stimuli(41).words(8).depind  = 0;
stimuli(41).words(8).depjump = 0;

% 46                                                          
% De raadsman die de wrede delinquent bijstond was op de radio
% 1  2        3   4  5     6          7        8   9  10 11   
% 2  0        2   6  6     8          6        3   8  11 9    
% 2  8        2   6  6     7          6        0   8  11 9    
stimuli(46).words(2).depind  = 8;
stimuli(46).words(2).depjump = 6;
stimuli(46).words(6).depind  = 7;
stimuli(46).words(6).depjump = 1;
stimuli(46).words(8).depind  = 0;
stimuli(46).words(8).depjump = 0;

% 48                                                                     
% De ouders die de angstige dochters bevrijden gingen opgelucht naar huis
% 1  2      3   4  5        6        7         8      9         10   11  
% 2  0      2   6  6        8        8         3      8         9    10  
% 2  8      2   6  6        8        3         0      8         9    10  
stimuli(48).words(2).depind  = 8;
stimuli(48).words(2).depjump = 6;
stimuli(48).words(7).depind  = 3;
stimuli(48).words(7).depjump = 4;
stimuli(48).words(8).depind  = 0;
stimuli(48).words(8).depjump = 0;

% 49
% Joost grijpt de stoere kidnapper die de bange directrice ontglipt in zijn kraag
% 1     2      3  4      5         6   7  8     9          10       11 12   13   
% 2     0      5  5      2         5   9  9     10         2        10 13   11   
% 2     0      5  5      2         5   9  9     10         6        2  13   11   
stimuli(49).words(10).depind  = 6;
stimuli(49).words(10).depjump = 4;
stimuli(49).words(11).depind  = 2;
stimuli(49).words(11).depjump = 9;
  
% 52                                                                                
% De werknemer die de strenge directeur gehoorzaamt is bang zijn baan kwijt te raken
% 1  2         3   4  5       6         7           8  9    10   11   12    13 14   
% 2  8         2   6  6       7         3           0  8    11   8    8     12 13   
% 2  8         2   6  6       7         3           0  8    11   14   14    14 9   
stimuli(52).words(11).depind  = 14;
stimuli(52).words(11).depjump = 3;
stimuli(52).words(12).depind  = 14;
stimuli(52).words(12).depjump = 2;
stimuli(52).words(13).depind  = 14;
stimuli(52).words(13).depjump = 1;
stimuli(52).words(14).depind  = 9;
stimuli(52).words(14).depjump = 5;

% 101                                                                                  
% De beroemdheid die de reporter wegstuurt wil de wachtende politie niet te woord staan
% 1  2           3   4  5        6         7   8  9         10      11   12 13    14   
% 2  7           2   5  6        3         0   10 10        7       13   13 13    7    
% 2  7           2   5  6        3         0   10 10        7       14   14 14    7    
stimuli(101).words(11).depind  = 14;
stimuli(101).words(11).depjump = 3;
stimuli(101).words(12).depind  = 14;
stimuli(101).words(12).depjump = 2;
stimuli(101).words(13).depind  = 14;
stimuli(101).words(13).depjump = 1;


% 141                                                 
% De omstanders die erg kritisch zijn maken de beroemde technoloog belachelijk
% 1  2          3   4   5        6    7     8  9        10         11         
% 2  6          2   6   6        10   6     10 10       11         0          
% 2  7          2   6   6        3    0     10 10       7          7          
stimuli(141).words(2).depind  = 7;
stimuli(141).words(2).depjump = 5;
stimuli(141).words(6).depind  = 3;
stimuli(141).words(6).depjump = 3;
stimuli(141).words(7).depind  = 0;
stimuli(141).words(7).depjump = 0;
stimuli(141).words(10).depind  = 7;
stimuli(141).words(10).depjump = 3;
stimuli(141).words(11).depind  = 7;
stimuli(141).words(11).depjump = 4;

% 161                                                                      
% De vastzittende kinderen die de vroege passanten alarmeren zijn in paniek
% 1  2            3        4   5  6      7         8         9    10 11    
% 3  3            0        3   6  7      4         7         8    9  10    
% 3  3            9        3   7  7      8         4         0    9  10    
stimuli(161).words(3).depind  = 9;
stimuli(161).words(3).depjump = 6;
stimuli(161).words(7).depind  = 8;
stimuli(161).words(7).depjump = 1;
stimuli(161).words(8).depind  = 4;
stimuli(161).words(8).depjump = 4;
stimuli(161).words(9).depind  = 0;
stimuli(161).words(9).depjump = 0;

% 167                                                  
% De erg botte bioloog die erg kwaad keek bukte en viel
% 1  2   3     4       5   6   7     8    9     10 11  
% 4  3   4     0       4   7   8     5    10    8  10  
% 4  3   4     9       4   7   8     5    0     9  0  
stimuli(167).words(4).depind  = 9;
stimuli(167).words(4).depjump = 5;
stimuli(167).words(9).depind  = 0;
stimuli(167).words(9).depjump = 0;
stimuli(167).words(10).depind  = 9;
stimuli(167).words(10).depjump = 1;
stimuli(167).words(11).depind  = 0;
stimuli(167).words(11).depjump = 0;

% 175                                                                    
% Mijn broer Hans die de milde pastoor zijn vele zonden opbiechtte huilde
% 1    2     3    4   5  6     7       8    9    10     11         12    
% 2    12    2    3   7  7     11      11   10   8      4          0     
% 2    12    2    3   7  7     11      10   10   11     4          0     
stimuli(175).words(8).depind  = 10;
stimuli(175).words(8).depjump = 2;
stimuli(175).words(10).depind  = 11;
stimuli(175).words(10).depjump = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% 94                                                                             
% Door heel scherpe bochten die in Griekenland voorkomen gebeuren veel ongelukken
% 1    2    3       4       5   6  7           8         9        10   11        
% 0    3    4       1       4   8  6           5         8        11   9  
% 9    3    4       1       4   8  6           5         0        11   9         
stimuli(94).words(1).depind  = 9;
stimuli(94).words(1).depjump = 8;
stimuli(94).words(9).depind  = 0;
stimuli(94).words(9).depjump = 0;
                                                                             
% 105                                                                   
% De verpleegster verzorgt de zieke die last van ontstoken pukkels heeft
% 1  2            3        4  5     6   7    8   9         10      11   
% 2  3            0        5  3     7   3    7   10        8       7    
% 2  3            0        5  3     5   11   7   10        8       6    
stimuli(105).words(6).depind  = 5;
stimuli(105).words(6).depjump = 1;
stimuli(105).words(7).depind  = 11;
stimuli(105).words(7).depjump = 4;
stimuli(105).words(11).depind  = 6;
stimuli(105).words(11).depjump = 5;

% 106                                                          
% De juf berispte het jongetje dat de gammele drukknop indrukte
% 1  2   3        4   5        6   7  8       9        10      
% 2  3   0        5   3        3   9  9       10       6       
% 2  3   0        5   3        5   9  9       10       6       
stimuli(106).words(6).depind  = 5;
stimuli(106).words(6).depjump = 1;

% 110                                                             
% Margriet die de drukke periode meer dan zat was ging op vakantie
% 1        2   3  4      5       6    7   8   9   10   11 12      
% 0        1   5  5      7       7    8   8   2   2    9  10      
% 10       1   5  5      9       8    8   9   2   0    10 11      
stimuli(110).words(1).depind  = 10;
stimuli(110).words(1).depjump = 9;
stimuli(110).words(5).depind  = 9;
stimuli(110).words(5).depjump = 4;
stimuli(110).words(6).depind  = 8;
stimuli(110).words(6).depjump = 2;
stimuli(110).words(8).depind  = 9;
stimuli(110).words(8).depjump = 1;
stimuli(110).words(10).depind  = 0;
stimuli(110).words(10).depjump = 0;
stimuli(110).words(11).depind  = 10;
stimuli(110).words(11).depjump = 1;
stimuli(110).words(12).depind  = 11;
stimuli(110).words(12).depjump = 1;

% 112                                                                
% Mijn aardige collega die ingedeeld was in de vroege dienst ging weg
% 1    2       3       4   5         6   7  8  9      10     11   12 
% 3    3       11      3   6         4   11 10 10     7      0    11 
% 3    3       11      3   6         4   6  10 10     7      0    11 
stimuli(112).words(7).depind  = 6;
stimuli(112).words(7).depjump = 1;

% 116                                                                  
% Mijn knappe oom Henk die de onzekere blondine uitnodigde moest lachen
% 1    2      3   4    5   6  7        8        9          10    11    
% 3    3      0   3    3   8  8        9        5          5     10    
% 3    3      10  3    3   8  8        9        5          0     10    

% 119                                                                   
% Aan onstuimige tieners die hun gang gaan valt doorgaans weinig te doen
% 1   2          3       4   5   6    7    8    9         10     11 12  
% 0   3          1       3   6   8    8    4    8         8      10 11  
% 8   3          1       3   6   7    4    0    8         8      10 11  

% 120                                                          
% Mannen die een strakke bandana om hun hoofd hebben zijn stoer
% 1      2   3   4       5       6  7   8     9      10   11   
% 10     1   5   5       10      5  8   10    10     0    10   
% 10     1   5   5       9       5  8   6     2      0    10   

% 123                                                     
% De tamme poema die op de Veluwe loopt is niet gevaarlijk
% 1  2     3     4   5  6  7      8     9  10   11        
% 3  3     9     3   9  7  5      9     0  9    9         
% 3  3     9     3   8  7  5      4     0  9    9         
                                                                                                                    
% 127                                                              
% De resultaten die er niet om logen lieten een sterke tendens zien
% 1  2          3   4  5    6  7     8      9   10     11      12  
% 2  8          2   8  6    8  6     0      11  11     12      8   
% 2  8          2   7  6    7  6     0      11  11     12      8   
                                      
% 128                                                          
% Moeder keek boos naar de kleuter die een flinke pruillip trok
% 1      2    3    4    5  6       7   8   9      10       11  
% 2      0    2    3    6  4       6   10  10     11       7   
                                                              
% 130                                                                         
% Toen de choreograaf die de trage danser uitschold de reden hoorde schrok hij
% 1    2  3           4   5  6     7      8         9  10    11     12     13 
% 12   3  11          3   7  7     8      4         10 8     1      0      12 
% 12   3  11          3   7  7     8      4         10 11    1      0      12 

% 131                                                                  
% De man die de politie arresteerde werd onder immens protest afgevoerd
% 1  2   3   4  5       6           7    8     9      10      11       
% 2  0   2   5  6       3           3    11    10     8       7        
% 2  7   2   5  6       3           0    11    10     8       7        

% 137                                                         
% Het houten bureau dat knullig in elkaar gezet was viel ineen
% 1   2      3      4   5       6  7      8     9   10   11   
% 3   3      9      3   7       7  7      8     4   0    9    
% 3   3      10     3   8       8  6      9     4   0    10    

% 140                                                            
% De ster die voldoende privacy belangrijk acht wordt vaak gebeld
% 1  2    3   4         5       6          7    8     9    10    
% 2  8    2   5         8       7          8    0     10   8     
% 2  8    2   5         7       7          3    0     10   8     
                     
% 141                                                                         
% De omstanders die erg kritisch zijn maken de beroemde technoloog belachelijk
% 1  2          3   4   5        6    7     8  9        10         11         
% 2  6          2   6   6        10   6     10 10       11         0          
% 2  7          2   6   6        3    0     10 10       11         7          

% 142                                                                
% De vlotte babbel die hij kan hebben tijdens sollicitaties helpt wel
% 1  2      3      4   5   6   7      8       9             10    11 
% 3  3      10     3   6   4   6      7       6             0     10 
% 3  3      10     3   6   4   6      7       8             0     10 

% 143                                                                                 
% Vincent die beroemde portretten geschilderd heeft kon daar helaas niks mee verdienen
% 1       2   3        4          5           6     7   8    9      10   11  12       
% 6       1   4        5          6           7     0   12   12     12   12  7        
% 7       1   4        5          6           2     0   12   12     12   12  7        

% 144                                                                 
% De artiesten die geen werk hebben moeten de huilende babies vermaken
% 1  2         3   4    5    6      7      8  9        10     11      
% 2  7         2   5    6    7      0      10 10       11     7       
% 2  7         2   5    6    3      0      10 10       11     7       

% 145                                                                 
% De route die langs de Utrechtse plassen liep was langer dan verwacht
% 1  2     3   4     5  6         7       8    9   10     11  12      
% 2  9     2   8     7  7         4       3    0   9      9   11      
% 2  9     2   8     7  7         4       3    0   9      10  11      

% 146                                                          
% De heks die haar een onzekere toekomst voorspelde lachte hard
% 1  2    3   4    5   6        7        8          9      10  
% 2  9    2   7    7   7        8        3          0      9   
% 2  9    2   8    7   7        8        3          0      9   

% 147                                                                            
% Gisteren kreeg de chauffeur die het verstopte buskruit ontdekt had een beloning
% 1        2     3  4         5   6   7         8        9       10  11  12      
% 2        0     4  2         4   9   8         9        10      5   12  10      
% 2        0     4  2         4   8   8         9        10      5   12  2      

% 148                                                                        
% De onervaren musicus die de dure zwarte piano gestemd heeft was zenuwachtig
% 1  2         3       4   5  6    7      8     9       10    11  12         
% 3  3         11      3   8  8    8      10    10      4     0   11         
% 3  3         11      3   8  8    8      9     10      4     0   11         

% 149                                                                  
% Mijn tante die ervan hield knusse dorpjes te bezoeken was enthousiast
% 1    2     3   4     5     6      7       8  9        10  11         
% 2    10    2   5     3     7      5       7  8        0   10         
% 2    10    2   5     3     7      8       5  8        0   10         

% 150                                                           
% Op de gammele tandem die niet verzekerd was kwamen we niet ver
% 1  2  3       4      5   6    7         8   9      10 11   12 
% 9  4  4       1      4   7    8         5   0      9  9    9  
%                                                               
% 151                                                                 
% De Hollandse bossen die prachtig zijn bezoekt de Zwitserse man graag
% 1  2         3      4   5        6    7       8  9         10  11   
% 3  3         6      3   6        0    0       10 10        7   10   
%                                                                     
% 152                                                                 
% Gisteren had oma die een zoete pannekoek had gegeten flinke buikpijn
% 1        2   3   4   5   6     7         8   9       10     11      
% 2        0   2   3   7   7     8         4   8       11     9       
%                                                                     
% 153                                                           
% Modieuze Sarah die wollen tassen op de markt bracht had succes
% 1        2     3   4      5      6  7  8     9      10  11    
% 2        6     4   4      8      8  8  6     0      0   7     
%                                                               
% 154                                                                       
% Het ideale breekijzer dat voor vele mannen onmisbaar is ligt in de winkels
% 1   2      3          4   5    6    7      8         9  10   11 12 13     
% 3   3      10         3   9    7    5      9         4  0    10 13 11     
%                                                                           
% 155                                                                        
% Voor twintig dollar die minder waard zijn dan voorheen krijg je maar weinig
% 1    2       3      4   5      6     7    8   9        10    11 12   13    
% 0    3       1      3   7      7     4    7   10       0     10 13   0     
%                                                                            
% 156                                                                               
% De staat betaalde de talentvolle advocaat die een uitstekend pleidooi had gehouden
% 1  2     3        4  5           6        7   8   9          10       11  12      
% 0  3     0        6  6           3        6   10  10         11       7   11      
%                                                                                   
% 157                                                                
% De schone parkiet die de madam inspireert zit opgesloten in de kooi
% 1  2      3       4   5  6     7          8   9          10 11 12  
% 3  3      8       3   6  7     4          0   8          9  12 10  
%                                                                    
% 158                                                                 
% De hevige bliksem die een kilometer verder insloeg zorgde voor brand
% 1  2      3       4   5   6         7      8       9      10   11   
% 3  3      0       3   6   8         8      4       0      9    10   
%                                                                     
% 159                                                         
% Mijn hondje beet zomaar in de lekkere taart die voor oma was
% 1    2      3    4      5  6  7       8     9   10   11  12 
% 2    0      2    5      2  8  8       5     8   12   10  9  
%                                                             
% 160                                                      
% De corrupte bankier die goede zaken deed had geen geweten
% 1  2        3       4   5     6     7    8   9    10     
% 3  3        0       3   6     7     4    4   10   8      
%                                                          
% 161                                                                      
% De vastzittende kinderen die de vroege passanten alarmeren zijn in paniek
% 1  2            3        4   5  6      7         8         9    10 11    
% 3  3            0        3   6  7      4         7         8    9  10    
%                                                                          
% 162                                                               
% Het nieuwe project dat veel geld kost lijkt in het water te vallen
% 1   2      3       4   5    6    7    8     9  10  11    12 13    
% 3   3      8       3   6    8    8    0     8  11  13    11 9     
%                                                                   
% 163                                                     
% Mijn gebakken ei dat een kapotte dooier had was heerlijk
% 1    2        3  4   5   6       7      8   9   10      
% 3    3        9  3   7   7       8      4   0   9       
%                                                         
% 165                                                            
% De collega's en omstanders troosten de bange techneut die huilt
% 1  2         3  4          5        6  7     8        9   10   
% 2  3         5  3          0        8  8     5        8   9    
%                                                                
% 166                                                   
% De dikke darmen die van het varken afkomen zijn gevuld
% 1  2     3      4   5   6   7      8       9    10    
% 3  3     9      3   8   7   5      4       0    9     
%                                                       
%                                                      
% 168                                                                   
% Hij struikelde over de behangrol die de onhandige behanger liet vallen
% 1   2          3    4  5         6   7  8         9        10   11    
% 2   0          2    5  3         5   9  9         10       6    10    
%                                                                       
% 169                                                               
% Ik haat de adviseur die onze dochter overtuigde dirigent te worden
% 1  2    3  4        5   6    7       8          9        10 11    
% 2  0    4  2        4   7    9       9          11       9  5     
%                                                                   
% 170                                                      
% Hij die niet wil luisteren moet nu op dikke blaren zitten
% 1   2   3    4   5         6    7  8  9     10     11    
% 6   1   4    2   4         0    8  11 10    8      6     
%                                                          
% 171                                                          
% De snelle drummer die een band zocht plaatste een advertentie
% 1  2      3       4   5   6    7     8        9   10         
% 3  3      8       3   6   7    4     0        10  8          
%                                                              
% 172                                                            
% Het stevige korte penseel dat de voorkeur van Joris had was weg
% 1   2       3     4       5   6  7        8   9     10  11  12 
% 4   4       4     11      4   7  10       7   8     5   0   11 
%                                                                
% 173                                                                        
% De fruitige dranken die soms vreemd smaakten werden geschonken op het feest
% 1  2        3       4   5    6      7        8      9          10 11  12   
% 3  3        8       3   6    7      4        0      8          9  12  10   
%                                                                            
% 174                                                      
% Met kromme tenen die ze niet meer recht kreeg stond ze op
% 1   2      3     4   5  6    7    8     9     10    11 12
% 0   3      1     3   9  9    6    9     4     0     10 10
%                                                          
% 175                                                                    
% Mijn broer Hans die de milde pastoor zijn vele zonden opbiechtte huilde
% 1    2     3    4   5  6     7       8    9    10     11         12    
% 2    12    2    3   7  7     11      11   10   8      4          0     
%                                                                        
% 176                                                                     
% Opa Jan die bakker is wilde vroeger altijd piloot worden of brandweerman
% 1   2   3   4      5  6     7       8      9      10     11 12          
% 6   1   2   5      3  0     10      10     10     6      0  11          
%                                                                         
% 177                                                    
% Ik at de muffe toast die niet goed smaakte toch maar op
% 1  2  3  4     5     6   7    8    9       10   11   12
% 2  0  5  5     9     5   8    9    0       11   9    9 
%                                                        
% 178                                                                     
% Frank werd erg nerveus van de vreemd ogende patholoog die hem onderzocht
% 1     2    3   4       5   6  7      8      9         10  11  12        
% 2     0    4   2       4   9  8      9      5         9   12  2         
%                                                                         
% 179                                                                       
% Mijn vriendin die de pas overleden tennisser kende ging naar de begrafenis
% 1    2        3   4  5   6         7         8     9    10   11 12        
% 2    9        2   7  6   7         8         3     0    9    12 0         
%                                                                           
% 180                                                                           
% in dat kamp voor tieners was geen enkele begeleider die verstand van zaken had
% 1  2   3    4    5       6   7    8      9          10  11       12  13    14 
% 6  3   1    3    4       0   9    9      6          9   14       11  12    10 
%                                                                               
% 181                                                          
% Hij redde de bejaarde die zich in de droge beschuit verslikte
% 1   2     3  4        5   6    7  8  9     10       11       
% 2   0     4  2        4   11   11 10 10    7        5        
%                                                              
% 182                                                                   
% De professor die vanaf zijn dertigste domino speelde had niet gewonnen
% 1  2         3   4     5    6         7      8       9   10   11      
% 2  9         2   8     7    7         4      3       0   11   9       
%                                                                       
% 183                                                                 
% Het versleten toestel dat nog aardig goed draait moet gekeurd worden
% 1   2         3       4   5   6      7    8      9    10      11    
% 3   3         0       3   7   7      8    4      4    11      9     
%                                                                     
% 184                                                                
% Rosa die de prachtige bruiloft bedacht had moest huilen van vreugde
% 1    2   3  4         5        6       7   8     9      10  11     
% 8    1   5  5         7        7       2   0     8      9   10     
%                                                                    
% 185                                                                 
% De grote bruine panda die met uitsterven bedreigd wordt rekent op u 
% 1  2     3      4     5   6   7          8        9     10     11 12
% 4  4     4      10    4   8   8          9        5     0      10 11
%                                                                     
% 186                                                              
% De bands die erg populair zijn brengen enorme tenten met zich mee
% 1  2     3   4   5        6    7       8      9      10  11   12 
% 2  7     2   5   6        3    0       9      7      9   10   10 
%                                                                  
% 187                                                                   
% De kleine gans die de andere persoon vasthield begon hard te fladderen
% 1  2      3    4   5  6      7       8         9     10   11 12       
% 3  3      0    3   7  7      8       4         0     9    9  11       
%                                                                       
% 188                                                                  
% Ton die dit prachtige paradijs had ontdekt wilde het verborgen houden
% 1   2   3   4         5        6   7       8     9   10        11    
% 8   1   5   5         6        2   6       0     8   11        8     
%                                                                      
% 189                                                                       
% De vers gemaakte salade die deze bedorven tomaat verpest heeft gooi ik weg
% 1  2    3        4      5   6    7        8      9       10    11   12 13 
% 4  3    4        11     4   8    8        10     10      5     0    11 11 
%                                                                           
% 190                                                                  
% Onze verhitte discussie die op niks uitdraaide heeft weinig zin gehad
% 1    2        3         4   5  6    7          8     9      10  11   
% 3    3        8         3   7  5    4          0     10     11  8    
%                                                                      
% 191                                                               
% De kopers van het perceel dat een vaste bestemming had kwamen niet
% 1  2      3   4   5       6   7   8     9          10  11     12  
% 2  11     2   5   3       5   9   9     10         6   0      11  
%                                                                   
% 192                                                                            
% Katten die continu plukjes haar verliezen kunnen een tekort aan vitamine hebben
% 1      2   3       4       5    6         7      8   9      10  11       12    
% 7      1   7       7       4    7         0      9   12     9   10       7     
%                                                                                
% 193                                                                        
% Verse beetgare pasta die overgoten wordt met rode saus is niet te versmaden
% 1     2        3     4   5         6     7   8    9    10 11   12 13       
% 3     3        10    3   6         4     6   9    7    0  10   10 12       
%                                                                            
% 194                                                                        
% Martine die het glimmende dressoir net gepoetst had vond een gouden ketting
% 1       2   3   4         5        6   7        8   9    10  11     12     
% 9       1   5   5         8        7   8        2   0    12  12     9      
%                                                                            
% 195                                                                                         
% Kreta dat prachtige stranden heeft is vanwege het massale toerisme veel minder aantrekkelijk
% 1     2   3         4        5     6  7       8   9       10       11   12     13           
% 0     0   4         0        0     0  6       10  10      7        12   13     6            
%                                                                                             
% 196                                                                   
% Peter die de gemene duivel had uitgedreven was doodmoe en sliep meteen
% 1     2   3  4      5      6   7           8   9       10 11    12    
% 8     1   5  5      6      2   6           0   10      0  10    11    
%                                                                       
% 197                                                            
% De heks die op haar kromme bezem door de lucht vloog was lelijk
% 1  2    3   4  5    6      7     8    9  10    11    12  13    
% 2  12   2   11 7    7      4     7    10 8     3     0   12    
%                                                                
% 198                                                                
% Zijn opa die doorgaans borrels drinkt is tegen een boom aan gereden
% 1    2   3   4         5       6      7  8     9   10   11  12     
% 2    0   2   5         6       3      3  7     10  8    12  7      
%                                                                    
% 199                                                                
% De ring van moeder die een echte diamant bevat is uit huis gestolen
% 1  2    3   4      5   6   7     8       9     10 11  12   13      
% 2  10   2   3      2   8   8     9       5     0  10  11   10      
%                                                                    
% 200                                                                   
% De oogarts van Anne die goedkope brillen aanbiedt is ook rijk geworden
% 1  2       3   4    5   6        7       8        9  10  11   12      
% 2  9       2   3    2   7        8       5        0  9   12   9       
%                                                                       
% 201                                                                               
% Het aardige vrouwtje gaf Henk die een kleurige papegaai gekocht had een zak pitjes
% 1   2       3        4   5    6   7   8        9        10      11  12  13  14    
% 3   3       4        0   4    5   9   9        11       11      6   13  14  11    
%                                                                                   
% 202                                                         
% De reus die de weg wees aan een kleine dwerg had een knuppel
% 1  2    3   4  5   6    7   8   9      10    11  12  13     
% 2  0    2   5  6   11   6   10  10     7     3   13  11     
%                                                             
% 203                                                                           
% Patricia die hard geleerd had haalde voor het moeilijke tentamen een hoog punt
% 1        2   3    4       5   6      7    8   9         10       11  12   13  
% 6        1   4    5       2   0      6    10  10        7        13  13   7   
%                                                                               
% 204                                                                
% De trui die in de nieuwe droger terecht was gekomen paste niet meer
% 1  2    3   4  5  6      7      8       9   10      11    12   13  
% 2  11   2   9  7  7      4      9       3   9       0     11   12  
%                                                                    
% 205                                                             
% in Rotterdam hebben we samen prachtige dingen tot stand gebracht
% 1  2         3      4  5     6         7      8   9     10      
% 0  1         0      3  3     7         9      9   9     3       
%                                                                 
% 206                                                      
% Op een kortere termijn vertrok het gezelschap naar de bus
% 1  2   3       4       5       6   7          8    9  10 
% 5  4   4       1       0       7   5          7    10 8  
%                                                          
% 207                                                      
% Lezers hebben daar in groten getale bezwaar tegen gemaakt
% 1      2      3    4  5      6      7       8     9      
% 2      0      6    6  6      7      7       7     2      
%                                                          
% 208                                                                                 
% Het is een schrijnende situatie waaraan de Nederlandse politiek nauwelijks iets doet
% 1   2  3   4           5        6       7  8           9        10         11   12  
% 2   0  5   5           2        5       9  9           12       9          12   6   
%                                                                                     
% 209                                                               
% De afgelopen dagen zijn politiek niet de meest succesvolle geweest
% 1  2         3     4    5        6    7  8     9           10     
% 3  3         0     5    10       10   9  9     10          0      
%                                                                   
% 210                                                                     
% Ook in Nederland staat het strenge toezicht op accountants ter discussie
% 1   2  3         4     5   6       7        8  9           10  11       
% 2   4  2         0     7   7       4        7  11          11  8        
%                                                                         
% 211                                                       
% Dit zijn geen regionale problemen zoals die op de Antillen
% 1   2    3    4         5         6     7   8  9  10      
% 2   0    5    5         2         5     6   5  10 8       
%                                                           
% 212                                                                   
% Niet alle pillen en blauwe poeders kunnen zonder meer worden ingevoerd
% 1    2    3      4  5      6       7      8      9    10     11       
% 7    3    4      1  6      4       9      9      9    0      9        
%                                                                       
% 213                                              
% Je haalt zo het complete bouwsel uit zijn verband
% 1  2     3  4   5        6       7   8    9      
% 2  0     2  6   6        2       6   9    7      
%                                                  
% 214                                                               
% Vorig jaar zijn deze dertig dossiers allemaal aan elkaar gekoppeld
% 1     2    3    4    5      6        7        8   9      10       
% 2     0    0    6    6      3        9        9   9      3        
%                                                                   
% 216                                                                    
% De actiegroep signaleert een nieuw probleem voor de natuur in Waterland
% 1  2          3          4   5     6        7    8  9      10 11       
% 2  3          0          6   6     3        6    9  7      9  10       
%                                                                        
% 217                                                      
% in de laatste race eindigde het olympisch paard als derde
% 1  2  3       4    5        6   7         8     9   10   
% 5  4  4       1    0        8   8         5     5   9    
%                                                          
% 218                                                                
% Bij het openbare debat werd iedereen duidelijk wat de bedoeling was
% 1   2   3        4     5    6        7         8   9  10        11 
% 5   4   4        1     0    5        5         5   10 11        8  
%                                                                    
% 219                                                
% Hij werkt voor twaalf dollar per uur bij die winkel
% 1   2     3    4      5      6   7   8   9   10    
% 2   0     2    5      3      5   6   7   10  8     
%                                                    
% 220                                                   
% Hij gaf zijn eigen bestaan op voor zijn bruid in India
% 1   2   3    4     5       6  7    8    9     10 11   
% 2   0   5    5     2       2  2    9    7     9  10   
%                                                       
% 221                                                                  
% Groeperingen binnen de kerk bestrijden zijn grote bekendheid en macht
% 1            2      3  4    5          6    7     8          9  10   
% 5            1      4  2    0          8    8     9          5  9    
%                                                                      
% 222                                                           
% Het is een minder tijdrovende procedure dan klassieke animatie
% 1   2  3   4      5           6         7   8         9       
% 2   0  6   6      6           2         2   9         7       
%                                                               
% 223                                                      
% De drukke pubers in mijn straat zorgen voor veel overlast
% 1  2      3      4  5    6      7      8    9    10      
% 3  3      0      3  6    4      0      7    10   8       
%                                                          
% 224                                               
% Het bruine broodje is belegd met kaas en verse ham
% 1   2      3       4  5      6   7    8  9     10 
% 3   3      4       0  4      5   8    6  10    8  
%                                                   
% 225                                                                           
% Meer dan duizend arbeiders werken in het moderne bedrijf tegenover het station
% 1    2   3       4         5      6  7   8       9       10        11  12     
% 4    1   2       5         0      5  9   9       6       9         12  10     
%                                                                               
% 226                                                
% Anke geeft de groene plant wat water met een gieter
% 1    2     3  4      5     6   7     8   9   10    
% 2    0     5  5      2     7   2     2   10  8     
%                                                    
% 227                                                         
% De wijnglazen staan op de bovenste plank in het keukenkastje
% 1  2          3     4  5  6        7     8  9   10          
% 2  3          0     3  7  7        4     7  10  8           
%                                                             
% 228                                                       
% De moedige trimmers bereikten eindelijk de top van de berg
% 1  2       3        4         5         6  7   8   9  10  
% 3  3       4        0         4         7  4   7   10 8   
%                                                           
% 229                                                    
% De man maakte een diepe buiging voor de nieuwe koningin
% 1  2   3      4   5     6       7    8  9      10      
% 2  0   0      6   6     3       6    10 10     7       
%                                                        
% 230                                                                              
% De huishoudster nam de tafel af met een vochtig doekje om het stof te verwijderen
% 1  2            3   4  5     6  7   8   9       10     11 12  13   14 15         
% 2  3            0   5  3     3  3   10  10      7      10 13  11   11 14         
%                                                                                  
% 232                                                                  
% De zakenvrouw droeg een mooie grijze pantalon tijdens de voorstelling
% 1  2          3     4   5     6      7        8       9  10          
% 2  3          0     7   7     7      3        7       10 8           
%                                                                      
% 233                                                                                        
% De Keukenhof wordt jaarlijks druk bezocht door buitenlandse toeristen met dure fotocamera's
% 1  2         3     4         5    6       7    8            9         10  11   12          
% 2  3         0     5         6    3       6    9            7         9   12   10          
%                                                                                            
% 234                                                                        
% De auto moest naar de garage voor een grote beurt en een periodieke keuring
% 1  2    3     4    5  6      7    8   9     10    11 12  13         14     
% 2  3    0     0    6  4      6    10  10    11    7  14  14         11     
%                                                                            
% 235                                                                    
% Kees kocht voor zijn vrouw een keurig bosje bloemen en een doos bonbons
% 1    2     3    4    5     6   7      8     9       10 11  12   13     
% 2    0     2    5    3     8   8      2     8       8  12  10   8      
%                                                                        
% 236                                                                
% in het sprookje zit de koning altijd op zijn gouden troon te niksen
% 1  2   3        4   5  6      7      8  9    10     11    12 13    
% 4  3   1        0   6  4      8      6  11   11     8     11 12    
%                                                                    
% 237                                                                    
% De schilder kleurde de details in met een klein penseel van varkenshaar
% 1  2        3       4  5       6  7   8   9     10      11  12         
% 2  3        0       5  3       3  3   10  10    7       10  11         
%                                                                        
% 238                                                         
% Dorien werd helemaal gek van de druppende kraan in de keuken
% 1      2    3        4   5   6  7         8     9  10 11    
% 2      0    4        2   2   8  8         5     8  11 9     
%                                                             
% 239                                                           
% De firma viert haar tienjarig bestaan met een gigantisch feest
% 1  2     3     4    5         6       7   8   9          10   
% 2  3     0     6    6         3       6   10  10         7    
%                                                               
% 240                                             
% Het zieke meisje had flinke koorts door de griep
% 1   2     3      4   5      6      7    8  9    
% 3   3     4      0   6      4      6    9  7    
%                                                 
% 241                                                          
% Ik hielp de lastige klant geduldig met zijn eerste bestelling
% 1  2     3  4       5     6        7   8    9      10        
% 2  0     5  5       2     2        6   10   10     7         
%                                                              
% 242                                                                                                
% Op kantoor gebruiken ze voor simpel kopieerwerk uitsluitend ongekleurd papier voor een beter milieu
% 1  2       3         4  5    6      7           8           9          10     11   12  13    14    
% 3  1       0         3  9    7      5           9           10         0      10   14  14    11    
%                                                                                                    
% 243                                                           
% Marco gaat ieder half jaar bij zijn eigen tandarts op controle
% 1     2    3     4    5    6   7    8     9        10 11      
% 2     0    5     5    2    5   9    9     2        9  10      
%                                                               
% 244                                                         
% De bloemist bezorgde bij Lisa een prachtig boeket rode rozen
% 1  2        3        4   5    6   7        8      9    10   
% 2  3        0        3   4    8   8        0      10   8    
%                                                             
% 245                                                    
% Floor had vannacht een hele angstige droom over slangen
% 1     2   3        4   5    6        7     8    9      
% 2     0   2        7   7    7        2     7    8      
%                                                        
% 246                                                                              
% De twee auto's waren betrokken bij een frontale botsing op de gevaarlijke autoweg
% 1  2    3      4     5         6   7   8        9       10 11 12          13     
% 3  3    4      0     4         5   9   9        6       9  13 13          10     
%                                                                                  
% 247                                                                   
% De eigenaar van het moderne theater beschuldigde de vrouw van diefstal
% 1  2        3   4   5       6       7            8  9     10  11      
% 2  7        2   6   6       3       0            9  7     9   10      
%                                                                       
% 248                                                                       
% Om niet herkend te worden droeg de overvaller een blonde pruik met krullen
% 1  2    3       4  5      6     7  8          9   10     11    12  13     
% 3  3    0       3  4      0     8  6          11  11     6     11  12     
%                                                                           
% 249                                             
% De zanger trad op voor een groot publiek in Ahoy
% 1  2      3    4  5    6   7     8       9  10  
% 2  3      0    3  3    8   8     5       8  9   
%                                                 
% 250                                                         
% Die boer loopt nog op ouderwetse klompen door het boerendorp
% 1   2    3     4   5  6          7       8    9   10        
% 2   3    0     3   3  7          5       7    10  8         
%                                                             
% 251                                                         
% Sinds Dorien's tante hier op bezoek was is er veel veranderd
% 1     2        3     4    5  6      7   8  9  10   11       
% 8     3        1     3    8  5      8   0  8  8    8        
%                                                             
% 252                                                           
% in de wieg lag een baby met gebalde knuistjes lekker te slapen
% 1  2  3    4   5   6    7   8       9         10     11 12    
% 4  3  1    0   6   4    4   9       7         9      4  11    
%                                                               
% 253                                                                      
% Bij het spelen lette het orkest goed op kleine bewegingen van de dirigent
% 1   2   3      4     5   6      7    8  9      10         11  12 13      
% 4   3   1      0     6   4      4    4  10     8          10  13 11      
%                                                                          
% 254                                                            
% na de verkiezingen was de PvdA de grootste partij van Nederland
% 1  2  3            4   5  6    7  8        9      10  11       
% 4  3  1            0   6  4    9  9        4      9   10       
%                                                                
% 255                                                                  
% Waarschijnlijk maken duiven de grootste rotzooi op het centrale plein
% 1              2     3      4  5        6       7  8   9        10   
% 2              0     2      6  6        0       6  10  10       7    
%                                                                      
% 256                                                                        
% Spanje is erg in trek vanwege het gunstige klimaat en de prachtige stranden
% 1      2  3   4  5    6       7   8        9       10 11 12        13      
% 2      0  2   3  4    5       9   9        10      6  13 13        10      
%                                                                            
% 257                                                                               
% Tegenwoordig juichen kinderen alleen nog voor grote verrassingen op hun verjaardag
% 1            2       3        4      5   6    7     8            9  10  11        
% 2            0       2        6      4   2    8     6            8  11  9         
%                                                                                   
% 258                                                                             
% Ondanks dat er kleine danspasjes werden gemaakt struikelde Roos over haar voeten
% 1       2   3  4      5          6      7       8          9    10   11   12    
% 8       1   6  5      6          2      6       0          8    8    12   10    
%                                                                                 
% 259                                                                
% De bouw van het schuurtje bleek nog een behoorlijk karwei voor Hans
% 1  2    3   4   5         6     7   8   9          10     11   12  
% 2  6    2   5   3         0     6   10  10         6      10   11  
%                                                                    
% 260                                                                            
% De minister was benieuwd naar het totale percentage van de kiezers in Friesland
% 1  2        3   4        5    6   7      8          9   10 11      12 13       
% 2  3        0   3        4    8   8      5          8   11 9       11 12       
%                                                                                
% 261                                                                     
% Het meisje moest van haar nieuwe tandarts een beugel tot haar achttiende
% 1   2      3     4   5    6      7        8   9      10  11   12        
% 2   3      0     0   7    7      4        9   4      9   12   10        
%                                                                         
% 262                                                              
% Het verloofde koppel bekijkt de locatie voor hun bruiloft in juni
% 1   2         3      4       5  6       7    8   9        10 11  
% 2   4         4      0       6  4       6    9   7        9  10  
%                                                                  
% 263                                                                              
% Er waren veel artsen in de stad vanwege een belangrijke bespreking over chirurgie
% 1  2     3    4      5  6  7    8       9   10          11         12   13       
% 2  0     4    2      4  7  5    2       11  11          8          11   12       
%                                                                                  
% 264                                                 
% Op zijn werk drinkt Peter heel wat koffie met suiker
% 1  2    3    4      5     6    7   8      9   10    
% 4  3    1    0      4     7    8   4      8   9     
%                                                     
% 265                                                               
% De botsing vond plaats op een riskante kruising net buiten de stad
% 1  2       3    4      5  6   7        8        9   10     11 12  
% 2  3       0    3      3  8   8        5        10  8      12 10  
%                                                                   
% 266                                                                                 
% De terrorist bracht de politie op een vervelend dwaalspoor door van auto te wisselen
% 1  2         3      4  5       6  7   8         9          10   11  12   13 14      
% 2  3         0      5  3       5  9   9         6          6    3   11   12 13      
%                                                                                     
% 267                                                                           
% De schildwacht stond uren bij de poort van een vervallen kasteel op de uitkijk
% 1  2           3     4    5   6  7     8   9   10        11      12 13 14     
% 2  3           0     3    3   7  5     7   11  11        8       11 14 12     
%                                                                               
% 268                                          
% We maakten een grote kring om samen te zingen
% 1  2       3   4     5     6  7     8  9     
% 2  0       5   5     2     5  2     2  8     
%                                              
% 269                                                                
% Vanwege het stormachtige weer spelen meerdere teams in een sporthal
% 1       2   3            4    5      6        7     8  9   10      
% 5       3   5            5    0      7        5     7  10  8       
%                                                                    
% 270                                                                                
% Halverwege de spannende wedstrijd houden de agenten een aantal vechtende pubers aan
% 1          2  3         4         5      6  7       8   9      10        11     12 
% 5          4  4         1         0      7  5       9   5      11        9      5  
%                                                                                    
% 271                                                              
% Aan het maken van reclame besteden lucratieve bedrijven veel geld
% 1   2   3     4   5       6        7          8         9    10  
% 0   3   1     3   4       0        8          6         10   6   
%                                                                  
% 272                                                                 
% Voor de aankoop van een auto sluiten mijn nieuwe buren een lening af
% 1    2  3       4   5   6    7       8    9      10    11  12     13
% 7    3  1       3   6   4    0       10   10     0     12  0      0 
%                                                                     
% 273                                                                                    
% Vanwege de massale stakingen in het slachthuis stijgen de huidige prijzen van het vlees
% 1       2  3       4         5  6   7          8       9  10      11      12  13  14   
% 8       4  4       1         4  7   5          0       11 11      8       11  14  12   
%                                                                                        
% 274                                                                              
% Bij de aankoop van twaalf flessen wijn krijgen de rijke toeristen een fles cadeau
% 1   2  3       4   5      6       7    8       9  10    11        12  13   14    
% 8   3  1       3   6      8       6    0       11 11    8         14  14   8     
%                                                                                  
% 275                                                             
% Onder de eeuwenoude eik in de tuin bloeien de witte tulpen volop
% 1     2  3          4   5  6  7    8       9  10    11     12   
% 8     4  4          1   4  7  5    0       11 11    8      11   
%                                                                 
% 276                                                                              
% Bij de opening van de nieuwe sporthal kregen de talrijke bezoekers een consumptie
% 1   2  3       4   5  6      7        8      9  10       11        12  13        
% 8   3  1       3   7  7      4        0      11 11       8         13  8         
%                                                                                  
% 277                                                                      
% Tijdens de heftige discussie stellen de gedreven advocaten lastige vragen
% 1       2  3       4         5       6  7        8         9       10    
% 5       4  4       1         0       8  8        5         10      5     
%                                                                          
% 278                                                                  
% Vanwege het onlangs behaalde diploma trakteren mijn vrienden op gebak
% 1       2   3       4        5       6         7    8        9  10   
% 6       5   4       5        1       0         8    6        8  9    
%                                                                      
% 279                                                                          
% Tijdens de rumoerige bespreking beslisten de leden de staking voort te zetten
% 1       2  3         4          5         6  7     8  9       10    11 12    
% 5       4  4         1          0         7  5     9  5       9     9  11    
%                                                                              
% 280                                                                           
% Tot ergernis van de strenge beheerder gooien de tieners rotzooi op het terrein
% 1   2        3   4  5       6         7      8  9       10      11 12  13     
% 0   1        2   6  6       3         0      9  7       7       10 13  11     
%                                                                               
% 281                                                                         
% Vanwege de enorme behoefte aan ijslollies voert de fabrikant de productie op
% 1       2  3      4        5   6          7     8  9         10 11        12
% 7       4  4      1        4   5          0     9  7         11 7         7 
%                                                                             
% 282                                                                   
% Alleen ervaren duikers springen vanaf de hoge duikplank in het zwembad
% 1      2       3       4        5     6  7    8         9  10  11     
% 4      4       4       0        4     8  8    5         8  11  9      
%                                                                       
% 283                                                     
% De gruwelijk verwende tieners kopen een ketting van goud
% 1  2         3        4       5     6   7       8   9   
% 4  3         4        5       0     7   5       7   8   
%                                                         
% 284                                                                         
% Zowel de leerlingen als de bezorgde docenten bidden voor de doodzieke rector
% 1     2  3          4   5  6        7        8      9    10 11        12    
% 8     3  1          3   7  7        8        0      8    12 12        9     
%                                                                             
% 285                                                          
% De in lompen gehulde bedelaar steelt fruit van de groenteboer
% 1  2  3      4       5        6      7     8   9  10         
% 5  4  2      5       6        0      6     7   10 8          
%                                                              
% 286                                                                           
% De vrolijke meisjes dansen tijdens de gezellige braderie uitgelaten met elkaar
% 1  2        3       4      5       6  7         8        9          10  11    
% 3  3        4       0      4       8  8         5        10         8   10    
%                                                                               
% 287                                                                     
% De vermoeide feestgangers rusten na de vrolijke bruiloft uit in het park
% 1  2         3            4      5  6  7        8        9   10 11  12  
% 3  3         4            0      4  8  8        5        10  8  12  10  
%                                                                         
% 288                                                                                    
% De lachwekkende clowns vermaken met talloze dwaasheden het laaiend enthousiaste publiek
% 1  2            3      4        5   6       7          8   9       10           11     
% 3  3            4      0        4   7       5          11  10      11           0      
%                                                                                        
% 289                                                                          
% De behoorlijk dronken bestuurder verzint een flauw smoesje voor de politieman
% 1  2          3       4          5       6   7     8       9    10 11        
% 4  3          4       5          0       8   8     5       8    11 9         
%                                                                              
% 290                                                                         
% De vrolijke ober serveert fel gekleurde drankjes met kokosnoten en ananassen
% 1  2        3    4        5   6         7        8   9          10 11       
% 3  3        4    0        6   7         4        7   10         8  10       
%                                                                             
% 291                                                                                      
% De goede vriend bedenkt een toepasselijk gedicht om het kersverse bruidspaar te verrassen
% 1  2     3      4       5   6            7       8  9   10        11         12 13       
% 3  3     4      0       7   7            4       7  11  11        13         11 4        
%                                                                                          
% 292                                                                     
% De gevaarlijke overvallers nemen met een handvol diamanten geen genoegen
% 1  2           3           4     5   6   7       8         9    10      
% 3  3           4           0     4   7   5       7         10   5       
%                                                                         
% 293                                                                         
% in indische restaurants wordt pikant vlees vaak met groene pepers geserveerd
% 1  2        3           4     5      6     7    8   9      10     11        
% 0  3        1           0     6      4     11   11  10     8      4         
%                                                                             
% 294                                                  
% De oudere man leest de zondagse krant in de huiskamer
% 1  2      3   4     5  6        7     8  9  10       
% 3  3      4   0     7  7        4     7  10 8        
%                                                      
% 295                                                            
% De pientere dame kreeg een prachtig boekje voor haar verjaardag
% 1  2        3    4     5   6        7      8    9    10        
% 3  3        4    0     7   7        4      7    10   8         
%                                                                
% 296                                                       
% De knappe ober presenteert het lopend buffet op het terras
% 1  2      3    4           5   6      7      8  9   10    
% 3  3      4    0           7   7      4      7  10  8     
%                                                           
% 297                                                               
% Kinderen in China naaien goedkope kleren voor westerse consumenten
% 1        2  3     4      5        6      7    8        9          
% 4        1  2     0      6        4      6    9        7          
%                                                                   
% 298                                                            
% Hij maakte de verstandige keuze om vlug naar huis te vertrekken
% 1   2      3  4           5     6  7    8    9    10 11        
% 2   0      5  5           2     5  8    5    8    5  10        
%                                                                
% 299                                                    
% Een heftige drang om te spijbelen overvalt me al meteen
% 1   2       3     4  5  6         7        8  9  10    
% 3   3       7     3  4  5         0        7  7  7     
%                                                        
% 300                                                 
% Van de drie vocalisten maakte Karin de meeste indruk
% 1   2  3    4          5      6     7  8      9     
% 5   4  4    1          0      5     9  9      5     
%                                                     
% 301                                                                
% Ook bij de Nederlandse dijken is een dergelijk probleem vastgesteld
% 1   2   3  4           5      6  7   8         9        10         
% 2   6   5  5           2      0  9   9         6        6          
%                                                                    
% 302                                                      
% Ik kom net terug uit de heropende dierentuin in Amsterdam
% 1  2   3   4     5   6  7         8          9  10       
% 2  0   2   2     2   8  8         5          8  9        
%                                                          
% 303                                               
% Op dat moment liet haar eigen broertje de hond uit
% 1  2   3      4    5    6     7        8  9    10 
% 4  3   1      0    7    7     4        9  7    7  
%                                                   
% 304                                                      
% Ook dat kleine dorpje wordt nu bedreigd door de nieuwbouw
% 1   2   3      4      5     6  7        8    9  10       
% 4   4   4      5      0     7  5        7    10 8        
%                                                          
% 305                                                   
% Op die goede prestatie was helemaal niets af te dingen
% 1  2   3     4         5   6        7     8  9  10    
% 5  4   4     1         0   7        5     5  0  9     
%                                                       
% 306                                                                       
% De vroegere afhankelijke positie past het veranderde Griekenland niet meer
% 1  2        3            4       5    6   7          8           9    10  
% 4  4        4            5       0    8   8          5           10   5   
%                                                                           
% 307                                                     
% Over enkele jaren breekt het onnodige drama pas goed los
% 1    2      3     4      5   6        7     8   9    10 
% 4    3      1     0      7   7        4     7   10   4  
%                                                         
% 308                                                                
% Een belangrijk probleem is de vraag naar meer goedkope grondstoffen
% 1   2          3        4  5  6     7    8    9        10          
% 3   3          4        0  6  4     6    9    10       7           
%                                                                    
% 309                                                 
% De naam van de huidige president kon hij niet noemen
% 1  2    3   4  5       6         7   8   9    10    
% 2  0    2   6  6       7         0   7   10   7     
%                                                     
% 310                                                           
% Alleen in ons eigen bedrijf geldt de verlaging voor reparaties
% 1      2  3   4     5       6     7  8         9    10        
% 2      6  5   5     6       0     8  6         8    9         
%                                                               
% 311                                                           
% Bij het komende congres willen ze dat goede bestuur weer terug
% 1   2   3       4       5      6  7   8     9       10   11   
% 5   4   4       1       0      5  5   9     5       9    0    
%                                                               
% 312                                                            
% Zijn houding lijkt hem vanaf het vroege begin te zijn ingegeven
% 1    2       3     4   5     6   7      8     9  10   11       
% 2    3       0     3   3     7   8      0     8  9    10       
%                                                                
% 313                                                               
% Soms hebben we alle vertrouwen in de Nederlandse politiek verloren
% 1    2      3  4    5          6  7  8           9        10      
% 2    0      2  5    2          5  9  9           6        2       
%                                                                   
% 314                                                           
% Zelfs een grove dwaling zorgde niet voor een mentale inzinking
% 1     2   3     4       5      6    7    8   9       10       
% 4     4   4     5       0      5    5    10  10      7        
%                                                               
% 315                                                                             
% Het besluit gaat over de voorgenomen destructie van de kerncentrale in Dodewaard
% 1   2       3    4    5  6           7          8   9  10           11 12       
% 2   3       0    3    7  7           4          7   10 8            10 11       
%                                                                                 
% 316                                                              
% De betere behuizing is afgedwongen door de nieuwe Europese regels
% 1  2      3         4  5           6    7  8      9        10    
% 3  3      4         0  4           5    0  10     10       0     
%                                                                  
% 317                                                          
% Wanneer krijgt die lakse puber nu eindelijk eens zijn diploma
% 1       2      3   4     5     6  7         8    9    10     
% 2       0      5   5     2     5  8         10   10   0      
%                                                              
% 318                                                             
% Dat kleine perceel was op een of andere manier het meest geliefd
% 1   2      3       4   5  6   7  8      9      10  11    12     
% 3   3      4       0   8  8   8  7      5      10  10    4      
%                                                                 
% 319                                                                
% Ook de vermoeide troepen in het gebied werden nog verder uitgebreid
% 1   2  3         4       5  6   7      8      9   10     11        
% 0   4  4         8       4  7   5      0      10  8      0         
%                                                                    
% 320                                                                   
% in de jaren zeventig trok het boeiende programma miljoenen luisteraars
% 1  2  3     4        5    6   7        8         9         10         
% 5  3  1     3        0    8   8        5         8         9          
%                                                                       
% 321                                                                  
% Vele duizenden bezoekers uit de hele wereld komen naar het popconcert
% 1    2         3         4   5  6    7      8     9    10  11        
% 2    8         2         3   7  7    4      0     8    11  9         
%                                                                      
% 322                                                        
% Dat mooie bericht gaat over het nieuwe en eeuwige Jeruzalem
% 1   2     3       4    5    6   7      8  9       10       
% 3   3     4       0    4    7   8      5  10      8        
%                                                            
% 323                                               
% De koning en zijn trouwe dienaren doen er niet toe
% 1  2      3  4    5      6        7    8  9    10 
% 2  3      7  6    6      3        0    7  7    7  
%                                                   
% 324                                                                  
% Van de eisende partij moest de malafide makelaar zijn bedrijf sluiten
% 1   2  3       4      5     6  7        8        9    10      11     
% 5   4  4       1      0     8  8        5        10   11      5      
%                                                                      
% 325                                          
% Ik lees graag mooie boeken in mijn vrije tijd
% 1  2    3     4     5      6  7    8     9   
% 2  0    4     5     2      5  9    9     6   
%                                              
% 326                                                              
% Vanwege zijn eigen bekentenis wordt hij veroordeeld voor de moord
% 1       2    3     4          5     6   7           8    9  10   
% 0       4    4     1          0     5   5           7    10 8    
%                                                                  
% 327                                                                
% Helaas dreef de machtige directeur zijn zin door bij zijn personeel
% 1      2     3  4        5         6    7   8    9   10   11       
% 2      0     5  5        2         7    5   7    8   11   9        
%                                                                    
% 328                                                                
% Het was een prachtige derde overwinning op Hawaii in drie jaar tijd
% 1   2   3   4         5     6           7  8      9  10   11   12  
% 2   0   6   6         6     2           6  7      2  11   9    11  
%                                                                    
% 329                                                        
% Hopelijk zien we de beroemde tekeningen wel snel weer terug
% 1        2    3  4  5        6          7   8    9    10   
% 2        0    2  6  6        2          6   9    2    9    
%                                                            
% 330                                                                  
% Het arbeidsethos is in centraal Bolivia heel anders dan in het zuiden
% 1   2            3  4  5        6       7    8      9   10 11  12    
% 2   3            0  3  6        4       9    9      10  3  12  10    
%                                                                      
% 331                                                                     
% Een paar mensen doen er alles aan om het populaire boekje te bemachtigen
% 1   2    3      4    5  6     7   8  9   10        11     12 13         
% 2   0    4      0    4  4     4   4  11  11        4      11 12         
%                                                                         
% 333                                                         
% Vandaar dat kippen zich op hun magere pootjes staande houden
% 1       2   3      4    5  6   7      8       9       10    
% 0       0   10     10   9  8   8      5       10      2     
%                                                             
% 334                                                
% De beruchte daders meldden zich zelf bij de politie
% 1  2        3      4       5    6    7   8  9      
% 3  3        4      6       6    6    4   8  6      
%                                                    
% 335                                           
% Op de tweede dinsdag ging het echter bijna mis
% 1  2  3      4       5    6   7      8     9  
% 5  4  4      1       0    5   5      9     0  
%                                               
% 336                                                           
% Er komt een nationaal bestuur om de bureaucratie te bestrijden
% 1  2    3   4         5       6  7  8            9  10        
% 2  0    5   5         2       5  8  6            6  9         
%                                                               
% 337                                                
% in Japan en China komt een geringe deflatie op gang
% 1  2     3  4     5    6   7       8        9  10  
% 0  3     1  5     0    8   8       10       10 5   
%                                                    
% 338                                            
% Na die fout stortte de complete ploeg in elkaar
% 1  2   3    4       5  6        7     8  9     
% 4  3   4    0       7  7        9     9  4     
%                                                
% 339                                                       
% Het zachte klimaat hield aan tot bijna halverwege de maand
% 1   2      3       4     5   6   7     8          9  10   
% 3   3      4       0     4   4   8     6          10 8    
%                                                           
% 341                                                         
% Vanwege de jonge plantjes zit de plastic emmer vol met aarde
% 1       2  3     4        5   6  7       8     9   10  11   
% 5       4  4     1        0   8  8       5     5   9   10   
%                                                             
% 342                                                      
% De hond kwam aanlopen met een plastic diadeem in zijn bek
% 1  2    3    4        5   6   7       8       9  10   11 
% 2  3    0    3        4   8   8       5       8  11   9  
%                                                          
% 343                                                      
% Natasja stopte de zakdoek in haar nieuwe broek met ruches
% 1       2      3  4       5  6    7      8     9   10    
% 2       0      4  2       4  8    8      5     4   9     
%                                                          
% 344                                                                                          
% Overtreders van de wet kunnen hier rekenen op een eerlijk proces met een onpartijdige rechter
% 1           2   3  4   5      6    7       8  9   10      11     12  13  14           15     
% 5           1   4  2   0      7    5       7  11  11      8      11  15  15           12     
%                                                                                              
% 345                                                                               
% Na een avondje stappen had de vrolijke bakker een behoorlijke kater van de alcohol
% 1  2   3       4       5   6  7        8      9   10          11    12  13 14     
% 5  3   4       1       0   8  8        5      11  11          5     11  14 12     
%                                                                                   
% 346                                                                   
% De student kwam niet rond van zijn karige beurs van vierhonderd gulden
% 1  2       3    4    5    6   7    8      9     10  11          12    
% 2  3       0    3    3    3   9    9      6     6   12          10    
%                                                                       
% 347                                                                                                      
% Na het uitvallen van de elektriciteit verlichtte Carolien haar gezellige terras met kaarsen en lampionnen
% 1  2   3         4   5  6             7          8        9    10        11     12  13      14 15        
% 7  3   1         3   6  4             0          7        11   11        7      11  14      12 14        
%                                                                                                          
% 348                                                                             
% De barones nodigde een aantal gasten uit voor een heerlijk diner met dure wijnen
% 1  2       3       4   5      6      7   8    9   10       11    12  13   14    
% 2  3       0       5   3      5      3   3    11  11       8     11  14   12    
%                                                                                 
% 349                                                                            
% De handen van de moordenaar zaten onder het druipende bloed van het slachtoffer
% 1  2      3   4  5          6     7     8   9         10    11  12  13         
% 2  6      2   5  3          0     6     10  10        7     10  13  11         
%                                                                                
% 350                                                                            
% Het volleybalteam won met de eerste plaats een grote beker gevuld met champagne
% 1   2             3   4   5  6      7      8   9     10    11     12  13       
% 2   3             0   3   7  7      4      10  10    11    3      11  12       
%                                                                                

% 351                                                                    
% Het vrouwtje veegde de vloer met een stokoude bezem gemaakt van twijgen
% 1   2        3      4  5     6   7   8        9     10      11  12     
% 2   3        0      5  3     5   9   9        6     3       10  11     
% 2   3        0      5  3     5   9   9        6     9       10  11     

% 352                                                                
% in het kantoor stond de vrouw bij de drukke balie voor de aangiftes
% 1  2   3       4     5  6     7   8  9      10    11   12 13       
% 4  3   4       0     6  4     6   10 10     7     10   13 11       
% 4  3   1       0     6  4     6   10 10     7     10   13 11       
                                                                    
                                                                       
% 355                                                                              
% Op zijn zestiende verjaardag kreeg de puber een stoere brommer en een helm cadeau
% 1  2    3         4          5     6  7     8   9      10      11 12  13   14    
% 5  4    4         1          0     7  5     10  10     11      5  13  11   11    
%                                                                                  
% 356                                                                    
% De auto kwam langs de snelweg stil te staan zonder brandstof in de tank
% 1  2    3    4     5  6       7    8  9     10     11        12 13 14  
% 2  3    0    3     6  4       3    3  8     9      10        11 14 12  
%                                                                        
% 357                                                                                    
% De toeristen hadden veel moeite met het opzetten van hun kleine tentje tijdens de storm
% 1  2         3      4    5      6   7   8        9   10  11     12     13      14 15   
% 2  3         0      5    3      5   8   6        8   12  12     9      12      15 13   
%                                                                                        
% 358                                                                      
% De aardige docent heeft dit jaar een erg rustige klas om les aan te geven
% 1  2       3      4     5   6    7   8   9       10   11 12  13  14 15   
% 3  3       4      0     6   10   10  9   10      4    10 11  11  11 14   
%                                                                          
% 359                                                 
% opa klopte de zwarte tabak uit zijn pijp in de asbak
% 1   2      3  4      5     6   7    8    9  10 11   
% 2   0      5  5      2     5   8    6    8  11 9    
%                                                     
% 360                                                                              
% De vakkundige tandarts trok bij Nico zijn achterste kies met de ontstoken wortels
% 1  2          3        4    5   6    7    8         9    10  11 12        13     
% 3  3          4        0    4   5    8    9         0    9   13 13        10     
%                                                                                  
% 361                                                                               
% Tijdens de vliegreis mocht het jongetje bij de ervaren piloot in de cockpit kijken
% 1       2  3         4     5   6        7   8  9       10     11 12 13      14    
% 4       3  1         0     6   14       6   10 10      7      10 13 11      0     
%                                                                                   
% 362                                                                 
% Aan het einde van de dag gaat de mobiele telefoon voor de overdracht
% 1   2   3     4   5  6   7    8  9       10       11   12 13        
% 7   3   1     3   6  4   0    10 10      7        10   13 11        
%                                                                     
% 363                                                                 
% Oma gaat nog steeds iedere donderdag naar de kerk voor de ochtendmis
% 1   2    3   4      5      6         7    8  9    10   11 12        
% 2   0    4   2      6      2         2    9  7    9    12 10        
%                                                                     
% 364                                                  
% De lange bokser woog negentig kilo schoon aan de haak
% 1  2     3      4    5        6    7      8   9  10  
% 3  3     4      0    6        4    4      4   10 8   
%                                                      
% 365                                                                        
% De brute beroving werd vastgelegd door een verborgen camera boven de ingang
% 1  2     3        4    5          6    7   8         9      10    11 12    
% 3  3     4        0    4          5    9   9         6      9     12 10    
%                                                                            
% 366                                                                   
% Midden in de stationshal hangt een grote poster met een zilveren lijst
% 1      2  3  4           5     6   7     8      9   10  11       12   
% 2      5  4  2           0     8   8     5      8   12  12       9    
%                                                                       
% 367                                                                                 
% De winst van die verkoper is erg hoog vanwege zijn vlotte babbel over zijn producten
% 1  2     3   4   5        6  7   8    9       10   11     12     13   14   15       
% 2  6     2   5   3        0  8   6    8       12   12     9      12   15   13       
%                                                                                     
% 368                                                                               
% De basketballers werden vanaf de kleine tribune begeleid door hun coach en trainer
% 1  2             3      4     5  6      7       8        9    10  11    12 13     
% 2  3             0      8     7  7      4       3        8    11  12    9  12     

% 369                                                                     
% Vader zit altijd aan het hoofd van de rechte tafel tijdens het avondeten
% 1     2   3      4   5   6     7   8  9      10    11      12  13       
% 2     0   6      6   6   2     2   8  8      5     8       11  9        
% 2     0   2      2   6   4     6   8  8      7     2       13  11        

% 376                                                           
% Als avondeten eet ons gezin meestal pasta met een lekkere saus
% 1   2         3   4   5     6       7     8   9   10      11  
% 3   1         0   5   3     7       3     7   11  11      8   
% 3   1         0   5   3     3       3     7   11  11      8   

% 378                                                                     
% Bram kon wel door de grond zakken na die enorme blunder van gistermiddag
% 1    2   3   4    5  6     7      8  9   10     11      12  13          
% 2    0   7   7    6  4     2      7  11  11     8       11  12          
% 2    0   2   7    6  4     2      7  11  11     8       11  12          

% 379                                                                                
% Ivo kreeg op zijn werk een strenge berisping van zijn baas over zijn slechte advies
% 1   2     3  4    5    6   7       8         9   10   11   12   13   14      15    
% 2   0     2  5    3    8   8       3         8   11   9    11   15   15      12    
% 2   0     2  5    3    8   8       2         8   11   9    11   15   15      12

% 381                                                                  
% Met mooi weer lag ik graag te zonnen op het mooie terras van het huis
% 1   2    3    4   5  6     7  8      9  10  11    12     13  14  15  
% 4   3    4    0   4  4     4  7      8  12  12    9      12  15  13  
% 4   3    1    0   4  4     4  7      8  12  12    9      12  15  13  

% 387                                                                             
% Ondanks de inspanning van de arbeider werd het belangrijke project niet afgerond
% 1       2  3          4   5  6        7    8   9           10      11   12      
% 7       3  7          3   6  4        0    10  10          7       12   7       
% 7       3  1          3   6  4        0    10  10          7       12   7       

% 392                                                                    
% Vrolijk spelend op hun paarse trommels liepen de leerlingen naar school
% 1       2       3  4   5      6        7      8  9          10   11    
% 2       7       7  6   6      7        0      9  7          9    10    
% 2       7       3  6   6      2        0      9  7          9    10    
                                                                        
% 393                                                            
% De gasten vertrokken omdat de lakse bediende zeer onbeleefd was
% 1  2      3          4     5  6     7        8    9         10 
% 2  0      2          3     7  7     10       7    10        4  
% 2  0      2          3     7  7     10       7    10        4  
% 2  3      0          3     7  7     10       9    10        4  

% 394   
% Tijdens de zeer zware training liepen de soldaten gebukt onder touwen door
% 1       2  3    4     5        6      7  8        9      10    11     12  
% 6       5  4    5     1        0      8  6        6      6     10     10            
% 6       5  4    5     1        0      8  6        6      6     10     6

% 395                                                                        
% Tijdens de eerste pauze kopen de scholieren vaak iets lekkers in de kantine
% 1       2  3      4     5     6  7          8    9    10      11 12 13     
% 5       4  4      1     0     7  5          9    5    9       9  13 11     
% 5       4  4      1     0     7  5          9    10   5       10 13 11     

% 397                                                              
% Met in iedere hand een lekker dropje liepen de zusjes naar school
% 1   2  3      4    5   6      7      8      9  10     11   12    
% 8   1  4      2    7   7      8      0      10 8      8    11    
% 8   1  4      2    7   7      1      0      10 8      8    11    

% 399                                                                              
% Om de lekkages in de oude kerk te verhelpen zoekt de vrome dominee een loodgieter
% 1  2  3        4  5  6    7    8  9         10    11 12    13      14  15        
% 10 3  10       3  7  7    4    7  8         0     13 13    10      15  10        
% 10 3  10       3  7  7    4    7  8         0     13 13    10      15  10        
% ????

% 401                                                                  
% Tijdens de reis door de jungle zien de rijke toeristen een groep apen
% 1       2  3    4    5  6      7    8  9     10        11  12    13  
% 7       3  1    3    6  4      0    10 10    7         12  13    10  
% 7       3  1    3    6  4      0    10 10    7         12  13    7  

% 406                                                                         
% Toen de gemene dictator arriveerde schreeuwden de burgers leuzen van protest
% 1    2  3      4        5          6           7  8       9      10  11     
% 6    4  4      5        1          0           8  6       8      9   10     
% 6    4  4      5        1          0           8  6       6      9   10     
                                                                            
