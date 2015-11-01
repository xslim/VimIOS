//
//  VimIOS-Bridging-Header.h
//  VimIOS
//
//  Created by Lars Kindler on 27/10/15.
//  Copyright © 2015 Lars Kindler. All rights reserved.
//

#ifndef VimIOS_Bridging_Header_h
#define VimIOS_Bridging_Header_h



#import "vim.h"
#import "gui.h"
int VimMain(int argc, char *argv[]);
void gui_resize_shell(int pixel_width, int pixel_height);
void gui_update_cursor(int force, int clear_selection);
void gui_undraw_cursor();



#endif /* VimIOS_Bridging_Header_h */
