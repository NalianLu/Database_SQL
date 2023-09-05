/* MySQL2_Relate_DM.sql */
-- ******************************************************************************************
-- Problem_01: Order Entry Database Design
-- ******************************************************************************************
-- Customer Table
CREATE TABLE Customer
(CustNo 		CHAR(8),
CustFirstName 	VARCHAR(50)  NOT NULL,
CustLastName 	VARCHAR(50)  NOT NULL,  
CustStreet 		VARCHAR(100) NOT NULL,
CustCity 		VARCHAR(100) NOT NULL,
CustState 		CHAR(2)      NOT NULL,
CustZip 		CHAR(10)     NOT NULL,
CustBal 		DECIMAL(6,2),
-- Primary key
CONSTRAINT PKCustomer PRIMARY KEY (CustNo)
);

-- Employee Table
CREATE TABLE Employee
(EmpNo 			CHAR(8),
EmpFirstName 	VARCHAR(50)  NOT NULL,
EmpLastName 	VARCHAR(50)  NOT NULL,
EmpPhone 		CHAR(14),
SupEmpNo 		CHAR(8),
EmpCommRate		DECIMAL(3,2),
EmpEmail		VARCHAR(120) NOT NULL,
-- Primary key
CONSTRAINT PKEmployee PRIMARY KEY (EmpNo),
-- Unique key
CONSTRAINT UKEmployee UNIQUE KEY (EmpEmail)
);

-- OrderTbl Table
CREATE TABLE OrderTbl
(OrdNo 			CHAR(8),
OrdDate 		DATE         NOT NULL,
CustNo			CHAR(8)      NOT NULL,
EmpNo			CHAR(8),
OrdName			VARCHAR(100) NOT NULL,
OrdStreet		VARCHAR(100) NOT NULL,
OrdCity			VARCHAR(100) NOT NULL,
OrdState		CHAR(2)      NOT NULL,
OrdZip			CHAR(10)     NOT NULL,
-- Primary key
CONSTRAINT PKOrderTbl PRIMARY KEY (OrdNo),
-- Foreign keys
CONSTRAINT FKCustomer FOREIGN KEY (CustNo) REFERENCES Customer (CustNo),
CONSTRAINT FKEmployee FOREIGN KEY (EmpNo) REFERENCES Employee (EmpNo)
);

-- Product Table
CREATE TABLE Product
(ProdNo				CHAR(8),
 ProdName			VARCHAR(100) NOT NULL,
 ProdMfg			VARCHAR(100) NOT NULL,
 ProdQOH			INTEGER      NOT NULL,
 ProdPrice			DECIMAL(6,2) NOT NULL,
 ProdNextShipDate   DATE,
 -- Primary key
CONSTRAINT PKProduct PRIMARY KEY (ProdNo)
);

-- OrderLine Table
CREATE TABLE OrderLine
(OrdNo			CHAR(8),
 ProdNo			CHAR(8)      NOT NULL,
 Qty			INTEGER      NOT NULL,
 -- Primary key
CONSTRAINT PKOrderLine PRIMARY KEY (OrdNo, ProdNo),
 -- Foreign keys
CONSTRAINT FKOrderTbl FOREIGN KEY (OrdNo) 
    REFERENCES OrderTbl (OrdNo)
	ON UPDATE RESTRICT
	ON DELETE RESTRICT,
CONSTRAINT FKProduct FOREIGN KEY (ProdNo) 
    REFERENCES Product (ProdNo)
	ON UPDATE RESTRICT
	ON DELETE RESTRICT
);

-- Add self-referencing foreign key on the Employee table
-- DO NOT run until after all the employee have been imported!!!
ALTER TABLE Employee ADD 
  CONSTRAINT FKSupervisor FOREIGN KEY (SupEmpNo) 
    REFERENCES Employee (EmpNo);

-- ******************************************************************************************
-- Problem_02: Stack Exchange Database Design
-- ******************************************************************************************
-- Users Table
CREATE TABLE Users
(UserID        INTEGER,
Reputation     INTEGER       NOT NULL,
CreationDate   DATETIME      NOT NULL,
DisplayName    VARCHAR(100)  NOT NULL,
LastAccessDate DATETIME      NOT NULL,
WebsiteUrl     VARCHAR(300),
Location       VARCHAR(100),
AboutMe        TEXT,
Views          INTEGER       NOT NULL,
UpVotes        INTEGER       NOT NULL,
DownVotes      INTEGER       NOT NULL,
-- Primary key
CONSTRAINT PKUsers PRIMARY KEY (UserID)
);

-- Posts Table
CREATE TABLE Posts
(PostID          INTEGER,
PostTypeID       INTEGER  NOT NULL,
AcceptedAnswerID INTEGER,
ParentID         INTEGER,
CreationDate     DATETIME NOT NULL,
Score            INTEGER  NOT NULL,
ViewCount        INTEGER,
PostBody         TEXT,
OwnerUserId      INTEGER,
LastEditorUserId INTEGER,
LastEditDate     DATETIME,
LastActivityDate DATETIME NOT NULL,
Title            TEXT,
Tags             TEXT,
AnswerCount      INTEGER,
CommentCount     INTEGER  NOT NULL,
ClosedDate       DATETIME,
-- Primary key
CONSTRAINT PKPosts PRIMARY KEY (PostID),
-- Foreign keys
CONSTRAINT FKOwnerUserId FOREIGN KEY (OwnerUserId) REFERENCES Users (UserID),
CONSTRAINT FKLastEditorUserId FOREIGN KEY (LastEditorUserId) REFERENCES Users (UserID)
);

