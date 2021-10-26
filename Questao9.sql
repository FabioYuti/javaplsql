CREATE OR REPLACE PROCEDURE sp_grava_record
(p_n_tipo NUMBER, p_n_subtipo NUMBER)
AS
	nOID		NUMBER;
	nNATUREZA	NUMBER;
	
BEGIN

	SELECT 	COALESCE(MAX(oid),0)+1 
	INTO	nOID
	FROM 	om_record;
	
	BEGIN
		SELECT 	natureza 
		INTO	nNATUREZA
		FROM 	om_record_natureza 
		WHERE	TIPO=p_n_tipo
		AND		SUBTIPO=p_n_subtipo;
		EXCEPTION
		WHEN NO_DATA_FOUND THEN
			nNATUREZA:=0;
	END;
	
	INSERT INTO om_record(oid,tipo,subtipo,natureza,data_criacao) VALUES
	(nOID,p_n_tipo,p_n_subtipo,nNATUREZA,SYSDATE);

END;
/

CREATE OR REPLACE TRIGGER T_INSERE_CALL
AFTER INSERT
   ON TCALL
   FOR EACH ROW

DECLARE
  v_n_tipo            NUMBER;
  v_n_subtipo            NUMBER;

BEGIN
 	v_n_tipo:=:NEW.TIPO;
  	v_n_subtipo:=:NEW.SUBTIPO;
  	IF INSERTING THEN
    	sp_grava_record(v_n_tipo,v_n_subtipo);
    END IF;
END;
/

