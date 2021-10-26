CREATE TABLE equipes
(	oid INT,
 	nome VARCHAR2(30),
 	nome_b1 VARCHAR2(30),
 	nome_b2 VARCHAR2(30),
 	nome_b3 VARCHAR2(30),
 	status INT,
 	CONSTRAINT check_status CHECK (status=0 OR status=1),
	CONSTRAINT pk_equipes PRIMARY KEY (oid)
);

CREATE TABLE tarefas
(	oid INT,
 	nome VARCHAR2(30),
 	data_criacao DATE,
 	area VARCHAR2(30),
 	equipe INT,
 	CONSTRAINT pk_tarefas PRIMARY KEY (oid)
);

CREATE TABLE log_processos
(	oid INT,
 	data DATE,
 	codigo INT,
 	descricao VARCHAR2(100),
 	CONSTRAINT pk_logprocessos PRIMARY KEY (oid)
);

CREATE OR REPLACE FUNCTION fc_sequencia_equipe
RETURN NUMBER
IS 	   nMaxId	NUMBER;
BEGIN

	SELECT 	nvl(max(oid),0)+1
	INTO	nMaxId
	FROM 	equipes;

   	Return nMaxId;
END;

INSERT INTO equipes VALUES (fc_sequencia_equipe(),'ALPHA1','MT_07019','13TRF','E08796',0);
INSERT INTO equipes VALUES (fc_sequencia_equipe(),'BETA2','MT_11606','13TRF','E08115',1);
INSERT INTO equipes VALUES (fc_sequencia_equipe(),'BETA1','MT_07901','13TRF','E09516',1);

CREATE OR REPLACE FUNCTION fc_sequencia_log_processos
RETURN NUMBER
IS 	   nMaxId	NUMBER;
BEGIN

	SELECT 	nvl(max(oid),0)+1
	INTO	nMaxId
	FROM 	log_processos;

   	Return nMaxId;
END;

/*----------------------12----------*/

CREATE OR REPLACE PACKAGE om_pkg_task
AS

  FUNCTION fc_sequencia_tarefa
  	RETURN NUMBER;
  
  FUNCTION fc_valida_equipe(p_s_equipe VARCHAR2,p_s_area VARCHAR2)
	RETURN NUMBER;
  
  PROCEDURE sp_grava_tarefa(p_s_id NUMBER,p_s_tarefa VARCHAR2,p_s_area VARCHAR2, p_n_equipe NUMBER);
  
  PROCEDURE sp_grava_log_processos(p_n_codigo NUMBER,p_s_descricao VARCHAR2);

END om_pkg_task;


CREATE OR REPLACE PACKAGE BODY om_pkg_task AS

	FUNCTION fc_sequencia_tarefa
	RETURN NUMBER
	IS 	   nMaxId	NUMBER;
	BEGIN
	
		SELECT 	nvl(max(oid),0)+1
		INTO	nMaxId
		FROM 	tarefas;
	
	   	Return nMaxId;
	END;


	FUNCTION fc_valida_equipe(p_s_equipe VARCHAR2,p_s_area VARCHAR2)
	RETURN NUMBER
	IS 	   
		nRetorno	NUMBER;
		nEquipe		NUMBER;
		nStatus		NUMBER;
	BEGIN
	
		BEGIN 
		   	SELECT OID,STATUS 
			INTO   nEquipe,nStatus 
			FROM   equipes 
			WHERE  NOME=P_S_EQUIPE
			AND    NOME_B1||'/'||NOME_B2||'/'||NOME_B3=P_S_AREA;
			EXCEPTION 
		    	WHEN no_data_found THEN
		        	nEquipe:=NULL;
		        	nStatus:=NULL;
	  	END;
		
		IF(nEquipe IS NULL) THEN 
			nRetorno:=-1;	
		ELSE
			IF(nStatus=0) THEN 
				nRetorno:=-2;
			ELSE
				nRetorno:=0;
			END IF;
		END if;
		
	   	Return nRetorno;
	END;
	
	PROCEDURE sp_grava_tarefa(p_s_id NUMBER,p_s_tarefa VARCHAR2,p_s_area VARCHAR2, p_n_equipe NUMBER)
	AS
	BEGIN
		INSERT INTO tarefas(oid,nome,data_criacao,area,equipe) VALUES
		(p_s_id,p_s_tarefa,SYSDATE,p_s_area,p_n_equipe);

	END;
	
	PROCEDURE sp_grava_log_processos
	(p_n_codigo NUMBER,p_s_descricao VARCHAR2)
	AS
	BEGIN
	
		INSERT INTO log_processos(oid,data,codigo,descricao) VALUES
		(fc_sequencia_log_processos(),SYSDATE,p_n_codigo,p_s_descricao);
	
	END;

END om_pkg_task;


DECLARE
  nSeqId NUMBER;
  nValidaEquipe NUMBER;
  nEquipe NUMBER;
  sEquipe VARCHAR(30);
  sArea VARCHAR(30);
  sTarefa VARCHAR(30);
BEGIN
	SAVEPOINT EXECUCAO_TAREFA; 
	sTarefa := 'Tarefa 1';
	sEquipe := 'BETA1';
	sArea	:= 'MT_07901/13TRF/E09516';
	nValidaEquipe:=om_pkg_task.fc_valida_equipe(sEquipe,'MT_07901/13TRF/E09516');
	
	IF(nValidaEquipe=0) THEN
		
		SELECT oid
		INTO   nEquipe 
		FROM   equipes 
		WHERE  nome = sEquipe
		AND    nome_b1||'/'||nome_b2||'/'||nome_b3 = sArea;
		
		nSeqId:=om_pkg_task.fc_sequencia_tarefa();
		om_pkg_task.sp_grava_tarefa(nSeqId,sTarefa,sArea,nEquipe);
	ELSE
		nSeqId:=om_pkg_task.fc_sequencia_tarefa();
		nEquipe:=0;
		om_pkg_task.sp_grava_tarefa(nSeqId,sTarefa,sArea,nEquipe);
	END IF;
	
	om_pkg_task.sp_grava_log_processos(nValidaEquipe,sTarefa||'-'||sEquipe||'-'||sArea);
	
	/*FORÇA O ERRO
	INSERT INTO tarefas(oid,nome,data_criacao,area,equipe) VALUES
	(1,'Tarefa 1',SYSDATE,'MT_07901/13TRF/E09516', 3);*/
	
	COMMIT;
	dbms_output.put_line('OPERAÇÃO FINALIZADA COM SUCESSO!');  	
	
  	EXCEPTION
	WHEN OTHERS THEN
		dbms_output.put_line('ERRO NA OPERAÇÃO!');
		ROLLBACK TO EXECUCAO_TAREFA;
			
END;

SELECT * FROM tarefas;
SELECT * FROM log_processos;