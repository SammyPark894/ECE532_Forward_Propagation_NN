/*
 * Copyright (C) 2009 - 2018 Xilinx, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 * OF SUCH DAMAGE.
 *
 */

#include <stdio.h>
#include <string.h>
#include "xparameters.h"
#include "axi_noweights.h"
#include "xil_io.h"
#include "lwip/err.h"
#include "lwip/tcp.h"
#if defined (__arm__) || defined (__aarch64__)
#include "xil_printf.h"
#endif

union FloatingPointIEEE754 {
	struct {
		unsigned int mantissa : 23;
		unsigned int exponent : 8;
		unsigned int sign : 1;
	} raw;
	float f;
} number;

int transfer_data() {
	return 0;
}

void print_app_header()
{
#if (LWIP_IPV6==0)
	xil_printf("\n\r\n\r-----lwIP TCP echo server ------\n\r");
#else
	xil_printf("\n\r\n\r-----lwIPv6 TCP echo server ------\n\r");
#endif
	xil_printf("TCP packets sent to port 6001 will be echoed back\n\r");
}

//so I'd imagine this is what we change with the "echo back the payload" comment
//but how to do this, I must find out
err_t recv_callback(void *arg, struct tcp_pcb *tpcb,
                               struct pbuf *p, err_t err)
{
	/* do not read the packet if we are not in ESTABLISHED state */
	if (!p) {
		tcp_close(tpcb);
		tcp_recv(tpcb, NULL);
		return ERR_OK;
	}

	/* indicate that the packet has been received */
	tcp_recved(tpcb, p->len);

