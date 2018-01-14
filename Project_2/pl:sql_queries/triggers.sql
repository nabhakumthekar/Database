create or replace TRIGGER insertCustomer
AFTER INSERT ON customers
for each row
declare 
currentUSER VARCHAR2(100); 
currentDate DATE;
nextLid number;
BEGIN
    select USER into currentUSER from dual; --store current user name into currentUSER local variable.
    --insert log entry into log table after a customer is inserted
    insert into logs(USER_NAME, OPERATION, OP_TIME, TABLE_NAME, TUPLE_PKEY) values(currentUSER, 'INSERT', SYSDATE, 'CUSTOMERS', :new.cid);
END;
/

CREATE OR REPLACE TRIGGER updateCustomer
after update of visits_made on customers
for each row
DECLARE
	currentUSER VARCHAR2(100);
BEGIN
	select USER into currentUSER from dual; --store current user name into currentUSER local variable.
    --insert log entry into log table after a customer is updated
	insert into logs(USER_NAME, OPERATION, OP_TIME, TABLE_NAME, TUPLE_PKEY) values(currentUSER, 'UPDATE', SYSDATE, 'CUSTOMERS', :new.cid);
END;
/

CREATE OR REPLACE TRIGGER insertPurchases
after insert on purchases
for each row
DECLARE
	currentUSER VARCHAR2(100);
BEGIN
	select USER into currentUSER from dual; --store current user name into currentUSER local variable.
    --insert log entry into log table after a purchase is inserted
    insert into logs(USER_NAME, OPERATION, OP_TIME, TABLE_NAME, TUPLE_PKEY) values(currentUSER, 'INSERT', SYSDATE, 'PURCHASES', :new.pur#);
END;
/

CREATE OR REPLACE TRIGGER updateProducts
after update of qoh on products
for each row
DECLARE
	currentUSER VARCHAR2(100);
BEGIN
	select USER into currentUSER from dual; --store current user name into currentUSER local variable.
    --insert log entry into log table after products qoh is updated
	insert into logs(USER_NAME, OPERATION, OP_TIME, TABLE_NAME, TUPLE_PKEY) values(currentUSER, 'UPDATE', SYSDATE, 'PRODUCTS', :new.pid);
END;
/

CREATE OR REPLACE TRIGGER insertSupplies
after insert on supplies
for each row
DECLARE
	currentUSER VARCHAR2(100);
BEGIN
	select USER into currentUSER from dual; --store current user name into currentUSER local variable.
    --insert log entry into log table after a record is inserted into supplies
    insert into logs(USER_NAME, OPERATION, OP_TIME, TABLE_NAME, TUPLE_PKEY) values(currentUSER, 'INSERT', SYSDATE, 'SUPPLIES', :new.sup#);
END;
/

create or replace trigger check_qoh_insertPurchases
after insert on purchases
for each row
declare 
	new_qoh number;
 	threshold number;
	supplies# char(2);
	supply_quantity number;
begin
	--decrease qoh for the product that customer purchased
	update products set qoh = qoh - :new.qty where pid = :new.pid;
	select qoh, qoh_threshold into new_qoh, threshold from products where pid = :new.pid;
	
 	IF (new_qoh < threshold) THEN
		select sid into supplies# from supplies where sup# in (select min(sup#) from supplies where pid = :new.pid);
		--calculate supply_quantity
		supply_quantity := 10 + ( threshold - new_qoh ) + 1 + new_qoh;
        
        --order supplies
		insert into supplies(PID, SID, SDATE, QUANTITY) values(:new.pid, supplies#, sysdate, supply_quantity);
		supply_quantity := supply_quantity + new_qoh;
		--Update qoh for product equal to the supply qty
		update products set qoh = supply_quantity where pid = :new.pid;
	END IF;
    
    --Update customers entry in the customers table
	update customers set visits_made = visits_made + 1, last_visit_date = :new.ptime where cid = :new.cid and last_visit_date <> :new.ptime;
end;
/


create or replace trigger deletePurchases
after delete on purchases
for each row
begin
	--increase qoh for the product that customer returned
	update products set qoh = qoh + :old.qty where pid = :old.pid;
	 	
	--Update visits made and last_visit_made of customers
	update customers set visits_made = visits_made + 1, last_visit_date = SYSDATE where cid = :old.cid;
end;
/










