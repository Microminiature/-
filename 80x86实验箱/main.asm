IOY0       EQU 0600H                   ;IOY0��ʼ��ַ
IOY1       EQU 0640H                   ;IOY1��ʼ��ַ
IOY2       EQU 0680H

M8251_DATA EQU IOY0+00H*2
M8251_CON  EQU IOY0+01H*2

M8254_2    EQU IOY1+02H*2
M8254_CON  EQU IOY1+03H*2

M8255_A    EQU IOY2+00H*2     ;8255��A�ڵ�ַ
M8255_B    EQU IOY2+01H*2     ;8255��B�ڵ�ַ
M8255_C    EQU IOY2+02H*2     ;8255��C�ڵ�ַ
M8255_CON  EQU IOY2+03H*2     ;8255�Ŀ��ƼĴ�����ַ


SSTACK SEGMENT STACK
	       DW 64 DUP(?)
SSTACK	ENDS

DDATA SEGMENT
	VAL   DB 3 DUP(?)
	PAUSE DB 0
DDATA ENDS
CODE SEGMENT
	              ASSUME CS:CODE,DS:DDATA
	START:        
	;װ���ж�������
	              PUSH   DS
	              MOV    AX,0000H
	              MOV    DS,AX
	              MOV    AX,OFFSET MIR7
	              MOV    SI,003CH        	;װ�ж���������װIP
	              MOV    [SI],AX
	              MOV    AX,CS
	              MOV    SI,003EH        	;װ�ж�������CS
	              MOV    [SI],AX
	              CLI                    	;�жϱ�־λ��0������Ӧ�������ж�
	              POP    DS
		     
	              MOV    AL,11H
	              OUT    20H,AL          	;ICW1
	              MOV    AL,08H
	              OUT    21H,AL          	;ICW2
	              MOV    AL,04H
	              OUT    21H,AL          	;ICW3
	              MOV    AL,01H
	              OUT    21H,AL          	;ICW4
	              MOV    AL,6FH
	              OUT    21H,AL          	;OCW1 0110 1111 ����4���жϴ�����
	              STI
		    
	              MOV    AX,DDATA
	              MOV    DS,AX           	;װ���ݶ�
			
	;��ʼ��8254
	              MOV    AL, 096H        	;��ʼ��8254,������2����д��8λ����ʽ3
	              MOV    DX, M8254_CON
	              OUT    DX, AL
	              MOV    AL, 0CH         	;���ó�ֵ12,
	              MOV    DX, M8254_2
	              OUT    DX, AL          	;��ʼ����
	              
	;��ʼ��8255
	              MOV    DX,M8255_CON    	;���ƼĴ�����ַ
	              MOV    AL,80H          	;ABC�ھ��������,��ʽ0�����������
	              OUT    DX,AL           	;��8255�����ּĴ���д�뷽ʽ��

	;��ʼ��8251A
	              MOV    CX,03H
	              MOV    DX,M8251_CON
	              MOV    AX,00H          	;������00h
	FLAG1:        
	              OUT    DX,AX
	              LOOP   FLAG1
	              CALL   DELAY
	         
	              MOV    AL, 40H
	              OUT    DX, AL          	;��λ8251A
	              CALL   DELAY
		  
	              MOV    AL, 07EH        	;ʹ�ò���������16��żУ��һλֹͣλ��8λ����λ
	              OUT    DX, AL
	              CALL   DELAY
	         
	              MOV    AL, 34H         	;�����ն�׼���ã�������գ���������־
	              OUT    DX, AL
	              CALL   DELAY

	              MOV    AX, 0152H       	;�����ʾ�ַ�R��ʾREADY
	              INT    10H

	LABEL_RECIEVE:
	              LEA    SI,VAL
	              MOV    CX, 03H
	RECIEVE:      
	              MOV    DX,M8251_CON    	;��ѯ״̬��
	WAITS:        
	              MOV    PAUSE,0
	              IN     AL, DX
	;CALL   DELAY
	              TEST   AL, 02H         	;���Խ������Ƿ�׼����
	              JZ     WAITS

	              MOV    DX, M8251_DATA
	              IN     AL, DX
			
	              MOV    [SI],AL         	;����������д��3000H..3000AH
	              INC    SI
	              LOOP   RECIEVE

	              MOV    DX,M8255_A
	              MOV    AL,VAL[0]
	              OUT    DX,AL           	;��ʾ��ˮ�Ƴ�ֵ
	              MOV    DX,M8255_B
	              OUT    DX,AL           	;B�ھ�����ʾ
	DISP:         
	              CMP    PAUSE,1
	              JZ     LABEL_RECIEVE   	;��⵽��Ƭ�������µĿ����źţ���ת���յȴ�
				  
	              CMP    VAL[1],0
	              JZ     LEFT            	;��ˮ�Ʒ���0��1��
	              ROR    AL,1
	              JMP    SHOW
	LEFT:         
	              ROL    AL,1
	SHOW:         
	              XOR    BX,BX
	              MOV    BL,VAL[2]
	              MOV    CX,11
	              SUB    CX,BX
	              CMP    CX,11
	              JZ     DONTMOVE        	;����ٶ���0������ֱ������������һ�����ݵĵȴ�
	SPEED:        
	              CALL   DELAY
	              LOOP   SPEED

	              MOV    DX,M8255_A
	              OUT    DX,AL
	              MOV    DX,M8255_B
	              OUT    DX,AL
	              
	              JMP    DISP
	DONTMOVE:     
	              JMP    LABEL_RECIEVE
				  
	;�ж��ӳ̣���PAUSE��־λΪ1
	MIR7:         STI
	              MOV    PAUSE,1
	              MOV    AL,20H
	              OUT    20H,AL
	              IRET
	DELAY:        
	              PUSH   CX
	              MOV    CX, 3000H
	FLAG2:        PUSH   AX
	              POP    AX
	              LOOP   FLAG2
	              POP    CX
	              RET
CODE	ENDS
  END       START 