#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <arpa/inet.h>
#include <wiringPi.h>



int button =  0;
int value = 0;

int main() {
	int client_socket = socket(AF_INET, SOCK_STREAM, 0);

    struct sockaddr_in address;
    address.sin_family = AF_INET;
    address.sin_port = htons(1234);

    // Set address to your computer's local address
    inet_aton("127.0.0.1", (struct in_addr *) &(address.sin_addr.s_addr));

    // Establish a connection to address on client_socket
    connect(client_socket, (struct sockaddr *) &address, sizeof(address));

    char message[] = "pi_bluetooth\n";
	wiringPiSetup();
	pinMode(button, INPUT);
	pullUpDnControl(button, PUD_UP);
	for(;;){
	 	value = digitalRead(button);
		if (value==LOW) {
			send(client_socket, message, strlen(message), 0);
			delay(1000);
		}
	}
}
