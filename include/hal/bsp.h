/**
 *   \file bsp.h
 *   \brief A Documented file.
 *
 *  Detailed description
 *
 */
#ifndef BSP_H
#define BSP_H

#include <stdarg.h>
#include <stdint.h>
#include <string.h>

#include "forth/global.h"
#include "system_stm32f1xx.h"

#define HSE_VALUE 8000000U
#define HSI_VALUE 8000000U
/*!< Vector Table base offset field. This value must be a multiple of 0x200. */
#define VECT_TAB_OFFSET 0x00000000U
/* Should be divisable by 2 (see HAL_UART_RxCpltCallback)*/
#define UART1_FIFO_SIZE

extern uint32_t SystemCoreClock;          /*!< System Clock Frequency (Core Clock) */
extern const uint8_t  AHBPrescTable[16];  /*!< AHB prescalers table values */
extern const uint8_t  APBPrescTable[8];   /*!< APB prescalers table values */

// #include "stm32f1xx_hal_conf.h"
// #include "stm32f1xx_hal_uart.h"
// #include "stm32f1xx_hal_rcc.h"
// #include "stm32f1xx_hal_flash.h"
// #include "stm32f1xx_hal_cortex.h"
// #include "stm32f1xx_hal_gpio.h"

void _Error_Handler(char *, int);
#define Error_Handler() _Error_Handler(__FILE__, __LINE__)
void SystemClock_Config();
void UART1_Init();
void GPIO_Init();
void Init();
void UART1_Send();
extern void SystemInit(void);
extern void SystemCoreClockUpdate(void);

#endif /* BSP_H */
