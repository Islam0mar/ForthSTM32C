    @@ Serial terminal code common to all STM parts which share same UART layout
    @@    Define Terminal_USART_Base before use !
    .syntax unified
    .cpu cortex-m3
    .text
	.align	1
	.p2align 2,,3
    .include    "stm32f103.i"
	.global	USART1_IRQHandler
	.syntax unified
	.thumb
	.thumb_func
	.fpu softvfp
	.type	USART1_IRQHandler, %function
USART1_IRQHandler:
    .ltorg
    .end
