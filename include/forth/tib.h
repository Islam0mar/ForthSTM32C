/**
 *   \file tib.h
 *   \brief A Documented file.
 *
 *  Detailed description
 *
 */

/* Should be divisable by 2 (see HAL_UART_RxCpltCallback)*/
#define TIB_SIZE 128U
#define PAD_SIZE 33U

/* Terminal Input Buffer FIFO cycle */
extern uint8_t terminal_buffer[TIB_SIZE];
extern char pad[PAD_SIZE];
uint8_t TIBGetIndex();
uint8_t *TIBGetAddrs();
void TIBIncrementIndex();
inline char TIBReadChar();
bool TIBEmpty();
void TIBFlush();



