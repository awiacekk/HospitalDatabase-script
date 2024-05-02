--Utworz procedure, w ktorej parametrach podasz date urodzenia pacjentow. Zostanie obliczone ich
--BMI i na wyjsciu program napisze, czy ich waga jest poprawna. Jesli nie, napisze ile
--pacjent musi schudnac do normalnej wagi, podajac jego imie i nazwisko.

alter procedure pr1 @rok int
as
declare cur cursor for select waga,wzrost,Data_Urodzenia,imie,nazwisko
							from pacjent p
								join osoba o
								on o.idosoba=p.IdPacjent;
declare @waga int,@wzrost int,@rokur date,@imie varchar(20),@nazwisko varchar(30);
begin
	open cur; 
	fetch next from cur into @waga,@wzrost,@rokur,@imie,@nazwisko;
	while @@FETCH_STATUS=0
	begin
		if year(@rokur)=@rok
		begin
			if @waga/POWER((@wzrost/100),2)>30
			print @imie+' '+@nazwisko+' powinien schudnac '+cast(25.0*POWER(@wzrost/100.0,2) as varchar(20))+' kg';
		end
		fetch next from cur into @waga,@wzrost,@rokur,@imie,@nazwisko;
	end;
	close cur;
	deallocate cur;
end;
go

exec pr1 1938;

--Utworz procedure, ktora sprawdzi, ktorzy lekarze posiadaja wiecej niz jedna specjalizacje,
--z czego jedna z nich zostanie podana w argumencie. Jesli podana specjalizacja nie
--istnieje, podnies blad. Zwieksz ich wynagrodzenie o 10%.

alter procedure pr2 @spec varchar(30)
as
declare @ile money;
begin
	if exists (select nazwa from Specjalizacja where nazwa=@spec )
	begin
		update personel 
			set pensja=1.1*pensja
			where idpersonel=(select idlekarz
								from lekarz l
								right join Specjalizacja s
								on l.IdSpecjalizacja=s.IdSpecjalizacja
									group by idlekarz
									having count(idlekarz)>1 and idlekarz in (select IdLekarz 
																				from lekarz l1 
																				right join Specjalizacja s1 
																				on l1.IdSpecjalizacja=s1.IdSpecjalizacja 
																				where nazwa=@spec));
	end;
	else
	raiserror('Specjalizacja nie istnieje',1,10);
end;
go

exec pr2 'Chirurgia ogolna';

-- Utworz wyzwalacz, ktory po dopisywaniu do tabeli personel_oddzial nowego pracownika sprawdzi, czy nie zostal
-- do niej dopisany juz wczesniej. W przeciwnym wypadku jego grafik zostanie zmieniony na godziny 8:00-15:00

alter trigger tr1 on personel_oddzial
after insert
as
declare @idper int,@idod int;
begin
set @idper = (select idpersonel from inserted)
set @idod = (select idoddzial from inserted)
if (select count(1) from Personel_Oddzial where IdPersonel=@idper)=1
		begin
			update Personel_Oddzial
			set RozpPracy='08:00', KoniecPracy='15:00'
			where idpersonel=@idper
		end;
        else 
        rollback;
end;
go

insert into Personel_Oddzial values (5,1,'00:00','00:00');
select * from Personel_Oddzial;

-- Utworz wyzwalacz, ktory przed dopisaniem pacjenta do nowej sali sprawdzi, czy nie
--przekroczono w niej liczby miejsc. W takim wypadku zglos blad.

alter trigger tr2 on pacjent_w_sali
for insert,update
as
declare @id_sala int;
begin
	set @id_sala=(select idsala from inserted);

	if (select count(1) from pacjent_w_sali group by idsala having idsala=@id_sala)>
	(select miejsca from sala where idsala=@id_sala)
	begin
	raiserror('Przekroczono liczbe pacjentow w sali',1,10);
	rollback;
	end;
end;
go

CREATE TABLE Miasto (
    IdMiasto integer identity NOT NULL,
    Miasto varchar(50)  NOT NULL,
    CONSTRAINT Miasto_pk PRIMARY KEY (IdMiasto)
) ;

INSERT INTO Miasto VALUES('Warszawa');
INSERT INTO Miasto VALUES('Bytom');
INSERT INTO Miasto VALUES('Plock');

CREATE TABLE Adres (
    IdAdres integer identity NOT NULL,
    Ulica varchar(50)  NOT NULL,
    NrBudynku varchar(10)  NOT NULL,
    NrLokalu varchar(10)  NULL,
    IdMiasto integer  NOT NULL,
    CONSTRAINT Adres_pk PRIMARY KEY (IdAdres)
) ;

