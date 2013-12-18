/* Created 05/22/2012 by Jordan McConnell at Sparkfun Electronics
 * This code is beerware, you know what I'm sayin'?
 *
 * Built on WinXP SP3 and WinAVR-20100110, AVRDUDE 5.10
 *
 * This code is a simple example of digital input for Sparkfun's
 * 32U4 Breakout Board using C and standard AVR libraries.  It
 * teaches you how to read the status of a digital pin to determine
 * whether its current status is HIGH or LOW.
 *
 * Pin PF0 is used as a digital input.  If its status is HIGH,
 * pin PD5 toggles each second, if it's status is LOW, pin PD6
 * toggles each second instead.
 *
 * The user can connect LED's to pins PD5 and PD6 or use a multimeter
 * to verify operation.  If pin PF0 is left unconnected, it's status
 * will be HIGH due to internal pullup resistors, and PD5 toggles.
 * If PF0 is connected to ground, PD6 toggles each second instead.
 */

// Libraries for register names and the delay function



#include <stdlib.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>   
#include <avr/io.h>
#include <stdio.h>
#include <util/delay.h>
#include <math.h>  //include libm

#include "trtSettings.h"
#include "trtUart.h"
#include "trtUart.c"

#include "mpu6050.c"
#include "mpu6050.h"
// UART file descriptor
// putchar and getchar are in uart.c
FILE uart_str = FDEV_SETUP_STREAM(uart_putchar, uart_getchar, _FDEV_SETUP_RW);

#define set_bit(address,bit) (address |= (1<<bit))
#define clear_bit(address,bit) (address &= ~(1<<bit))
#define toggle_bit(address,bit) (address ^= (1<<bit))

// This macro is for checking if a certain bit is set in a given register.
// This is useful here for checking the status of individual input pins.
#define check_bit(address,bit) ((address & (1<<bit)) == (1<<bit))

int16_t ax = 1;
int16_t ay = 1;
int16_t az = 2;
int16_t gx = 3;
int16_t gy = 4;
int16_t gz = 5;

int state = 1;
int stateDebounce = 0;

int systemTime = 0;

char bluetoothTestChar = 'a';

int main(void)
{
    // The following line sets bit 5 high in register DDRD
    // set_bit(DDRD,7); // Pin PD7 is now configured as an OUTPUT
    // set_bit(PORTD,7); // Pin PD7 is now HIGH
    _delay_ms(1000);
    trt_uart_init();
    _delay_ms(500);
    sei();
    _delay_ms(5);
    stdout = stdin = stderr = &uart_str;

    mpu6050_init(); // initializes via i2c_init() and then initializes the MPU  

    _delay_ms(1000);



//    fprintf(stdout,"\r\nMCU Restarting . . .\r\n");
    
    while(1)
    {

        GetRawDataTest();//stdout
        // if(gx>20000) 
        // {
        //     stateDebounce++;

        //     if (stateDebounce > 100)
        //     {  
        //         if(state == 1) 
        //         { 
        //             state = 2;
        //             stateDebounce = 0;
        //         }

        //         else
        //         {
        //             state++;
        //             stateDebounce = 0;
        //         }
        //     }
            
        //     // if(state == 'b') state = 'a';
        // }

        
        // uart_putchar(bluetoothTestChar, stdout);

        _delay_ms(20);
    }

    return 0;
}

void GetRawDataTest()
{

    toggle_bit(PORTD,7); // PD5 switches from LOW to HIGH or vice vers
    mpu6050_getRawData(&ax, &ay, &az, &gx, &gy, &gz);
    char itemp[10];

    ltoa(ax,itemp,10);
    uart_puts(itemp);
    uart_putchar(' ', stdout);


    ltoa(ay,itemp,10);
    uart_puts(itemp);
    uart_putchar(' ', stdout);

    ltoa(az,itemp,10);
    uart_puts(itemp);
    uart_putchar(' ', stdout);

    ltoa(gy,itemp,10);
    uart_puts(itemp);
    uart_putchar(' ', stdout);

/*    ltoa(gy,itemp,10);
    uart_puts(itemp);
    uart_putchar(' ', stdout);

    ltoa(gz,itemp,10);
    uart_puts(itemp);
    uart_putchar(' ', stdout);

*/    
    uart_putchar('\n', stdout);


/*    (gx,itemp,10);
    fputs(itemp,stdout);
    fputc(' ', stdout);*/




/*    sprintf(stdout," LOOOLS  ");


    char itmp[10];
    ltoa(ax,itmp,10); 
*/    // uart_putchar(' ',stdout); 
    // uart_putchar('A',stdout);
    // fprintf(stdout, "%d %d %d %d %d %d %d\n", ax, ay, az, gx, gy, gz, state);
    // _delay_ms(10);
}

















