use master;
begin
declare @sql nvarchar(max);
select @sql = coalesce(@sql,'') + 'kill ' + convert(varchar, spid) + ';'
from master..sysprocesses
where dbid in (db_id('MD360Gate'),db_id('AlamedaDB'),db_id('HarrisDB'),db_id('ParklandDB'),db_id('AlamedaDoctorDB'),db_id('ParklandDoctorDB'),db_id('HarrisNurseDB'),db_id('ParklandNurseDB')) and cmd = 'AWAITING COMMAND' and spid <> @@spid;
exec(@sql);
end;
go

if db_id('MD360Gate') 			is not null drop database MD360Gate;
if db_id('AlamedaDB') 			is not null drop database AlamedaDB;
if db_id('HarrisDB') 			is not null drop database HarrisDB;
if db_id('ParklandDB')  		is not null drop database ParklandDB;
if db_id('AlamedaDoctorDB') 	is not null drop database AlamedaDoctorDB;
if db_id('ParklandDoctorDB')  	is not null drop database ParklandDoctorDB;
if db_id('HarrisNurseDB') 		is not null drop database HarrisNurseDB;
if db_id('ParklandNurseDB')  	is not null drop database ParklandNurseDB;
create database AlamedaDB;
create database HarrisDB;
create database ParklandDB;
create database AlamedaDoctorDB;
create database ParklandDoctorDB;
create database HarrisNurseDB;
create database ParklandNurseDB;
go

use PdbLogic;
exec Pdbinstall 'MD360Gate',@ColumnName='ClinicId';
go

use MD360Gate;
exec PdbcreatePartition 'MD360Gate','AlamedaDB',1;
exec PdbcreatePartition 'MD360Gate','HarrisDB',2;
exec PdbcreatePartition 'MD360Gate','ParklandDB',3;
exec PdbcreatePartition 'MD360Gate','AlamedaDoctorDB',@DatabaseTypeId=6,@PrimaryDatabaseName='AlamedaDB';
exec PdbcreatePartition 'MD360Gate','ParklandDoctorDB',@DatabaseTypeId=6,@PrimaryDatabaseName='ParklandDB';
exec PdbcreatePartition 'MD360Gate','HarrisNurseDB',@DatabaseTypeId=6,@PrimaryDatabaseName='HarrisDB';
exec PdbcreatePartition 'MD360Gate','ParklandNurseDB',@DatabaseTypeId=6,@PrimaryDatabaseName='ParklandDB';

create table Clinics
	(	ClinicId			PartitionDBType 		not null primary key
	,	Name				nvarchar(128)			not null unique
	,	ClinicNumber		nvarchar(32)			not null unique
	);

create table Medicines
	(	ClinicId			PartitionDBType 		not null references Clinics (ClinicId)
	,	Id  				smallint identity(1,1) 	not null primary key
	,	Name				nvarchar(128)			not null unique
	);
	
create table Rooms
	(	ClinicId			PartitionDBType 		not null references Clinics (ClinicId)
	,	Id  				smallint identity(1,1) 	not null primary key
	,	Name				nvarchar(128)			not null unique
	,	Building			tinyint					not null
	,	Floor				tinyint					not null
	,	Room				tinyint					not null
	);
	
create table Patients
	(	ClinicId			PartitionDBType 		not null references Clinics (ClinicId)
	,	Id  				bigint identity(1,1) 	not null primary key
	,	FirstName			nvarchar(128)			not null
	,	LastName			nvarchar(128)			not null
	,	EMail				nvarchar(128)	
	,	PhoneNumber			nvarchar(64)
	,	Country				nvarchar(2)
	,	City				nvarchar(128)
	,	Address				nvarchar(256)
	,	PostalCode			nvarchar(8)	
	);
		
create table Doctors
	(	ClinicId			PartitionDBType 		not null references Clinics (ClinicId)
	,	Id  				bigint identity(1,1) 	not null primary key
	,	FirstName			nvarchar(128)			not null
	,	LastName			nvarchar(128)			not null
	,	EMail				nvarchar(128)	
	,	PhoneNumber			nvarchar(64)
	,	Country				nvarchar(2)
	,	City				nvarchar(128)
	,	Address				nvarchar(256)
	,	PostalCode			nvarchar(8)	
	);