INSERT INTO Adres VALUES('Kwiatowa',8,NULL,1);
INSERT INTO Adres VALUES('Marcowa',10,'5A',2);
INSERT INTO Adres VALUES('Lesna',5,NULL,3);
INSERT INTO Adres VALUES('Lesna',20,NULL,3);
INSERT INTO Adres VALUES('Wodna',39,'A',1);
INSERT INTO Adres VALUES('Zylna',5,NULL,2);

CREATE TABLE Choroba (
    IdChoroba integer identity NOT NULL,
    Nazwa varchar(50)  NOT NULL,
    CONSTRAINT Choroba_pk PRIMARY KEY (IdChoroba)
) ;

INSERT INTO Choroba VALUES ('Nowotwor');
INSERT INTO Choroba VALUES ('Zapalenie pluc');
INSERT INTO Choroba VALUES ('Covid-19');
INSERT INTO Choroba VALUES ('Zakrzepica');
INSERT INTO Choroba VALUES ('Zawal miesnia sercowego');
INSERT INTO Choroba VALUES ('Zlamanie');
INSERT INTO Choroba VALUES ('Przepuklina');

CREATE TABLE Historia_Chorob (
	IdLeczona_Choroba integer NOT NULL,
    IdPacjent integer  NOT NULL,
    IdChoroba integer  NOT NULL,
    CONSTRAINT Historia_Chorob_pk PRIMARY KEY (IdPacjent)
) ;
INSERT INTO Historia_Chorob VALUES (2,3,7);
INSERT INTO Historia_Chorob VALUES (6,12,6);
INSERT INTO Historia_Chorob VALUES (5,10,7);
INSERT INTO Historia_Chorob VALUES (1,2,1);
CREATE TABLE Objawy (
    IdObjaw integer identity NOT NULL,
    Objaw varchar(50)  NOT NULL,
    CONSTRAINT Objawy_pk PRIMARY KEY (IdObjaw)
) ;
INSERT INTO Objawy VALUES ('Bol w klatce piersiowej');
INSERT INTO Objawy VALUES ('Wymioty');
INSERT INTO Objawy VALUES ('Kaszel');
INSERT INTO Objawy VALUES ('Bol nogi');
INSERT INTO Objawy VALUES ('Sennosc');
INSERT INTO Objawy VALUES ('Brak kontaktu');

CREATE TABLE Leczona_Choroba (
    IdLeczona_Choroba integer identity NOT NULL,
    IdPacjent integer  NOT NULL,
    IdChoroba integer  NOT NULL,
    Rozpoznanie date  NOT NULL,
    IdObjaw integer  NOT NULL,
    Stadium varchar(20)  NULL,
    CONSTRAINT Leczona_Choroba_pk PRIMARY KEY (IdLeczona_Choroba)
) ;
INSERT INTO Leczona_Choroba VALUES (3,5,'1990-09-10',1,NULL);
INSERT INTO Leczona_Choroba VALUES (2,4,'1980-09-05',4,'I');
INSERT INTO Leczona_Choroba VALUES (2,1,'2013-10-17',1,'III');
INSERT INTO Leczona_Choroba VALUES (3,2,'2010-08-18',3,'I');
INSERT INTO Leczona_Choroba VALUES (7,5,'2010-02-01',4,NULL);
INSERT INTO Leczona_Choroba VALUES (9,6,'2012-05-23',4,NULL);
INSERT INTO Leczona_Choroba VALUES (10,4,'2017-07-19',1,'II');
INSERT INTO Leczona_Choroba VALUES (12,1,'2020-12-06',2,NULL);

CREATE TABLE Lek (
    IdLek integer identity NOT NULL,
    Nazwa varchar(255)  NOT NULL,
    CONSTRAINT Lek_pk PRIMARY KEY (IdLek)
) ;
INSERT INTO LEK VALUES ('Paracetamol');
INSERT INTO LEK VALUES ('Penicylina benzylowa');
INSERT INTO LEK VALUES ('Amoksycylina');
INSERT INTO LEK VALUES ('Feksofenadyna');
INSERT INTO LEK VALUES ('Kloksacylina');
CREATE TABLE Lek_Choroba (
    IdLek integer  NOT NULL,
    Dawka decimal(10,2)  NOT NULL,
    IdLeczona_Choroba integer  NOT NULL,
    Reakcja integer  NULL
) ;

