/**
 *   \file bsp.h
 *   \brief A Documented file.
 *
 *  Detailed description
 *
 */
#ifndef BSP_H
#define BSP_H

#define HSE_VALUE 8000000U
#define HSI_VALUE 8000000U
/*!< Vector Table base offset field. This value must be a multiple of 0x200. */
#define VECT_TAB_OFFSET 0x00000000U 


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
void init();

#endif /* BSP_H */
