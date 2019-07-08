    .syntax unified
    .cpu cortex-m3
    .text
	.align	1
	.p2align 2,,3
	.global	SystemInit
	.syntax unified
	.thumb
	.thumb_func
	.fpu softvfp
	.type	SystemInit, %function
SystemInit:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	@@ push	{r4, r5}	@
@ system_stm32f1xx.c:214:   RCC->CIR = 0x009F0000;
	mov	r5, #10420224	@ tmp133,
@ system_stm32f1xx.c:226:   SCB->VTOR = FLASH_BASE | VECT_TAB_OFFSET; /* Vector Table Relocation in Internal FLASH. */
	mov	r4, #134217728	@ tmp135,
@ system_stm32f1xx.c:179:   RCC->CR |= (uint32_t)0x00000001;
	ldr	r3, .L4	@ tmp120,
@ system_stm32f1xx.c:183:   RCC->CFGR &= (uint32_t)0xF8FF0000;
	ldr	r2, .L4+4	@ _4,
@ system_stm32f1xx.c:179:   RCC->CR |= (uint32_t)0x00000001;
	ldr	r1, [r3]	@ _1, MEM[(struct RCC_TypeDef *)1073876992B].CR
@ system_stm32f1xx.c:226:   SCB->VTOR = FLASH_BASE | VECT_TAB_OFFSET; /* Vector Table Relocation in Internal FLASH. */
	ldr	r0, .L4+8	@ tmp134,
@ system_stm32f1xx.c:179:   RCC->CR |= (uint32_t)0x00000001;
	orr	r1, r1, #1	@ _2, _1,
	str	r1, [r3]	@ _2, MEM[(struct RCC_TypeDef *)1073876992B].CR
