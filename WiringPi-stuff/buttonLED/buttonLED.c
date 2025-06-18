#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <arpa/inet.h>
#include <wiringPi.h>




int led = 3;
int ledB = 4;

int main() {
	int client_socket = socket(AF_INET, SOCK_STREAM, 0);

    struct sockaddr_in address;
    address.sin_family = AF_INET;
    address.sin_port = htons(8081);
	char messageB[256];
    memset(messageB, 0, 256);
    // Set address to your computer's local address
    inet_aton("127.0.0.1", (struct in_addr *) &(address.sin_addr.s_addr));

    // Establish a connection to address on client_socket
    connect(client_socket, (struct sockaddr *) &address, sizeof(address));

	
	wiringPiSetup();
	pinMode (led, OUTPUT) ;
	digitalWrite (ledB, HIGH) ;
	for(;;){
		digitalWrite (led, LOW) ;		
		recv(client_socket, messageB, 255, 0);
		if (messageB[]=="pairing") {
			digitalWrite (led, HIGH) ;	// On
    		delay (500) ;		// mS
    		digitalWrite (led, LOW) ;	// Off
    		delay (500) ;
		}
	}
}
