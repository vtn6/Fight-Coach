
//trtSettings.h


#define PRESCALER 1024 // the actual value for timer1 prescalar
#define PRESCALEBITS 5 // the bits to be set in TCCR1b 

#define F_CPU 16000000UL // clock frequency in Hz
#define TICKSPERSECOND F_CPU / PRESCALER

/* UART baud rate */
#define UART_BAUD  115200
