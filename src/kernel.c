#include "kernel.h"
#include <stddef.h>
#include <stdint.h>

uint16_t *video_mem = 0;

uint16_t terminal_make_char(char c, char color){
    return (color << 8) | c; // Because the value we return is 16 bits (2 bytes), and we need 1st byte for color and 2nd byte for character
                             // Due to little endianness
}

void terminal_put_char(int x, int y, char character, char color){
    video_mem[(y*VGA_WIDTH) + x] = terminal_make_char(character,color);
}

//Basically clearing out screen
void terminal_initialize()
{
    video_mem = (uint16_t*)(0xB8000);
    for(int y = 0; y < VGA_HEIGHT; y++){
        for(int x = 0; x<VGA_WIDTH; x++){
            //Converting x and y  coordinates into 1 dimensional array
            terminal_put_char(x,y,' ',0);
        }
    }
}

size_t strlen(const char* str){

    int len =0;
    while(str[len]) len++;

    return len;
}

void print(const char *string){

    for(int i = 0; i<strlen(string);i++){
        video_mem[i] = terminal_make_char(string[i],3);
    }
}

void kernel_main(){

    terminal_initialize();
    //video_mem[0] = 0x0341 // 41 is the character 'A' and 03 is the color code
    //char *greet_message = "Welcome to Operating System !";
    // video_mem[0] = terminal_make_char('B',3);
    // video_mem[1] = terminal_make_char('C',3);

    print("welcome to the Operating System");
}