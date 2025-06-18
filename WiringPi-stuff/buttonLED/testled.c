#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <wiringPi.h>

int led = 3;

int main() {
	wiringPiSetup();
	pinMode (led, OUTPUT) ;
	digitalWrite (led, HIGH) ;
}
