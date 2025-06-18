#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <arpa/inet.h>

int main(void)
{
    int client_socket = socket(AF_INET, SOCK_STREAM, 0);

    struct sockaddr_in address;
    address.sin_family = AF_INET;
    address.sin_port = htons(8080);

    // Set address to your computer's local address
    inet_aton("127.0.0.1", (struct in_addr *) &(address.sin_addr.s_addr));

    // Establish a connection to address on client_socket
    connect(client_socket, (struct sockaddr *) &address, sizeof(address));

    char message[] = "Hello, World!\n";

    // Send message to the client
    for(;;){
    send(client_socket, message, strlen(message), 0);
    };
    // Close the connection


    printf("%s", message);
    return 0;
}