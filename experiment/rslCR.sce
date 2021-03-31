scenario = "rslCR";
pcl_file = "rslCR_MAIN.pcl";

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
		height = 90; width = 3; color = 255,255,255;
	} b_2AFC;
	x = 0; y = 0;
	
	text {caption = ""; font_size=42; width=400; text_align=align_center;} t_2AFC_left;
	x = -400;
	y = 0;
	
	text {caption = ""; font_size=42; width=400; text_align=align_center;} t_2AFC_right;
	x = 400;
	y = 0;
} p_2AFC;

picture {
	box { 
		height = 90; width = 3; color = 255,255,255;
	} b_MEG;
	x = 0; y = 0;
	
	text {caption = ""; font_size = 42; width=400; text_align=align_center;} t_MEG_Q;
	x = 0; y = 0;
	
	#text {caption = ""; font_size=42; width=400; text_align=align_center;} t_MEG_top;
	#x = 0;
	#y = 120;
	#
	#text {caption = ""; font_size=42; width=200; text_align=align_center;} t_MEG_left;
	#x = -200;
	#y = 0;
	#
	#text {caption = ""; font_size=42; width=200; text_align=align_center;} t_MEG_right;
	#x = 200;
	#y = 0;
} p_MEG;

picture {
	box {
		height = 3; width = 1600; color = 255,255,255;
	} b_4AFC_horizontal;
	x = 0;
	y = 0;
	
	box {
		height = 120; width = 3; color = 255,255,255;
	} b_4AFC_vertical;
	x = 0;
	y = 0;
	
	#text { caption = ""; font_size = 42; width=400; text_align=align_center; } t_4AFC_1_top_left; 
	#x = -400;
	#y = -40;
	#
	#text { caption = ""; font_size = 42; width=400; text_align=align_center; } t_4AFC_2_bottom_left;
	#x = -400;
	#y = 40;
	#
	#text { caption = ""; font_size = 42; width=400; text_align=align_center; } t_4AFC_3_top_right;
	#x = 400;
	#y = -40;
	#
	#text { caption = ""; font_size = 42; width=400; text_align=align_center; } t_4AFC_4_bottom_right;
	#x = 400;
	#y = 40;
	
	text { caption = ""; font_size = 42; width=400; text_align=align_center; } t_4AFC_1_top_left; 
	x = -400;
	y = 40;
	
	text { caption = ""; font_size = 42; width=400; text_align=align_center; } t_4AFC_2_bottom_left;
	x = -400;
	y = -40;
	
	text { caption = ""; font_size = 42; width=400; text_align=align_center; } t_4AFC_3_top_right;
	x = 400;
	y = 40;
	
	text { caption = ""; font_size = 42; width=400; text_align=align_center; } t_4AFC_4_bottom_right;
	x = 400;
	y = -40;
} p_4AFC;

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

sound {
	wavefile {
		filename = "./audio/1_1_2.wav"; preload = true;
	} w_Sound2;
} s_Sound2;