INSERT INTO Lek_Choroba VALUES (1,3.2,3,1);
INSERT INTO Lek_Choroba VALUES (2,10,7,2);
INSERT INTO Lek_Choroba VALUES (3,30,2,4);
INSERT INTO Lek_Choroba VALUES (2,50,2,1);
INSERT INTO Lek_Choroba VALUES (5,60,4,NULL);
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
CREATE TABLE NrBudynku (
    IdBudynek integer identity NOT NULL,
    Oznaczenie char(1)  NOT NULL,
    CONSTRAINT NrBudynku_pk PRIMARY KEY (IdBudynek)
) ;
INSERT INTO NrBudynku VALUES ('A');
INSERT INTO NrBudynku VALUES ('B');
INSERT INTO NrBudynku VALUES ('C');
CREATE TABLE Oddzial (
    IdOddzial integer identity NOT NULL,
    Nazwa varchar(50)  NOT NULL,
    IdPietro integer  NOT NULL,
    CONSTRAINT Oddzial_pk PRIMARY KEY (IdOddzial)
) ;
INSERT INTO Oddzial VALUES ('Chirurgia ogolna',1);
INSERT INTO Oddzial VALUES ('Chorob wewnetrznych',1);
INSERT INTO Oddzial VALUES ('Intensywnej terapii',2);
INSERT INTO Oddzial VALUES ('Kardiologiczny',3);

CREATE TABLE Osoba (
    IdOsoba integer identity NOT NULL,
    Imie varchar(20)  NOT NULL,
    Nazwisko varchar(20)  NOT NULL,
    Data_Urodzenia date  NOT NULL,
    CONSTRAINT Osoba_pk1 PRIMARY KEY (IdOsoba)
) ;

INSERT INTO Osoba VALUES ('Magdalena','Osiecka','1990/05/23');
INSERT INTO Osoba VALUES ('Jan','Cegla','1982/11/05');
INSERT INTO Osoba VALUES ('Adam','Janczar','1955/01/11');
INSERT INTO Osoba VALUES ('Anita','Kacprzak','1967/02/11');
INSERT INTO Osoba VALUES ('Jaroslaw','Bednar','1967/03/28');
INSERT INTO Osoba VALUES ('Anna','Jakiel','2005/12/30');
INSERT INTO Osoba VALUES ('Jozef','Szczesny','1938/12/08');
INSERT INTO Osoba VALUES ('Barbara','Sosna','1979/09/21');
INSERT INTO Osoba VALUES ('Dawid','Adamski','1999/04/15');
INSERT INTO Osoba VALUES ('Jaroslaw','Niedzielski','1949/02/26');
INSERT INTO Osoba VALUES ('Antoni','Drewno','1980/03/14');
INSERT INTO Osoba VALUES ('Katarzyna','Sosna','1995/10/18');
INSERT INTO Osoba VALUES ('Janina','Sobczak','1968/04/27');

CREATE TABLE Pacjent (
    IdPacjent integer  NOT NULL,
    DataPrzyjecia date  NOT NULL,
    PESEL varchar(11)  NOT NULL,
    NrDowodu varchar(20)  NOT NULL,
    Plec char(1)  NOT NULL,
    Waga integer  NOT NULL,
    Wzrost integer  NOT NULL,
    Adres integer  NOT NULL,
    CONSTRAINT Pacjent_pk PRIMARY KEY (IdPacjent)
) ;

INSERT INTO Pacjent VALUES (2,'2014/09/14','87102937581','DAB678567','M','89','180',1);
INSERT INTO Pacjent VALUES (3,'2018/08/10','89643790854','AAC768543','M','160','193',2);
INSERT INTO Pacjent VALUES (7,'2010/02/01','98065432145','BMA897543','M','86','175',3);
INSERT INTO Pacjent VALUES (9,'2012/05/22','98745645678','SDA765432','M','98','178',4);
INSERT INTO Pacjent VALUES (10,'2017/08/27','45637865432','HAD876543','M','60','170',5);
INSERT INTO Pacjent VALUES (12,'2020/12/03','89765543219','MAC786543','K','56','166',6);

CREATE TABLE Pacjent_W_Sali (
    IdSala integer  NOT NULL,
    IdPacjent integer  NOT NULL,
    CONSTRAINT Pacjent_W_Sali_pk PRIMARY KEY (IdSala,IdPacjent)
) ;

INSERT INTO Pacjent_W_Sali VALUES (1,2);
INSERT INTO Pacjent_W_Sali VALUES (2,3);
INSERT INTO Pacjent_W_Sali VALUES (3,7);
INSERT INTO Pacjent_W_Sali VALUES (3,9);
INSERT INTO Pacjent_W_Sali VALUES (3,10);