create table Nurses
	(	ClinicId			PartitionDBType 		not null references Clinics (ClinicId)
	,	Id  				bigint identity(1,1) 	not null primary key
	,	FirstName			nvarchar(128)			not null
	,	LastName			nvarchar(128)			not null
	,	EMail				nvarchar(128)	
	,	PhoneNumber			nvarchar(64)
	,	Country				nvarchar(2)
	,	City				nvarchar(128)
	,	Address				nvarchar(256)
	,	PostalCode			nvarchar(8)	
	);	
	
create table Appointments
	(	ClinicId			PartitionDBType 		not null references Clinics (ClinicId)
	,	Id  				bigint identity(1,1) 	not null primary key
	,	PatientId			bigint					not null references Patients (Id)
	,	DoctorId			bigint					not null references Patients (Id)
	,	RoomId				smallint				not null references Rooms (Id)
	,	Date 				date					not null
	);

create table Prescriptions
	(	ClinicId			PartitionDBType 		not null references Clinics (ClinicId)
	,	Id  				bigint identity(1,1) 	not null primary key
	,	AppointmentId		bigint					not null references Appointments (Id)
	,	MedicineId			smallint				not null references Medicines (Id)
	,	Comment				nvarchar(256)			
	);

create table Treatments
	(	ClinicId			PartitionDBType 		not null references Clinics (ClinicId)
	,	Id  				bigint identity(1,1) 	not null primary key
	,	PatientId			bigint					not null references Patients (Id)
	,	NurseId				bigint					not null references Nurses (Id)
	,	MedicineId			smallint				not null references Medicines (Id)
	,	RoomId				smallint				not null references Rooms (Id)
	,	Date 				date					not null
	);	
	

exec PdbtargetSplitTable 'MD360Gate','dbo','Doctors','AlamedaDoctorDB';
exec PdbtargetSplitTable 'MD360Gate','dbo','Doctors','ParklandDoctorDB';
exec PdbtargetSplitTable 'MD360Gate','dbo','Appointments','AlamedaDoctorDB';
exec PdbtargetSplitTable 'MD360Gate','dbo','Appointments','ParklandDoctorDB';
exec PdbtargetSplitTable 'MD360Gate','dbo','Prescriptions','AlamedaDoctorDB';
exec PdbtargetSplitTable 'MD360Gate','dbo','Prescriptions','ParklandDoctorDB';
exec PdbtargetSplitTable 'MD360Gate','dbo','Nurses','HarrisNurseDB';
exec PdbtargetSplitTable 'MD360Gate','dbo','Nurses','ParklandNurseDB';
exec PdbtargetSplitTable 'MD360Gate','dbo','Treatments','HarrisNurseDB';
exec PdbtargetSplitTable 'MD360Gate','dbo','Treatments','ParklandNurseDB';

insert into PdbClinics (ClinicId,Name,ClinicNumber) values (1,'Alameda','001');
insert into PdbClinics (ClinicId,Name,ClinicNumber) values (2,'Harris','002');
insert into PdbClinics (ClinicId,Name,ClinicNumber) values (3,'Parkland','003');

insert into PdbMedicines (Name) values ('Xanax');
insert into PdbMedicines (Name) values ('Zoloft');
insert into PdbMedicines (Name) values ('Celexa');
insert into PdbMedicines (Name) values ('Prozac');
insert into PdbMedicines (Name) values ('Ativan');
insert into PdbMedicines (Name) values ('Desyrel');
insert into PdbMedicines (Name) values ('Lexapro');
insert into PdbMedicines (Name) values ('Cymbalta');
insert into PdbMedicines (Name) values ('Wellbutrin');
insert into PdbMedicines (Name) values ('Effexor');
insert into PdbMedicines (Name) values ('Valium');
insert into PdbMedicines (Name) values ('Paxil');
insert into PdbMedicines (Name) values ('Seroquel');
insert into PdbMedicines (Name) values ('Risperdal');
insert into PdbMedicines (Name) values ('Vyvanse');
insert into PdbMedicines (Name) values ('Concerta');
insert into PdbMedicines (Name) values ('Abilify');
insert into PdbMedicines (Name) values ('Buspar');
insert into PdbMedicines (Name) values ('Vistaril');
insert into PdbMedicines (Name) values ('Amphetamine');
insert into PdbMedicines (Name) values ('Zyprexa');
insert into PdbMedicines (Name) values ('Methylphenidate');
insert into PdbMedicines (Name) values ('Pristiq');