	/* echo back the payload */
	/* in this case, we assume that the payload is < TCP_SND_BUF */
	if (tcp_sndbuf(tpcb) > p->len) {

		char * editingString=p->payload;
		editingString[p->len] = 0;
		xil_printf("Received: \"%s\"\n", editingString);
		//xil_printf(", Sent: \"%s\"\n\r", editingString);
		//int num = atoi(editingString);

		float num;
		unsigned int ieee754;
		int done;
		int ready;
		char * msg = strtok(editingString, ",");

		if(strstr(msg, "Conv1") != NULL){
			xil_printf("Received convolutional layer 1 weights\n");
			xil_printf("Begin storing of convolutional layer 1 weights\n\n");
			for (int i = 0; i < 7; i++){
				for(int j = 0; j < 7; j++){
					msg = strtok(NULL, ",");
					num = atof(msg);
					number.f = num;
					ieee754 = number.raw.mantissa + (number.raw.exponent << 23) + (number.raw.sign << 31);

					//write num into i-th row, j-th col of the weight array
					AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG0_OFFSET, ieee754);
					AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG1_OFFSET, j);
					AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG2_OFFSET, i);


					//check if IP is ready
					ready = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG11_OFFSET);
					while(!ready) ready = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG11_OFFSET);

					//once ready set imagewen to high to start reading
					AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG4_OFFSET, 1);
					//check when the write is done
					done = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG10_OFFSET);
					while(!done) done = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG10_OFFSET);
					//once done, set the imagewen back to low
					AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG4_OFFSET, 0);

				}
			}

		}else if(strstr(msg, "Conv2") != NULL){
			xil_printf("Received convolutional layer 2 weights\n");
			xil_printf("Begin storing of convolutional layer 2 weights\n\n");
			for (int i = 0; i < 2; i++){
				for(int j = 0; j < 2; j++){
					msg = strtok(NULL, ",");
					num = atof(msg);
					number.f = num;
					ieee754 = number.raw.mantissa + (number.raw.exponent << 23) + (number.raw.sign << 31);

					//write num into i-th row, j-th col of the weight array
					AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG0_OFFSET, ieee754);
					AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG1_OFFSET, j);
					AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG2_OFFSET, i);


					//check if IP is ready
					ready = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG11_OFFSET);
					while(!ready) ready = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG11_OFFSET);

					//once ready set imagewen to high to start reading
					AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG5_OFFSET, 1);
					//check when the write is done
					done = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG10_OFFSET);
					while(!done) done = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG10_OFFSET);
					//once done, set the imagewen back to low
					AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG5_OFFSET, 0);

				}
			}

		}else if(strstr(msg, "Lin") != NULL){
			xil_printf("Received convolutional layer 1 weights\n");
			xil_printf("Begin storing of convolutional layer 1 weights\n\n");
			for (int i = 0; i < 10; i++){
				msg = strtok(NULL, ",");
				num = atof(msg);
				number.f = num;
				ieee754 = number.raw.mantissa + (number.raw.exponent << 23) + (number.raw.sign << 31);


				//write num into i-th row, j-th col of the weight array
				AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG0_OFFSET, ieee754);
				AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG1_OFFSET, i);


				//check if IP is ready
				ready = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG11_OFFSET);
				while(!ready) ready = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG11_OFFSET);

				//once ready set imagewen to high to start reading
				AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG6_OFFSET, 1);
				//check when the write is done
				done = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG10_OFFSET);
				while(!done) done = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG10_OFFSET);
				//once done, set the imagewen back to low
				AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG6_OFFSET, 0);
			}

		}else if(strstr(msg, "Image_h") != NULL){
			int row_start;
			if(strstr(msg, "Image_h0") != NULL){
				xil_printf("Received first quarter of image\n");
				xil_printf("Begin storing of first half of image\n");
				row_start = 0;
			}else if(strstr(msg, "Image_h1") != NULL){
				xil_printf("Received second quarter of image\n");
				xil_printf("Begin storing of first half of image\n");
				row_start = 7;
			}else if(strstr(msg, "Image_h2") != NULL){
				xil_printf("Received third quarter of image\n");
				xil_printf("Begin storing of first half of image\n");
				row_start = 14;
			}else if(strstr(msg, "Image_h3") != NULL){
				xil_printf("Received fourth quarter of image\n");
				xil_printf("Begin storing of first half of image\n");
				row_start = 21;
			}
			xil_printf("\n");
			for (int i = row_start; i < row_start+7; i++){
				for(int j = 0; j < 28; j++){
					msg = strtok(NULL, ",");
					num = atof(msg);
					number.f = num;
					ieee754 = number.raw.mantissa + (number.raw.exponent << 23) + (number.raw.sign << 31);

					//xil_printf("%x\n", ieee754);

					//write num into i-th row, j-th col of the image array
					AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG0_OFFSET, ieee754);
					AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG1_OFFSET, i);
					AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG2_OFFSET, j);


					//check if IP is ready
					ready = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG11_OFFSET);
					while(!ready) ready = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG11_OFFSET);

					//once ready set imagewen to high to start reading
					AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG3_OFFSET, 1);
					//check when the write is done
					done = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG10_OFFSET);
					while(!done) done = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG10_OFFSET);
					//once done, set the imagewen back to low
					AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG3_OFFSET, 0);
				}
			}
		}if(strstr(msg, "Start_Calc") != NULL){
			//Check if ready signal is high
			ready = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG11_OFFSET);
			while(!ready) ready = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG11_OFFSET);

			//write 1 into start_cal_in
			AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG9_OFFSET, 1);

			//Wait for done signal to be high
			done = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG10_OFFSET);
			while(!done) done = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG10_OFFSET);
			//Once done signal is high, read from the calc_out
			int ans = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG8_OFFSET);

			xil_printf("The NN predicts the image is %x\n", ans);

			//Once done reading the value, set the start_cal_in back to 0
			AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG9_OFFSET, 0);
			err = tcp_write(tpcb, p->payload, p->len, 1);
		}




		//err = tcp_write(tpcb, p->payload, p->len, 1);
	} else
		xil_printf("no space in tcp_sndbuf\n\r");//so this is in case message too big

	/* free the received pbuf */
	pbuf_free(p);

	return ERR_OK;
}

err_t accept_callback(void *arg, struct tcp_pcb *newpcb, err_t err)
{
	static int connection = 1;

	/* set the receive callback for this connection */
	tcp_recv(newpcb, recv_callback);

	/* just use an integer number indicating the connection id as the
	   callback argument */
	tcp_arg(newpcb, (void*)(UINTPTR)connection);

	/* increment for subsequent accepted connections */
	connection++;

	return ERR_OK;
}