-- PostHistory table
CREATE TABLE PostHistory
(PostHistoryID    INTEGER,
PostHistoryTypeID INTEGER  NOT NULL,
PostID            INTEGER  NOT NULL,
CreationDate      DATETIME NOT NULL,
UserID            INTEGER,
PostText          TEXT,
PostComment       TEXT,
-- Primary key
CONSTRAINT PKPostHistory PRIMARY KEY (PostHistoryID),
-- Foreign keys
CONSTRAINT FKPostID FOREIGN KEY (PostID) REFERENCES Posts (PostID),
CONSTRAINT FKUserID FOREIGN KEY (UserID) REFERENCES Users (UserID)
);

-- Comments Table
CREATE TABLE Comments
(CommentID   INTEGER,
PostID       INTEGER  NOT NULL,
Score        INTEGER  NOT NULL,
CommentText  TEXT     NOT NULL,
CreationDate DATETIME NOT NULL,
UserID       INTEGER,
-- Primary key
CONSTRAINT PKComments PRIMARY KEY (CommentID),
-- Foreign keys
CONSTRAINT FKCommentsPostID FOREIGN KEY (PostID) REFERENCES Posts (PostID),
CONSTRAINT FKCommentsUserID FOREIGN KEY (UserID) REFERENCES Users (UserID)
);

-- Votes Table
CREATE TABLE Votes
(VoteID      INTEGER,
PostID       INTEGER  NOT NULL,
VoteTypeID   INTEGER  NOT NULL,
CreationDate DATETIME NOT NULL,
 -- Primary key
CONSTRAINT PKVotes PRIMARY KEY (VoteID),
-- Foreign keys
CONSTRAINT FKVotesPostID FOREIGN KEY (PostID) REFERENCES Posts (PostID)
);

-- Badges Table
CREATE TABLE Badges
(BadgeID   INTEGER,
UserID     INTEGER     NOT NULL,
BadgeName  VARCHAR(50) NOT NULL,
BadgeDate  DATETIME    NOT NULL,
BadgeClass INTEGER     NOT NULL,
TagBased   BOOLEAN     NOT NULL,
 -- Primary key
CONSTRAINT PKBadges PRIMARY KEY (BadgeID),
 -- Foreign keys
CONSTRAINT FKBadgesUserID FOREIGN KEY (UserID) REFERENCES Users (UserID)
);

-- Tags Table
CREATE TABLE Tags
(TagID          INTEGER,
TageName        VARCHAR(50) NOT NULL,
TagCount        INTEGER     NOT NULL,
IsRequired      BOOLEAN,
IsModeratorOnly BOOLEAN,
ExcerptPostID   INTEGER,
WikiPostID      INTEGER,
-- Primary key
CONSTRAINT PKTags PRIMARY KEY (TagID)
);

-- ******************************************************************************************
-- Problem_03: Employees Database Design
-- ******************************************************************************************
CREATE TABLE employees (
    emp_no      INT             NOT NULL,
    birth_date  DATE            NOT NULL,
    first_name  VARCHAR(14)     NOT NULL,
    last_name   VARCHAR(16)     NOT NULL,
    gender      ENUM ('M','F')  NOT NULL,    
    hire_date   DATE            NOT NULL,
    -- Primary key
	CONSTRAINT PKemployees PRIMARY KEY (emp_no)
);

CREATE TABLE departments (
    dept_no     CHAR(4)         NOT NULL,
    dept_name   VARCHAR(40)     NOT NULL,
    -- Primary key
	CONSTRAINT PKdepartments PRIMARY KEY (dept_no),
    -- Unique key
	CONSTRAINT UKdepartments UNIQUE KEY (dept_name)
);

CREATE TABLE dept_manager (
   emp_no       INT             NOT NULL,
   dept_no      CHAR(4)         NOT NULL,
   from_date    DATE            NOT NULL,
   to_date      DATE            NOT NULL,
   -- Compound primary key 
   CONSTRAINT PKdept_manager PRIMARY KEY (emp_no, dept_no),
   -- Foreign keys
   CONSTRAINT FKmanager_emp_no FOREIGN KEY (emp_no) REFERENCES employees (emp_no),
   CONSTRAINT FKmanager_dept_no FOREIGN KEY (dept_no) REFERENCES departments (dept_no)
); 

CREATE TABLE dept_emp (
    emp_no      INT             NOT NULL,
    dept_no     CHAR(4)         NOT NULL,
    from_date   DATE            NOT NULL,
    to_date     DATE            NOT NULL,
   -- Compound primary key
   CONSTRAINT PKdept_emp PRIMARY KEY (emp_no, dept_no),
   -- Foreign keys
   CONSTRAINT FKdept_emp_no FOREIGN KEY (emp_no) REFERENCES employees (emp_no),
   CONSTRAINT FKdept_no FOREIGN KEY (dept_no) REFERENCES departments (dept_no)
);

CREATE TABLE titles (
    emp_no      INT             NOT NULL,
    title       VARCHAR(50)     NOT NULL,
    from_date   DATE            NOT NULL,
    to_date     DATE,
   -- Compound primary key
   CONSTRAINT PKtitles PRIMARY KEY (emp_no, title, from_date),
   -- Foreign key
   CONSTRAINT FKtitles_emp_no FOREIGN KEY (emp_no) REFERENCES employees (emp_no)
); 

CREATE TABLE salaries (
    emp_no      INT             NOT NULL,
    salary      INT             NOT NULL,
    from_date   DATE            NOT NULL,
    to_date     DATE            NOT NULL,
   -- Compound primary key
   CONSTRAINT PKsalaries PRIMARY KEY (emp_no, from_date),
   -- Foreign key 
   CONSTRAINT FKsalaries FOREIGN KEY (emp_no) REFERENCES employees (emp_no)
);

