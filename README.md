# javaplsql
radek

/**************************************************************************************************************************************************/

Questão 9

Após rodar o script de geração da Procedure e da Função rodar o script para testar o procedimento:

DECLARE 
BEGIN
	INSERT INTO TCALL(OID, TIPO, SUBTIPO, DATA_CRIACAO) VALUES (4, 2, 3, SYSDATE);
	INSERT INTO TCALL(OID, TIPO, SUBTIPO, DATA_CRIACAO) VALUES (5, 1, 2, SYSDATE);
END;

SELECT * FROM OM_RECORD;

/**************************************************************************************************************************************************/

Questão 12 4º Na simulação no Oracle 11.2 SQL Developer para simulação do erro e efetuar o ROLLBACK descomentar e apagar /*FORÇA O ERRO e apagar */

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

Nos select é possível verificar o savepoint do rollback efetivado:

SELECT * FROM tarefas;
SELECT * FROM log_processos;
