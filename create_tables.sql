create table customers(
	customerkey int PRIMARY KEY,
	gender varchar(10),
	name varchar(50),
	city varchar(100),	
	state_code varchar(100),
	state varchar(100),
	zip_code varchar(20),
	country varchar(50),
	continent varchar(50),
	birthday date
);

create table products(
	productkey int PRIMARY KEY,
	productname varchar(100),
	brand varchar(50),
	color varchar(50),
	unitcostUSD dec(20,2),
	unitpriceUSD dec(20,2),
	subcategorykey int,
	subcategory	varchar(50),
	categorykey int,
	category varchar(30)
);

create table sales(
	ordernumber int,	
	line_item int,
	order_date date,
	customerkey int,
	storekey int,
	productkey int,
	quantity int,
	currency_code varchar(10)
);

create table stores(
	storekey int,
	country	 varchar(100),
	state varchar(100),
	square_meters int,
	open_date date
);	