CREATE TABLE Personel (
    IdPersonel integer  NOT NULL,
    Data_Zatrudnienia date  NOT NULL,
    Pensja decimal(10,2)  NULL,
    CONSTRAINT Personel_pk PRIMARY KEY (IdPersonel)
) ;

INSERT INTO Personel VALUES (1,'2018/05/13',2000);
INSERT INTO Personel VALUES (4,'1995/06/28',6230);
INSERT INTO Personel VALUES (5,'1996/11/02',5790);
INSERT INTO Personel VALUES (13,'1989/06/09',3800);
INSERT INTO Personel VALUES (6,'2021/04/21',NULL);
INSERT INTO Personel VALUES (8,'2009/07/04',4670);
INSERT INTO Personel VALUES (11,'2006/07/15',6000);

CREATE TABLE Personel_Oddzial (
    IdPersonel integer  NOT NULL,
    IdOddzial integer  NOT NULL,
    RozpPracy char(5)  NOT NULL,
    KoniecPracy char(5)  NOT NULL
) ;

INSERT INTO Personel_Oddzial VALUES (1,1,'08:00','15:00');
INSERT INTO Personel_Oddzial VALUES (4,4,'09:00','15:00');
INSERT INTO Personel_Oddzial VALUES (5,3,'09:30','14:00');
INSERT INTO Personel_Oddzial VALUES (5,2,'08:00','14:00');
INSERT INTO Personel_Oddzial VALUES (5,2,'08:00','17:00');

CREATE TABLE Pietro (
    IdPietro integer identity NOT NULL,
	Nr_Pietra integer  NOT NULL,
    IdBudynek integer  NOT NULL,
    CONSTRAINT Pietro_pk PRIMARY KEY (IdPietro)
) ;

INSERT INTO Pietro VALUES (2,1);
INSERT INTO Pietro VALUES (2,2);
INSERT INTO Pietro VALUES (2,3);

CREATE TABLE Sala (
    IdSala integer identity NOT NULL,
    Miejsca integer  NOT NULL,
    IdOddzial integer  NOT NULL,
    CONSTRAINT Sala_pk PRIMARY KEY (IdSala)
) ;

INSERT INTO Sala VALUES (2,1);
INSERT INTO Sala VALUES (5,1);
INSERT INTO Sala VALUES (6,3);

CREATE TABLE Specjalizacja (
    IdSpecjalizacja integer identity NOT NULL,
    Nazwa varchar(30)  NOT NULL,
    CONSTRAINT Specjalizacja_pk PRIMARY KEY (IdSpecjalizacja)
) ;

INSERT INTO Specjalizacja VALUES ('Geriatria');
INSERT INTO Specjalizacja VALUES ('Chirurgia ogolna');
INSERT INTO Specjalizacja VALUES ('Choroby wewnetrzne');

ALTER TABLE Historia_Chorob add CONSTRAINT Historia_Chorob_Choroba
    FOREIGN KEY (IdChoroba)
    REFERENCES Choroba (IdChoroba);

-- Reference: Historia_Chorob_Pacjent (table: Historia_Chorob)
ALTER TABLE Historia_Chorob add CONSTRAINT Historia_Chorob_Pacjent
    FOREIGN KEY (IdPacjent)
    REFERENCES Pacjent (IdPacjent);

-- Reference: Leczona_Choroba (table: Historia_Chorob)
--ALTER TABLE Historia_Chorob add CONSTRAINT Leczona_Choroba
--    FOREIGN KEY (IdLeczona_Choroba)
--    REFERENCES Leczona_Choroba (IdLeczona_Choroba);

-- Reference: Leczona_Choroba_Choroba (table: Leczona_Choroba)
ALTER TABLE Leczona_Choroba add CONSTRAINT Leczona_Choroba_Choroba
    FOREIGN KEY (IdChoroba)
    REFERENCES Choroba (IdChoroba);

-- Reference: Leczona_Choroba_Objawy (table: Leczona_Choroba)
ALTER TABLE Leczona_Choroba add CONSTRAINT Leczona_Choroba_Objawy
    FOREIGN KEY (IdObjaw)
    REFERENCES Objawy (IdObjaw);

-- Reference: Leczona_Choroba_Pacjent (table: Leczona_Choroba)
ALTER TABLE Leczona_Choroba add CONSTRAINT Leczona_Choroba_Pacjent
    FOREIGN KEY (IdPacjent)
    REFERENCES Pacjent (IdPacjent);

