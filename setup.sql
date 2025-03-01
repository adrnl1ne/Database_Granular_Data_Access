USE master;
GO
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'ProjectDB')
    DROP DATABASE ProjectDB;
GO
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'basic')
    DROP LOGIN basic;
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'viewer')
    DROP LOGIN viewer;
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'editor')
    DROP LOGIN editor;
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'cell_editor')
    DROP LOGIN cell_editor;
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'admin')
    DROP LOGIN admin;
GO
CREATE DATABASE ProjectDB;
GO
USE ProjectDB;
GO
CREATE TABLE ClassifiedFiles (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Filename NVARCHAR(255),
    Content NVARCHAR(MAX),
    ClearanceLevel INT,
    Department NVARCHAR(50)
);
GO
CREATE TABLE Sec_UserColSecurity (
    UserName SYSNAME,
    ColumnName SYSNAME,
    HasAccess BIT,
    ClearanceLevelMax INT
);
GO
INSERT INTO Sec_UserColSecurity (UserName, ColumnName, HasAccess, ClearanceLevelMax) VALUES
('basic', 'ID', 1, 1),
('basic', 'Filename', 1, 1),
('basic', 'Content', 0, 1),
('basic', 'ClearanceLevel', 1, 1),
('basic', 'Department', 1, 1),
('viewer', 'ID', 1, 2),
('viewer', 'Filename', 1, 2),
('viewer', 'Content', 1, 2),
('viewer', 'ClearanceLevel', 1, 2),
('viewer', 'Department', 1, 2),
('editor', 'ID', 1, 3),
('editor', 'Filename', 1, 3),
('editor', 'Content', 1, 3),
('editor', 'ClearanceLevel', 1, 3),
('editor', 'Department', 1, 3),
('cell_editor', 'ID', 1, 3),
('cell_editor', 'Filename', 1, 3),
('cell_editor', 'Content', 1, 3),
('cell_editor', 'ClearanceLevel', 1, 3),
('cell_editor', 'Department', 1, 3),
('admin', 'ID', 1, 3),
('admin', 'Filename', 1, 3),
('admin', 'Content', 1, 3),
('admin', 'ClearanceLevel', 1, 3),
('admin', 'Department', 1, 3);
GO
CREATE LOGIN basic WITH PASSWORD = 'Basic456!';
CREATE LOGIN viewer WITH PASSWORD = 'View456!';
CREATE LOGIN editor WITH PASSWORD = 'Edit456!';
CREATE LOGIN cell_editor WITH PASSWORD = 'Cell456!';
CREATE LOGIN admin WITH PASSWORD = 'Admin123!';
CREATE USER basic FOR LOGIN basic;
CREATE USER viewer FOR LOGIN viewer;
CREATE USER editor FOR LOGIN editor;
CREATE USER cell_editor FOR LOGIN cell_editor;
CREATE USER admin FOR LOGIN admin;
GO
GRANT SELECT ON ClassifiedFiles TO basic;
GRANT SELECT ON ClassifiedFiles TO viewer;
GRANT SELECT, INSERT ON ClassifiedFiles TO editor;
GRANT SELECT, UPDATE(Content) ON ClassifiedFiles TO cell_editor;
GRANT CONTROL ON ClassifiedFiles TO admin;
GRANT SELECT ON Sec_UserColSecurity TO basic, viewer, editor, cell_editor, admin;
GO
CREATE FUNCTION dbo.fn_securityPredicate (@ClearanceLevel AS INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS fn_securityPredicate_result
    WHERE
        (USER_NAME() = 'basic' AND @ClearanceLevel = 1)
        OR (USER_NAME() = 'viewer' AND @ClearanceLevel <= 2)
        OR (USER_NAME() IN ('editor', 'cell_editor', 'admin'));
GO
CREATE SECURITY POLICY ClassifiedFilesPolicy
ADD FILTER PREDICATE dbo.fn_securityPredicate(ClearanceLevel) ON dbo.ClassifiedFiles
WITH (STATE = ON);
GO
INSERT INTO ClassifiedFiles (Filename, Content, ClearanceLevel, Department) VALUES
('memo1.txt', 'Public meeting notes', 1, 'HR'),
('report_q1.pdf', 'Employee performance stats', 2, 'HR'),
('budget_2025.xlsx', 'Financial projections', 3, 'Finance'),
('policy_update.doc', 'New hire guidelines', 1, 'HR'),
('audit_log.txt', 'Internal audit details', 3, 'Finance'),
('survey_results.csv', 'Staff feedback summary', 2, 'Operations'),
('contract_draft.pdf', 'Vendor termsConfidential', 3, 'Legal'),
('training_plan.ppt', 'Basic onboarding slides', 1, 'Training');
GO
CREATE VIEW ClassifiedFiles_Secure AS
    SELECT 
        ID,
        Filename,
        CASE WHEN EXISTS (SELECT 1 FROM Sec_UserColSecurity WHERE UserName = USER_NAME() AND ColumnName = 'Content' AND HasAccess = 1) 
             THEN Content ELSE NULL END AS Content,
        ClearanceLevel,
        Department
    FROM ClassifiedFiles;
GO
GRANT SELECT ON ClassifiedFiles_Secure TO basic, viewer, editor, cell_editor, admin;
GO
PRINT 'Database setup completed successfully!';