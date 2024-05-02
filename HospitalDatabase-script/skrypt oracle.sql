-- Created by Vertabelo (http://vertabelo.com)
-- Last modification date: 2021-06-16 11:59:17.365

--1 Utworz procedure, w ktorej parametrach podasz date urodzenia pacjentow. Zostanie obliczone ich
--BMI i na wyjsciu program napisze, czy ich waga jest poprawna. Jesli nie, napisze ile
--pacjent musi schudnac do normalnej wagi, podajac jego imie i nazwisko.
Set Serveroutput on;
create or replace procedure pr1 (rok number)
as
cursor cur (v_rok int) is select imie,nazwisko,waga,wzrost from pacjent p join osoba o on p.idpacjent=o.idosoba
                                                where extract(year from data_urodzenia)=rok;
v_row cur%rowtype;
v_current number(10,2);
begin
    open cur(rok);
    loop
    fetch cur into v_row;
    exit when cur%NOTFOUND;
    v_current := v_row.waga/POWER((v_row.wzrost/100.0),2);
        if v_current>30 then
            dbms_output.put_line(v_row.imie || ' ' || v_row.nazwisko || ' powinien schudnac ' || 25.0*POWER(v_row.wzrost/100.0,2) || ' kg');
        end if;
    end loop;
    close cur;
end;
commit;

execute pr1 (1955);

--2. Utworz procedure, z argumentami imie i nazwisko. Jesli dana osoba nie jest lekarzem
-- z przynajmniej dwoma specjalizacjami, wyswietl informacje. Zwieksz jego wynagrodzenie o 10% i zwroc nowa pensje.
--Jesli nie zostana spelnione warunki, zwroc 0.
Set Serveroutput on;
create or replace procedure pr2 (im varchar2, naz varchar2, pens out number)
as 
v_var int;
begin
select count(1) into v_var
from osoba
where imie=im and nazwisko=naz and idosoba in (select idlekarz
                                                                                        from lekarz
                                                                                        group by idlekarz
                                                                                        having count(1)>1);
    if v_var>0 then
    select idosoba into v_var
        from osoba
            where imie=im and nazwisko=naz and idosoba in (select idlekarz
                                                                                                     from lekarz
                                                                                                        group by idlekarz
                                                                                                        having count(1)>1);
        update personel
        set pensja=1.1*pensja
        where idpersonel=v_var;
        select pensja into pens from personel where idpersonel=v_var;
    else
         pens:=0;
        dbms_output.put_line('Nie zostaly spelnione warunki');
    end if;
end;

declare pp number(10,2);
begin
pr2 ('Jaroslaw','Bednar',pp);
dbms_output.put_line(pp || 'zl');
end;

--WYZWALACZE

-- Utworz wyzwalacz, ktory po wpisaniu do tabeli Lek_Choroba nowego leku
--wypisze lek z maksymalna iloscia reakcji.

Set Serveroutput on;
create or replace trigger tr1
after insert or update on lek_choroba
declare 
v_liczba int;
v_id int;
v_nazwa varchar(30);
begin
    select count(reakcja),le.idlek into v_liczba,v_id
        from lek_choroba l
        join lek le
        on l.idlek=le.idlek
        group by le.idlek
        order by count(reakcja) desc
        fetch first 1 rows only;
        
        select nazwa into v_nazwa
            from lek
            where idlek=v_id;
        
     dbms_output.put_line(v_nazwa || ' z ' || v_liczba);
end;

insert into lek_choroba values (2,40,5,4);

--Utworz wyzwalacz, ktory po dodaniu do tabeli Personel nowego pracownika, wpisze go do tabeli
--Personel_Oddzial do oddzialu z najwieksza liczba pacjentow z godzina rozpoczenia pracy o 9:00 i konca o 15:00, jesli
--nie jest wolontariuszem (nie otrzymuje pensji).

Set Serveroutput on;
create or replace trigger t2
after insert on personel
for each row
declare id_oddzial int;
begin
    select s.idoddzial into id_oddzial
    from pacjent_w_sali p
    join sala s
    on p.idsala=s.idsala
    group by s.idoddzial
    having count(s.idoddzial)=(select max(count(s.idoddzial))
                                                from pacjent_w_sali p
                                                join sala s
                                                on p.idsala=s.idsala
                                                 group by s.idoddzial);
    if :new.pensja is not null  then
        insert into personel_oddzial
        values (:new.idpersonel,id_oddzial,'09:00','15:00'); 
    end if;
end;

insert into personel values (6,'2009/07/04',4670);

-- tables
-- Table: Miasto
CREATE TABLE Miasto (
    IdMiasto integer  NOT NULL,
    Miasto varchar2(50)  NOT NULL,
    CONSTRAINT Miasto_pk PRIMARY KEY (IdMiasto)
) ;
INSERT INTO Miasto VALUES(0,'Warszawa');
INSERT INTO Miasto VALUES(1,'Bytom');
INSERT INTO Miasto VALUES(2,'Plock');

-- tables
-- Table: Miasto
-- Table: Adres
CREATE TABLE Adres (
    IdAdres integer  NOT NULL,
    Ulica varchar2(50)  NOT NULL,
    NrBudynku varchar2(10)  NOT NULL,
    NrLokalu varchar2(10)  NULL,
    IdMiasto integer  NOT NULL,
    CONSTRAINT Adres_pk PRIMARY KEY (IdAdres)
) ;
INSERT INTO Adres VALUES(0,'Kwiatowa',8,NULL,0);
INSERT INTO Adres VALUES(1,'Marcowa',10,'5A',1);
INSERT INTO Adres VALUES(2,'Lesna',5,NULL,2);
INSERT INTO Adres VALUES(3,'Lesna',20,NULL,2);
INSERT INTO Adres VALUES(4,'Wodna',39,'A',0);
INSERT INTO Adres VALUES(5,'Zylna',5,NULL,1);

-- Table: Choroba
CREATE TABLE Choroba (
    IdChoroba integer  NOT NULL,
    Nazwa varchar2(50)  NOT NULL,
    CONSTRAINT Choroba_pk PRIMARY KEY (IdChoroba)
) ;
INSERT INTO Choroba VALUES (1,'Nowotwor');
INSERT INTO Choroba VALUES (2,'Zapalenie pluc');
INSERT INTO Choroba VALUES (3,'Covid-19');
INSERT INTO Choroba VALUES (4,'Zakrzepica');
INSERT INTO Choroba VALUES (5,'Zawal miesnia sercowego');
INSERT INTO Choroba VALUES (6,'Zlamanie');
INSERT INTO Choroba VALUES (7,'Przepuklina');

-- Table: Historia_Chorob
CREATE TABLE Historia_Chorob (
    IdHistoria_Chorob integer NOT NULL,
	IdLeczona_Choroba integer  NOT NULL,
    IdPacjent integer  NOT NULL,
    IdChoroba integer  NOT NULL,
    CONSTRAINT Historia_Chorob_pk PRIMARY KEY (IdHistoria_Chorob)
) ;

INSERT INTO Historia_Chorob VALUES (1,2,3,7);
INSERT INTO Historia_Chorob VALUES (2,6,12,6);
INSERT INTO Historia_Chorob VALUES (3,5,10,7);
INSERT INTO Historia_Chorob VALUES (4,1,2,1);
INSERT INTO Historia_Chorob VALUES (5,2,3,1);

-- Table: Objawy
CREATE TABLE Objawy (
    IdObjaw integer  NOT NULL,
    Objaw varchar2(50)  NOT NULL,
    CONSTRAINT Objawy_pk PRIMARY KEY (IdObjaw)
) ;
INSERT INTO Objawy VALUES (0,'Bol w klatce piersiowej');
INSERT INTO Objawy VALUES (1,'Wymioty');
INSERT INTO Objawy VALUES (2,'Kaszel');
INSERT INTO Objawy VALUES (3,'Bol nogi');
INSERT INTO Objawy VALUES (4,'Sennosc');
INSERT INTO Objawy VALUES (5,'Brak kontaktu');
-- Table: Leczona_Choroba
CREATE TABLE Leczona_Choroba (
    IdLeczona_Choroba integer  NOT NULL,
    IdPacjent integer  NOT NULL,
    IdChoroba integer  NOT NULL,
    Rozpoznanie date  NOT NULL,
    IdObjaw integer  NOT NULL,
    Stadium varchar2(20)  NULL,
    CONSTRAINT Leczona_Choroba_pk PRIMARY KEY (IdLeczona_Choroba)
) ;
INSERT INTO Leczona_Choroba VALUES (7,5,1,'1990-09-10',1,NULL);
INSERT INTO Leczona_Choroba VALUES (8,2,4,'1980-09-05',3,'I');
INSERT INTO Leczona_Choroba VALUES (1,2,1,'2013-10-17',0,'III');
INSERT INTO Leczona_Choroba VALUES (2,3,2,'2010-08-18',2,'I');
INSERT INTO Leczona_Choroba VALUES (3,7,5,'2010-02-01',3,NULL);
INSERT INTO Leczona_Choroba VALUES (4,9,6,'2012-05-23',3,NULL);
INSERT INTO Leczona_Choroba VALUES (5,10,4,'2017-07-19',0,'II');
INSERT INTO Leczona_Choroba VALUES (6,12,1,'2020-12-06',1,NULL);

-- Table: Lek
CREATE TABLE Lek (
    IdLek integer  NOT NULL,
    Nazwa varchar2(255)  NOT NULL,
    CONSTRAINT Lek_pk PRIMARY KEY (IdLek)
) ;
INSERT INTO LEK VALUES (1,'Paracetamol');
INSERT INTO LEK VALUES (2,'Penicylina benzylowa');
INSERT INTO LEK VALUES (3,'Amoksycylina');
INSERT INTO LEK VALUES (4,'Feksofenadyna');
INSERT INTO LEK VALUES (5,'Kloksacylina');

-- Table: Lek_Choroba
CREATE TABLE Lek_Choroba (
    IdLek integer  NOT NULL,
    Dawka number(10,2)  NOT NULL,
    IdLeczona_Choroba integer  NOT NULL,
    Reakcja integer  NULL,
    CONSTRAINT Lek_Choroba_pk PRIMARY KEY (IdLek)
) ;

INSERT INTO Lek_Choroba VALUES (1,3.2,3,1);
INSERT INTO Lek_Choroba VALUES (2,10,7,2);
INSERT INTO Lek_Choroba VALUES (3,30,2,4);
INSERT INTO Lek_Choroba VALUES (2,50,2,1);
INSERT INTO Lek_Choroba VALUES (5,60,4,NULL);

-- Table: Lekarz
CREATE TABLE Lekarz (
    IdLekarz integer  NOT NULL,
    IdSpecjalizacja integer  NULL,
	Ukonczenie_specjalizacji date  NULL
) ;

INSERT INTO Lekarz VALUES (1,NULL,NULL);
INSERT INTO Lekarz VALUES (4,2,'1994/08/01');
INSERT INTO Lekarz VALUES (5,2,'1998/10/05');
INSERT INTO Lekarz VALUES (5,3,'2003/12/20');
INSERT INTO Lekarz VALUES (8,1,'2004/09/17');
INSERT INTO Lekarz VALUES (11,3,'2011/02/09');

-- Table: NrBudynku
CREATE TABLE NrBudynku (
    IdBudynek integer  NOT NULL,
    Oznaczenie char(1)  NOT NULL,
    CONSTRAINT NrBudynku_pk PRIMARY KEY (IdBudynek)
) ;
INSERT INTO NrBudynku VALUES (1,'A');
INSERT INTO NrBudynku VALUES (2,'B');
INSERT INTO NrBudynku VALUES (3,'C');
INSERT INTO NrBudynku VALUES (4,'D');
INSERT INTO NrBudynku VALUES (5,'E');

-- Table: Oddzial
CREATE TABLE Oddzial (
    IdOddzial integer  NOT NULL,
    Nazwa varchar2(50)  NOT NULL,
    IdPietro integer  NOT NULL,
    CONSTRAINT Oddzial_pk PRIMARY KEY (IdOddzial)
) ;

INSERT INTO Oddzial VALUES (1,'Chirurgia ogolna',1);
INSERT INTO Oddzial VALUES (2,'Chorob wewnetrznych',1);
INSERT INTO Oddzial VALUES (3,'Intensywnej terapii',2);
INSERT INTO Oddzial VALUES (4,'Kardiologiczny',3);

-- Table: Osoba
CREATE TABLE Osoba (
    IdOsoba integer  NOT NULL,
    Imie varchar2(20)  NOT NULL,
    Nazwisko varchar2(20)  NOT NULL,
    Data_Urodzenia date  NOT NULL,
    CONSTRAINT Osoba_pk PRIMARY KEY (IdOsoba)
) ;
INSERT INTO OSOBA VALUES (1,'Magdalena','Osiecka','1990/05/23');
INSERT INTO OSOBA VALUES (2,'Jan','Cegla','1982/11/05');
INSERT INTO OSOBA VALUES (3,'Adam','Janczar','1955/01/11');
INSERT INTO OSOBA VALUES (4,'Anita','Kacprzak','1967/02/11');
INSERT INTO OSOBA VALUES (5,'Jaroslaw','Bednar','1967/03/28');
INSERT INTO OSOBA VALUES (6,'Anna','Jakiel','2005/12/30');
INSERT INTO OSOBA VALUES (7,'Jozef','Szczesny','1938/12/08');
INSERT INTO OSOBA VALUES (8,'Barbara','Sosna','1979/09/21');
INSERT INTO OSOBA VALUES (9,'Dawid','Adamski','1999/04/15');
INSERT INTO OSOBA VALUES (10,'Jaroslaw','Niedzielski','1949/02/26');
INSERT INTO OSOBA VALUES (11,'Antoni','Drewno','1980/03/14');
INSERT INTO OSOBA VALUES (12,'Katarzyna','Sosna','1995/10/18');
INSERT INTO OSOBA VALUES (13,'Janina','Sobczak','1968/04/27');

-- Table: Pacjent
CREATE TABLE Pacjent (
    IdPacjent integer  NOT NULL,
    DataPrzyjecia date  NOT NULL,
    PESEL varchar2(11)  NOT NULL,
    NrDowodu varchar2(20)  NOT NULL,
    Plec char(1)  NOT NULL,
    Waga integer  NOT NULL,
    Wzrost integer  NOT NULL,
    Adres integer  NOT NULL,
    CONSTRAINT Pacjent_pk PRIMARY KEY (IdPacjent)
) ;
INSERT INTO Pacjent VALUES (2,'2014/09/14','87102937581','DAB678567','M','89','180',0);
INSERT INTO Pacjent VALUES (3,'18/08/10','89643790854','AAC768543','M','160','193',1);
INSERT INTO Pacjent VALUES (7,'10/02/01','98065432145','BMA897543','M','86','175',2);
INSERT INTO Pacjent VALUES (9,'12/05/22','98745645678','SDA765432','M','98','178',3);
INSERT INTO Pacjent VALUES (10,'17/08/27','45637865432','HAD876543','M','60','170',4);
INSERT INTO Pacjent VALUES (12,'20/12/03','89765543219','MAC786543','K','56','166',5);

-- Table: Pacjent_W_Sali
CREATE TABLE Pacjent_W_Sali (
    IdSala integer  NOT NULL,
    IdPacjent integer  NOT NULL,
    CONSTRAINT Pacjent_W_Sali_pk PRIMARY KEY (IdSala,IdPacjent)
) ;
INSERT INTO Pacjent_W_Sali VALUES (1,2);
INSERT INTO Pacjent_W_Sali VALUES (2,3);
INSERT INTO Pacjent_W_Sali VALUES (2,7);
INSERT INTO Pacjent_W_Sali VALUES (3,9);
INSERT INTO Pacjent_W_Sali VALUES (3,10);
INSERT INTO Pacjent_W_Sali VALUES (3,12);

-- Table: Personel
CREATE TABLE Personel (
    IdPersonel integer  NOT NULL,
    Data_Zatrudnienia date  NOT NULL,
    Pensja number(10,2)  NULL,
    CONSTRAINT Personel_pk PRIMARY KEY (IdPersonel)
) ;
INSERT INTO Personel VALUES (1,'2018/05/13',2000);
INSERT INTO Personel VALUES (4,'1995/06/28',6230);
INSERT INTO Personel VALUES (5,'1996/11/02',5790);
INSERT INTO Personel VALUES (13,'1989/06/09',3800);
INSERT INTO Personel VALUES (6,'2021/04/21',NULL);
INSERT INTO Personel VALUES (8,'2009/07/04',4670);
INSERT INTO Personel VALUES (11,'2006/07/15',6000);

-- Table: Personel_Oddzial
CREATE TABLE Personel_Oddzial (
    IdPersonel_Oddzial integer NOT NULL,
    IdPersonel integer  NOT NULL,
    IdOddzial integer  NOT NULL,
    RozpPracy char(5)  NOT NULL,
    KoniecPracy char(5)  NOT NULL,
    CONSTRAINT Personel_Oddzial_pk PRIMARY KEY (IdPersonel_Oddzial)
) ;

INSERT INTO Personel_Oddzial VALUES (1,1,1,'08:00','15:00');
INSERT INTO Personel_Oddzial VALUES (2,4,2,'09:00','15:00');
INSERT INTO Personel_Oddzial VALUES (3,5,3,'09:30','14:00');
INSERT INTO Personel_Oddzial VALUES (4,5,3,'08:00','14:00');
INSERT INTO Personel_Oddzial VALUES (5,5,4,'08:00','17:00');

-- Table: Pietro
CREATE TABLE Pietro (
    IdPietro integer  NOT NULL,
	Nr_Pietra integer  NOT NULL,
    IdBudynek integer  NOT NULL,
    CONSTRAINT Pietro_pk PRIMARY KEY (IdPietro)
) ;
INSERT INTO Pietro VALUES (1,1,1);
INSERT INTO Pietro VALUES (2,1,2);
INSERT INTO Pietro VALUES (3,1,3);

-- Table: Sala
CREATE TABLE Sala (
    IdSala integer  NOT NULL,
    Miejsca integer  NOT NULL,
    IdOddzial integer  NOT NULL,
    CONSTRAINT Sala_pk PRIMARY KEY (IdSala)
) ;

INSERT INTO Sala VALUES (1,2,1);
INSERT INTO Sala VALUES (2,5,1);
INSERT INTO Sala VALUES (3,6,3);

-- Table: Specjalizacja
CREATE TABLE Specjalizacja (
    IdSpecjalizacja integer  NOT NULL,
    Nazwa varchar2(30)  NOT NULL,
    CONSTRAINT Specjalizacja_pk PRIMARY KEY (IdSpecjalizacja)
) ;
INSERT INTO Specjalizacja VALUES (1,'Geriatria');
INSERT INTO Specjalizacja VALUES (2,'Chirurgia ogolna');
INSERT INTO Specjalizacja VALUES (3,'Choroby wewnetrzne');

-- foreign keys
-- Reference: Historia_Chorob_Choroba (table: Historia_Chorob)
ALTER TABLE Historia_Chorob ADD CONSTRAINT Historia_Chorob_Choroba
    FOREIGN KEY (IdChoroba)
    REFERENCES Choroba (IdChoroba);

-- Reference: Historia_Chorob_Pacjent (table: Historia_Chorob)
ALTER TABLE Historia_Chorob ADD CONSTRAINT Historia_Chorob_Pacjent
    FOREIGN KEY (IdPacjent)
    REFERENCES Pacjent (IdPacjent);

-- Reference: Leczona_Choroba (table: Historia_Chorob)
ALTER TABLE Historia_Chorob ADD CONSTRAINT Leczona_Choroba
    FOREIGN KEY (IdLeczona_Choroba)
    REFERENCES Leczona_Choroba (IdLeczona_Choroba);

-- Reference: Leczona_Choroba_Choroba (table: Leczona_Choroba)
ALTER TABLE Leczona_Choroba ADD CONSTRAINT Leczona_Choroba_Choroba
    FOREIGN KEY (IdChoroba)
    REFERENCES Choroba (IdChoroba);

-- Reference: Leczona_Choroba_Objawy (table: Leczona_Choroba)
ALTER TABLE Leczona_Choroba ADD CONSTRAINT Leczona_Choroba_Objawy
    FOREIGN KEY (IdObjaw)
    REFERENCES Objawy (IdObjaw);

-- Reference: Leczona_Choroba_Pacjent (table: Leczona_Choroba)
ALTER TABLE Leczona_Choroba ADD CONSTRAINT Leczona_Choroba_Pacjent
    FOREIGN KEY (IdPacjent)
    REFERENCES Pacjent (IdPacjent);

-- Reference: Lek_Choroba_Leczona_Choroba (table: Lek_Choroba)
ALTER TABLE Lek_Choroba ADD CONSTRAINT Lek_Choroba_Leczona_Choroba
    FOREIGN KEY (IdLeczona_Choroba)
    REFERENCES Leczona_Choroba (IdLeczona_Choroba);

-- Reference: Lek_Choroba_Objawy (table: Lek_Choroba)
ALTER TABLE Lek_Choroba ADD CONSTRAINT Lek_Choroba_Objawy
    FOREIGN KEY (Reakcja)
    REFERENCES Objawy (IdObjaw);

-- Reference: Lekarz_Specjalizacja (table: Lekarz)
ALTER TABLE Lekarz ADD CONSTRAINT Lekarz_Specjalizacja
    FOREIGN KEY (IdSpecjalizacja)
    REFERENCES Specjalizacja (IdSpecjalizacja);

-- Reference: Lekarz_Specjalizacja_Personel (table: Lekarz)
ALTER TABLE Lekarz ADD CONSTRAINT Lekarz_Specjalizacja_Personel
    FOREIGN KEY (IdLekarz)
    REFERENCES Personel (IdPersonel);

-- Reference: Oddzial_Pietro (table: Oddzial)
ALTER TABLE Oddzial ADD CONSTRAINT Oddzial_Pietro
    FOREIGN KEY (IdPietro)
    REFERENCES Pietro (IdPietro);

-- Reference: Pacjent_Lek_Lek (table: Lek_Choroba)
ALTER TABLE Lek_Choroba ADD CONSTRAINT Pacjent_Lek_Lek
    FOREIGN KEY (IdLek)
    REFERENCES Lek (IdLek);

-- Reference: Pacjent_Osoba (table: Pacjent)
ALTER TABLE Pacjent ADD CONSTRAINT Pacjent_Osoba
    FOREIGN KEY (IdPacjent)
    REFERENCES Osoba (IdOsoba);

-- Reference: Pacjent_Ulica (table: Pacjent)
ALTER TABLE Pacjent ADD CONSTRAINT Pacjent_Ulica
    FOREIGN KEY (Adres)
    REFERENCES Adres (IdAdres);

-- Reference: Pacjent_W_Sali_Pacjent (table: Pacjent_W_Sali)
ALTER TABLE Pacjent_W_Sali ADD CONSTRAINT Pacjent_W_Sali_Pacjent
    FOREIGN KEY (IdPacjent)
    REFERENCES Pacjent (IdPacjent);

-- Reference: Pacjent_W_Sali_Sala (table: Pacjent_W_Sali)
ALTER TABLE Pacjent_W_Sali ADD CONSTRAINT Pacjent_W_Sali_Sala
    FOREIGN KEY (IdSala)
    REFERENCES Sala (IdSala);

-- Reference: Personel_Oddzial_Oddzial (table: Personel_Oddzial)
ALTER TABLE Personel_Oddzial ADD CONSTRAINT Personel_Oddzial_Oddzial
    FOREIGN KEY (IdOddzial)
    REFERENCES Oddzial (IdOddzial);

-- Reference: Personel_Oddzial_Personel (table: Personel_Oddzial)
ALTER TABLE Personel_Oddzial ADD CONSTRAINT Personel_Oddzial_Personel
    FOREIGN KEY (IdPersonel)
    REFERENCES Personel (IdPersonel);

-- Reference: Personel_Osoba (table: Personel)
ALTER TABLE Personel ADD CONSTRAINT Personel_Osoba
    FOREIGN KEY (IdPersonel)
    REFERENCES Osoba (IdOsoba);

-- Reference: Pietro_NrBudynku (table: Pietro)
ALTER TABLE Pietro ADD CONSTRAINT Pietro_NrBudynku
    FOREIGN KEY (IdBudynek)
    REFERENCES NrBudynku (IdBudynek);

-- Reference: Sala_Oddzial (table: Sala)
ALTER TABLE Sala ADD CONSTRAINT Sala_Oddzial
    FOREIGN KEY (IdOddzial)
    REFERENCES Oddzial (IdOddzial);

-- Reference: Ulica_Miasto (table: Adres)
ALTER TABLE Adres ADD CONSTRAINT Ulica_Miasto
    FOREIGN KEY (IdMiasto)
    REFERENCES Miasto (IdMiasto);

-- End of file.