-- Reference: Lek_Choroba_Leczona_Choroba (table: Lek_Choroba)
ALTER TABLE Lek_Choroba add CONSTRAINT Lek_Choroba_Leczona_Choroba
    FOREIGN KEY (IdLeczona_Choroba)
    REFERENCES Leczona_Choroba (IdLeczona_Choroba);

-- Reference: Lek_Choroba_Objawy (table: Lek_Choroba)
ALTER TABLE Lek_Choroba add CONSTRAINT Lek_Choroba_Objawy
    FOREIGN KEY (Reakcja)
    REFERENCES Objawy (IdObjaw);

-- Reference: Lekarz_Specjalizacja (table: Lekarz)
ALTER TABLE Lekarz add CONSTRAINT Lekarz_Specjalizacja
    FOREIGN KEY (IdSpecjalizacja)
    REFERENCES Specjalizacja (IdSpecjalizacja);

-- Reference: Lekarz_Specjalizacja_Personel (table: Lekarz)
ALTER TABLE Lekarz add CONSTRAINT Lekarz_Specjalizacja_Personel
    FOREIGN KEY (IdLekarz)
    REFERENCES Personel (IdPersonel);

-- Reference: Oddzial_Pietro (table: Oddzial)
ALTER TABLE Oddzial add CONSTRAINT Oddzial_Pietro
    FOREIGN KEY (IdPietro)
    REFERENCES Pietro (IdPietro);

-- Reference: Pacjent_Lek_Lek (table: Lek_Choroba)
ALTER TABLE Lek_Choroba add CONSTRAINT Pacjent_Lek_Lek
    FOREIGN KEY (IdLek)
    REFERENCES Lek (IdLek);

-- Reference: Pacjent_Osoba (table: Pacjent)
ALTER TABLE Pacjent add CONSTRAINT Pacjent_Osoba
    FOREIGN KEY (IdPacjent)
    REFERENCES Osoba (IdOsoba);

-- Reference: Pacjent_Ulica (table: Pacjent)
ALTER TABLE Pacjent add CONSTRAINT Pacjent_Ulica
    FOREIGN KEY (Adres)
    REFERENCES Adres (IdAdres);

-- Reference: Pacjent_W_Sali_Pacjent (table: Pacjent_W_Sali)
ALTER TABLE Pacjent_W_Sali add CONSTRAINT Pacjent_W_Sali_Pacjent
    FOREIGN KEY (IdPacjent)
    REFERENCES Pacjent (IdPacjent);

-- Reference: Pacjent_W_Sali_Sala (table: Pacjent_W_Sali)
ALTER TABLE Pacjent_W_Sali add CONSTRAINT Pacjent_W_Sali_Sala
    FOREIGN KEY (IdSala)
    REFERENCES Sala (IdSala);

-- Reference: Personel_Oddzial_Oddzial (table: Personel_Oddzial)
ALTER TABLE Personel_Oddzial add CONSTRAINT Personel_Oddzial_Oddzial
    FOREIGN KEY (IdOddzial)
    REFERENCES Oddzial (IdOddzial);

-- Reference: Personel_Oddzial_Personel (table: Personel_Oddzial)
ALTER TABLE Personel_Oddzial add CONSTRAINT Personel_Oddzial_Personel
    FOREIGN KEY (IdPersonel)
    REFERENCES Personel (IdPersonel);

-- Reference: Personel_Osoba (table: Personel)
ALTER TABLE Personel add CONSTRAINT Personel_Osoba
    FOREIGN KEY (IdPersonel)
    REFERENCES Osoba (IdOsoba);

-- Reference: Pietro_NrBudynku (table: Pietro)
ALTER TABLE Pietro add CONSTRAINT Pietro_NrBudynku
    FOREIGN KEY (IdBudynek)
    REFERENCES NrBudynku (IdBudynek);

-- Reference: Sala_Oddzial (table: Sala)
ALTER TABLE Sala add CONSTRAINT Sala_Oddzial
    FOREIGN KEY (IdOddzial)
    REFERENCES Oddzial (IdOddzial);

-- Reference: Ulica_Miasto (table: Adres)
ALTER TABLE Adres add CONSTRAINT Ulica_Miasto
    FOREIGN KEY (IdMiasto)
    REFERENCES Miasto (IdMiasto);

DBCC CHECKIDENT (leczona_choroba, RESEED, 0)

insert into pacjent_w_sali values (3,3);
