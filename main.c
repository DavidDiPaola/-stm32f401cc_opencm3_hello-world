/*
2020 David DiPaola
Licensed under CC0
*/

#include <libopencm3/stm32/rcc.h>
#include <libopencm3/stm32/gpio.h>

int
main(void) {
	rcc_clock_setup_pll(rcc_hse_25mhz_3v3 + RCC_CLOCK_3V3_84MHZ);

	rcc_periph_clock_enable(RCC_GPIOC);
	gpio_mode_setup(GPIOC, GPIO_MODE_OUTPUT, GPIO_PUPD_NONE, GPIO13);
	gpio_set(GPIOC, GPIO13);

	for (;;) {
		for (int i=0; i<2000000l; i++) {
			__asm__("nop");
		}

		gpio_toggle(GPIOC, GPIO13);
	}
}
