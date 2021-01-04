scenario = "rslEXPO";
pcl_file = "rslEXPO_MAIN.pcl";

active_buttons = 1;

default_background_color = 0, 0, 0;
default_font = "Arial";
default_font_size = 20;
default_text_color = 255, 255, 255; 
default_text_align = align_center;

begin;

picture {
	
} p_Blank;

picture {
	text {caption = ""; font_size = 42;} t_Text;
	x = 0;
	y = 0;
	
	text {caption = ""; font_size = 24;} t_Text2;
	x = 0;
	y = -40;
} p_Text;

picture {
	box { 
		height = 6; width = 90; color = 255,255,255; 
	} b_Horz;
	x = 0; y = 0;
	
	box { 
		height = 90; width = 6; color = 255,255,255;
	} b_Vert;
	x = 0; y = 0;
} p_Fixation;

sound {
	wavefile {
		filename = "./audio/1_1_1.wav"; preload = true;
	} w_Sound;
} s_Sound;