@ system_stm32f1xx.c:183:   RCC->CFGR &= (uint32_t)0xF8FF0000;
	ldr	r1, [r3, #4]	@ _3, MEM[(struct RCC_TypeDef *)1073876992B].CFGR
	ands	r2, r2, r1	@, _4, _4, _3
	str	r2, [r3, #4]	@ _4, MEM[(struct RCC_TypeDef *)1073876992B].CFGR
@ system_stm32f1xx.c:189:   RCC->CR &= (uint32_t)0xFEF6FFFF;
	ldr	r2, [r3]	@ _5, MEM[(struct RCC_TypeDef *)1073876992B].CR
	bic	r2, r2, #17301504	@ _6, _5,
	bic	r2, r2, #65536	@ _6, _6,
	str	r2, [r3]	@ _6, MEM[(struct RCC_TypeDef *)1073876992B].CR
@ system_stm32f1xx.c:192:   RCC->CR &= (uint32_t)0xFFFBFFFF;
	ldr	r2, [r3]	@ _7, MEM[(struct RCC_TypeDef *)1073876992B].CR
	bic	r2, r2, #262144	@ _8, _7,
	str	r2, [r3]	@ _8, MEM[(struct RCC_TypeDef *)1073876992B].CR
@ system_stm32f1xx.c:195:   RCC->CFGR &= (uint32_t)0xFF80FFFF;
	ldr	r2, [r3, #4]	@ _9, MEM[(struct RCC_TypeDef *)1073876992B].CFGR
	bic	r2, r2, #8323072	@ _10, _9,
	str	r2, [r3, #4]	@ _10, MEM[(struct RCC_TypeDef *)1073876992B].CFGR
@ system_stm32f1xx.c:214:   RCC->CIR = 0x009F0000;
	str	r5, [r3, #8]	@ tmp133, MEM[(struct RCC_TypeDef *)1073876992B].CIR
@ system_stm32f1xx.c:226:   SCB->VTOR = FLASH_BASE | VECT_TAB_OFFSET; /* Vector Table Relocation in Internal FLASH. */
	str	r4, [r0, #8]	@ tmp135, MEM[(struct SCB_Type *)3758157056B].VTOR
@ system_stm32f1xx.c:228: }
	@@ pop	{r4, r5}
	bx	lr	@
.L5:
	.align	2
.L4:
	.word	1073876992
	.word	-117506048
	.word	-536810240
	.size	SystemInit, .-SystemInit
	.align	1
	.p2align 2,,3
	.global	SystemCoreClockUpdate
	.syntax unified
	.thumb
	.thumb_func
	.fpu softvfp
	.type	SystemCoreClockUpdate, %function
SystemCoreClockUpdate:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
@ system_stm32f1xx.c:278:   tmp = RCC->CFGR & RCC_CFGR_SWS;
	ldr	r2, .L14	@ tmp127,
	ldr	r3, [r2, #4]	@ _1, MEM[(struct RCC_TypeDef *)1073876992B].CFGR
	and	r3, r3, #12	@ tmp, _1,
@ system_stm32f1xx.c:280:   switch (tmp)
	cmp	r3, #8	@ tmp,
	bne	.L12	@,
@ system_stm32f1xx.c:291:       pllmull = RCC->CFGR & RCC_CFGR_PLLMULL;
	ldr	r3, [r2, #4]	@ _2, MEM[(struct RCC_TypeDef *)1073876992B].CFGR
@ system_stm32f1xx.c:292:       pllsource = RCC->CFGR & RCC_CFGR_PLLSRC;
	ldr	r1, [r2, #4]	@ _3, MEM[(struct RCC_TypeDef *)1073876992B].CFGR
@ system_stm32f1xx.c:295:       pllmull = ( pllmull >> 18) + 2;
	ubfx	r3, r3, #18, #4	@ tmp132, _2,,
@ system_stm32f1xx.c:297:       if (pllsource == 0x00)
	lsls	r1, r1, #15	@, _3,
@ system_stm32f1xx.c:295:       pllmull = ( pllmull >> 18) + 2;
	add	r3, r3, #2	@ pllmull, tmp132,
@ system_stm32f1xx.c:297:       if (pllsource == 0x00)
	bpl	.L13	@,
@ system_stm32f1xx.c:310:         if ((RCC->CFGR & RCC_CFGR_PLLXTPRE) != (uint32_t)RESET)
	ldr	r2, [r2, #4]	@ _6, MEM[(struct RCC_TypeDef *)1073876992B].CFGR
	lsls	r2, r2, #14	@, _6,
	bmi	.L13	@,
@ system_stm32f1xx.c:316:           SystemCoreClock = HSE_VALUE * pllmull;
	ldr	r2, .L14+4	@ tmp138,
	mul	r3, r2, r3	@ _5, tmp138, pllmull
	b	.L7	@
.L12:
@ system_stm32f1xx.c:280:   switch (tmp)
	ldr	r3, .L14+4	@ _5,
.L7:
@ system_stm32f1xx.c:368:   tmp = AHBPrescTable[((RCC->CFGR & RCC_CFGR_HPRE) >> 4)];
	ldr	r2, .L14	@ tmp139,
	ldr	r0, .L14+8	@ tmp141,
	ldr	r2, [r2, #4]	@ _10, MEM[(struct RCC_TypeDef *)1073876992B].CFGR
@ system_stm32f1xx.c:370:   SystemCoreClock >>= tmp;  
	ldr	r1, .L14+12	@ tmp140,
@ system_stm32f1xx.c:368:   tmp = AHBPrescTable[((RCC->CFGR & RCC_CFGR_HPRE) >> 4)];
	ubfx	r2, r2, #4, #4	@ tmp143, _10,,
	ldrb	r2, [r0, r2]	@ zero_extendqisi2	@ tmp, AHBPrescTable
@ system_stm32f1xx.c:370:   SystemCoreClock >>= tmp;  
	lsrs	r3, r3, r2	@ tmp145, _5, tmp
	str	r3, [r1]	@ tmp145, SystemCoreClock
@ system_stm32f1xx.c:371: }
	bx	lr	@
.L13:
@ system_stm32f1xx.c:312:           SystemCoreClock = (HSE_VALUE >> 1) * pllmull;
	ldr	r2, .L14+16	@ tmp137,
	mul	r3, r2, r3	@ _5, tmp137, pllmull
	b	.L7	@
.L15:
	.align	2
.L14:
	.word	1073876992
	.word	8000000
	.word	.LANCHOR1
	.word	.LANCHOR0
	.word	4000000
	.size	SystemCoreClockUpdate, .-SystemCoreClockUpdate
	.global	APBPrescTable
	.global	AHBPrescTable
	.global	SystemCoreClock
	.section	.rodata
	.align	2
	.set	.LANCHOR1,. + 0
	.type	AHBPrescTable, %object
	.size	AHBPrescTable, 16
AHBPrescTable:
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	1
	.byte	2
	.byte	3
	.byte	4
	.byte	6
	.byte	7
	.byte	8
	.byte	9
	.type	APBPrescTable, %object
	.size	APBPrescTable, 8
APBPrescTable:
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.byte	1
	.byte	2
	.byte	3
	.byte	4
	.data
	.align	2
	.set	.LANCHOR0,. + 0
	.type	SystemCoreClock, %object
	.size	SystemCoreClock, 4
SystemCoreClock:
	.word	72000000
    
