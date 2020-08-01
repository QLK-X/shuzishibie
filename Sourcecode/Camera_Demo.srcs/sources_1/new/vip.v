`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/08/01 14:44:19
// Design Name: 
// Module Name: vip
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module vip(
    //module clock
    input           clk            ,  // ʱ���ź�
    input           rst_n          ,  // ��λ�źţ�����Ч��

    //ͼ����ǰ�����ݽӿ�
    input           pre_frame_vsync,
    input           pre_frame_hsync,
    input           pre_frame_de   ,
    input    [23:0] pre_rgb        ,
    input    [10:0] xpos           ,
    input    [10:0] ypos           ,

    //ͼ����������ݽӿ�
    output          post_frame_vsync,  // ��ͬ���ź�
    output          post_frame_hsync,  // ��ͬ���ź�
    output          post_frame_de   ,  // ��������ʹ��
    output   [23:0] post_rgb        ,  // RGB565��ɫ����

    //user interface
    output  [23:0]  digit              // ʶ�𵽵�����
);

//parameter define
parameter NUM_ROW = 1  ;               // ��ʶ���ͼ�������
parameter NUM_COL = 4  ;               // ��ʶ���ͼ�������
parameter H_PIXEL = 480;               // ͼ���ˮƽ����
parameter V_PIXEL = 272;               // ͼ��Ĵ�ֱ����
parameter DEPBIT  = 10 ;               // ����λ��

//wire define
wire   [ 7:0]         img_y;
wire                  monoc;
wire                  monoc_fall;
wire   [DEPBIT-1:0]   row_border_addr;
wire   [DEPBIT-1:0]   row_border_data;
wire   [DEPBIT-1:0]   col_border_addr;
wire   [DEPBIT-1:0]   col_border_data;
wire   [3:0]          num_col;
wire   [3:0]          num_row;
wire                  hs_t0;
wire                  vs_t0;
wire                  de_t0;
wire   [ 1:0]         frame_cnt;
wire                  project_done_flag;

//*****************************************************
//**                    main code
//*****************************************************

//RGBתYCbCrģ��
rgb2ycbcr u_rgb2ycbcr(
    //module clock
    .clk             (clk    ),            // ʱ���ź�
    .rst_n           (rst_n  ),            // ��λ�źţ�����Ч��
    //ͼ����ǰ�����ݽӿ�
    .pre_frame_vsync (pre_frame_vsync),    // vsync�ź�
    .pre_frame_hsync (pre_frame_hsync),    // href�ź�
    .pre_frame_de    (pre_frame_de   ),    // data enable�ź�
    .img_red         (pre_rgb[15:11] ),
    .img_green       (pre_rgb[10:5 ] ),
    .img_blue        (pre_rgb[ 4:0 ] ),
    //ͼ����������ݽӿ�
    .post_frame_vsync(vs_t0),               // vsync�ź�
    .post_frame_hsync(hs_t0),               // href�ź�
    .post_frame_de   (de_t0),               // data enable�ź�
    .img_y           (img_y),
    .img_cb          (),
    .img_cr          ()
);

//��ֵ��ģ��
binarization u_binarization(
    //module clock
    .clk                (clk    ),          // ʱ���ź�
    .rst_n              (rst_n  ),          // ��λ�źţ�����Ч��
    //ͼ����ǰ�����ݽӿ�
    .pre_frame_vsync    (vs_t0),            // vsync�ź�
    .pre_frame_hsync    (hs_t0),            // href�ź�
    .pre_frame_de       (de_t0),            // data enable�ź�
    .color              (img_y),
    //ͼ����������ݽӿ�
    .post_frame_vsync   (post_frame_vsync), // vsync�ź�
    .post_frame_hsync   (post_frame_hsync), // href�ź�
    .post_frame_de      (post_frame_de   ), // data enable�ź�
    .monoc              (monoc           ), // ��ɫͼ����������
    .monoc_fall         (monoc_fall      )
    //user interface
);

//ͶӰģ��
projection #(
    .NUM_ROW(NUM_ROW),
    .NUM_COL(NUM_COL),
    .H_PIXEL(H_PIXEL),
    .V_PIXEL(V_PIXEL),
    .DEPBIT (DEPBIT)
) u_projection(
    //module clock
    .clk                (clk    ),          // ʱ���ź�
    .rst_n              (rst_n  ),          // ��λ�źţ�����Ч��
    //Image data interface
    .frame_vsync        (post_frame_vsync), // vsync�ź�
    .frame_hsync        (post_frame_hsync), // href�ź�
    .frame_de           (post_frame_de   ), // data enable�ź�
    .monoc              (monoc           ), // ��ɫͼ����������
    .ypos               (ypos),
    .xpos               (xpos),
    //project border ram interface
    .row_border_addr_rd (row_border_addr),
    .row_border_data_rd (row_border_data),
    .col_border_addr_rd (col_border_addr),
    .col_border_data_rd (col_border_data),
    //user interface
    .num_col            (num_col),
    .num_row            (num_row),
    .frame_cnt          (frame_cnt),
    .project_done_flag  (project_done_flag)
);

//��������ʶ��ģ��
digital_recognition #(
    .NUM_ROW(NUM_ROW),
    .NUM_COL(NUM_COL),
    .H_PIXEL(H_PIXEL),
    .V_PIXEL(V_PIXEL),
    .NUM_WIDTH((NUM_ROW*NUM_COL<<2)-1)
)u_digital_recognition(
    //module clock
    .clk                (clk       ),        // ʱ���ź�
    .rst_n              (rst_n     ),        // ��λ�źţ�����Ч��
    //image data interface
    .monoc              (monoc     ),
    .monoc_fall         (monoc_fall),
    .color_rgb          (post_rgb  ),
    .xpos               (xpos      ),
    .ypos               (ypos      ),
    //project border ram interface
    .row_border_addr    (row_border_addr),
    .row_border_data    (row_border_data),
    .col_border_addr    (col_border_addr),
    .col_border_data    (col_border_data),
    .num_col            (num_col),
    .num_row            (num_row),
    //user interface
    .frame_cnt          (frame_cnt),
    .project_done_flag  (project_done_flag),
    .digit              (digit)
);

endmodule