int start_application()
{
	struct tcp_pcb *pcb;
	err_t err;
	unsigned port = 7;

	/* create new TCP PCB structure */
	pcb = tcp_new_ip_type(IPADDR_TYPE_ANY);
	if (!pcb) {
		xil_printf("Error creating PCB. Out of Memory\n\r");
		return -1;
	}

	/* bind to specified @port */
	err = tcp_bind(pcb, IP_ANY_TYPE, port);
	if (err != ERR_OK) {
		xil_printf("Unable to bind to port %d: err = %d\n\r", port, err);
		return -2;
	}

	/* we do not need any arguments to callback functions */
	tcp_arg(pcb, NULL);

	/* listen for connections */
	pcb = tcp_listen(pcb);
	if (!pcb) {
		xil_printf("Out of memory while tcp_listen\n\r");
		return -3;
	}

	/* specify callback to use for incoming connections */
	tcp_accept(pcb, accept_callback);

	xil_printf("TCP echo server started @ port %d\n\r", port);
	//1th image guess 2
	/*float image[28][28] = { { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.62352943, 0.99215686, 0.62352943, 0.19607843, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.1882353, 0.93333334, 0.9882353, 0.9882353, 0.9882353, 0.92941177, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.21176471, 0.8901961, 0.99215686, 0.9882353, 0.9372549, 0.9137255, 0.9882353, 0.22352941, 0.023529412, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.039215688, 0.23529412, 0.8784314, 0.9882353, 0.99215686, 0.9882353, 0.7921569, 0.32941177, 0.9882353, 0.99215686, 0.47843137, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.6392157, 0.9882353, 0.9882353, 0.9882353, 0.99215686, 0.9882353, 0.9882353, 0.3764706, 0.7411765, 0.99215686, 0.654902, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.93333334, 0.99215686, 0.99215686, 0.74509805, 0.44705883, 0.99215686, 0.89411765, 0.18431373, 0.30980393, 1.0, 0.65882355, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.1882353, 0.93333334, 0.9882353, 0.9882353, 0.7019608, 0.047058824, 0.29411766, 0.4745098, 0.08235294, 0.0, 0.0, 0.99215686, 0.9529412, 0.19607843, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.14901961, 0.64705884, 0.99215686, 0.9137255, 0.8156863, 0.32941177, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.99215686, 0.9882353, 0.64705884, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.02745098, 0.69803923, 0.9882353, 0.9411765, 0.2784314, 0.07450981, 0.10980392, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.99215686, 0.9882353, 0.7647059, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.22352941, 0.9882353, 0.9882353, 0.24705882, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.99215686, 0.9882353, 0.7647059, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7764706, 0.99215686, 0.74509805, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.99215686, 0.76862746, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.29803923, 0.9647059, 0.9882353, 0.4392157, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.99215686, 0.9882353, 0.5803922, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.33333334, 0.9882353, 0.9019608, 0.09803922, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.02745098, 0.5294118, 0.99215686, 0.7294118, 0.047058824, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.33333334, 0.9882353, 0.8745098, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.02745098, 0.5137255, 0.9882353, 0.88235295, 0.2784314, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.33333334, 0.9882353, 0.5686275, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.1882353, 0.64705884, 0.9882353, 0.6784314, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3372549, 0.99215686, 0.88235295, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.44705883, 0.93333334, 0.99215686, 0.63529414, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.33333334, 0.9882353, 0.9764706, 0.57254905, 0.1882353, 0.11372549, 0.33333334, 0.69803923, 0.88235295, 0.99215686, 0.8745098, 0.654902, 0.21960784, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.33333334, 0.9882353, 0.9882353, 0.9882353, 0.8980392, 0.84313726, 0.9882353, 0.9882353, 0.9882353, 0.76862746, 0.50980395, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.10980392, 0.78039217, 0.9882353, 0.9882353, 0.99215686, 0.9882353, 0.9882353, 0.9137255, 0.5686275, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.09803922, 0.5019608, 0.9882353, 0.99215686, 0.9882353, 0.5529412, 0.14509805, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },} ;
*/
	//4th image guess 1
	/*float image[28][28] ={ { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.21568628, 0.5803922, 0.8235294, 0.99215686, 0.99215686, 0.44313726, 0.34117648, 0.5803922, 0.21568628, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.34117648, 0.9098039, 0.9882353, 0.99215686, 0.7411765, 0.8235294, 0.9882353, 0.9882353, 0.99215686, 0.65882355, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.015686275, 0.22352941, 0.9490196, 0.9882353, 0.74509805, 0.25490198, 0.019607844, 0.047058824, 0.7137255, 0.9882353, 0.99215686, 0.45490196, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3764706, 0.9882353, 0.9882353, 0.7176471, 0.05490196, 0.0, 0.0, 0.36078432, 0.9882353, 0.9882353, 0.88235295, 0.08235294, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5176471, 0.99215686, 0.9882353, 0.57254905, 0.05490196, 0.0, 0.0, 0.0, 0.84313726, 0.9882353, 0.9882353, 0.30980393, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.49411765, 0.99215686, 0.96862745, 0.6901961, 0.03529412, 0.0, 0.0, 0.03137255, 0.30588236, 0.9607843, 0.99215686, 0.5058824, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0627451, 0.9098039, 0.9882353, 0.6901961, 0.0, 0.0, 0.0, 0.14117648, 0.7882353, 0.9882353, 0.9882353, 0.6627451, 0.043137256, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.08627451, 0.9882353, 0.9882353, 0.11764706, 0.08627451, 0.46666667, 0.77254903, 0.94509804, 0.99215686, 0.9882353, 0.9843137, 0.3019608, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0627451, 0.90588236, 0.9882353, 0.99215686, 0.9882353, 0.9882353, 0.9882353, 0.8862745, 0.8901961, 0.9882353, 0.90588236, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.21568628, 0.92156863, 0.99215686, 0.8509804, 0.5411765, 0.16470589, 0.09411765, 0.7529412, 0.9882353, 0.56078434, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.24313726, 1.0, 0.99215686, 0.42745098, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2784314, 0.99215686, 0.9882353, 0.08235294, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.99215686, 0.9882353, 0.08235294, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2784314, 0.99215686, 0.9882353, 0.08235294, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.41568628, 0.99215686, 0.9882353, 0.08235294, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.1764706, 1.0, 0.99215686, 0.08235294, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.85490197, 0.9882353, 0.21960784, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3764706, 0.9882353, 0.7411765, 0.16470589, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.05490196, 0.72156864, 0.9882353, 0.6666667, 0.043137256, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.05490196, 0.5764706, 0.9882353, 0.16470589, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
};*/

	float image[28][28] = { { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.18039216, 0.4117647, 0.99607843, 0.99607843, 0.99607843, 0.99607843, 1.0, 0.9372549, 0.16078432, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.14509805, 0.4627451, 0.87058824, 0.99607843, 0.99215686, 0.99215686, 0.99215686, 0.99215686, 0.99215686, 0.99215686, 0.827451, 0.21176471, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.05490196, 0.78431374, 0.99215686, 0.99215686, 0.99607843, 0.99215686, 0.99215686, 0.99215686, 0.99215686, 0.99215686, 0.99215686, 0.99215686, 0.45490196, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0627451, 0.627451, 0.9254902, 0.99215686, 0.99215686, 0.99215686, 0.99607843, 0.99215686, 0.99215686, 0.9647059, 0.8980392, 0.99215686, 0.99215686, 0.99215686, 0.45490196, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3882353, 0.99215686, 0.99215686, 0.99215686, 0.99215686, 0.99215686, 0.99607843, 0.99215686, 0.99215686, 0.8352941, 0.3882353, 0.99215686, 0.99215686, 0.99215686, 0.45490196, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.09803922, 0.7607843, 0.99215686, 0.99215686, 0.99215686, 0.99215686, 0.5137255, 0.38039216, 0.6627451, 0.99215686, 0.3647059, 0.3882353, 0.99215686, 0.99215686, 0.99215686, 0.45490196, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.80784315, 0.99215686, 0.99215686, 0.9843137, 0.9137255, 0.49803922, 0.03529412, 0.0, 0.07058824, 0.14901961, 0.011764706, 0.05882353, 0.67058825, 0.99215686, 0.99215686, 0.45490196, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.21568628, 0.9411765, 0.99215686, 0.99215686, 0.9137255, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.12156863, 0.7294118, 0.99215686, 0.99215686, 0.45490196, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.6901961, 0.99215686, 0.99215686, 0.99215686, 0.49803922, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3882353, 0.99215686, 0.99215686, 0.99215686, 0.45490196, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.6901961, 0.99215686, 0.99215686, 0.5137255, 0.03529412, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3882353, 0.99215686, 0.99215686, 0.99215686, 0.45490196, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.46666667, 0.99607843, 0.99607843, 0.9098039, 0.29411766, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.61960787, 0.99607843, 0.99607843, 0.45882353, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.4627451, 0.99215686, 0.99215686, 0.6039216, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.6117647, 0.99215686, 0.99215686, 0.45490196, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.4627451, 0.99215686, 0.99215686, 0.6039216, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.6117647, 0.99215686, 0.99215686, 0.45490196, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.18039216, 0.87058824, 0.99215686, 0.99215686, 0.6039216, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.02745098, 0.45490196, 0.9647059, 0.99215686, 0.7058824, 0.03529412, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.4627451, 0.99215686, 0.99215686, 0.6039216, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.45490196, 0.99215686, 0.99215686, 0.99215686, 0.68235296, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.4627451, 0.99215686, 0.99215686, 0.6039216, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.43137255, 0.9647059, 0.99215686, 0.99215686, 0.9411765, 0.2627451, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.4627451, 0.99215686, 0.99215686, 0.93333334, 0.84313726, 0.19215687, 0.078431375, 0.078431375, 0.078431375, 0.25882354, 0.84313726, 0.94509804, 0.99215686, 0.9607843, 0.9137255, 0.2509804, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.32156864, 0.8980392, 0.99215686, 0.99215686, 0.99215686, 0.99215686, 0.99215686, 0.99215686, 0.99215686, 0.99607843, 0.99215686, 0.99215686, 0.9411765, 0.41960785, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.6901961, 0.99215686, 0.99215686, 0.99215686, 0.99215686, 0.99215686, 0.99215686, 0.99215686, 0.99607843, 0.99215686, 0.99215686, 0.42352942, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.15686275, 0.9372549, 0.99215686, 0.99215686, 0.99215686, 0.99215686, 0.99215686, 0.99215686, 0.99607843, 0.6313726, 0.22352941, 0.015686275, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			{ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, },
			}
;


	float conv1_weight[7][7] = { { 0.458775, 1.0158736, 1.2670113, 1.4476663, 1.0446395, 0.6450059, 0.35756186, },
{ -0.31941304, 0.10798547, 0.35000166, 0.34464085, 0.29203948, 0.15009883, 0.05757153, },
{ -0.59914494, -0.7566488, -1.0347289, -0.5249662, -0.31917018, -0.52566487, -0.52636987, },
{ -0.7109156, -1.3773378, -1.3657646, -1.3329109, -0.76320153, -0.51039964, -0.99756, },
{ -0.6809235, -1.0501548, -1.1221141, -0.5086686, -0.46751454, -0.49680236, -1.0157187, },
{ 0.5573157, 0.8328649, 0.4531213, 0.8270917, 0.83342, 0.48771653, 0.24781714, },
{ 1.0967895, 0.96696633, 0.9882143, 1.1006608, 1.0917543, 1.2194479, 0.6800953, },} ;

	float conv2_weight[2][2] = { { -0.43059766, -0.04491652, },
{ 0.8097128, 0.09199108, },} ;

	float lin_weight[10] = { 1.4622306, -3.14523, 1.444124, 2.2355812, -0.7204899, 1.8375468, 0.6211022, -2.8686664, 1.0486159, -0.43585962, } ;
	float num;
	unsigned int ieee754;
	int ready;
	int done;
	
	for (int i = 0; i < 28; i++){
		for(int j = 0; j < 28; j++){
			num = image[i][j];
			number.f = num;
			ieee754 = number.raw.mantissa + (number.raw.exponent << 23) + (number.raw.sign << 31);

			//xil_printf("%x\n", ieee754);

			//write num into i-th row, j-th col of the image array
			AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG0_OFFSET, ieee754);
			AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG1_OFFSET, i);
			AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG2_OFFSET, j);


			//check if IP is ready
			ready = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG11_OFFSET);
			while(!ready) ready = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG11_OFFSET);

			//once ready set imagewen to high to start reading
			AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG3_OFFSET, 1);
			//check when the write is done
			done = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG10_OFFSET);
			while(!done) done = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG10_OFFSET);
			//once done, set the imagewen back to low
			AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG3_OFFSET, 0);
		}
	}

	xil_printf("Received convolutional layer 1 weights\n");
	xil_printf("Begin storing of convolutional layer 1 weights\n\n");
	for (int i = 0; i < 7; i++){
		for(int j = 0; j < 7; j++){
			num = conv1_weight[i][j];
			number.f = num;
			ieee754 = number.raw.mantissa + (number.raw.exponent << 23) + (number.raw.sign << 31);

			//write num into i-th row, j-th col of the weight array
			AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG0_OFFSET, ieee754);
			AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG1_OFFSET, j);
			AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG2_OFFSET, i);


			//check if IP is ready
			ready = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG11_OFFSET);
			while(!ready) ready = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG11_OFFSET);

			//once ready set imagewen to high to start reading
			AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG4_OFFSET, 1);
			//check when the write is done
			done = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG10_OFFSET);
			while(!done) done = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG10_OFFSET);
			//once done, set the imagewen back to low
			AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG4_OFFSET, 0);

		}
	}
	
	xil_printf("Received convolutional layer 2 weights\n");
	xil_printf("Begin storing of convolutional layer 2 weights\n\n");
	for (int i = 0; i < 2; i++){
		for(int j = 0; j < 2; j++){
			num = conv2_weight[i][j];
			number.f = num;
			ieee754 = number.raw.mantissa + (number.raw.exponent << 23) + (number.raw.sign << 31);

			//write num into i-th row, j-th col of the weight array
			AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG0_OFFSET, ieee754);
			AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG1_OFFSET, j);
			AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG2_OFFSET, i);


			//check if IP is ready
			ready = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG11_OFFSET);
			while(!ready) ready = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG11_OFFSET);

			//once ready set imagewen to high to start reading
			AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG5_OFFSET, 1);
			//check when the write is done
			done = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG10_OFFSET);
			while(!done) done = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG10_OFFSET);
			//once done, set the imagewen back to low
			AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG5_OFFSET, 0);

		}
	}
	
	xil_printf("Received convolutional layer 1 weights\n");
	xil_printf("Begin storing of convolutional layer 1 weights\n\n");
	for (int i = 0; i < 10; i++){
		num = lin_weight[i];
		number.f = num;
		ieee754 = number.raw.mantissa + (number.raw.exponent << 23) + (number.raw.sign << 31);


		//write num into i-th row, j-th col of the weight array
		AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG0_OFFSET, ieee754);
		AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG1_OFFSET, i);


		//check if IP is ready
		ready = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG11_OFFSET);
		while(!ready) ready = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG11_OFFSET);

		//once ready set imagewen to high to start reading
		AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG6_OFFSET, 1);
		//check when the write is done
		done = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG10_OFFSET);
		while(!done) done = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG10_OFFSET);
		//once done, set the imagewen back to low
		AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG6_OFFSET, 0);
	}

	//Check if ready signal is high
	ready = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG11_OFFSET);
	while(!ready) ready = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG11_OFFSET);

	//write 1 into start_cal_in
	AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG9_OFFSET, 1);

	//Wait for done signal to be high
	done = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG10_OFFSET);
	while(!done) done = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG10_OFFSET);
	//Once done signal is high, read from the calc_out
	int ans = AXI_NOWEIGHTS_mReadReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG8_OFFSET);

	xil_printf("The NN predicts the image is %x\n", ans);

	//Once done reading the value, set the start_cal_in back to 0
	AXI_NOWEIGHTS_mWriteReg(XPAR_AXI_NOWEIGHTS_0_S00_AXI_BASEADDR, AXI_NOWEIGHTS_S00_AXI_SLV_REG9_OFFSET, 0);


	return 0;
}