insert into PdbRooms (Name,Building,Floor,Room)
select 'Building '+right('0' + cast(Building as nvarchar(max)),2)+', Floor '+right('0' + cast(Floor as nvarchar(max)),2)+', Room '+right('0' + cast(Room as nvarchar(max)),2) Name,Building,Floor,Room
from (select top 2 row_number() over (order by number) Building from master..spt_values) Buildings
join (select top 10 row_number() over (order by number) Floor from master..spt_values) Floors on 1=1
join (select top 10 row_number() over (order by number) Room from master..spt_values) Rooms on 1=1;

insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (1,'Robin','Williams','robin.williams@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (1,'George','Carlin','george.carlin@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (1,'Louis','CK','louis.ck@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (1,'Richard','Pryor','richard.pryor@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (1,'Dave','Chappelle','dave.chappelle@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (1,'Chris','Rock','chris.rock@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (1,'Eddie','Murphy','eddie.murphy@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (1,'Jerry','Seinfeld','jerry.seinfeld@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (1,'Steve','Martin','steve.martin@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (1,'Kevin','Hart','kevin.hart@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (1,'Mitch','Hedberg','mitch.hedberg@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (1,'Rodney','Dangerfield','rodney.dangerfield@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (1,'Bill','Burr','bill.burr@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (1,'Bill','Cosby','bill.cosby@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (1,'Bill','Hicks','bill.hicks@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (1,'Lewis','Black','lewis.black@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (1,'Jim','Gaffigan','jim.gaffigan@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (1,'Steven','Wright','steven.wright@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (1,'Ricky','Gervais','ricky.gervais@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (1,'Jim','Carrey','jim.carrey@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (2,'Don','Rickles','don.rickles@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (2,'Zach','Galifianakis','zach.galifianakis@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (2,'Patton','Oswalt','patton.oswalt@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (2,'Will','Ferrell','will.ferrell@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (2,'Bernie','Mac','bernie.mac@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (2,'Aziz','Ansari','aziz.ansari@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (2,'Redd','Foxx','redd.foxx@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (2,'Jon','Stewart','jon.stewart@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (2,'Sam','Kinison','sam.kinison@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (2,'Bob','Newhart','bob.newhart@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (2,'Norm','Macdonald','norm.macdonald@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (2,'Ron','White','ron.white@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (2,'Ellen','DeGeneres','ellen.degeneres@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (2,'Daniel','Tosh','daniel.tosh@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (2,'Sarah','Silverman','sarah.silverman@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (2,'Jim','Jefferies','jim.jefferies@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (2,'Lenny','Bruce','lenny.bruce@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (2,'Chris','Farley','chris.farley@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (2,'Johnny','Carson','johnny.carson@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (2,'Craig','Ferguson','craig.ferguson@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (3,'Stephen','Colbert','stephen.colbert@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (3,'Russell','Peters','russell.peters@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (3,'Billy','Crystal','billy.crystal@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (3,'Mel','Brooks','mel.brooks@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (3,'Jonathan','Winters','jonathan.winters@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (3,'Gabriel','Iglesias','gabriel.iglesias@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (3,'David','Cross','david.cross@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (3,'Greg','Giraldo','greg.giraldo@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (3,'Adam','Sandler','adam.sandler@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (3,'Amy','Schumer','amy.schumer@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (3,'Bob','Hope','bob.hope@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (3,'Dave','Attell','dave.attell@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (3,'Joan','Rivers','joan.rivers@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (3,'Steve','Carell','steve.carell@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (3,'Bill','Maher','bill.maher@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (3,'John','Candy','john.candy@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (3,'Andy','Kaufman','andy.kaufman@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (3,'John','Oliver','john.oliver@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (3,'Eddie','Izzard','eddie.izzard@partitiondb.com');
insert into PdbPatients (ClinicId,FirstName,LastName,EMail) values (3,'Brian','Regan','brian.regan@partitiondb.com');

insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (1,'Michael','Jackson','michael.jackson@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (1,'Elvis','Presley','elvis.presley@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (1,'Paul','McCartney','paul.mccartney@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (1,'John','Lennon','john.lennon@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (1,'Marvin','Gaye','marvin.gaye@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (1,'Freddie','Mercury','freddie.mercury@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (1,'Frank','Sinatra','frank.sinatra@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (1,'George','Michael','george.michael@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (1,'Bruce','Springsteen','bruce.springsteen@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (1,'David','Bowie','david.bowie@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (1,'Mick','Jagger','mick.jagger@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (1,'Bob','Dylan','bob.dylan@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (1,'Stevie','Wonder','stevie.wonder@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (1,'Ray','Charles','ray.charles@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (1,'Tom','Jones','tom.jones@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (1,'Jon','Bon Jovi','jon.bon jovi@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (1,'Eric','Clapton','eric.clapton@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (1,'Neil','Diamond','neil.diamond@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (1,'John','Legend','john.legend@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (1,'Billy','Joel','billy.joel@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (2,'Phil','Collins','phil.collins@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (2,'Lionel','Richie','lionel.richie@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (2,'Jim','Morrison','jim.morrison@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (2,'Steven','Tyler','steven.tyler@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (2,'James','Taylor','james.taylor@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (2,'Rod','Stewart','rod.stewart@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (2,'Robert','Palmer','robert.palmer@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (2,'Paul','Simon','paul.simon@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (2,'Bryan','Adams','bryan.adams@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (2,'Peter','Gabriel','peter.gabriel@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (2,'Barry','Manilow','barry.manilow@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (2,'Roy','Orbison','roy.orbison@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (2,'James','Brown','james.brown@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (2,'Johnny','Cash','johnny.cash@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (2,'Jackson','Browne','jackson.browne@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (2,'Smokey','Robinson','smokey.robinson@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (2,'Steve','Perry','steve.perry@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (2,'Kenny','Loggins','kenny.loggins@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (2,'Barry','Gibb','barry.gibb@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (2,'Daryl','Hall','daryl.hall@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (3,'Andy','Gibb','andy.gibb@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (3,'Huey','Lewis','huey.lewis@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (3,'Cliff','Richard','cliff.richard@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (3,'Bruno','Mars','bruno.mars@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (3,'Don','Henley','don.henley@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (3,'Justin','Timberlake','justin.timberlake@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (3,'Neil','Young','neil.young@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (3,'Barry','White','barry.white@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (3,'Buddy','Holly','buddy.holly@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (3,'Usher','','usher@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (3,'R.','Kelly','r..kelly@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (3,'Billy','Idol','billy.idol@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (3,'Ricky','Martin','ricky.martin@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (3,'David','Lee Roth','david.lee roth@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (3,'Michael','Buble','michael.buble@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (3,'Elton','John','elton.john@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (3,'Bob','Marley','bob.marley@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (3,'John','Mayer','john.mayer@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (3,'Peter','Frampton','peter.frampton@partitiondb.com');
insert into PdbDoctors (ClinicId,FirstName,LastName,EMail) values (3,'Michael','McDonald','michael.mcdonald@partitiondb.com');

insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (1,'Whitney','Houston','whitney.houston@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (1,'Madonna','','madonna@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (1,'Stevie','Nicks','stevie.nicks@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (1,'Tina','Turner','tina.turner@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (1,'Donna','Summer','donna.summer@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (1,'Diana','Ross','diana.ross@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (1,'Olivia','Newton-John','olivia.newton-john@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (1,'Pat','Benatar','pat.benatar@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (1,'Carly','Simon','carly.simon@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (1,'Linda','Ronstadt','linda.ronstadt@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (1,'Karen','Carpenter','karen.carpenter@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (1,'Aretha','Franklin','aretha.franklin@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (1,'Bonnie','Raitt','bonnie.raitt@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (1,'Melissa','Etheridge','melissa.etheridge@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (1,'Mariah','Carey','mariah.carey@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (1,'Celine','Dion','celine.dion@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (1,'Cher','','cher@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (1,'Cyndi','Lauper','cyndi.lauper@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (1,'Debbie','Harry','debbie.harry@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (1,'Annie','Lennox','annie.lennox@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (2,'Gloria','Estefan','gloria.estefan@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (2,'Sheryl','Crow','sheryl.crow@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (2,'Janis','Joplin','janis.joplin@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (2,'Bette','Midler','bette.midler@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (2,'Barbra','Streisand','barbra.streisand@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (2,'Rita','Coolidge','rita.coolidge@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (2,'Dionne','Warwick','dionne.warwick@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (2,'Chaka','Khan','chaka.khan@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (2,'Patti','LaBelle','patti.labelle@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (2,'Gladys','Knight','gladys.knight@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (2,'Janet','Jackson','janet.jackson@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (2,'Paula','Abdul','paula.abdul@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (2,'Joan','Jett','joan.jett@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (2,'Belinda','Carlisle','belinda.carlisle@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (2,'Bonnie','Tyler','bonnie.tyler@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (2,'Sheena','Easton','sheena.easton@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (2,'Kim','Carnes','kim.carnes@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (2,'Juice','Newton','juice.newton@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (2,'Carole','King','carole.king@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (2,'Joni','Mitchell','joni.mitchell@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (3,'Adele','','adele@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (3,'Vanessa','Carlton','vanessa.carlton@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (3,'Kelly','Clarkson','kelly.clarkson@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (3,'Katy','Perry','katy.perry@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (3,'Christina','Aguilera','christina.aguilera@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (3,'Alicia','Keys','alicia.keys@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (3,'Norah','Jones','norah.jones@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (3,'Jennifer','Hudson','jennifer.hudson@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (3,'Beyonce','Knowles','beyonce.knowles@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (3,'Sade','','sade@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (3,'Mary','J.Blige','mary.j.blige@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (3,'Anita','Baker','anita.baker@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (3,'Toni','Braxton','toni.braxton@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (3,'Gloria','Gaynor','gloria.gaynor@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (3,'Natalie','Cole','natalie.cole@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (3,'Tracy','Chapman','tracy.chapman@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (3,'Laura','Branigan','laura.branigan@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (3,'Grace','Slick','grace.slick@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (3,'Chrissie','Hynde','chrissie.hynde@partitiondb.com');
insert into PdbNurses (ClinicId,FirstName,LastName,EMail) values (3,'Lady','Gaga','lady.gaga@partitiondb.com');
go

create synonym Hospitals 	for Clinics;
create synonym Drugs 		for Medicines;
create synonym Professors 	for Doctors;
create synonym Medics	 	for Nurses;
create synonym Customers	for Patients;
go

create view Users
as
	select FirstName,LastName,EMail,PhoneNumber,Country,City,Address,PostalCode
	from Doctors
	union all
	select FirstName,LastName,EMail,PhoneNumber,Country,City,Address,PostalCode
	from Nurses;
go
	
create procedure getDoctors
	(@ClinicId tinyint = null
	)
as
begin
	if @ClinicId is null
		select FirstName,LastName,EMail
		from PdbDoctors;
	else
		select FirstName,LastName,EMail
		from PdbDoctors
		where ClinicId = @ClinicId;
end;
go

create procedure getDoctorsPU
	(@ClinicId tinyint = null
	)
as
begin
	if @ClinicId is null
		select FirstName,LastName,EMail
		from PdbDoctors;
	else
		select FirstName,LastName,EMail
		from PdbDoctors
		where ClinicId = @ClinicId;
end;
go

create procedure getDoctorsPE
	(@ClinicId tinyint = null
	)
as
begin
	if @ClinicId is null
		select FirstName,LastName,EMail
		from PdbDoctors;
	else
		select FirstName,LastName,EMail
		from PdbDoctors
		where ClinicId = @ClinicId;
end;
go